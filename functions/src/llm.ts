import Anthropic from "@anthropic-ai/sdk";

import { GENERIC_FAILURE, ReplyError } from "./errors";
import { findBannedWords, postProcess, splitTip } from "./postprocess";
import { buildSystemPrompt, optionSpecs, retryUserTurn, userTurn } from "./prompt";
import type { GenerateReplyInput } from "./validation";

export interface Logger {
  info(message: string, data?: Record<string, unknown>): void;
  warn(message: string, data?: Record<string, unknown>): void;
  error(message: string, data?: Record<string, unknown>): void;
}

export interface ReplyEngineOptions {
  apiKey: string;
  model: string;
  logger: Logger;
  /** When set (e.g. http://localhost:11434), replies come from this Ollama server instead of Claude. */
  ollamaUrl?: string;
}

export interface HealthStatus {
  ok: boolean;
  provider: string;
  model: string;
  detail?: string;
}

export interface ReplyEngine {
  generate(input: GenerateReplyInput): Promise<{ reply: string; regenerated: boolean; tip?: string }>;
  /** Probes the model provider (no generation, so no token cost). */
  check?(): Promise<HealthStatus>;
}

export interface ReplyOption {
  /** "Chill" / "Balanced" / "Bold", or the date type in DATE_IDEAS mode. */
  label: string;
  tone: number;
  reply: string;
  tip?: string;
}

export const DEFAULT_MODEL = "claude-opus-5-5";
export const DEFAULT_OLLAMA_MODEL = "llama3.2:3b";

// Models that accept `output_config.effort` and server-side refusal fallbacks.
const CURRENT_MODELS = new Set(["claude-opus-5-5", "claude-opus-5", "claude-sonnet-5-5", "claude-fable-5-1"]);

/**
 * Prompt → Claude → post-process (strip quotes, max 2 sentences) → one
 * regeneration if a banned word slips through. Shared by the Cloud Function
 * and the Docker server; throws only ReplyError.
 */
export function createReplyEngine({ apiKey, model, logger, ollamaUrl }: ReplyEngineOptions): ReplyEngine {
  const client = new Anthropic({ apiKey, maxRetries: 2, timeout: 45_000 });
  const current = CURRENT_MODELS.has(model);
  const writeReply = ollamaUrl ? writeOllamaReply : writeClaudeReply;

  async function writeOllamaReply(system: string, userTurn: string): Promise<string> {
    let response: Response;
    try {
      response = await fetch(`${ollamaUrl!.replace(/\/+$/, "")}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model,
          stream: false,
          messages: [
            { role: "system", content: system },
            { role: "user", content: userTurn },
          ],
          options: { temperature: 0.8, num_predict: 256 },
        }),
        signal: AbortSignal.timeout(90_000),
      });
    } catch (error) {
      logger.error("Ollama connection error: is it running at OLLAMA_URL?", { message: String(error) });
      throw new ReplyError("unavailable", "The wingman is unreachable right now. Try again shortly.");
    }

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      logger.error("Ollama API error", { status: response.status, detail: detail.slice(0, 300), model });
      throw new ReplyError("internal", GENERIC_FAILURE);
    }

    const body = (await response.json()) as { message?: { content?: string } };
    // Reasoning models wrap their thinking in <think>…</think>; keep only the answer.
    const text = (body.message?.content ?? "").replace(/<think>[\s\S]*?<\/think>/g, "").trim();
    if (!text) {
      logger.warn("Empty completion", { model });
      throw new ReplyError("internal", "Came back empty. Hit regenerate.");
    }
    return text;
  }

  async function writeClaudeReply(system: string, userTurn: string): Promise<string> {
    const response = await client.beta.messages.create({
      model,
      max_tokens: 2048,
      system,
      messages: [{ role: "user", content: userTurn }],
      // A one-line chat reply needs little deliberation: low effort keeps
      // latency and cost down. On a policy decline, retry on Anthropic's
      // recommended fallback model instead of failing.
      ...(current
        ? {
            output_config: { effort: "low" as const },
            betas: ["server-side-fallback-2026-07-01"],
            fallbacks: "default" as const,
          }
        : {}),
    });

    if (response.stop_reason === "refusal") {
      throw new ReplyError("failed-precondition", "Couldn't write that one. Try different context.");
    }

    const text = response.content
      .map((block) => (block.type === "text" ? block.text : ""))
      .join("")
      .trim();
    if (!text) {
      logger.warn("Empty completion", { stopReason: response.stop_reason, model: response.model });
      throw new ReplyError("internal", "Came back empty. Hit regenerate.");
    }
    return text;
  }

  function toReplyError(error: unknown): ReplyError {
    if (error instanceof ReplyError) return error;
    if (error instanceof Anthropic.RateLimitError) {
      return new ReplyError("unavailable", "The wingman is swamped. Try again in a minute.");
    }
    if (error instanceof Anthropic.AuthenticationError || error instanceof Anthropic.PermissionDeniedError) {
      logger.error("LLM credentials rejected: check ANTHROPIC_API_KEY", { status: error.status });
      return new ReplyError("internal", GENERIC_FAILURE);
    }
    if (error instanceof Anthropic.APIConnectionError) {
      logger.error("LLM connection error", { message: error.message });
      return new ReplyError("unavailable", "The wingman is unreachable right now. Try again shortly.");
    }
    if (error instanceof Anthropic.APIError) {
      logger.error("LLM API error", { status: error.status, message: error.message });
      return new ReplyError("internal", GENERIC_FAILURE);
    }
    logger.error("Unexpected error", { error: String(error) });
    return new ReplyError("internal", GENERIC_FAILURE);
  }

  return {
    async generate(input) {
      try {
        const system = buildSystemPrompt(input.mode, input.tone, input.language, input.context, {
          notes: input.notes,
          angle: input.angle,
          prefs: input.prefs,
          previous: input.previous,
        });
        const turn = { tip: input.tips, tweak: input.tweak };
        const write = async (text: string) => {
          const { message, tip } = splitTip(await writeReply(system, text));
          return { reply: postProcess(message, { short: input.prefs?.short, emoji: input.prefs?.emoji }), tip };
        };

        let result = await write(userTurn(turn));
        const banned = findBannedWords(result.reply);
        if (banned.length > 0) {
          // One regeneration, naming the offending words.
          result = await write(retryUserTurn(banned, turn));
          if (findBannedWords(result.reply).length > 0) {
            throw new ReplyError("internal", "Came back off-brand. Hit regenerate.");
          }
        }
        if (!result.reply) throw new ReplyError("internal", "Came back empty. Hit regenerate.");
        return {
          reply: result.reply,
          regenerated: banned.length > 0,
          ...(input.tips && result.tip ? { tip: result.tip } : {}),
        };
      } catch (error) {
        throw toReplyError(error);
      }
    },

    async check() {
      const provider = ollamaUrl ? "ollama" : "anthropic";
      try {
        if (ollamaUrl) {
          const res = await fetch(`${ollamaUrl.replace(/\/+$/, "")}/api/tags`, { signal: AbortSignal.timeout(5_000) });
          if (!res.ok) return { ok: false, provider, model, detail: `Ollama answered HTTP ${res.status}` };
          const { models = [] } = (await res.json()) as { models?: { name: string }[] };
          const installed = models.some((m) => m.name === model || m.name === `${model}:latest`);
          return installed
            ? { ok: true, provider, model }
            : { ok: false, provider, model, detail: `Model not installed. Run: ollama pull ${model}` };
        }
        await client.models.retrieve(model, {}, { timeout: 5_000, maxRetries: 0 });
        return { ok: true, provider, model };
      } catch (error) {
        return { ok: false, provider, model, detail: error instanceof Error ? error.message : String(error) };
      }
    },
  };
}

/**
 * Tries [primary] (e.g. a local Ollama model) and, when it is down or keeps
 * breaking the rules, retries the same request on [fallback] (e.g. Claude).
 * Caller errors such as refusals are not retried.
 */
export function withFallback(primary: ReplyEngine, fallback: ReplyEngine, logger: Logger): ReplyEngine {
  return {
    async generate(input) {
      try {
        return await primary.generate(input);
      } catch (error) {
        if (!(error instanceof ReplyError) || (error.code !== "unavailable" && error.code !== "internal")) throw error;
        logger.warn("Primary model failed, using fallback", { code: error.code });
        return fallback.generate(input);
      }
    },
    async check() {
      const unknown = (provider: string): HealthStatus => ({ ok: true, provider, model: "unknown" });
      const [main, backup] = await Promise.all([
        primary.check?.() ?? unknown("primary"),
        fallback.check?.() ?? unknown("fallback"),
      ]);
      const detail = [main.ok ? "" : `primary: ${main.detail}`, backup.ok ? "" : `fallback: ${backup.detail}`]
        .filter(Boolean)
        .join("; ");
      return {
        ok: main.ok || backup.ok,
        provider: `${main.provider} -> ${backup.provider}`,
        model: `${main.model} -> ${backup.model}`,
        ...(detail ? { detail } : {}),
      };
    },
  };
}

/**
 * Writes `input.count` replies in parallel (see `optionSpecs`: tones Chill →
 * Bold, or date types in DATE_IDEAS). Returns whatever succeeded and throws
 * the first error only when every option failed.
 */
export async function generateReplies(
  engine: ReplyEngine,
  input: GenerateReplyInput,
): Promise<{ replies: ReplyOption[]; regenerated: number }> {
  const specs = optionSpecs(input.mode, input.tone, input.count);
  const results = await Promise.allSettled(
    specs.map(({ tone, angle }) => engine.generate({ ...input, tone, ...(angle ? { angle } : {}) })),
  );

  const replies: ReplyOption[] = [];
  let regenerated = 0;
  results.forEach((result, i) => {
    if (result.status !== "fulfilled") return;
    const { label, tone } = specs[i];
    const { reply, tip } = result.value;
    replies.push({ label, tone, reply, ...(tip ? { tip } : {}) });
    if (result.value.regenerated) regenerated += 1;
  });
  if (replies.length === 0) throw (results[0] as PromiseRejectedResult).reason;
  return { replies, regenerated };
}
