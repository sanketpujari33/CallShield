const FORMAT_CONTROL_CODES = new Set([0x200b, 0x200c, 0x200d, 0x200e, 0x200f, 0xfeff]);
const MAX_SMS_DOMAINS = 10;
const MAX_SMS_URL_INDICATORS = 10;
const DOMAIN_RE = /^[a-z0-9](?:[a-z0-9.-]{0,251}[a-z0-9])?$/;
const URL_INDICATOR_RE = /^[a-z_]{3,40}$/;

const ONE_DIGIT_COUNTRY_CODES = new Set(["1", "7"]);
const TWO_DIGIT_COUNTRY_CODES = new Set([
  "20", "27",
  "30", "31", "32", "33", "34", "36", "39",
  "40", "41", "43", "44", "45", "46", "47", "48", "49",
  "51", "52", "53", "54", "55", "56", "57", "58",
  "60", "61", "62", "63", "64", "65", "66",
  "81", "82", "84", "86",
  "90", "91", "92", "93", "94", "95", "98",
]);

const TRUNK_ZERO_SIGNIFICANT_COUNTRY_CODES = new Set(["39", "225"]);

export function splitCountryCode(digits) {
  if (!digits || typeof digits !== "string") return null;
  if (ONE_DIGIT_COUNTRY_CODES.has(digits.slice(0, 1))) return [digits.slice(0, 1), digits.slice(1)];
  if (TWO_DIGIT_COUNTRY_CODES.has(digits.slice(0, 2))) return [digits.slice(0, 2), digits.slice(2)];
  if (digits.length >= 3) return [digits.slice(0, 3), digits.slice(3)];
  return null;
}

export function stripNationalTrunkPrefix(digits) {
  const split = splitCountryCode(digits);
  if (split === null) return digits;
  const [countryCode, national] = split;
  if (TRUNK_ZERO_SIGNIFICANT_COUNTRY_CODES.has(countryCode)) return digits;
  const stripped = national.replace(/^0+/, "");
  if (stripped === "") return digits;
  return countryCode + stripped;
}

export function normalizePhoneNumberForReport(number) {
  if (typeof number !== "string") return null;

  let cleaned = "";
  for (const ch of number) {
    if (!FORMAT_CONTROL_CODES.has(ch.charCodeAt(0))) cleaned += ch;
  }
  cleaned = cleaned.trim();

  const explicitInternational = cleaned.startsWith("+");

  let digits = "";
  for (const ch of cleaned) {
    if (ch >= "0" && ch <= "9") digits += ch;
  }

  if (digits.length < 7 || digits.length > 15) return null;
  if (!explicitInternational && digits.length === 10) return `+1${digits}`;
  if (explicitInternational) {
    digits = stripNationalTrunkPrefix(digits);
    if (digits.length < 7 || digits.length > 15) return null;
  }
  return `+${digits}`;
}

export function isPlausibleReportNumber(e164) {
  if (typeof e164 !== "string" || !e164.startsWith("+")) return false;
  const digits = e164.slice(1);
  if (!/^[0-9]+$/.test(digits)) return false;
  if (digits.length < 8 || digits.length > 15) return false;
  if (digits[0] === "0") return false;
  if (digits[0] === "1") {
    // NANP rules
    if (digits.length !== 11) return false;
    const npa = digits.slice(1, 4);
    const nxx = digits.slice(4, 7);
    if (npa[0] < "2" || npa.slice(1) === "11" || npa === "555") return false;
    if (nxx[0] < "2" || nxx === "555") return false;
  }
  return true;
}

export function normalizeSmsDomain(value) {
  if (typeof value !== "string") return null;

  let domain = value.toLowerCase().trim();
  domain = domain.replace(/^https?:\/\//, "").replace(/^www\./, "");
  domain = domain.split("/")[0].split("?")[0].split("#")[0].split(":")[0];
  domain = domain.replace(/^\.+|\.+$/g, "");
  if (domain.length < 5 || domain.length > 253) return null;
  if (!domain.includes(".")) return null;
  if (!DOMAIN_RE.test(domain)) return null;

  const labels = domain.split(".");
  if (labels.some((label) => label.length < 1 || label.length > 63)) return null;
  if (labels.some((label) => label.startsWith("-") || label.endsWith("-"))) return null;
  return domain;
}

export function sanitizeSmsDomains(value) {
  if (!Array.isArray(value)) return [];

  const domains = [];
  for (const raw of value) {
    const domain = normalizeSmsDomain(raw);
    if (domain && !domains.includes(domain)) domains.push(domain);
    if (domains.length >= MAX_SMS_DOMAINS) break;
  }
  return domains;
}

export function sanitizeSmsUrlIndicators(value) {
  if (!Array.isArray(value)) return [];

  const indicators = [];
  for (const raw of value) {
    if (typeof raw !== "string") continue;
    const indicator = raw.toLowerCase().trim();
    if (URL_INDICATOR_RE.test(indicator) && !indicators.includes(indicator)) {
      indicators.push(indicator);
    }
    if (indicators.length >= MAX_SMS_URL_INDICATORS) break;
  }
  return indicators;
}

export function sanitizeSmsReportFields(body) {
  return {
    sms_domains: sanitizeSmsDomains(body?.sms_domains),
    sms_url_indicators: sanitizeSmsUrlIndicators(body?.sms_url_indicators),
  };
}
