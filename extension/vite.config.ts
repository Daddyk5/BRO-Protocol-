import { defineConfig } from "vite";

import { assertFirebaseEnv } from "./env.config.ts";

// Popup page + background service worker (ES module). The content script is
// built separately as a single IIFE (see vite.content.config.ts) because
// content scripts cannot import shared chunks.
export default defineConfig(({ mode }) => {
  assertFirebaseEnv(mode);
  return {
    base: "./",
    build: {
      outDir: "dist",
      emptyOutDir: true,
      target: "chrome120",
      rolldownOptions: {
        input: {
          popup: "popup.html",
          background: "src/background.ts",
        },
        output: {
          entryFileNames: "[name].js",
          chunkFileNames: "chunks/[name]-[hash].js",
          assetFileNames: "assets/[name]-[hash][extname]",
        },
      },
    },
  };
});
