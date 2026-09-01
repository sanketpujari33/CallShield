import fs from "node:fs/promises";
import path from "node:path";
import { config } from "../src/config.js";
import { sha256 } from "../src/utils/crypto.js";

function getShardKey(number) {
  const hash = sha256(number);
  return hash.slice(0, 2).toLowerCase();
}

async function run() {
  console.log("Reading spam numbers from:", config.spamNumbersPath);
  const raw = await fs.readFile(config.spamNumbersPath, "utf8");
  const data = JSON.parse(raw);

  const numbers = data.numbers || data;
  if (!Array.isArray(numbers)) {
    throw new Error("Expected numbers array in spam database");
  }

  console.log(`Processing ${numbers.length} spam numbers into 256 shards...`);
  await fs.mkdir(config.shardsDir, { recursive: true });

  const shards = {};
  for (let i = 0; i < 256; i++) {
    const key = i.toString(16).padStart(2, "0");
    shards[key] = [];
  }

  for (const entry of numbers) {
    const num = typeof entry === "string" ? entry : entry.number;
    if (!num) continue;
    const key = getShardKey(num);
    shards[key].push(entry);
  }

  const manifestShards = {};
  for (const [key, list] of Object.entries(shards)) {
    const content = JSON.stringify(list, null, 2);
    const hash = sha256(content);
    manifestShards[key] = {
      count: list.length,
      sha256: hash,
    };
    const shardFile = path.join(config.shardsDir, `${key}.json`);
    await fs.writeFile(shardFile, content, "utf8");
  }

  const manifest = {
    version: data.version || 38,
    generated_at: new Date().toISOString(),
    total_numbers: numbers.length,
    shard_count: 256,
    shards: manifestShards,
  };

  await fs.writeFile(config.manifestPath, JSON.stringify(manifest, null, 2), "utf8");
  console.log("Successfully generated 256 shards and manifest!");
}

run().catch((err) => {
  console.error("Error generating shards:", err);
  process.exit(1);
});
