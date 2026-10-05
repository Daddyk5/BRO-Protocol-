import { timingSafeEqual } from "node:crypto";
import type { IncomingMessage, RequestListener, ServerResponse } from "node:http";

import { ReplyError, type ReplyErrorCode } from "./core/errors";
import { type Logger, type ReplyEngine, generateReplies } from "./core/llm";
import { parseInput } from "./core/validation";
import type { MemoryRateLimiter } from "./rateLimit";

export interface AppDeps {
  engine: ReplyEngine;
  limiter: MemoryRateLimiter;
  logger: Logger;
  /** When non-empty, requests must carry `X-Bro-Client: <clientToken>`. */
  clientToken: string;
}

const MAX_BODY_BYTES = 64 * 1024;

// Same status codes the Firebase callable protocol uses.
const HTTP_STATUS: Record<ReplyErrorCode, number> = {
  "invalid-argument": 400,
  "failed-precondition": 400,
  unauthenticated: 401,
  "resource-exhausted": 429,
  unavailable: 503,
  internal: 500,
};

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Bro-Client, X-Firebase-AppCheck",
  "Access-Control-Max-Age": "86400",
};

function send(res: ServerResponse, status: number, body: unknown): void {
  res.writeHead(status, { ...CORS_HEADERS, "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

function sendError(res: ServerResponse, error: ReplyError): void {
  send(res, HTTP_STATUS[error.code], {
    error: { status: error.code.replace(/-/g, "_").toUpperCase(), message: error.message },
  });
}

async function readJson(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of req) {
    size += (chunk as Buffer).length;
    if (size > MAX_BODY_BYTES) throw new ReplyError("invalid-argument", "Request too large.");
    chunks.push(chunk as Buffer);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new ReplyError("invalid-argument", "Request body must be JSON.");
  }
}

function tokenMatches(expected: string, provided: string | string[] | undefined): boolean {
  if (typeof provided !== "string") return false;
  const a = Buffer.from(expected);
  const b = Buffer.from(provided);
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * POST /generateReply  body { data: { mode, context, tone, language, deviceId, count? } }
 *                      →    { result: { reply, replies: [{ label, tone, reply }] } } | { error: { status, message } }
 * GET  /healthz        →    { ok: true }   (cheap liveness, used by the Docker HEALTHCHECK)
 * GET  /healthz?deep=1 →    { ok, provider, model, detail? }   (probes the model; 503 when unreachable)
 *
 * The wire format matches Firebase HTTPS callables, so the app and extension
 * only change their base URL to switch backends.
 */
export function createApp({ engine, limiter, logger, clientToken }: AppDeps): RequestListener {
  return async (req, res) => {
    const [path, query = ""] = (req.url ?? "/").split("?");

    if (req.method === "OPTIONS") {
      res.writeHead(204, CORS_HEADERS);
      res.end();
      return;
    }
    if (req.method === "GET" && path === "/healthz") {
      if (!new URLSearchParams(query).has("deep") || !engine.check) {
        send(res, 200, { ok: true });
        return;
      }
      const status = await engine.check();
      send(res, status.ok ? 200 : 503, status);
      return;
    }
    if (path !== "/generateReply") {
      send(res, 404, { error: { status: "NOT_FOUND", message: "Not found." } });
      return;
    }
    if (req.method !== "POST") {
      send(res, 405, { error: { status: "INVALID_ARGUMENT", message: "Use POST." } });
      return;
    }

    try {
      if (clientToken && !tokenMatches(clientToken, req.headers["x-bro-client"])) {
        throw new ReplyError("unauthenticated", "This build isn't verified. Update Bro Protocol and try again.");
      }

      const body = (await readJson(req)) as { data?: unknown } | null;
      const input = parseInput(body?.data);

      if (!limiter.consume(`dev_${input.deviceId}`, input.count)) {
        throw new ReplyError(
          "resource-exhausted",
          `Easy, bro. That's ${limiter.max} replies this hour. Take a breather and come back.`,
        );
      }

      const { replies, regenerated } = await generateReplies(engine, input);
      const reply = (replies.find((r) => r.label === "Balanced") ?? replies[0]).reply;
      const tipsReturned = replies.filter((r) => r.tip).length;
      // Log shape only, never the chat content.
      logger.info("Reply generated", {
        mode: input.mode,
        language: input.language,
        contextChars: input.context.length,
        replies: replies.length,
        regenerated,
        tipsReturned,
        withNotes: Boolean(input.notes),
      });
      send(res, 200, { result: { reply, replies } });
    } catch (error) {
      if (error instanceof ReplyError) {
        sendError(res, error);
      } else {
        logger.error("Unexpected error", { error: String(error) });
        sendError(res, new ReplyError("internal", "Something broke on our side. Try again in a moment."));
      }
    }
  };
}
