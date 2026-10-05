import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";

export const RATE_LIMIT_MAX = 20;
export const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

const COLLECTION = "rateLimits";

/**
 * Fixed one-hour window per device ID, counted in a Firestore transaction so
 * concurrent function instances agree. Each reply written costs one unit.
 * `allowed` is false when [cost] would go over the limit (nothing is counted).
 */
export async function consumeRateLimit(
  deviceId: string,
  cost = 1,
  now = Date.now(),
): Promise<{ allowed: boolean; remaining: number; resetAt: number }> {
  const db = getFirestore();
  const ref = db.collection(COLLECTION).doc(deviceId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() as { windowStart?: Timestamp; count?: number } | undefined;
    const windowStart = data?.windowStart?.toMillis() ?? 0;
    const count = data?.count ?? 0;

    if (now - windowStart >= RATE_LIMIT_WINDOW_MS) {
      const resetAt = now + RATE_LIMIT_WINDOW_MS;
      if (cost > RATE_LIMIT_MAX) return { allowed: false, remaining: RATE_LIMIT_MAX, resetAt };
      tx.set(ref, {
        windowStart: Timestamp.fromMillis(now),
        count: cost,
        // Lets a Firestore TTL policy on `expiresAt` clean up idle devices.
        expiresAt: Timestamp.fromMillis(now + 2 * RATE_LIMIT_WINDOW_MS),
      });
      return { allowed: true, remaining: RATE_LIMIT_MAX - cost, resetAt };
    }
    const resetAt = windowStart + RATE_LIMIT_WINDOW_MS;
    if (count + cost > RATE_LIMIT_MAX) return { allowed: false, remaining: RATE_LIMIT_MAX - count, resetAt };

    tx.update(ref, { count: FieldValue.increment(cost) });
    return { allowed: true, remaining: RATE_LIMIT_MAX - count - cost, resetAt };
  });
}
