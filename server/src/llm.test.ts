import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, before, test } from "node:test";

import { ReplyError } from "./core/errors";
import { type Logger, type ReplyEngine, createReplyEngine, generateReplies, withFallback } from "./core/llm";
import type { GenerateReplyInput } from "./core/validation";
import { MemoryRateLimiter } from "./rateLimit";

const silent: Logger = { info: () => {}, warn: () => {}, error: () => {} };
const input: GenerateReplyInput = {
  mode: "LATE_NIGHT",
  context: "can't sleep",
  tone: 0.5,
  language: "english",
  deviceId: "device-1234",
  count: 1,
};

// A fake Ollama: each /api/chat call answers with the next queued reply.
let queue: string[] = [];
let lastBody: { model?: string; messages?: { role: string; content: string }[] } = {};
let fake: Server;
let ollamaUrl: string;

before(async () => {
  fake = createServer(async (req, res) => {
    if (req.url === "/api/tags") {
      res.end(JSON.stringify({ models: [{ name: "llama3.2:3b" }] }));
      return;
    }
    let raw = "";
    for await (const chunk of req) raw += chunk;
    lastBody = JSON.parse(raw);
    const content = queue.shift();
    if (content === undefined) {
      res.writeHead(500).end("boom");
      return;
    }
    res.end(JSON.stringify({ message: { role: "assistant", content } }));
  });
  await new Promise<void>((resolve) => fake.listen(0, resolve));
  ollamaUrl = `http://127.0.0.1:${(fake.address() as AddressInfo).port}`;
});

after(() => fake.close());

const ollama = (model = "llama3.2:3b") => createReplyEngine({ apiKey: "", model, logger: silent, ollamaUrl });

test("ollama: sends the system prompt and post-processes the reply", async () => {
  queue = ['<think>hmm</think>"Same. Tell me what keeps you up. Then a third sentence."'];
  const { reply, regenerated } = await ollama().generate(input);
  assert.equal(reply, "Same. Tell me what keeps you up.");
  assert.equal(regenerated, false);
  assert.equal(lastBody.model, "llama3.2:3b");
  assert.match(lastBody.messages?.[0].content ?? "", /\[MODE: LATE_NIGHT\]/);
});

test("ollama: regenerates once on a banned word, then gives up", async () => {
  queue = ["Love the vibe.", "Love the energy."];
  assert.deepEqual(await ollama().generate(input), { reply: "Love the energy.", regenerated: true });

  queue = ["Love the vibe.", "Still a vibe."];
  await assert.rejects(ollama().generate(input), (e: unknown) => e instanceof ReplyError && e.code === "internal");
});

test("ollama: unreachable server maps to unavailable", async () => {
  const down = createReplyEngine({ apiKey: "", model: "x", logger: silent, ollamaUrl: "http://127.0.0.1:1" });
  await assert.rejects(down.generate(input), (e: unknown) => e instanceof ReplyError && e.code === "unavailable");
});

test("ollama: health check reports missing models", async () => {
  assert.equal((await ollama().check!()).ok, true);
  const missing = await ollama("mistral").check!();
  assert.equal(missing.ok, false);
  assert.match(missing.detail ?? "", /ollama pull mistral/);
});

test("fallback takes over when the primary fails", async () => {
  const backup: ReplyEngine = { generate: async () => ({ reply: "from backup", regenerated: false }) };
  queue = []; // fake Ollama answers 500
  assert.equal((await withFallback(ollama(), backup, silent).generate(input)).reply, "from backup");

  // Bad requests are not retried on the fallback.
  const picky: ReplyEngine = {
    generate: async () => {
      throw new ReplyError("failed-precondition", "no");
    },
  };
  await assert.rejects(withFallback(picky, backup, silent).generate(input), /no/);
});

test("generateReplies spreads tones and keeps partial results", async () => {
  const seen: number[] = [];
  const engine: ReplyEngine = {
    generate: async ({ tone }) => {
      seen.push(tone);
      if (tone > 0.8) throw new ReplyError("internal", "nope");
      return { reply: `t${tone}`, regenerated: false };
    },
  };
  const { replies } = await generateReplies(engine, { ...input, count: 3 });
  assert.deepEqual(seen.sort(), [0.15, 0.5, 0.85]);
  assert.deepEqual(
    replies.map((r) => r.label),
    ["Chill", "Balanced"],
  );

  const single = await generateReplies(engine, { ...input, tone: 0.2 });
  assert.deepEqual(single.replies, [{ label: "Chill", tone: 0.2, reply: "t0.2" }]);

  await assert.rejects(generateReplies(engine, { ...input, tone: 0.9 }), /nope/);
});

test("rate limiter charges per reply and survives a restart", () => {
  const dir = mkdtempSync(join(tmpdir(), "bro-rl-"));
  const filePath = join(dir, "limits.json");
  try {
    const first = new MemoryRateLimiter(4, { filePath });
    assert.equal(first.consume("a", 3), true);
    assert.equal(first.consume("a", 3), false); // 6 > 4, nothing counted
    first.close(); // saves

    const second = new MemoryRateLimiter(4, { filePath });
    assert.equal(second.consume("a", 1), true);
    assert.equal(second.consume("a", 1), false);
    second.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
