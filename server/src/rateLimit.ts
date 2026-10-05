import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export interface RateLimiterOptions {
  windowMs?: number;
  /** When set, counters are saved here (and reloaded on start) so a restart doesn't reset them. */
  filePath?: string;
}

type Window = { start: number; count: number };

/**
 * Fixed one-hour window per key, kept in memory and optionally snapshotted to
 * a JSON file every minute and on shutdown. Right for a single container.
 */
export class MemoryRateLimiter {
  readonly windowMs: number;
  private readonly filePath?: string;
  private readonly windows = new Map<string, Window>();
  private readonly ticker: NodeJS.Timeout;
  private dirty = false;

  constructor(
    readonly max: number,
    { windowMs = 60 * 60 * 1000, filePath }: RateLimiterOptions = {},
  ) {
    this.windowMs = windowMs;
    this.filePath = filePath;
    this.load();
    this.ticker = setInterval(() => {
      this.sweep();
      this.save();
    }, 60 * 1000);
    this.ticker.unref();
  }

  /** Counts [cost] units; returns false (without counting) when that would go over the limit. */
  consume(key: string, cost = 1, now = Date.now()): boolean {
    const window = this.windows.get(key);
    if (!window || now - window.start >= this.windowMs) {
      if (cost > this.max) return false;
      this.windows.set(key, { start: now, count: cost });
      this.dirty = true;
      return true;
    }
    if (window.count + cost > this.max) return false;
    window.count += cost;
    this.dirty = true;
    return true;
  }

  sweep(now = Date.now()): void {
    for (const [key, window] of this.windows) {
      if (now - window.start >= this.windowMs) {
        this.windows.delete(key);
        this.dirty = true;
      }
    }
  }

  /** Writes the counters to [filePath] if anything changed (atomic rename). */
  save(): void {
    if (!this.filePath || !this.dirty) return;
    try {
      mkdirSync(dirname(this.filePath), { recursive: true });
      const tmp = `${this.filePath}.tmp`;
      writeFileSync(tmp, JSON.stringify(Object.fromEntries(this.windows)));
      renameSync(tmp, this.filePath);
      this.dirty = false;
    } catch (error) {
      console.error(JSON.stringify({ severity: "ERROR", message: "Couldn't save rate limits", error: String(error) }));
    }
  }

  close(): void {
    clearInterval(this.ticker);
    this.save();
  }

  private load(): void {
    if (!this.filePath) return;
    let raw: string;
    try {
      raw = readFileSync(this.filePath, "utf8");
    } catch {
      return; // First start: nothing saved yet.
    }
    try {
      const saved = JSON.parse(raw) as Record<string, Window>;
      for (const [key, w] of Object.entries(saved)) {
        if (typeof w?.start === "number" && typeof w?.count === "number") this.windows.set(key, w);
      }
      this.sweep();
    } catch {
      console.error(JSON.stringify({ severity: "WARNING", message: "Ignoring unreadable rate-limit file" }));
    }
  }
}
