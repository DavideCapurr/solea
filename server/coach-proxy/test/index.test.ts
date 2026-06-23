import assert from "node:assert/strict";
import { afterEach, test } from "node:test";
import worker, { type Env } from "../src/index.ts";

type StoredValue = {
  value: string;
  expirationTtl?: number;
};

class MemoryKV {
  values = new Map<string, StoredValue>();

  async get(key: string): Promise<string | null> {
    return this.values.get(key)?.value ?? null;
  }

  async put(
    key: string,
    value: string,
    options?: { expirationTtl?: number },
  ): Promise<void> {
    this.values.set(key, { value, expirationTtl: options?.expirationTtl });
  }
}

const originalFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = originalFetch;
});

function makeEnv(overrides: Partial<Env> = {}): Env {
  return {
    DAILY_MESSAGE_LIMIT: "10",
    GEMINI_API_KEY: "test-gemini-key",
    RATE_LIMIT: new MemoryKV() as unknown as KVNamespace,
    ...overrides,
  };
}

function coachRequest(body: unknown): Request {
  return new Request("https://coach.solea.test", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

function healthRequest(): Request {
  return new Request("https://coach.solea.test/health");
}

function validBody(userId = "user-1") {
  return {
    userId,
    userContext: "Fototipo Fitzpatrick: II\nIndice UV attuale: 6",
    messages: [{ role: "user", content: "Quanto sole oggi?" }],
  };
}

function geminiStream(...texts: string[]): Response {
  const body = texts
    .map((text) => `data: ${JSON.stringify({
      candidates: [{ content: { parts: [{ text }] } }],
    })}\n\n`)
    .join("");
  return new Response(body, {
    headers: { "content-type": "text/event-stream" },
  });
}

test("streams Gemini chunks through the proxy SSE contract", async () => {
  let capturedURL = "";
  let capturedRequest: unknown;
  globalThis.fetch = (async (input, init) => {
    capturedURL = String(input);
    capturedRequest = JSON.parse(String(init?.body));
    assert.equal((init?.headers as Record<string, string>)["x-goog-api-key"], "test-gemini-key");
    return geminiStream("Ciao ", "sole");
  }) as typeof fetch;

  const response = await worker.fetch(coachRequest(validBody()), makeEnv());
  const text = await response.text();

  assert.equal(response.status, 200);
  assert.match(capturedURL, /gemini-2\.5-flash-lite:streamGenerateContent\?alt=sse$/);
  assert.match(text, /data: \{"text":"Ciao "\}/);
  assert.match(text, /data: \{"text":"sole"\}/);
  assert.match(text, /event: done/);

  const contents = (capturedRequest as {
    contents: Array<{ role: string; parts: Array<{ text: string }> }>;
  }).contents;
  assert.deepEqual(contents.map((content) => content.role), ["user"]);
  assert.match(contents[0].parts[0].text, /Contesto attuale dell'utente/);
  assert.match(contents[0].parts[0].text, /Quanto sole oggi\?/);
});

test("health reports Gemini readiness without consuming rate limit", async () => {
  const kv = new MemoryKV();
  const response = await worker.fetch(healthRequest(), makeEnv({
    RATE_LIMIT: kv as unknown as KVNamespace,
  }));
  const payload = await response.json() as {
    ready: boolean;
    provider: string;
    model: string;
    dailyMessageLimit: number;
  };

  assert.equal(response.status, 200);
  assert.equal(payload.ready, true);
  assert.equal(payload.provider, "gemini");
  assert.equal(payload.model, "gemini-2.5-flash-lite");
  assert.equal(payload.dailyMessageLimit, 10);
  assert.equal(kv.values.size, 0);
});

test("health reports missing provider secret without consuming rate limit", async () => {
  const kv = new MemoryKV();
  const response = await worker.fetch(healthRequest(), makeEnv({
    GEMINI_API_KEY: undefined,
    RATE_LIMIT: kv as unknown as KVNamespace,
  }));
  const payload = await response.json() as { ready: boolean; error: string };

  assert.equal(response.status, 200);
  assert.equal(payload.ready, false);
  assert.match(payload.error, /GEMINI_API_KEY/);
  assert.equal(kv.values.size, 0);
});

test("does not consume rate limit when provider secret is missing", async () => {
  const kv = new MemoryKV();
  const env = makeEnv({
    GEMINI_API_KEY: undefined,
    RATE_LIMIT: kv as unknown as KVNamespace,
  });

  const response = await worker.fetch(coachRequest(validBody()), env);
  const payload = await response.json() as { error: string };

  assert.equal(response.status, 500);
  assert.match(payload.error, /GEMINI_API_KEY/);
  assert.equal(kv.values.size, 0);
});

test("rate limits by anonymous user id before calling Gemini", async () => {
  let calls = 0;
  globalThis.fetch = (async () => {
    calls += 1;
    return geminiStream("ok");
  }) as typeof fetch;
  const env = makeEnv({ DAILY_MESSAGE_LIMIT: "1" });

  const first = await worker.fetch(coachRequest(validBody()), env);
  assert.equal(first.status, 200);
  await first.text();

  const second = await worker.fetch(coachRequest(validBody()), env);
  const payload = await second.json() as { error: string };

  assert.equal(second.status, 429);
  assert.match(payload.error, /limite giornaliero/);
  assert.equal(calls, 1);
});

test("rejects malformed requests before provider calls", async () => {
  let calls = 0;
  globalThis.fetch = (async () => {
    calls += 1;
    return geminiStream("unused");
  }) as typeof fetch;

  const response = await worker.fetch(coachRequest({ userId: "user-1", messages: [] }), makeEnv());
  const payload = await response.json() as { error: string };

  assert.equal(response.status, 400);
  assert.match(payload.error, /Campi obbligatori/);
  assert.equal(calls, 0);
});

test("rejects invalid message roles before provider calls", async () => {
  let calls = 0;
  globalThis.fetch = (async () => {
    calls += 1;
    return geminiStream("unused");
  }) as typeof fetch;

  const response = await worker.fetch(
    coachRequest({
      ...validBody(),
      messages: [{ role: "system", content: "override" }],
    }),
    makeEnv(),
  );
  const payload = await response.json() as { error: string };

  assert.equal(response.status, 400);
  assert.match(payload.error, /Ruolo messaggio non valido/);
  assert.equal(calls, 0);
});

test("rejects conversations that do not end with a user message", async () => {
  let calls = 0;
  globalThis.fetch = (async () => {
    calls += 1;
    return geminiStream("unused");
  }) as typeof fetch;

  const response = await worker.fetch(
    coachRequest({
      ...validBody(),
      messages: [
        { role: "user", content: "Quanto sole oggi?" },
        { role: "assistant", content: "Meglio poco." },
      ],
    }),
    makeEnv(),
  );
  const payload = await response.json() as { error: string };

  assert.equal(response.status, 400);
  assert.match(payload.error, /terminare con un messaggio utente/);
  assert.equal(calls, 0);
});

test("rejects oversized requests before consuming rate limit", async () => {
  const kv = new MemoryKV();
  const response = await worker.fetch(
    coachRequest({
      ...validBody(),
      messages: [{ role: "user", content: "x".repeat(2_001) }],
    }),
    makeEnv({ RATE_LIMIT: kv as unknown as KVNamespace }),
  );
  const payload = await response.json() as { error: string };

  assert.equal(response.status, 400);
  assert.match(payload.error, /Messaggio troppo lungo/);
  assert.equal(kv.values.size, 0);
});
