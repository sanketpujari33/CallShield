import test from "node:test";
import assert from "node:assert/strict";
import {
  normalizePhoneNumberForReport,
  isPlausibleReportNumber,
  stripNationalTrunkPrefix,
  normalizeSmsDomain,
  sanitizeSmsDomains,
  sanitizeSmsUrlIndicators,
} from "../src/utils/phoneNormalizer.js";

test("stripNationalTrunkPrefix: removes leading zero for non-exempt countries", () => {
  // China +86 0558 -> +86558
  assert.equal(stripNationalTrunkPrefix("8605586468536"), "865586468536");
  // UK +44 020 -> +4420
  assert.equal(stripNationalTrunkPrefix("4402079460999"), "442079460999");
});

test("stripNationalTrunkPrefix: preserves trunk zero for Italy (+39) and Cote d'Ivoire (+225)", () => {
  // Italy +39 06 -> preserves 0
  assert.equal(stripNationalTrunkPrefix("39061234567"), "39061234567");
  // Cote d'Ivoire +225 07 -> preserves 0
  assert.equal(stripNationalTrunkPrefix("2250708091011"), "2250708091011");
});

test("normalizePhoneNumberForReport: 10-digit bare US becomes +1 NANP", () => {
  assert.equal(normalizePhoneNumberForReport("2125551234"), "+12125551234");
  assert.equal(normalizePhoneNumberForReport("(212) 555-1234"), "+12125551234");
});

test("normalizePhoneNumberForReport: explicit + does not add +1", () => {
  assert.equal(normalizePhoneNumberForReport("+44 20 7946 0999"), "+442079460999");
  assert.equal(normalizePhoneNumberForReport("+86 0558 646 8536"), "+865586468536");
});

test("isPlausibleReportNumber: validates NANP and international", () => {
  assert.equal(isPlausibleReportNumber("+12127365000"), true);
  assert.equal(isPlausibleReportNumber("+12123456789"), true);
  assert.equal(isPlausibleReportNumber("+442079460999"), true);
  
  // 555 exchange is rejected as fictional
  assert.equal(isPlausibleReportNumber("+12125551234"), false);
  
  // Area code starting with 0 or 1
  assert.equal(isPlausibleReportNumber("+10125551234"), false);
  assert.equal(isPlausibleReportNumber("+11125551234"), false);
  
  // Area code N11 (service code)
  assert.equal(isPlausibleReportNumber("+19115551234"), false);
  
  // Too short / too long
  assert.equal(isPlausibleReportNumber("+12345"), false);
  assert.equal(isPlausibleReportNumber("+1234567890123456"), false);
});

test("normalizeSmsDomain and sanitizers", () => {
  assert.equal(normalizeSmsDomain("https://www.scam-bank.com/login?ref=1"), "scam-bank.com");
  assert.equal(normalizeSmsDomain("phish.co.uk"), "phish.co.uk");
  assert.equal(normalizeSmsDomain("invalid"), null);

  const domains = sanitizeSmsDomains(["https://a.com", "http://b.com", "https://a.com"]);
  assert.deepEqual(domains, ["a.com", "b.com"]);

  const indicators = sanitizeSmsUrlIndicators(["urgent_action", "verify_account", "bad!"]);
  assert.deepEqual(indicators, ["urgent_action", "verify_account"]);
});
