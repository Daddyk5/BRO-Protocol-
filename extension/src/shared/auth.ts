import { config } from "./config";

/**
 * Anonymous Firebase Auth over the REST API. MV3 extensions can't run App
 * Check attestation, so the backend accepts a Firebase ID token instead and
 * rate-limits per anonymous user.
 */
interface Session {
  idToken: string;
  refreshToken: string;
  expiresAt: number;
}

const STORAGE_KEY = "authSession";
const EXPIRY_MARGIN_MS = 60_000;

let inFlight: Promise<string> | null = null;

export class AuthError extends Error {}

export async function getIdToken(forceRefresh = false): Promise<string> {
  inFlight ??= loadToken(forceRefresh).finally(() => {
    inFlight = null;
  });
  return inFlight;
}

export async function clearSession(): Promise<void> {
  await chrome.storage.local.remove(STORAGE_KEY);
}

async function loadToken(forceRefresh: boolean): Promise<string> {
  const stored = (await chrome.storage.local.get(STORAGE_KEY))[STORAGE_KEY] as Session | undefined;

  if (stored && !forceRefresh && stored.expiresAt - EXPIRY_MARGIN_MS > Date.now()) {
    return stored.idToken;
  }

  if (stored?.refreshToken) {
    try {
      const refreshed = await refresh(stored.refreshToken);
      await chrome.storage.local.set({ [STORAGE_KEY]: refreshed });
      return refreshed.idToken;
    } catch {
      // Refresh token revoked or expired: fall through to a new anonymous user.
    }
  }

  const created = await signUpAnonymously();
  await chrome.storage.local.set({ [STORAGE_KEY]: created });
  return created.idToken;
}

async function signUpAnonymously(): Promise<Session> {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${encodeURIComponent(config.apiKey)}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ returnSecureToken: true }),
    },
  );
  const body = (await response.json().catch(() => null)) as
    | { idToken?: string; refreshToken?: string; expiresIn?: string; error?: { message?: string } }
    | null;

  if (!response.ok || !body?.idToken || !body.refreshToken) {
    const code = body?.error?.message ?? `HTTP ${response.status}`;
    if (code.includes("OPERATION_NOT_ALLOWED") || code.includes("ADMIN_ONLY_OPERATION")) {
      throw new AuthError("Anonymous sign-in is disabled. Enable it in Firebase Console → Authentication.");
    }
    throw new AuthError(`Couldn't sign in to Bro Protocol (${code}).`);
  }

  return {
    idToken: body.idToken,
    refreshToken: body.refreshToken,
    expiresAt: Date.now() + Number(body.expiresIn ?? "3600") * 1000,
  };
}

async function refresh(refreshToken: string): Promise<Session> {
  const response = await fetch(`https://securetoken.googleapis.com/v1/token?key=${encodeURIComponent(config.apiKey)}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "refresh_token", refresh_token: refreshToken }),
  });
  const body = (await response.json().catch(() => null)) as
    | { id_token?: string; refresh_token?: string; expires_in?: string }
    | null;
  if (!response.ok || !body?.id_token || !body.refresh_token) {
    throw new AuthError(`Token refresh failed (HTTP ${response.status}).`);
  }
  return {
    idToken: body.id_token,
    refreshToken: body.refresh_token,
    expiresAt: Date.now() + Number(body.expires_in ?? "3600") * 1000,
  };
}
