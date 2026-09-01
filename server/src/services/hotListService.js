import fs from "node:fs/promises";
import { config } from "../config.js";

export async function getHotNumbers() {
  try {
    const data = await fs.readFile(config.hotNumbersPath, "utf8");
    return JSON.parse(data);
  } catch {
    return { version: 1, numbers: [] };
  }
}

export async function getHotRanges() {
  try {
    const data = await fs.readFile(config.hotRangesPath, "utf8");
    return JSON.parse(data);
  } catch {
    return { version: 1, ranges: [] };
  }
}
