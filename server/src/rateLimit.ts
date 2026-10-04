/**
 * Fixed one-hour window per key, kept in memory. Right for a single container;
 * counters reset when the container restarts.
 */
export class MemoryRateLimiter {
  private readonly windows = new Map<string, { start: number; count: number }>();
  private readonly sweeper: NodeJS.Timeout;

  constructor(
    readonly max: number,
    readonly windowMs = 60 * 60 * 1000,
  ) {
    this.sweeper = setInterval(() => this.sweep(), 10 * 60 * 1000);
    this.sweeper.unref();
  }

  /** Counts one request; returns false (without counting) when over the limit. */
  consume(key: string, now = Date.now()): boolean {
    const window = this.windows.get(key);
    if (!window || now - window.start >= this.windowMs) {
      this.windows.set(key, { start: now, count: 1 });
      return true;
    }
    if (window.count >= this.max) return false;
    window.count += 1;
    return true;
  }

  sweep(now = Date.now()): void {
    for (const [key, window] of this.windows) {
      if (now - window.start >= this.windowMs) this.windows.delete(key);
    }
  }

  close(): void {
    clearInterval(this.sweeper);
  }
}
