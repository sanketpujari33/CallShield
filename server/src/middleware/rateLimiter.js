import { config } from "../config.js";

// In-memory state with automatic sliding-window expiration
const ipRateLimits = new Map(); // ip -> { count, windowStart }
const dedupEntries = new Map(); // `${ip}:${number}` -> expiryTimestamp

// Periodic cleanup interval (runs every 60s)
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of ipRateLimits.entries()) {
    if (now - entry.windowStart >= config.rateLimitWindowMs) {
      ipRateLimits.delete(ip);
    }
  }
  for (const [key, expiry] of dedupEntries.entries()) {
    if (now >= expiry) {
      dedupEntries.delete(key);
    }
  }
}, 60000).unref();

export function getClientIp(req) {
  const cfIp = req.headers["cf-connecting-ip"];
  if (cfIp && typeof cfIp === "string" && cfIp.trim().length > 0) {
    return cfIp.trim();
  }
  const xForwardedFor = req.headers["x-forwarded-for"];
  if (xForwardedFor && typeof xForwardedFor === "string") {
    const first = xForwardedFor.split(",")[0].trim();
    if (first) return first;
  }
  return req.ip || req.socket?.remoteAddress || "127.0.0.1";
}

export function checkRateLimit(ip) {
  const now = Date.now();
  const entry = ipRateLimits.get(ip);

  if (!entry) {
    ipRateLimits.set(ip, { count: 1, windowStart: now });
    return { allowed: true, remaining: config.rateLimitMax - 1, retryAfter: 0 };
  }

  const elapsed = now - entry.windowStart;
  if (elapsed >= config.rateLimitWindowMs) {
    ipRateLimits.set(ip, { count: 1, windowStart: now });
    return { allowed: true, remaining: config.rateLimitMax - 1, retryAfter: 0 };
  }

  if (entry.count >= config.rateLimitMax) {
    const retryAfter = Math.ceil((config.rateLimitWindowMs - elapsed) / 1000);
    return { allowed: false, remaining: 0, retryAfter };
  }

  entry.count += 1;
  const retryAfter = Math.ceil((config.rateLimitWindowMs - elapsed) / 1000);
  return { allowed: true, remaining: config.rateLimitMax - entry.count, retryAfter };
}

export function isDuplicateReport(ip, normalizedNumber) {
  const key = `${ip}:${normalizedNumber}`;
  const expiry = dedupEntries.get(key);
  if (!expiry) return false;
  if (Date.now() >= expiry) {
    dedupEntries.delete(key);
    return false;
  }
  return true;
}

export function recordReportDedup(ip, normalizedNumber) {
  const key = `${ip}:${normalizedNumber}`;
  dedupEntries.set(key, Date.now() + config.dedupWindowMs);
}

export function rateLimitMiddleware(req, res, next) {
  const clientIp = getClientIp(req);
  const result = checkRateLimit(clientIp);

  res.setHeader("X-RateLimit-Limit", config.rateLimitMax);
  res.setHeader("X-RateLimit-Remaining", result.remaining);

  if (!result.allowed) {
    res.setHeader("Retry-After", result.retryAfter);
    return res.status(429).json({
      error: "Rate limited, please retry later",
      retryAfter: result.retryAfter,
    });
  }

  next();
}

/** Reset in-memory rate limits (used by unit tests) */
export function resetRateLimits() {
  ipRateLimits.clear();
  dedupEntries.clear();
}
