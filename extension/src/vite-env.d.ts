/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_FIREBASE_API_KEY?: string;
  readonly VITE_FIREBASE_PROJECT_ID?: string;
  readonly VITE_FUNCTIONS_REGION?: string;
  readonly VITE_FUNCTIONS_BASE_URL?: string;
  readonly VITE_BRO_BACKEND_URL?: string;
  readonly VITE_BRO_CLIENT_TOKEN?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
