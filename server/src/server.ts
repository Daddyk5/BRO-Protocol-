import { createServer } from "node:http";

import { createApp } from "./app";
import { DEFAULT_MODEL, type Logger, createReplyEngine } from "./core/llm";
import { MemoryRateLimiter } from "./rateLimit";

// One JSON object per line, so `docker compose logs` stays greppable.
const logger: Logger = {
  info: (message, data) => console.log(JSON.stringify({ severity: "INFO", message, ...data })),
  warn: (message, data) => console.warn(JSON.stringify({ severity: "WARNING", message, ...data })),
  error: (message, data) => console.error(JSON.stringify({ severity: "ERROR", message, ...data })),
};

const apiKey = process.env.ANTHROPIC_API_KEY?.trim() ?? "";
if (!apiKey) {
  logger.error("ANTHROPIC_API_KEY is not set. Put it in server/.env (see server/.env.example).");
  process.exit(1);
}

const port = Number(process.env.PORT) || 8080;
const model = process.env.LLM_MODEL?.trim() || DEFAULT_MODEL;
const limiter = new MemoryRateLimiter(Number(process.env.RATE_LIMIT_PER_HOUR) || 20);
const clientToken = process.env.CLIENT_TOKEN?.trim() ?? "";

const server = createServer(
  createApp({ engine: createReplyEngine({ apiKey, model, logger }), limiter, logger, clientToken }),
);
server.requestTimeout = 90_000;

server.listen(port, () => {
  logger.info("Bro Protocol server listening", {
    port,
    model,
    rateLimitPerHour: limiter.max,
    clientTokenRequired: Boolean(clientToken),
  });
});

function shutdown(signal: string): void {
  logger.info("Shutting down", { signal });
  limiter.close();
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 10_000).unref();
}
process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
