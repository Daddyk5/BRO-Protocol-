import assert from "node:assert/strict";
import { test } from "node:test";

import { findBannedWords, limitSentences, postProcess, splitTip } from "./postprocess";
import { buildSystemPrompt, optionSpecs, toneString } from "./prompt";
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

test("splits the WHY tip from the message", () => {
  assert.deepEqual(splitTip("Coffee Saturday?\nWHY: It's specific. And short."), {
    message: "Coffee Saturday?",
    tip: "It's specific.",
  });
  assert.deepEqual(splitTip("Coffee Saturday?\n\n**Why**: Easy yes."), { message: "Coffee Saturday?", tip: "Easy yes." });
  assert.deepEqual(splitTip("No tip here. Why: not on its own line"), { message: "No tip here. Why: not on its own line" });
});

test("adds notes and date types to the prompt", () => {
  const prompt = buildSystemPrompt("DATE_IDEAS", 0.5, "english", "she loves ramen", {
    notes: "Name: Mia",
    angle: "an evening plan",
  });
  assert.match(prompt, /\[MODE: DATE_IDEAS\]/);
  assert.match(prompt, /Notes about her: "Name: Mia"\nDate type: an evening plan$/);
});

test("option specs: tones for most modes, date types for DATE_IDEAS", () => {
  assert.deepEqual(
    optionSpecs("BANTER", 0.5, 3).map((s) => s.label),
    ["Chill", "Balanced", "Bold"],
  );
  const dates = optionSpecs("DATE_IDEAS", 0.4, 3);
  assert.deepEqual(
    dates.map((s) => s.label),
    ["Low-key", "Activity", "Evening"],
  );
  assert.ok(dates.every((s) => s.tone === 0.4 && s.angle));
  assert.deepEqual(optionSpecs("DATE_IDEAS", 0.9, 1), [{ label: "Bold", tone: 0.9 }]);
});

test("validates input", () => {
  assert.throws(() => parseInput({ mode: "NOPE", context: "hi", deviceId: "abcdefgh12" }));
  assert.throws(() => parseInput({ mode: "BANTER", context: "   ", deviceId: "abcdefgh12" }));
  const ok = parseInput({ mode: "REVIVE", context: " hey ", tone: 7, deviceId: "abcdefgh12" });
  assert.deepEqual(ok, {
    mode: "REVIVE",
    context: "hey",
    tone: 1,
    language: "english",
    deviceId: "abcdefgh12",
    count: 1,
    tips: false,
  });
  const extras = parseInput({ mode: "IMPROVE_DRAFT", context: "hi", deviceId: "abcdefgh12", tips: true, notes: " Mia " });
  assert.equal(extras.tips, true);
  assert.equal(extras.notes, "Mia");
  assert.throws(() => parseInput({ mode: "BANTER", context: "hi", deviceId: "abcdefgh12", notes: "x".repeat(1001) }));
  assert.equal(parseInput({ mode: "LATE_NIGHT", context: "hi", deviceId: "abcdefgh12", count: 9 }).count, 3);
});
