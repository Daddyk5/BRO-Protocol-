import { createServer } from "node:http";

import { createApp } from "./app";
import {
  DEFAULT_MODEL,
  DEFAULT_OLLAMA_MODEL,
  type Logger,
  type ReplyEngine,
  createReplyEngine,
  warmUpOllama,
  withFallback,
} from "./core/llm";
import { MemoryRateLimiter } from "./rateLimit";

// One JSON object per line, so `docker compose logs` stays greppable.
const logger: Logger = {
  info: (message, data) => console.log(JSON.stringify({ severity: "INFO", message, ...data })),
  warn: (message, data) => console.warn(JSON.stringify({ severity: "WARNING", message, ...data })),
  error: (message, data) => console.error(JSON.stringify({ severity: "ERROR", message, ...data })),
};

const env = (name: string) => process.env[name]?.trim() || undefined;

// Claude, a local Ollama model, or both: Ollama first with Claude as the fallback.
const ollamaUrl = env("OLLAMA_URL");
const apiKey = env("ANTHROPIC_API_KEY");
if (!apiKey && !ollamaUrl) {
  logger.error("Set ANTHROPIC_API_KEY and/or OLLAMA_URL in server/.env (see server/.env.example).");
  process.exit(1);
}
// LLM_MODEL is kept as a shorthand for whichever provider runs first.
const ollamaModel = env("OLLAMA_MODEL") ?? (ollamaUrl ? env("LLM_MODEL") : undefined) ?? DEFAULT_OLLAMA_MODEL;
const claudeModel = env("CLAUDE_MODEL") ?? (ollamaUrl ? undefined : env("LLM_MODEL")) ?? DEFAULT_MODEL;

const claude = apiKey ? createReplyEngine({ apiKey, model: claudeModel, logger }) : undefined;
const ollama = ollamaUrl ? createReplyEngine({ apiKey: "", model: ollamaModel, logger, ollamaUrl }) : undefined;
const engine: ReplyEngine = ollama && claude ? withFallback(ollama, claude, logger) : (ollama ?? claude)!;

const port = Number(process.env.PORT) || 8080;
const limiter = new MemoryRateLimiter(Number(process.env.RATE_LIMIT_PER_HOUR) || 20, {
  filePath: env("RATE_LIMIT_FILE"),
});
const clientToken = env("CLIENT_TOKEN") ?? "";

const server = createServer(createApp({ engine, limiter, logger, clientToken }));
server.requestTimeout = 90_000;

server.listen(port, async () => {
  logger.info("Bro Protocol server listening", {
    port,
    provider: ollama && claude ? "ollama -> anthropic" : ollama ? "ollama" : "anthropic",
    model: ollama && claude ? `${ollamaModel} -> ${claudeModel}` : ollama ? ollamaModel : claudeModel,
    persistentRateLimits: Boolean(env("RATE_LIMIT_FILE")),
    rateLimitPerHour: limiter.max,
    clientTokenRequired: Boolean(clientToken),
  });
  // Load the local model now so the first user doesn't wait for it.
  if (ollamaUrl) {
    const started = Date.now();
    const ok = await warmUpOllama(ollamaUrl, ollamaModel);
    logger.info(ok ? "Model warmed up" : "Model warm-up failed (it will load on first request)", {
      model: ollamaModel,
      ms: Date.now() - started,
    });
  }
});

function shutdown(signal: string): void {
  logger.info("Shutting down", { signal });
  limiter.close();
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 10_000).unref();
}
process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
