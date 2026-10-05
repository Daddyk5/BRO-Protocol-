import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import { defineSecret, defineString } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { ReplyError } from "./errors";
import { DEFAULT_MODEL, ReplyEngine, createReplyEngine, generateReplies } from "./llm";
import { RATE_LIMIT_MAX, consumeRateLimit } from "./rateLimit";
import { parseInput } from "./validation";

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

// `firebase functions:secrets:set ANTHROPIC_API_KEY`: the key lives only in
// Secret Manager and never ships in the app or the extension.
const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");
const LLM_MODEL = defineString("LLM_MODEL", { default: DEFAULT_MODEL });

let engine: ReplyEngine | undefined;

/**
 * generateReply({ mode, context, tone, language, deviceId, count? })
 *   → { reply, replies: [{ label, tone, reply }] }   (count > 1 spreads tones Chill → Bold)
 *
 * Callers must present either a valid App Check token (the mobile app) or a
 * Firebase Auth ID token (the Chrome extension signs in anonymously, because
 * App Check attestation is not available to MV3 extensions).
 */
export const generateReply = onCall(
  {
    secrets: [ANTHROPIC_API_KEY],
    enforceAppCheck: false, // enforced below: App Check OR Firebase Auth
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    try {
      if (!request.app && !request.auth) {
        throw new ReplyError("unauthenticated", "This build isn't verified. Update Bro Protocol and try again.");
      }

      const input = parseInput(request.data);
      const limitKey = request.auth ? `uid_${request.auth.uid}` : `dev_${input.deviceId}`;
      if (!(await consumeRateLimit(limitKey, input.count))) {
        throw new ReplyError(
          "resource-exhausted",
          `Easy, bro. That's ${RATE_LIMIT_MAX} replies this hour. Take a breather and come back.`,
        );
      }

      engine ??= createReplyEngine({ apiKey: ANTHROPIC_API_KEY.value(), model: LLM_MODEL.value(), logger });
      const { replies, regenerated } = await generateReplies(engine, input);
      const reply = (replies.find((r) => r.label === "Balanced") ?? replies[0]).reply;

      // Log shape only, never the chat content.
      logger.info("Reply generated", {
        mode: input.mode,
        language: input.language,
        contextChars: input.context.length,
        replies: replies.length,
        regenerated,
        caller: request.app ? "app" : "extension",
      });
      return { reply, replies };
    } catch (error) {
      if (error instanceof ReplyError) throw new HttpsError(error.code, error.message);
      logger.error("Unexpected error", { error: String(error) });
      throw new HttpsError("internal", "Something broke on our side. Try again in a moment.");
    }
  },
);
