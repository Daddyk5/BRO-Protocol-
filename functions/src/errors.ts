/**
 * Transport-neutral error. Codes match Firebase callable error codes, so the
 * Cloud Function maps them 1:1 to HttpsError and the Docker server maps them
 * to the same `{ error: { status, message } }` response shape.
 */
export type ReplyErrorCode =
  | "invalid-argument"
  | "unauthenticated"
  | "resource-exhausted"
  | "failed-precondition"
  | "unavailable"
  | "internal";

export class ReplyError extends Error {
  constructor(
    readonly code: ReplyErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "ReplyError";
  }
}

export const GENERIC_FAILURE = "Something broke on our side. Try again in a moment.";
