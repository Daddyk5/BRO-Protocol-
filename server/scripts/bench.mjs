// Times real /generateReply calls against a running backend.
//   node scripts/bench.mjs [runs=5] [baseUrl=http://localhost:8080]
// Each run asks for 3 options with tips, like the app's default.
const runs = Number(process.argv[2] ?? 5);
const base = (process.argv[3] ?? "http://localhost:8080").replace(/\/+$/, "");

const contexts = [
  ["BANTER", "lol you seem like trouble"],
  ["LATE_NIGHT", "still up? cant sleep"],
  ["MOVE_OFF_APP", "this has been fun, you're actually funny"],
  ["REVIVE", "haha yeah that show was wild"],
  ["DATE_IDEAS", "i've been craving ramen and want to try bouldering"],
];

async function once(i) {
  const [mode, context] = contexts[i % contexts.length];
  const started = performance.now();
  const res = await fetch(`${base}/generateReply`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      data: { mode, context, tone: 0.5, language: "english", deviceId: `bench-device-${Date.now()}`, count: 3, tips: true },
    }),
  });
  const seconds = (performance.now() - started) / 1000;
  const body = await res.json();
  const ok = res.ok && body.result?.replies?.length > 0;
  console.log(
    `${String(i + 1).padStart(2)}. ${mode.padEnd(12)} ${seconds.toFixed(1).padStart(5)}s  ${ok ? `${body.result.replies.length} replies` : `FAILED ${JSON.stringify(body.error)}`}`,
  );
  return { seconds, ok };
}

const results = [];
for (let i = 0; i < runs; i++) results.push(await once(i));

const times = results.filter((r) => r.ok).map((r) => r.seconds).sort((a, b) => a - b);
const avg = times.reduce((s, t) => s + t, 0) / (times.length || 1);
const p = (q) => times[Math.min(times.length - 1, Math.floor(q * times.length))] ?? 0;
console.log(
  `\n${times.length}/${runs} ok · avg ${avg.toFixed(1)}s · median ${p(0.5).toFixed(1)}s · slowest ${p(1).toFixed(1)}s`,
);
