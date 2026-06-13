import Anthropic from "@anthropic-ai/sdk";

export interface Env {
  ANTHROPIC_API_KEY: string;
  RATE_LIMIT: KVNamespace;
  DAILY_MESSAGE_LIMIT: string;
}

/// Persona del Coach Solare. È statica → cache_control per il prompt caching,
/// così i token del system prompt costano ~10% dalla seconda richiesta in poi.
const COACH_SYSTEM_PROMPT = `Sei il "Coach Solare" dell'app Solea, esperto di esposizione al sole e abbronzatura sana.
Aiuti l'utente ad abbronzarsi al meglio SENZA scottarsi. Tono amichevole, motivante, conciso (max 3-4 frasi).
Usi il contesto fornito (fototipo Fitzpatrick, indice UV attuale, riepilogo sessioni) per dare consigli concreti e personalizzati.
Dai indicazioni pratiche su tempi di esposizione, SPF, idratazione e doposole.
NON fornisci diagnosi o consigli medici: per dubbi sulla pelle rimandi sempre a un dermatologo.
Rispondi nella lingua dell'utente (italiano se ti scrive in italiano).`;

interface CoachRequest {
  userId: string;
  userContext: string;
  messages: Array<{ role: "user" | "assistant"; content: string }>;
}

function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "content-type": "application/json" },
  });
}

/// Conteggio giornaliero per utente su KV. La chiave scade a fine giornata UTC.
async function checkAndIncrementRateLimit(env: Env, userId: string): Promise<boolean> {
  const limit = Number.parseInt(env.DAILY_MESSAGE_LIMIT, 10);
  if (!Number.isFinite(limit) || limit <= 0) {
    // Configurazione errata: meglio fallire chiaramente che ignorare il limite.
    throw new Error("DAILY_MESSAGE_LIMIT non valido");
  }
  const today = new Date().toISOString().slice(0, 10);
  const key = `rl:${userId}:${today}`;
  const current = Number.parseInt((await env.RATE_LIMIT.get(key)) ?? "0", 10);
  if (current >= limit) {
    return false;
  }
  // Scadenza a 24h: la chiave si autopulisce.
  await env.RATE_LIMIT.put(key, String(current + 1), { expirationTtl: 60 * 60 * 24 });
  return true;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return jsonError(405, "Usa POST.");
    }
    if (!env.ANTHROPIC_API_KEY) {
      return jsonError(500, "ANTHROPIC_API_KEY non configurata sul server.");
    }

    let body: CoachRequest;
    try {
      body = (await request.json()) as CoachRequest;
    } catch {
      return jsonError(400, "Corpo della richiesta non valido (JSON atteso).");
    }

    if (!body.userId || !Array.isArray(body.messages) || body.messages.length === 0) {
      return jsonError(400, "Campi obbligatori mancanti: userId e messages.");
    }

    let allowed: boolean;
    try {
      allowed = await checkAndIncrementRateLimit(env, body.userId);
    } catch (error) {
      return jsonError(500, `Errore nel rate limiting: ${(error as Error).message}`);
    }
    if (!allowed) {
      return jsonError(429, "Hai raggiunto il limite giornaliero di messaggi al Coach. Riprova domani.");
    }

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

    // Il contesto utente (volatile) va dopo il prompt statico cacheabile: in coda
    // ai messaggi, così non invalida il prefisso in cache.
    const messages: Anthropic.MessageParam[] = body.messages.map((m) => ({
      role: m.role,
      content: m.content,
    }));
    if (body.userContext) {
      messages.unshift({
        role: "user",
        content: `Contesto attuale dell'utente:\n${body.userContext}`,
      });
    }

    let stream: ReturnType<typeof client.messages.stream>;
    try {
      stream = client.messages.stream({
        model: "claude-opus-4-8",
        max_tokens: 1024,
        system: [
          {
            type: "text",
            text: COACH_SYSTEM_PROMPT,
            cache_control: { type: "ephemeral" },
          },
        ],
        messages,
      });
    } catch (error) {
      return jsonError(502, `Errore nella richiesta a Claude: ${(error as Error).message}`);
    }

    // Inoltra i delta di testo all'app come Server-Sent Events.
    const encoder = new TextEncoder();
    const sse = new ReadableStream({
      async start(controller) {
        try {
          for await (const event of stream) {
            if (
              event.type === "content_block_delta" &&
              event.delta.type === "text_delta"
            ) {
              controller.enqueue(
                encoder.encode(`data: ${JSON.stringify({ text: event.delta.text })}\n\n`),
              );
            }
          }
          controller.enqueue(encoder.encode("event: done\ndata: {}\n\n"));
          controller.close();
        } catch (error) {
          // L'errore di streaming arriva all'app come evento esplicito, non viene
          // mascherato come fine normale della risposta.
          controller.enqueue(
            encoder.encode(
              `event: error\ndata: ${JSON.stringify({ error: (error as Error).message })}\n\n`,
            ),
          );
          controller.close();
        }
      },
    });

    return new Response(sse, {
      headers: {
        "content-type": "text/event-stream",
        "cache-control": "no-cache",
        connection: "keep-alive",
      },
    });
  },
} satisfies ExportedHandler<Env>;
