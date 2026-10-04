import { loadEnv } from "vite";

/** Fails the build early (instead of shipping a broken extension) when .env is incomplete. */
export function assertFirebaseEnv(mode: string): void {
  const env = loadEnv(mode, ".", "VITE_");
  const missing = ["VITE_FIREBASE_API_KEY", "VITE_FIREBASE_PROJECT_ID"].filter((key) => !env[key]);
  if (missing.length > 0 && !env.VITE_FUNCTIONS_BASE_URL && !env.VITE_BRO_BACKEND_URL) {
    throw new Error(
      `Missing ${missing.join(", ")}. Copy extension/.env.example to extension/.env and either set ` +
        "VITE_BRO_BACKEND_URL (Docker backend) or fill the Firebase web app values.",
    );
  }
}
