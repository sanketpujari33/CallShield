import test from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import { app } from "../src/server.js";
import { resetRateLimits } from "../src/middleware/rateLimiter.js";

test("GET /: returns API HTML overview", async () => {
  const res = await request(app).get("/");
  assert.equal(res.status, 200);
  assert.ok(res.text.includes("CallShield"));
});

test("GET /api/health: returns server health", async () => {
  const res = await request(app).get("/api/health");
  assert.equal(res.status, 200);
  assert.equal(res.body.status, "ok");
  assert.ok(res.body.uptimeSeconds >= 0);
});

test("GET /api/data/manifest: returns database manifest", async () => {
  const res = await request(app).get("/api/data/manifest");
  assert.equal(res.status, 200);
  assert.ok(res.body.version > 0);
  assert.ok(res.body.shards);
});

test("GET /api/data/shards/00: returns shard 00 content", async () => {
  const res = await request(app).get("/api/data/shards/00");
  assert.equal(res.status, 200);
  assert.ok(res.body.numbers && Array.isArray(res.body.numbers));
});

test("GET /api/data/hot_numbers: returns hot numbers list", async () => {
  const res = await request(app).get("/api/data/hot_numbers");
  assert.equal(res.status, 200);
  assert.ok(res.body.numbers !== undefined);
});

test("POST /api/reports: submits report and returns success", async () => {
  resetRateLimits();
  const testNumber = `+1212736${Math.floor(1000 + Math.random() * 9000)}`;
  const res = await request(app)
    .post("/api/reports")
    .send({
      number: testNumber,
      type: "robocall",
      sms_domains: ["scam-example.com"],
      sms_url_indicators: ["urgent_call"],
    });

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.number, testNumber);
  assert.equal(res.body.type, "robocall");
});

test("POST /api/reports: rejects invalid number", async () => {
  resetRateLimits();
  const res = await request(app)
    .post("/api/reports")
    .send({
      number: "123", // too short
      type: "spam",
    });

  assert.equal(res.status, 400);
  assert.ok(res.body.error);
});

test("GET /api/lookup/:number: performs multi-source lookup", async () => {
  const res = await request(app).get("/api/lookup/+12125551234");
  assert.equal(res.status, 200);
  assert.ok(res.body.number);
  assert.ok(Array.isArray(res.body.sources));
});

test("POST /api/lookup/batch: performs batch classification of calls and messages", async () => {
  const res = await request(app)
    .post("/api/lookup/batch")
    .send({
      items: [
        { number: "+18095551234", text: "Urgent action required! Verify account" },
        { number: "+18005559999", text: "Limited offer 50% discount on shoes" },
        { number: "+12127365000", text: "Hi Mom, see you at 6pm" },
      ],
    });
  assert.equal(res.status, 200);
  assert.equal(res.body.total, 3);
  assert.equal(res.body.spamCount, 1);
  assert.equal(res.body.marketingCount, 1);
  assert.equal(res.body.normalCount, 1);
});

