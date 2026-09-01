import fs from "node:fs/promises";
import path from "node:path";
import { config } from "../config.js";
import { sha256 } from "../utils/crypto.js";

export async function getManifest() {
  try {
    const data = await fs.readFile(config.manifestPath, "utf8");
    return JSON.parse(data);
  } catch (err) {
    console.error("Error reading manifest:", err);
    return null;
  }
}

export async function getShard(shardKey) {
  if (!shardKey || typeof shardKey !== "string") return null;
  const cleanKey = shardKey.toLowerCase().replace(".json", "").trim();
  if (!/^[0-9a-f]{2}$/.test(cleanKey)) return null;

  const shardFile = path.join(config.shardsDir, `${cleanKey}.json`);
  try {
    const data = await fs.readFile(shardFile, "utf8");
    return {
      key: cleanKey,
      content: JSON.parse(data),
      raw: data,
      sha256: sha256(data),
    };
  } catch {
    return null;
  }
}

export async function getLegacyDatabase() {
  try {
    const data = await fs.readFile(config.spamNumbersPath, "utf8");
    return JSON.parse(data);
  } catch (err) {
    console.error("Error reading legacy database:", err);
    return null;
  }
}

export async function getSpamDomains() {
  try {
    const data = await fs.readFile(config.spamDomainsPath, "utf8");
    return JSON.parse(data);
  } catch {
    return [];
  }
}

export async function getModelWeights() {
  try {
    const data = await fs.readFile(config.spamModelWeightsPath, "utf8");
    return JSON.parse(data);
  } catch {
    return null;
  }
}
