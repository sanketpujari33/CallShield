import path from "node:path";
import { fileURLToPath } from "node:url";
import dotenv from "dotenv";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..");

export const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  host: process.env.HOST || "0.0.0.0",
  nodeEnv: process.env.NODE_ENV || "development",
  reporterBucketSecret: process.env.REPORTER_BUCKET_SECRET || "callshield-default-dev-secret-32-chars-long!",
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || "60000", 10),
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || "5", 10),
  dedupWindowMs: parseInt(process.env.DEDUP_WINDOW_MS || "300000", 10),
  dataDir: path.resolve(ROOT_DIR, "data"),
  reportsDir: path.resolve(ROOT_DIR, "data", "reports"),
  shardsDir: path.resolve(ROOT_DIR, "data", "spam_number_shards"),
  manifestPath: path.resolve(ROOT_DIR, "data", "spam_numbers.manifest.json"),
  hotNumbersPath: path.resolve(ROOT_DIR, "data", "hot_numbers.json"),
  hotRangesPath: path.resolve(ROOT_DIR, "data", "hot_ranges.json"),
  spamDomainsPath: path.resolve(ROOT_DIR, "data", "spam_domains.json"),
  spamModelWeightsPath: path.resolve(ROOT_DIR, "data", "spam_model_weights.json"),
  spamNumbersPath: path.resolve(ROOT_DIR, "data", "spam_numbers.json"),
};
