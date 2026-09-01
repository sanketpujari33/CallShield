import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { config } from "../config.js";
import { deriveReporterBucket } from "../utils/crypto.js";
import {
  normalizePhoneNumberForReport,
  isPlausibleReportNumber,
  sanitizeSmsReportFields,
} from "../utils/phoneNormalizer.js";

const VALID_TYPES = new Set([
  "spam",
  "robocall",
  "scam",
  "telemarketer",
  "debt_collector",
  "sms_spam",
  "not_spam",
  "ai_voice",
  "unknown",
]);

export async function submitReport({ number, type, sms_domains, sms_url_indicators, clientIp }) {
  if (!number || typeof number !== "string") {
    return { success: false, status: 400, error: "Valid phone number is required" };
  }

  const normalized = normalizePhoneNumberForReport(number);
  if (!normalized || !isPlausibleReportNumber(normalized)) {
    return { success: false, status: 400, error: "Invalid phone number format or non-plausible number" };
  }

  const validatedType = VALID_TYPES.has(type) ? type : "unknown";
  const smsFields = sanitizeSmsReportFields({ sms_domains, sms_url_indicators });

  const timestamp = new Date().toISOString();
  const reporterBucket = deriveReporterBucket(clientIp, timestamp, config.reporterBucketSecret);
  const rand = crypto.randomUUID().slice(0, 8);
  const cleanNumber = normalized.replace("+", "");
  const filename = `${cleanNumber}_${Date.now()}_${rand}.json`;

  const report = {
    number: normalized,
    type: validatedType,
    reported_at: timestamp,
    source: "community_app",
    reporter_bucket: reporterBucket,
  };

  if (smsFields.sms_domains.length > 0) {
    report.sms_domains = smsFields.sms_domains;
  }
  if (smsFields.sms_url_indicators.length > 0) {
    report.sms_url_indicators = smsFields.sms_url_indicators;
  }

  await fs.mkdir(config.reportsDir, { recursive: true });
  const filePath = path.join(config.reportsDir, filename);
  await fs.writeFile(filePath, JSON.stringify(report, null, 2), "utf8");

  return {
    success: true,
    status: 200,
    number: normalized,
    type: validatedType,
    reported_at: timestamp,
    filename,
  };
}

export async function listRecentReports(limit = 100) {
  try {
    await fs.mkdir(config.reportsDir, { recursive: true });
    const files = await fs.readdir(config.reportsDir);
    const jsonFiles = files.filter((f) => f.endsWith(".json"));
    
    // Sort descending by timestamp in filename
    jsonFiles.sort((a, b) => b.localeCompare(a));
    const selected = jsonFiles.slice(0, limit);

    const reports = await Promise.all(
      selected.map(async (file) => {
        try {
          const content = await fs.readFile(path.join(config.reportsDir, file), "utf8");
          return { filename: file, ...JSON.parse(content) };
        } catch {
          return null;
        }
      })
    );

    return reports.filter(Boolean);
  } catch (err) {
    console.error("Error reading reports:", err);
    return [];
  }
}

export async function getReportStats() {
  try {
    await fs.mkdir(config.reportsDir, { recursive: true });
    const files = await fs.readdir(config.reportsDir);
    const count = files.filter((f) => f.endsWith(".json")).length;
    return { totalReports: count };
  } catch {
    return { totalReports: 0 };
  }
}
