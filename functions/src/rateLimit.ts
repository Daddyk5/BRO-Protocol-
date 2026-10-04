import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";

export const RATE_LIMIT_MAX = 20;
export const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

const COLLECTION = "rateLimits";

/**
 * Fixed one-hour window per device ID, counted in a Firestore transaction so
 * concurrent function instances agree. Returns false when the device is over
 * the limit (the request is not counted).
 */
export async function consumeRateLimit(deviceId: string, now = Date.now()): Promise<boolean> {
  const db = getFirestore();
  const ref = db.collection(COLLECTION).doc(deviceId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() as { windowStart?: Timestamp; count?: number } | undefined;
    const windowStart = data?.windowStart?.toMillis() ?? 0;
    const count = data?.count ?? 0;

    if (now - windowStart >= RATE_LIMIT_WINDOW_MS) {
      tx.set(ref, {
        windowStart: Timestamp.fromMillis(now),
        count: 1,
        // Lets a Firestore TTL policy on `expiresAt` clean up idle devices.
        expiresAt: Timestamp.fromMillis(now + 2 * RATE_LIMIT_WINDOW_MS),
      });
      return true;
    }
    if (count >= RATE_LIMIT_MAX) return false;

    tx.update(ref, { count: FieldValue.increment(1) });
    return true;
  });
}
