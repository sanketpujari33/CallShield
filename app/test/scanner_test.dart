import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/data/checker/checker_pipeline.dart';
import 'package:callshield_app/data/checker/checkers.dart';
import 'package:callshield_app/data/local/database_helper.dart';
import 'package:callshield_app/data/scanner/device_scanner_service.dart';
import 'package:callshield_app/domain/models/device_scan_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckerPipeline pipeline;
  late DeviceScannerService scannerService;

  setUp(() {
    final db = DatabaseHelper.instance;
    pipeline = CheckerPipeline([
      ManualWhitelistChecker(db),
      ContactWhitelistChecker(),
      WildcardRuleChecker(db),
      SpamDatabaseChecker(db),
      HeuristicChecker(),
      MLSpamScorerChecker(),
      SmsKeywordChecker(db),
      SmsContentChecker(),
    ]);
    scannerService = DeviceScannerService();
  });

  group('DeviceScannerService Tests', () {
    test('scans call history and accurately categorizes spam, marketing, and normal', () async {
      final summary = await scannerService.scanCalls(pipeline);
      expect(summary.totalScanned, greaterThan(0));
      expect(summary.items.isNotEmpty, isTrue);

      // Verify presence of all three classification tiers
      expect(summary.items.any((i) => i.verdict == DeviceScanVerdict.spam), isTrue);
      expect(summary.items.any((i) => i.verdict == DeviceScanVerdict.marketing), isTrue);
      expect(summary.items.any((i) => i.verdict == DeviceScanVerdict.normal), isTrue);
    });

    test('scans SMS inbox and flags phishing scams and marketing promos', () async {
      final summary = await scannerService.scanSms(pipeline);
      expect(summary.totalScanned, greaterThan(0));
      expect(summary.spamCount, greaterThan(0));
      expect(summary.marketingCount, greaterThan(0));

      final phishingItem = summary.items.firstWhere((i) => i.isSpam);
      expect(phishingItem.scanType, equals(DeviceScanType.sms));
      expect(phishingItem.confidence, greaterThanOrEqualTo(60));

      final promoItem = summary.items.firstWhere((i) => i.isMarketing);
      expect(promoItem.verdict, equals(DeviceScanVerdict.marketing));
    });

    test('scans contacts and validates trusted entries', () async {
      final summary = await scannerService.scanContacts(pipeline);
      expect(summary.totalScanned, greaterThan(0));
      expect(summary.normalCount, greaterThan(0));

      final normalContact = summary.items.firstWhere((i) => i.isNormal);
      expect(normalContact.scanType, equals(DeviceScanType.contact));
      expect(normalContact.matchReason, contains('Trusted address book contact'));
    });
  });
}
