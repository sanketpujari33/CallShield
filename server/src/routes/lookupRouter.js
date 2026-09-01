import express from "express";
import { multiSourceLookup, batchAnalyze } from "../services/externalLookup.js";

export const lookupRouter = express.Router();

lookupRouter.post("/batch", async (req, res) => {
  const { items } = req.body || {};
  if (!Array.isArray(items)) {
    return res.status(400).json({ error: "items array is required in request body" });
  }
  const result = await batchAnalyze(items);
  return res.json(result);
});

lookupRouter.get("/:number", async (req, res) => {
  const { number } = req.params;
  const result = await multiSourceLookup(number);
  return res.json(result);
});
