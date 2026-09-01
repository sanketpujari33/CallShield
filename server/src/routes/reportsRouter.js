import express from "express";
import {
  getClientIp,
  isDuplicateReport,
  recordReportDedup,
  rateLimitMiddleware,
} from "../middleware/rateLimiter.js";
import { submitReport, listRecentReports } from "../services/communityReports.js";
import { normalizePhoneNumberForReport } from "../utils/phoneNormalizer.js";
import { config } from "../config.js";

export const reportsRouter = express.Router();

reportsRouter.post("/", rateLimitMiddleware, async (req, res) => {
  try {
    const clientIp = getClientIp(req);
    const { number, type, sms_domains, sms_url_indicators } = req.body || {};

    if (!number || typeof number !== "string") {
      return res.status(400).json({ error: "number is required and must be a string" });
    }

    const normalized = normalizePhoneNumberForReport(number);
    if (!normalized) {
      return res.status(400).json({ error: "Invalid phone number format" });
    }

    // Dedup check
    if (isDuplicateReport(clientIp, normalized)) {
      res.setHeader("Retry-After", String(Math.ceil(config.dedupWindowMs / 1000)));
      return res.status(429).json({
        error: "Duplicate report, already submitted recently",
        retryAfter: Math.ceil(config.dedupWindowMs / 1000),
      });
    }

    const result = await submitReport({
      number,
      type,
      sms_domains,
      sms_url_indicators,
      clientIp,
    });

    if (!result.success) {
      return res.status(result.status || 400).json({ error: result.error });
    }

    // Record dedup marker only upon successful submission
    recordReportDedup(clientIp, normalized);

    return res.status(200).json({
      success: true,
      number: result.number,
      type: result.type,
      reported_at: result.reported_at,
    });
  } catch (err) {
    console.error("Error submitting report:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

reportsRouter.get("/", async (req, res) => {
  const limit = parseInt(req.query.limit || "50", 10);
  const reports = await listRecentReports(Math.min(limit, 200));
  return res.json({ count: reports.length, reports });
});
