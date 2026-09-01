import test from "node:test";
import assert from "node:assert/strict";
import {
  checkRateLimit,
  isDuplicateReport,
  recordReportDedup,
  resetRateLimits,
} from "../src/middleware/rateLimiter.js";

test("rateLimiter: enforces max request limit", () => {
  resetRateLimits();
  const testIp = "192.168.1.100";

  for (let i = 0; i < 5; i++) {
    const res = checkRateLimit(testIp);
    assert.equal(res.allowed, true);
  }

  // 6th request should fail
  const blocked = checkRateLimit(testIp);
  assert.equal(blocked.allowed, false);
  assert.ok(blocked.retryAfter > 0);
});

test("dedup: blocks repeated reports within window", () => {
  resetRateLimits();
  const testIp = "192.168.1.200";
  const num = "+12125551234";

  assert.equal(isDuplicateReport(testIp, num), false);
  recordReportDedup(testIp, num);
  assert.equal(isDuplicateReport(testIp, num), true);
  
  // Different number should still be allowed
  assert.equal(isDuplicateReport(testIp, "+12125559999"), false);
});
