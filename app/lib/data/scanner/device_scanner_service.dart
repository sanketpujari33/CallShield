import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/platform/callshield_platform.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../domain/models/caller_identity.dart';
import '../../domain/models/device_scan_models.dart';
import '../checker/checker_pipeline.dart';
import '../remote/callshield_api_client.dart';
import '../sms/sms_content_analyzer.dart';

class DeviceScannerService {
  final CallShieldPlatform _platform = CallShieldPlatform.instance;
  final CallShieldApiClient _apiClient = CallShieldApiClient();

  /// Scans device call history and categorizes each call
  Future<DeviceScanSummary> scanCalls(CheckerPipeline pipeline, {int limit = 100}) async {
    List<Map<String, dynamic>> rawCalls = [];
    if (!kIsWeb && Platform.isAndroid) {
      rawCalls = await _platform.getCallLog(limit: limit);
    }

    if (rawCalls.isEmpty) {
      rawCalls = _getSampleCallLog();
    }

    final items = <DeviceScanItem>[];
    int spam = 0;
    int marketing = 0;
    int normal = 0;

    for (int i = 0; i < rawCalls.length; i++) {
      final call = rawCalls[i];
      final rawNumber = (call['number'] ?? '').toString();
      final name = (call['name'] ?? '').toString();
      final dateEpoch = call['date'] is int ? call['date'] as int : DateTime.now().millisecondsSinceEpoch;
      final date = DateTime.fromMillisecondsSinceEpoch(dateEpoch);
      final duration = call['duration'] ?? 0;

      final normalized = PhoneNormalizer.normalize(rawNumber) ?? rawNumber;
      final isContact = name.isNotEmpty;

      final identity = CallerIdentity(
        rawNumber: rawNumber,
        normalizedNumber: normalized,
        displayName: name,
        isContact: isContact,
      );

      final result = await pipeline.run(identity, date);

      DeviceScanVerdict verdict;
      String matchReason;
      String category;
      int confidence;

      if (result != null && result.isBlocked) {
        verdict = DeviceScanVerdict.spam;
        matchReason = result.description;
        category = result.reasonCode.name;
        confidence = result.confidence;
        spam++;
      } else if (_isMarketingNumber(normalized, name)) {
        verdict = DeviceScanVerdict.marketing;
        matchReason = 'Toll-Free marketing dialer pattern';
        category = 'telemarketing';
        confidence = 80;
        marketing++;
      } else {
        verdict = DeviceScanVerdict.normal;
        matchReason = isContact ? 'Verified address book contact' : 'Standard regional phone number';
        category = 'clean';
        confidence = 0;
        normal++;
      }

      items.add(DeviceScanItem(
        id: 'call_$i',
        number: normalized,
        displayName: name.isNotEmpty ? name : PhoneNormalizer.formatDisplay(normalized),
        snippet: 'Duration: ${duration}s • ${verdict.label}',
        timestamp: date,
        scanType: DeviceScanType.call,
        verdict: verdict,
        confidence: confidence,
        matchReason: matchReason,
        category: category,
      ));
    }

    return DeviceScanSummary(
      totalScanned: items.length,
      spamCount: spam,
      marketingCount: marketing,
      normalCount: normal,
      items: items,
    );
  }

  /// Scans device SMS inbox and categorizes phishing vs marketing vs clean
  Future<DeviceScanSummary> scanSms(CheckerPipeline pipeline, {int limit = 100}) async {
    List<Map<String, dynamic>> rawSms = [];
    if (!kIsWeb && Platform.isAndroid) {
      rawSms = await _platform.getSmsInbox(limit: limit);
    }

    if (rawSms.isEmpty) {
      rawSms = _getSampleSmsInbox();
    }

    final items = <DeviceScanItem>[];
    int spam = 0;
    int marketing = 0;
    int normal = 0;

    for (int i = 0; i < rawSms.length; i++) {
      final msg = rawSms[i];
      final address = (msg['address'] ?? '').toString();
      final body = (msg['body'] ?? '').toString();
      final dateEpoch = msg['date'] is int ? msg['date'] as int : DateTime.now().millisecondsSinceEpoch;
      final date = DateTime.fromMillisecondsSinceEpoch(dateEpoch);

      final normalized = PhoneNormalizer.normalize(address) ?? address;
      final smsAnalysis = SmsContentAnalyzer.instance.analyze(body);

      DeviceScanVerdict verdict;
      String matchReason;
      String category;
      int confidence;

      if (smsAnalysis.isSpam) {
        verdict = DeviceScanVerdict.spam;
        matchReason = smsAnalysis.reasons.isNotEmpty ? smsAnalysis.reasons.first : 'Phishing text detected';
        category = 'sms_phishing';
        confidence = smsAnalysis.confidence;
        spam++;
      } else if (_isMarketingSms(body)) {
        verdict = DeviceScanVerdict.marketing;
        matchReason = 'Promotional marketing discount / sales offer';
        category = 'sms_marketing';
        confidence = 80;
        marketing++;
      } else {
        verdict = DeviceScanVerdict.normal;
        matchReason = 'Clean message content';
        category = 'clean';
        confidence = 0;
        normal++;
      }

      items.add(DeviceScanItem(
        id: 'sms_$i',
        number: normalized,
        displayName: normalized,
        snippet: body,
        timestamp: date,
        scanType: DeviceScanType.sms,
        verdict: verdict,
        confidence: confidence,
        matchReason: matchReason,
        category: category,
      ));
    }

    return DeviceScanSummary(
      totalScanned: items.length,
      spamCount: spam,
      marketingCount: marketing,
      normalCount: normal,
      items: items,
    );
  }

  /// Scans device contacts and verifies trustworthiness
  Future<DeviceScanSummary> scanContacts(CheckerPipeline pipeline, {int limit = 200}) async {
    List<Map<String, dynamic>> rawContacts = [];
    if (!kIsWeb && Platform.isAndroid) {
      rawContacts = await _platform.getDeviceContacts(limit: limit);
    }

    if (rawContacts.isEmpty) {
      rawContacts = _getSampleContacts();
    }

    final items = <DeviceScanItem>[];
    int spam = 0;
    int marketing = 0;
    int normal = 0;

    for (int i = 0; i < rawContacts.length; i++) {
      final c = rawContacts[i];
      final name = (c['name'] ?? '').toString();
      final num = (c['number'] ?? '').toString();
      final normalized = PhoneNormalizer.normalize(num) ?? num;

      final identity = CallerIdentity(
        rawNumber: num,
        normalizedNumber: normalized,
        displayName: name,
        isContact: true,
      );

      final result = await pipeline.run(identity, DateTime.now());

      DeviceScanVerdict verdict;
      String matchReason;
      String category;
      int confidence;

      if (result != null && result.isBlocked) {
        verdict = DeviceScanVerdict.spam;
        matchReason = 'Contact matches known spam/fraud database (${result.description})';
        category = 'compromised_contact';
        confidence = result.confidence;
        spam++;
      } else if (name.toLowerCase().contains('spam') || name.toLowerCase().contains('telemarketer')) {
        verdict = DeviceScanVerdict.marketing;
        matchReason = 'Labeled as marketing in address book';
        category = 'marketing_contact';
        confidence = 85;
        marketing++;
      } else {
        verdict = DeviceScanVerdict.normal;
        matchReason = 'Trusted address book contact';
        category = 'trusted_contact';
        confidence = 0;
        normal++;
      }

      items.add(DeviceScanItem(
        id: 'contact_$i',
        number: normalized,
        displayName: name.isNotEmpty ? name : normalized,
        snippet: 'Contact Phone: $normalized',
        timestamp: DateTime.now(),
        scanType: DeviceScanType.contact,
        verdict: verdict,
        confidence: confidence,
        matchReason: matchReason,
        category: category,
      ));
    }

    return DeviceScanSummary(
      totalScanned: items.length,
      spamCount: spam,
      marketingCount: marketing,
      normalCount: normal,
      items: items,
    );
  }

  /// Sends discovered spam items to the backend server
  Future<int> sendReportsToServer(List<DeviceScanItem> items) async {
    final spamItems = items.where((e) => e.isSpam && !e.isReported).toList();
    if (spamItems.isEmpty) return 0;

    int reported = 0;
    for (final item in spamItems) {
      final ok = await _apiClient.submitSpamReport(
        number: item.number,
        type: item.category.isNotEmpty ? item.category : 'spam',
      );
      if (ok) {
        item.isReported = true;
        reported++;
      }
    }
    return reported;
  }

  bool _isMarketingNumber(String normalized, String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('marketing') || lowerName.contains('promo') || lowerName.contains('sales')) {
      return true;
    }
    if (normalized.startsWith('+1800') ||
        normalized.startsWith('+1888') ||
        normalized.startsWith('+1877') ||
        normalized.startsWith('+1866') ||
        normalized.startsWith('+1855')) {
      return true;
    }
    return false;
  }

  bool _isMarketingSms(String body) {
    final lower = body.toLowerCase();
    const keywords = [
      'discount',
      'promo',
      'coupon',
      'sale',
      'limited offer',
      'exclusive deal',
      'shop now',
      'free trial',
      'unsubscribe',
      'reply stop',
    ];
    return keywords.any((k) => lower.contains(k));
  }

  // ── Sample Demonstration Data for Non-Android Platforms & Emulators ──

  List<Map<String, dynamic>> _getSampleCallLog() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      {'number': '+18095551234', 'name': '', 'type': 3, 'date': now - 1800000, 'duration': 2},
      {'number': '+18005559876', 'name': 'Direct Sales Promo', 'type': 1, 'date': now - 7200000, 'duration': 45},
      {'number': '+12125550199', 'name': '', 'type': 1, 'date': now - 14400000, 'duration': 0},
      {'number': '+14155552671', 'name': 'Alice Smith', 'type': 2, 'date': now - 28800000, 'duration': 180},
      {'number': '+12025550143', 'name': '', 'type': 3, 'date': now - 43200000, 'duration': 5},
      {'number': '+12127365000', 'name': 'Bob Miller (Work)', 'type': 1, 'date': now - 86400000, 'duration': 320},
    ];
  }

  List<Map<String, dynamic>> _getSampleSmsInbox() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      {
        'address': '+18095558888',
        'body': 'URGENT: Your bank account is locked due to suspicious activity. Verify now at http://fake-login-sec.com',
        'date': now - 1200000,
      },
      {
        'address': '+18005553333',
        'body': 'Flash Weekend Sale! Get 40% OFF all footwear using code SPRING40 at checkout. Reply STOP to opt-out.',
        'date': now - 5400000,
      },
      {
        'address': '+14155552671',
        'body': 'Hey, are we still meeting for lunch at 1 PM today?',
        'date': now - 18000000,
      },
      {
        'address': '22000',
        'body': 'Your CallShield verification code is: 849201. Do not share this code with anyone.',
        'date': now - 36000000,
      },
      {
        'address': '+13475559123',
        'body': 'Congratulations! You won a \$1,000 crypto giveaway reward. Claim your payout here: http://bit.ly/crypto-scam',
        'date': now - 72000000,
      },
    ];
  }

  List<Map<String, dynamic>> _getSampleContacts() {
    return [
      {'name': 'Alice Smith', 'number': '+14155552671'},
      {'name': 'Bob Miller (Work)', 'number': '+12127365000'},
      {'name': 'Home Office', 'number': '+12125559000'},
      {'name': 'Spam Robocalls Filtered', 'number': '+18095551234'},
    ];
  }
}
