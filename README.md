# CallShield (Flutter & Node.js Edition)

A high-performance, privacy-first spam call and text detection system converted into a cross-platform **Flutter App** and **Node.js Express Backend**.

---

## 🌟 Core Architecture

```
dart-node/
├── app/                                # Flutter Cross-Platform Client
│   ├── assets/data/                    # Bundled GBDT weights, 256 dataset shards, hot list
│   ├── lib/
│   │   ├── core/                       # Constants, Signal Ledger theme, normalization, crypto
│   │   ├── domain/                     # 28 Reason codes, STIR/SHAKEN caller identity, rules, schedules
│   │   ├── data/                       # 15+ layer pipeline, SQLite DAO, GBDT ML engine, heuristics, SMS analyzer
│   │   └── presentation/               # Signal Ledger UI (Home, Activity, Lookup, Rules, Stats, Settings)
│   └── test/                           # 27 automated unit, widget, and ML tests
│
└── server/                             # Node.js Express REST Backend & Sharding Engine
    ├── src/                            # Express server, routers, rate limiting, HMAC reporter bucketing
    ├── scripts/generate-shards.js      # 256 content-addressed shard generation
    └── test/                           # 16 unit and integration tests
```

---

## 🛡️ 15+ Layer Detection Pipeline

The Flutter app executes an on-device detection pipeline ordered strictly by descending priority:

| Priority | Layer | Description |
|---|---|---|
| **10,000** | `ManualWhitelistChecker` | Checks personal user whitelist |
| **9,000** | `ContactWhitelistChecker` | Allows incoming calls from phone contacts |
| **8,800** | `ContactsOnlyChecker` | Strict Mode: blocks any caller not in contacts |
| **8,500** | `StirShakenFailedChecker` | Carrier verification failure (spoofed caller ID) |
| **7,000** | `UserBlocklistChecker` | Personal blocklist with optional expiration |
| **5,500** | `WildcardRuleChecker` | Wildcard globs (`+1800*`) & regex with scheduled days/hours |
| **5,400** | `RangePatternChecker` | Length-locked `#` patterns (`+33162######`) |
| **5,320** | `PrefixRuleChecker` | Caribbean (`+1-809`) and international Wangiri scams |
| **5,300** | `StirShakenAuthenticatedChecker` | Whitelists verified carrier A-Level attestation |
| **5,200** | `SpamDatabaseChecker` | SQLite query against indexed spam records |
| **3,000** | `HeuristicChecker` | Neighbor spoofing (`NPA+NXX`), toll-free, and VoIP checks |
| **2,000** | `MLSpamScorerChecker` | Gradient-Boosted Decision Tree (GBDT) 20-feature scoring |
| **5,400** | `SmsKeywordChecker` | User-defined SMS keywords with time schedules |
| **1,900** | `SmsContentChecker` | Automated phishing link and shortener detection |

---

## 🤖 20-Feature Pure Dart GBDT Model

The ML engine evaluates binary decision trees in pure Dart without external binary dependencies:
- Features: `toll_free`, `high_spam_npa`, `voip_range`, `repeated_digits_ratio`, `sequential_asc_ratio`, `all_same_digit`, `nxx_555`, `last4_zero`, `invalid_nxx`, `subscriber_all_same`, `alternating_pattern`, `sequential_desc_ratio`, `nxx_below_200`, `low_digit_entropy`, `subscriber_sequential`, `time_of_day_sin`, `time_of_day_cos`, `geographic_distance`, `short_number`, `plus_one_prefix`.
- Scoring: `sigmoid(initial_score + learning_rate * sum(leaf_values))`

---

## 🔐 Cryptography & Privacy

- **Zero Tracking**: No user tracking, zero telemetry.
- **Encrypted Backups**: `PBKDF2-HMAC-SHA256` key derivation (100,000 iterations) + `AES-256-GCM` with random 96-bit IV.
- **Autodialer SIT Tone Generator**: Generates ITU-T E.180 3-tone disconnect signal (950Hz / 1400Hz / 1800Hz) to de-list numbers from robocall lists.
- **Anonymous Community Reports**: Daily rotating HMAC-SHA256 reporter bucketing.

---

## 🌟 Truecaller for Android Flagship Super-Suite

CallShield includes the complete flagship Truecaller feature set:

1. **📞 Live Incoming Call Overlay Banner**:
   - Floating dark-mode card with dynamic colors (Green for Food Delivery & Verified Logistics, Red for IRS / Phishing scams, Amber for Auto Warranty Robocalls, Blue for Contacts).
   - STIR/SHAKEN Level A verification badge & threat score meter.
   - Interactive full-screen incoming call simulator with pulsing call controls.

2. **🤖 AI Assistant Call Screener**:
   - AI answers unknown & suspected calls on your behalf.
   - Generates live conversational speech-to-text transcript bubbles in real-time.
   - 4 Assistant Personas (*Friendly*, *Professional*, *Security Filter*, *Formal*).
   - Interactive quick reply action chips (*"Ask details"*, *"I am busy"*, *"Pick Up"*, *"Block Call"*).

3. **💬 Smart SMS Inbox & Fraud Shield**:
   - 4 Smart Categorized Tabs: **Personal**, **Transactions (Bank alerts with 1-Tap `Copy OTP` button)**, **Promotions**, and **Spam & Phishing Link Alerts**.
   - Automatic phishing URL interceptor and batch spam cleaner.

4. **🛡️ WhatsApp & Telegram OTT App Shield**:
   - Unknown VoIP caller ID & scam overlay for **WhatsApp**, **Telegram**, and **Viber**.
   - Intercepts malicious URLs and fraud campaigns in unknown chat messages.
   - Auto-mute calls from high-fraud international country codes.

5. **🎙️ In-App Call Recording Hub**:
   - Records incoming & outgoing calls in-app without third-party tools.
   - Audio waveform equalizer visualizer with interactive seek bar & live timer.
   - Automated AI speech-to-text transcripts with audio export & share.

---

## 🚀 Running the Project

### 1. Start the Node.js Server
```bash
cd dart-node/server
npm install
npm start
# Server starts on http://localhost:3000
# Run tests: npm test
```

### 2. Start the Flutter App
```bash
cd dart-node/app
flutter pub get
flutter run
# Run tests: flutter test
```

