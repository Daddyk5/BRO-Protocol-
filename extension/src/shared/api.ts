import { AuthError, clearSession, getIdToken } from "./auth";
import { config, functionsBaseUrl, selfHosted } from "./config";
import type { GeneratePayload } from "./messages";
import { getDeviceId } from "./storage";

interface CallableResponse {
  result?: { reply?: unknown };
  error?: { message?: string; status?: string };
}

/** Calls the same `generateReply` backend the mobile app uses (Cloud Function or Docker server). */
export async function generateReply(payload: GeneratePayload): Promise<string> {
  const deviceId = await getDeviceId();

  const attempt = async (forceRefresh: boolean) => {
    const headers: Record<string, string> = { "Content-Type": "application/json" };
    if (selfHosted) {
      if (config.broClientToken) headers["X-Bro-Client"] = config.broClientToken;
    } else {
      headers.Authorization = `Bearer ${await getIdToken(forceRefresh)}`;
    }
    return fetch(`${functionsBaseUrl()}/generateReply`, {
      method: "POST",
      headers,
      body: JSON.stringify({ data: { ...payload, deviceId } }),
    });
  };

  let response: Response;
  try {
    response = await attempt(false);
    if (response.status === 401 && !selfHosted) {
      // Stale or revoked ID token: refresh once, then start over if needed.
      response = await attempt(true);
      if (response.status === 401) {
        await clearSession();
        response = await attempt(false);
      }
    }
  } catch (error) {
    if (error instanceof AuthError) throw error;
    throw new Error("No connection. Check your internet and try again.");
  }

  const body = (await response.json().catch(() => null)) as CallableResponse | null;
  if (!response.ok || body?.error) {
    const message = body?.error?.message;
    throw new Error(message && message !== "INTERNAL" ? message : "Something broke on our side. Try again in a moment.");
  }

  const reply = body?.result?.reply;
  if (typeof reply !== "string" || !reply) throw new Error("Came back empty. Hit regenerate.");
  return reply;
}
