const env = import.meta.env;

export const config = {
  apiKey: env.VITE_FIREBASE_API_KEY ?? "",
  projectId: env.VITE_FIREBASE_PROJECT_ID ?? "",
  region: env.VITE_FUNCTIONS_REGION || "us-central1",
  functionsBaseUrlOverride: env.VITE_FUNCTIONS_BASE_URL ?? "",
  /** Self-hosted (Docker) backend. When set, Firebase isn't used at all. */
  broBackendUrl: env.VITE_BRO_BACKEND_URL ?? "",
  broClientToken: env.VITE_BRO_CLIENT_TOKEN ?? "",
};

export const selfHosted = Boolean(config.broBackendUrl);

export function functionsBaseUrl(): string {
  if (selfHosted) return config.broBackendUrl.replace(/\/+$/, "");
  if (config.functionsBaseUrlOverride) return config.functionsBaseUrlOverride.replace(/\/$/, "");
  return `https://${config.region}-${config.projectId}.cloudfunctions.net`;
}
