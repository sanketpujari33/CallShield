import { normalizePhoneNumberForReport } from "../utils/phoneNormalizer.js";

// Cache external lookups for 1 hour to prevent flooding
const lookupCache = new Map(); // digits -> { timestamp, data }
const CACHE_TTL_MS = 60 * 60 * 1000;

function getDigits(number) {
  return String(number || "").replace(/\D/g, "");
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 4000) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    return response;
  } finally {
    clearTimeout(id);
  }
}

export async function lookupSkipCalls(digits) {
  try {
    const res = await fetchWithTimeout(`https://spam.skipcalls.app/check/${digits}`, {
      headers: { "User-Agent": "CallShield-Server/1.0" },
    });
    if (!res.ok) return { source: "SkipCalls", isSpam: false, reports: 0, status: "HTTP_" + res.status };
    const json = await res.json();
    return {
      source: "SkipCalls",
      isSpam: Boolean(json.spam || json.is_spam || json.score > 50),
      reports: parseInt(json.reports || json.count || 0, 10),
      detail: json.category || json.label || "",
      status: "SUCCESS",
    };
  } catch (e) {
    return { source: "SkipCalls", isSpam: false, reports: 0, status: e.name === "AbortError" ? "TIMEOUT" : "ERROR" };
  }
}

export async function lookupPhoneBlock(digits) {
  try {
    const res = await fetchWithTimeout(`https://phoneblock.net/phoneblock/api/check?num=${digits}`, {
      headers: { "User-Agent": "CallShield-Server/1.0" },
    });
    if (!res.ok) return { source: "PhoneBlock", isSpam: false, reports: 0, status: "HTTP_" + res.status };
    const json = await res.json();
    const votes = parseInt(json.votes || json.rating || 0, 10);
    return {
      source: "PhoneBlock",
      isSpam: votes > 2 || Boolean(json.is_spam),
      reports: votes,
      detail: json.comment || "",
      status: "SUCCESS",
    };
  } catch (e) {
    return { source: "PhoneBlock", isSpam: false, reports: 0, status: e.name === "AbortError" ? "TIMEOUT" : "ERROR" };
  }
}

export async function lookupWhoCalledMe(digits) {
  try {
    const res = await fetchWithTimeout(`https://whocalledme.uk/api/check/${digits}`, {
      headers: { "User-Agent": "CallShield-Server/1.0" },
    });
    if (!res.ok) return { source: "WhoCalledMe", isSpam: false, reports: 0, status: "HTTP_" + res.status };
    const json = await res.json();
    return {
      source: "WhoCalledMe",
      isSpam: Boolean(json.spam || (json.score && json.score > 40)),
      reports: parseInt(json.reports || 0, 10),
      detail: json.summary || "",
      status: "SUCCESS",
    };
  } catch (e) {
    return { source: "WhoCalledMe", isSpam: false, reports: 0, status: e.name === "AbortError" ? "TIMEOUT" : "ERROR" };
  }
}

export async function lookupOpenCnam(digits) {
  try {
    const res = await fetchWithTimeout(`https://api.opencnam.com/v3/phone/${digits}?format=json`, {
      headers: { "User-Agent": "CallShield-Server/1.0" },
    });
    if (!res.ok) return { source: "OpenCNAM", callerName: "", status: "HTTP_" + res.status };
    const json = await res.json();
    return {
      source: "OpenCNAM",
      callerName: json.name || json.caller_id || "",
      status: "SUCCESS",
    };
  } catch (e) {
    return { source: "OpenCNAM", callerName: "", status: e.name === "AbortError" ? "TIMEOUT" : "ERROR" };
  }
}

export async function multiSourceLookup(rawNumber) {
  const digits = getDigits(rawNumber);
  if (digits.length < 7) {
    return {
      number: rawNumber,
      isSpam: false,
      totalReports: 0,
      callerName: "",
      sources: [],
      error: "Phone number must have at least 7 digits",
    };
  }

  const cached = lookupCache.get(digits);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL_MS) {
    return cached.data;
  }

  const [skipCalls, phoneBlock, whoCalledMe, openCnam] = await Promise.all([
    lookupSkipCalls(digits),
    lookupPhoneBlock(digits),
    lookupWhoCalledMe(digits),
    lookupOpenCnam(digits),
  ]);

  const sources = [skipCalls, phoneBlock, whoCalledMe];
  const totalReports = sources.reduce((acc, s) => acc + (s.reports || 0), 0);
  const isSpam = sources.some((s) => s.isSpam) || totalReports >= 3;

  const result = {
    number: normalizePhoneNumberForReport(rawNumber) || `+${digits}`,
    isSpam,
    totalReports,
    callerName: openCnam.callerName || "",
    sources: [
      ...sources,
      { source: openCnam.source, isSpam: false, detail: openCnam.callerName, status: openCnam.status },
    ],
    timestamp: new Date().toISOString(),
  };

  lookupCache.set(digits, { timestamp: Date.now(), data: result });
  return result;
}

export async function batchAnalyze(items = []) {
  const results = [];
  for (const item of items.slice(0, 100)) {
    const number = item.number || item.address || "";
    const text = item.body || item.text || "";
    const digits = getDigits(number);

    // Quick heuristic rules on server
    const isTollFree = /^(1?(800|888|877|866|855|844|833))/.test(digits);
    const isWangiri = /^(1(809|829|849|876|284|473))/.test(digits);
    const is555 = !isTollFree && /^\d{4}555\d{4}$/.test(digits);

    const lowerText = text.toLowerCase();
    const spamKeywords = [
      "urgent action",
      "account suspended",
      "click here to verify",
      "crypto giveaway",
      "claim your refund",
      "unauthorized transaction",
      "wire transfer",
      "gift card",
      "irs notice"
    ];
    const marketingKeywords = [
      "discount",
      "limited offer",
      "flash sale",
      "promo code",
      "coupon",
      "exclusive deal",
      "shop now",
      "free trial",
      "stop2end",
      "reply stop"
    ];

    const hasSpamText = spamKeywords.some((k) => lowerText.includes(k));
    const hasMarketingText = marketingKeywords.some((k) => lowerText.includes(k));

    let classification = "normal";
    let confidence = 0;
    let category = "clean";
    let reason = "Clean / legitimate signal";

    if (isWangiri || is555 || hasSpamText) {
      classification = "spam";
      confidence = 95;
      category = isWangiri ? "wangiri" : (is555 ? "spoofed_555" : "phishing");
      reason = isWangiri
        ? "Known Caribbean Wangiri callback scam prefix"
        : (is555 ? "Invalid 555 fictional exchange (spoofed)" : "Phishing keyword indicator detected");
    } else if (isTollFree || hasMarketingText) {
      classification = "marketing";
      confidence = 80;
      category = "telemarketing";
      reason = isTollFree ? "Toll-Free automated dialer / sales line" : "Promotional marketing keyword pattern";
    }

    results.push({
      number: normalizePhoneNumberForReport(number) || number,
      classification,
      isSpam: classification === "spam",
      isMarketing: classification === "marketing",
      isNormal: classification === "normal",
      category,
      confidence,
      reason,
      snippet: text.slice(0, 80),
    });
  }

  return {
    total: results.length,
    spamCount: results.filter((r) => r.isSpam).length,
    marketingCount: results.filter((r) => r.isMarketing).length,
    normalCount: results.filter((r) => r.isNormal).length,
    items: results,
  };
}
