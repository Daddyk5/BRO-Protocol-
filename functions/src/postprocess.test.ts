import assert from "node:assert/strict";
import { test } from "node:test";

import { findBannedWords, limitSentences, postProcess } from "./postprocess";
import { buildSystemPrompt, toneString } from "./prompt";
import { parseInput } from "./validation";

test("strips quotation marks but keeps apostrophes", () => {
  assert.equal(postProcess('"That\'s a bold claim about pineapple pizza."'), "That's a bold claim about pineapple pizza.");
  assert.equal(postProcess("“Hiking or just collecting trail photos?”"), "Hiking or just collecting trail photos?");
  assert.equal(postProcess("'Fair point.'"), "Fair point.");
});

test("limits to two sentences", () => {
  assert.equal(postProcess("One. Two! Three? Four."), "One. Two!");
  assert.equal(limitSentences("It costs 3.5 dollars. Worth it. Trust me.", 2), "It costs 3.5 dollars. Worth it.");
  assert.equal(limitSentences("Just one sentence", 2), "Just one sentence");
  assert.equal(limitSentences("Ha! 😂 Fine. Last one.", 2), "Ha! 😂 Fine.");
});

test("detects banned words and simple inflections", () => {
  assert.deepEqual(findBannedWords("Good vibes only"), ["vibe"]);
  assert.deepEqual(findBannedWords("Total sigma move, alpha energy"), ["alpha", "sigma"]);
  assert.deepEqual(findBannedWords("The alphabet soup was great"), []);
});

test("fills the system prompt template", () => {
  const prompt = buildSystemPrompt("BANTER", 0.9, "taglish", "Price is $5 & $& stays literal");
  assert.match(prompt, /Mode: \[MODE: BANTER\]\nTone: Bold, Taglish\nContext: "Price is \$5 & \$& stays literal"$/);
  assert.equal(toneString(0.1, "english"), "Chill");
});

test("validates input", () => {
  assert.throws(() => parseInput({ mode: "NOPE", context: "hi", deviceId: "abcdefgh12" }));
  assert.throws(() => parseInput({ mode: "BANTER", context: "   ", deviceId: "abcdefgh12" }));
  const ok = parseInput({ mode: "REVIVE", context: " hey ", tone: 7, deviceId: "abcdefgh12" });
  assert.deepEqual(ok, { mode: "REVIVE", context: "hey", tone: 1, language: "english", deviceId: "abcdefgh12" });
});
