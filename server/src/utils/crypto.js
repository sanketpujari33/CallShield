import crypto from "node:crypto";

/**
 * Produce a daily-rotating, non-reversible reporter bucket from client IP.
 * Guarantees privacy: the public report queue counts independent sources
 * without storing an IP address or stable cross-day identity.
 */
export function deriveReporterBucket(ip, reportedAt, secret) {
  if (typeof secret !== "string" || secret.length < 32) {
    throw new Error("REPORTER_BUCKET_SECRET is missing or too short (min 32 chars)");
  }
  const day = new Date(reportedAt).toISOString().slice(0, 10);
  const hmac = crypto.createHmac("sha256", secret);
  hmac.update(`v1:${day}:${ip}`);
  const digest = hmac.digest("hex");
  return digest.slice(0, 16);
}

/**
 * Compute SHA-256 hash of a buffer or string.
 */
export function sha256(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}
