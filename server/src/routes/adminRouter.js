import express from "express";
import { getReportStats } from "../services/communityReports.js";
import { getManifest } from "../services/shardService.js";
import { createRequire } from 'module';

var require = createRequire(import.meta.url);
var module = { exports: {} };

export const adminRouter = express.Router();

adminRouter.get("/health", async (req, res) => {
  const [reportStats, manifest] = await Promise.all([getReportStats(), getManifest()]);
  return res.json({
    status: "ok",
    uptimeSeconds: Math.floor(process.uptime()),
    databaseVersion: manifest?.version || "unknown",
    totalShards: manifest?.shards ? Object.keys(manifest.shards).length : 0,
    totalQueuedReports: reportStats.totalReports,
    timestamp: new Date().toISOString(),
  });
});
