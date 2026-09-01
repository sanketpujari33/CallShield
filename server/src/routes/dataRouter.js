import express from "express";
import {
  getManifest,
  getShard,
  getLegacyDatabase,
  getSpamDomains,
  getModelWeights,
} from "../services/shardService.js";
import { getHotNumbers, getHotRanges } from "../services/hotListService.js";

export const dataRouter = express.Router();

// Manifest
dataRouter.get("/manifest", async (req, res) => {
  const manifest = await getManifest();
  if (!manifest) return res.status(404).json({ error: "Manifest not found" });
  res.setHeader("Cache-Control", "public, max-age=300");
  return res.json(manifest);
});

// Shards by hex key (e.g. /shards/00, /shards/ff)
dataRouter.get("/shards/:shard", async (req, res) => {
  const shard = await getShard(req.params.shard);
  if (!shard) return res.status(404).json({ error: "Shard not found" });
  res.setHeader("Cache-Control", "public, max-age=86400");
  res.setHeader("ETag", `"${shard.sha256}"`);
  return res.json(shard.content);
});

// Hot Numbers
dataRouter.get("/hot_numbers", async (req, res) => {
  const hot = await getHotNumbers();
  res.setHeader("Cache-Control", "public, max-age=300");
  return res.json(hot);
});

// Hot Ranges
dataRouter.get("/hot_ranges", async (req, res) => {
  const ranges = await getHotRanges();
  res.setHeader("Cache-Control", "public, max-age=300");
  return res.json(ranges);
});

// Spam Domains
dataRouter.get("/spam_domains", async (req, res) => {
  const domains = await getSpamDomains();
  res.setHeader("Cache-Control", "public, max-age=3600");
  return res.json(domains);
});

// Model Weights
dataRouter.get("/model_weights", async (req, res) => {
  const weights = await getModelWeights();
  if (!weights) return res.status(404).json({ error: "Model weights not found" });
  res.setHeader("Cache-Control", "public, max-age=3600");
  return res.json(weights);
});

// Legacy monolithic spam database
dataRouter.get("/all", async (req, res) => {
  const db = await getLegacyDatabase();
  if (!db) return res.status(404).json({ error: "Database not found" });
  res.setHeader("Cache-Control", "public, max-age=86400");
  return res.json(db);
});
