// Copies the transport-neutral reply logic from functions/src into
// server/src/core so both backends run the exact same prompt and rules.
// (The Dockerfile does the same copy from the repo root.)
import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const CORE_FILES = ["errors.ts", "llm.ts", "postprocess.ts", "prompt.ts", "validation.ts"];

const here = dirname(fileURLToPath(import.meta.url));
const from = resolve(here, "../../functions/src");
const to = resolve(here, "../src/core");
mkdirSync(to, { recursive: true });
for (const file of CORE_FILES) copyFileSync(resolve(from, file), resolve(to, file));
console.log(`synced ${CORE_FILES.length} core files from functions/src`);
