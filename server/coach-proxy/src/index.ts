import Anthropic from "@anthropic-ai/sdk";

export interface Env {
  MISTRAL_API_KEY?: string;
  MISTRAL_MODEL?: string;
  GEMINI_API_KEY?: string;
  GEMINI_MODEL?: string;
  ANTHROPIC_API_KEY?: string;
  ANTHROPIC_MODEL?: string;
  COACH_PROVIDER?: string;
  RATE_LIMIT: KVNamespace;
  DAILY_MESSAGE_LIMIT: string;
}

const DEFAULT_PROVIDER = "gemini";
const DEFAULT_MISTRAL_MODEL = "ministral-3b-latest";
const DEFAULT_GEMINI_MODEL = "gemini-2.5-flash-lite";
const DEFAULT_ANTHROPIC_MODEL = "claude-sonnet-4-6";
const MAX_USER_ID_CHARS = 128;
const MAX_USER_CONTEXT_CHARS = 1_200;
const MAX_MESSAGES = 12;
const MAX_MESSAGE_CHARS = 2_000;
const MAX_TOTAL_MESSAGE_CHARS = 8_000;

/// Persona del Coach Solare. È statica e viene inviata dal proxy, mai dall'app.
const COACH_SYSTEM_PROMPT = `Sei il "Coach Solare" dell'app Solea, esperto di esposizione al sole e abbronzatura sana.
Aiuti l'utente ad abbronzarsi al meglio SENZA scottarsi. Tono amichevole, motivante, conciso (max 3-4 frasi).
Usi il contesto fornito (fototipo Fitzpatrick, indice UV attuale, riepilogo sessioni) per dare consigli concreti e personalizzati.
Dai indicazioni pratiche su tempi di esposizione, SPF, idratazione e doposole.
NON fornisci diagnosi o consigli medici: per dubbi sulla pelle rimandi sempre a un dermatologo.
Rispondi nella lingua dell'utente (italiano se ti scrive in italiano).`;

interface CoachRequest {
  userId: string;
  userContext?: string;
  messages: Array<{ role: "user" | "assistant"; content: string }>;
}

type CoachProvider = "mistral" | "gemini" | "anthropic";

type ConversationMessage = CoachRequest["messages"][number];

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface GeminiPart {
  text?: string;
}

interface GeminiContent {
  role?: "user" | "model";
  parts: GeminiPart[];
}

interface GeminiStreamChunk {
  candidates?: Array<{
    content?: {
      parts?: GeminiPart[];
    };
  }>;
}

interface MistralStreamChunk {
  choices?: Array<{
    delta?: {
      content?: string | Array<{ type?: string; text?: string }>;
    };
  }>;
}

function jsonError(status: number, message: string): Response {
  return jsonResponse(status, { error: message });
}

function jsonResponse(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}

/// Conteggio giornaliero per utente su KV. La chiave scade a fine giornata UTC.
async function checkAndIncrementRateLimit(env: Env, userId: string): Promise<boolean> {
  if (!env.RATE_LIMIT) {
    throw new Error("RATE_LIMIT KV non configurato");
  }
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

function selectedProvider(env: Env): CoachProvider | undefined {
  const value = (env.COACH_PROVIDER ?? DEFAULT_PROVIDER).toLowerCase();
  if (value === "mistral" || value === "gemini" || value === "anthropic") {
    return value;
  }
  return undefined;
}

function modelForProvider(provider: CoachProvider, env: Env): string {
  switch (provider) {
  case "mistral":
    return env.MISTRAL_MODEL ?? DEFAULT_MISTRAL_MODEL;
  case "gemini":
    return env.GEMINI_MODEL ?? DEFAULT_GEMINI_MODEL;
  case "anthropic":
    return env.ANTHROPIC_MODEL ?? DEFAULT_ANTHROPIC_MODEL;
  }
}

function providerConfigurationError(provider: CoachProvider, env: Env): string | undefined {
  switch (provider) {
  case "mistral":
    return env.MISTRAL_API_KEY ? undefined : "MISTRAL_API_KEY non configurata sul server.";
  case "gemini":
    return env.GEMINI_API_KEY ? undefined : "GEMINI_API_KEY non configurata sul server.";
  case "anthropic":
    return env.ANTHROPIC_API_KEY ? undefined : "ANTHROPIC_API_KEY non configurata sul server.";
  }
}

function healthResponse(env: Env): Response {
  const provider = selectedProvider(env);
  if (!provider) {
    return jsonResponse(500, {
      status: "error",
      ready: false,
      provider: env.COACH_PROVIDER ?? DEFAULT_PROVIDER,
      error: "COACH_PROVIDER non supportato.",
    });
  }

  const dailyMessageLimit = Number.parseInt(env.DAILY_MESSAGE_LIMIT, 10);
  const limitConfigured = Number.isFinite(dailyMessageLimit) && dailyMessageLimit > 0;
  const configurationError = providerConfigurationError(provider, env);
  let rateLimitError: string | undefined;
  if (!env.RATE_LIMIT) {
    rateLimitError = "RATE_LIMIT KV non configurato.";
  } else if (!limitConfigured) {
    rateLimitError = "DAILY_MESSAGE_LIMIT non valido.";
  }
  const ready = !configurationError && !rateLimitError;

  return jsonResponse(200, {
    status: ready ? "ok" : "not_ready",
    ready,
    provider,
    model: modelForProvider(provider, env),
    dailyMessageLimit: limitConfigured ? dailyMessageLimit : null,
    limits: {
      maxMessages: MAX_MESSAGES,
      maxMessageCharacters: MAX_MESSAGE_CHARS,
      maxTotalMessageCharacters: MAX_TOTAL_MESSAGE_CHARS,
      maxUserContextCharacters: MAX_USER_CONTEXT_CHARS,
    },
    error: configurationError ?? rateLimitError,
  });
}

function validateCoachRequest(body: CoachRequest): string | undefined {
  if (typeof body.userId !== "string" || body.userId.trim().length === 0) {
    return "Campi obbligatori mancanti: userId e messages.";
  }
  if (body.userId.length > MAX_USER_ID_CHARS) {
    return `userId troppo lungo (max ${MAX_USER_ID_CHARS} caratteri).`;
  }
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return "Campi obbligatori mancanti: userId e messages.";
  }
  if (body.messages.length > MAX_MESSAGES) {
    return `Troppi messaggi nella conversazione (max ${MAX_MESSAGES}).`;
  }
  if (body.userContext !== undefined) {
    if (typeof body.userContext !== "string") {
      return "userContext deve essere una stringa.";
    }
    if (body.userContext.length > MAX_USER_CONTEXT_CHARS) {
      return `Contesto utente troppo lungo (max ${MAX_USER_CONTEXT_CHARS} caratteri).`;
    }
  }

  let totalMessageChars = 0;
  for (const [index, message] of body.messages.entries()) {
    if (message.role !== "user" && message.role !== "assistant") {
      return `Ruolo messaggio non valido in posizione ${index}.`;
    }
    if (typeof message.content !== "string" || message.content.trim().length === 0) {
      return `Contenuto messaggio mancante in posizione ${index}.`;
    }
    if (message.content.length > MAX_MESSAGE_CHARS) {
      return `Messaggio troppo lungo in posizione ${index} (max ${MAX_MESSAGE_CHARS} caratteri).`;
    }
    totalMessageChars += message.content.length;
  }
  if (body.messages[0].role !== "user") {
    return "La conversazione deve iniziare con un messaggio utente.";
  }
  if (body.messages.at(-1)?.role !== "user") {
    return "La conversazione deve terminare con un messaggio utente.";
  }
  if (totalMessageChars > MAX_TOTAL_MESSAGE_CHARS) {
    return `Conversazione troppo lunga (max ${MAX_TOTAL_MESSAGE_CHARS} caratteri).`;
  }
  return undefined;
}

function contentWithContext(content: string, userContext?: string): string {
  if (!userContext) {
    return content;
  }
  return `Contesto attuale dell'utente:\n${userContext}\n\nMessaggio dell'utente:\n${content}`;
}

function conversationMessagesWithContext(body: CoachRequest): ConversationMessage[] {
  return body.messages.map((message, index) => ({
    ...message,
    content: index === 0 ? contentWithContext(message.content, body.userContext) : message.content,
  }));
}

function buildChatMessages(body: CoachRequest): ChatMessage[] {
  const messages: ChatMessage[] = [
    { role: "system", content: COACH_SYSTEM_PROMPT },
  ];
  for (const message of conversationMessagesWithContext(body)) {
    messages.push({
      role: message.role,
      content: message.content,
    });
  }
  return messages;
}

function buildGeminiContents(body: CoachRequest): GeminiContent[] {
  const contents: GeminiContent[] = [];
  for (const message of conversationMessagesWithContext(body)) {
    contents.push({
      role: message.role === "assistant" ? "model" : "user",
      parts: [{ text: message.content }],
    });
  }
  return contents;
}

function buildAnthropicMessages(body: CoachRequest): Anthropic.MessageParam[] {
  // Il contesto utente resta volatile e minimale: niente foto, niente identificativi.
  return conversationMessagesWithContext(body).map((message) => ({
    role: message.role,
    content: message.content,
  }));
}

async function* streamMistralReply(
  body: CoachRequest,
  env: Env,
): AsyncGenerator<string> {
  if (!env.MISTRAL_API_KEY) {
    throw new Error("MISTRAL_API_KEY non configurata sul server.");
  }

  const response = await fetch("https://api.mistral.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      authorization: `Bearer ${env.MISTRAL_API_KEY}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: env.MISTRAL_MODEL ?? DEFAULT_MISTRAL_MODEL,
      messages: buildChatMessages(body),
      max_tokens: 700,
      temperature: 0.4,
      stream: true,
      response_format: { type: "text" },
    }),
  });

  if (!response.ok) {
    throw new Error(`Errore Mistral (${response.status}): ${await providerErrorMessage(response)}`);
  }
  if (!response.body) {
    throw new Error("Risposta Mistral senza stream.");
  }

  yield* parseSSE(response.body, mistralTextFromEvent);
}

async function* streamGeminiReply(
  body: CoachRequest,
  env: Env,
): AsyncGenerator<string> {
  if (!env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY non configurata sul server.");
  }

  const model = env.GEMINI_MODEL ?? DEFAULT_GEMINI_MODEL;
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?alt=sse`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": env.GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: COACH_SYSTEM_PROMPT }],
        },
        contents: buildGeminiContents(body),
        generationConfig: {
          maxOutputTokens: 700,
          temperature: 0.4,
        },
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`Errore Gemini (${response.status}): ${await providerErrorMessage(response)}`);
  }
  if (!response.body) {
    throw new Error("Risposta Gemini senza stream.");
  }

  yield* parseSSE(response.body, geminiTextFromEvent);
}

async function providerErrorMessage(response: Response): Promise<string> {
  const text = await response.text();
  if (!text) {
    return response.statusText;
  }
  try {
    const decoded = JSON.parse(text) as { error?: { message?: string } };
    return decoded.error?.message ?? text;
  } catch {
    return text;
  }
}

async function* parseSSE(
  body: ReadableStream<Uint8Array>,
  textFromEvent: (event: string) => Iterable<string>,
): AsyncGenerator<string> {
  const decoder = new TextDecoder();
  const reader = body.getReader();
  let buffer = "";

  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) {
        break;
      }
      buffer += decoder.decode(value, { stream: true });
      yield* drainSSEEvents(buffer, textFromEvent, (remaining) => {
        buffer = remaining;
      });
    }
  } finally {
    reader.releaseLock();
  }

  buffer += decoder.decode();
  if (buffer.trim()) {
    yield* textFromEvent(buffer);
  }
}

function* drainSSEEvents(
  buffer: string,
  textFromEvent: (event: string) => Iterable<string>,
  setRemaining: (remaining: string) => void,
): Generator<string> {
  let remaining = buffer;
  while (true) {
    const boundary = remaining.indexOf("\n\n");
    if (boundary === -1) {
      setRemaining(remaining);
      return;
    }
    const event = remaining.slice(0, boundary);
    remaining = remaining.slice(boundary + 2);
    yield* textFromEvent(event);
  }
}

function dataFromSSEEvent(event: string): string {
  return event
    .split(/\r?\n/)
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice(5).trim())
    .join("\n");
}

function* mistralTextFromEvent(event: string): Generator<string> {
  const data = dataFromSSEEvent(event);
  if (!data || data === "[DONE]") {
    return;
  }

  const chunk = JSON.parse(data) as MistralStreamChunk;
  for (const choice of chunk.choices ?? []) {
    const content = choice.delta?.content;
    if (typeof content === "string" && content) {
      yield content;
    } else if (Array.isArray(content)) {
      for (const part of content) {
        if (part.type === "text" && part.text) {
          yield part.text;
        }
      }
    }
  }
}

function* geminiTextFromEvent(event: string): Generator<string> {
  const data = dataFromSSEEvent(event);
  if (!data || data === "[DONE]") {
    return;
  }

  const chunk = JSON.parse(data) as GeminiStreamChunk;
  for (const candidate of chunk.candidates ?? []) {
    for (const part of candidate.content?.parts ?? []) {
      if (part.text) {
        yield part.text;
      }
    }
  }
}

async function* streamAnthropicReply(
  body: CoachRequest,
  env: Env,
): AsyncGenerator<string> {
  if (!env.ANTHROPIC_API_KEY) {
    throw new Error("ANTHROPIC_API_KEY non configurata sul server.");
  }

  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const stream = client.messages.stream({
    model: env.ANTHROPIC_MODEL ?? DEFAULT_ANTHROPIC_MODEL,
    max_tokens: 1024,
    system: [
      {
        type: "text",
        text: COACH_SYSTEM_PROMPT,
        cache_control: { type: "ephemeral" },
      },
    ],
    messages: buildAnthropicMessages(body),
  });

  for await (const event of stream) {
    if (
      event.type === "content_block_delta" &&
      event.delta.type === "text_delta"
    ) {
      yield event.delta.text;
    }
  }
}

function createSSEStream(chunks: AsyncIterable<string>): ReadableStream<Uint8Array> {
  const encoder = new TextEncoder();
  return new ReadableStream({
    async start(controller) {
      try {
        for await (const text of chunks) {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ text })}\n\n`),
          );
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
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "GET") {
      const path = new URL(request.url).pathname;
      if (path === "/" || path === "/health") {
        return healthResponse(env);
      }
      return jsonError(404, "Endpoint non trovato.");
    }

    if (request.method !== "POST") {
      return jsonError(405, "Usa POST.");
    }

    const provider = selectedProvider(env);
    if (!provider) {
      return jsonError(500, "COACH_PROVIDER non supportato.");
    }

    let body: CoachRequest;
    try {
      body = (await request.json()) as CoachRequest;
    } catch {
      return jsonError(400, "Corpo della richiesta non valido (JSON atteso).");
    }

    const validationError = validateCoachRequest(body);
    if (validationError) {
      return jsonError(400, validationError);
    }

    const configurationError = providerConfigurationError(provider, env);
    if (configurationError) {
      return jsonError(500, configurationError);
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

    let chunks: AsyncGenerator<string>;
    switch (provider) {
    case "mistral":
      chunks = streamMistralReply(body, env);
      break;
    case "gemini":
      chunks = streamGeminiReply(body, env);
      break;
    case "anthropic":
      chunks = streamAnthropicReply(body, env);
      break;
    }
    const sse = createSSEStream(chunks);

    return new Response(sse, {
      headers: {
        "content-type": "text/event-stream",
        "cache-control": "no-cache",
        connection: "keep-alive",
      },
    });
  },
} satisfies ExportedHandler<Env>;
