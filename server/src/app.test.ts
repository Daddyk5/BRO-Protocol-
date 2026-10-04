import assert from "node:assert/strict";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { after, before, test } from "node:test";

import { createApp } from "./app";
import type { Logger } from "./core/llm";
import { MemoryRateLimiter } from "./rateLimit";

const silent: Logger = { info: () => {}, warn: () => {}, error: () => {} };
const limiter = new MemoryRateLimiter(2);
let server: Server;
let base: string;

before(async () => {
  server = createServer(
    createApp({
      engine: { generate: async (input) => ({ reply: `ok:${input.mode}`, regenerated: false }) },
      limiter,
      logger: silent,
      clientToken: "secret-token",
    }),
  );
  await new Promise<void>((resolve) => server.listen(0, resolve));
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
});

after(() => {
  limiter.close();
  server.close();
});

const call = (data: unknown, token = "secret-token") =>
  fetch(`${base}/generateReply`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Bro-Client": token },
    body: JSON.stringify({ data }),
  });

const valid = { mode: "BANTER", context: "hey", tone: 0.5, language: "english", deviceId: "device-1234" };

test("health check", async () => {
  const res = await fetch(`${base}/healthz`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { ok: true });
});

test("returns the callable-shaped result", async () => {
  const res = await call(valid);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { result: { reply: "ok:BANTER" } });
  assert.equal(res.headers.get("access-control-allow-origin"), "*");
});

test("rejects a wrong client token", async () => {
  const res = await call(valid, "nope");
  assert.equal(res.status, 401);
  assert.equal(((await res.json()) as { error: { status: string } }).error.status, "UNAUTHENTICATED");
});

test("validates input", async () => {
  const res = await call({ ...valid, mode: "NOPE" });
  assert.equal(res.status, 400);
  assert.equal(((await res.json()) as { error: { status: string } }).error.status, "INVALID_ARGUMENT");
});

test("rate limits per device", async () => {
  const data = { ...valid, deviceId: "device-limit-1" };
  assert.equal((await call(data)).status, 200);
  assert.equal((await call(data)).status, 200);
  const res = await call(data);
  assert.equal(res.status, 429);
  assert.equal(((await res.json()) as { error: { status: string } }).error.status, "RESOURCE_EXHAUSTED");
});

test("answers CORS preflight", async () => {
  const res = await fetch(`${base}/generateReply`, { method: "OPTIONS" });
  assert.equal(res.status, 204);
  assert.match(res.headers.get("access-control-allow-headers") ?? "", /X-Bro-Client/);
});
