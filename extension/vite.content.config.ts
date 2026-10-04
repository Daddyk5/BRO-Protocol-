import { defineConfig } from "vite";

import { assertFirebaseEnv } from "./env.config.ts";

export default defineConfig(({ mode }) => {
  assertFirebaseEnv(mode);
  return {
    publicDir: false,
    build: {
      outDir: "dist",
      emptyOutDir: false,
      target: "chrome120",
      lib: {
        entry: "src/content/content.ts",
        formats: ["iife"],
        name: "BroProtocolContent",
        fileName: () => "content.js",
      },
    },
  };
});
