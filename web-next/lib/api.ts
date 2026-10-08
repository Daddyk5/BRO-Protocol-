import type { ModeId } from "./modes";

export interface ReplyOption {
  label: string;
  tone: number;
  reply: string;
  tip?: string;
}

export interface GenerateInput {
  mode: ModeId;
  context: string;
  deviceId: string;
  count: 1 | 3;
  notes?: string;
}

// Same-origin proxy by default (see next.config.ts); set the env var to call a backend directly.
const BASE = (process.env.NEXT_PUBLIC_BRO_BACKEND_URL || "/api/bro").replace(/\/+$/, "");
const CLIENT_TOKEN = process.env.NEXT_PUBLIC_BRO_CLIENT_TOKEN || "";

/** Calls the Bro Protocol backend (same contract as the mobile app). */
export async function generateReplies(input: GenerateInput): Promise<ReplyOption[]> {
  let res: Response;
  try {
    res = await fetch(`${BASE}/generateReply`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(CLIENT_TOKEN ? { "X-Bro-Client": CLIENT_TOKEN } : {}),
      },
      body: JSON.stringify({
        data: { ...input, tone: 0.5, language: "english", tips: true },
      }),
    });
  } catch {
    throw new Error("Can't reach the server. Check your connection and try again.");
  }

  const body = (await res.json().catch(() => null)) as {
    result?: { replies?: ReplyOption[]; reply?: string };
    error?: { status?: string; message?: string };
  } | null;

  if (!res.ok) {
    const message = body?.error?.message;
    throw new Error(message && body?.error?.status !== "INTERNAL" ? message : "Something broke on our side. Try again.");
  }
  const replies = body?.result?.replies?.filter((r) => r.reply) ?? [];
  if (replies.length === 0 && body?.result?.reply) {
    return [{ label: "Balanced", tone: 0.5, reply: body.result.reply }];
  }
  if (replies.length === 0) throw new Error("Came back empty. Hit regenerate.");
  return replies;
}
