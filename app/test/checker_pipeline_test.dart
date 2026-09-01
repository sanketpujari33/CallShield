import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/data/checker/checker_pipeline.dart';
import 'package:callshield_app/data/checker/checkers.dart';
import 'package:callshield_app/domain/models/block_reason_code.dart';
import 'package:callshield_app/domain/models/caller_identity.dart';

void main() {
  group('CheckerPipeline', () {
    test('sorts checkers in descending order of priority', () {
      final pipeline = CheckerPipeline([
        HeuristicChecker(), // 3000
        ContactWhitelistChecker(), // 9000
        MLSpamScorerChecker(), // 2000
        StirShakenFailedChecker(), // 8500
      ]);

      expect(pipeline.checkers[0].priority, equals(9000));
      expect(pipeline.checkers[1].priority, equals(8500));
      expect(pipeline.checkers[2].priority, equals(3000));
      expect(pipeline.checkers[3].priority, equals(2000));
    });

    test('contact whitelist allows through before heuristic checks', () async {
      final pipeline = CheckerPipeline([
        ContactWhitelistChecker(),
        HeuristicChecker(),
        MLSpamScorerChecker(),
      ]);

      // A number that would trigger heuristics (+1800 toll free or neighbor), but is in contacts
      final identity = CallerIdentity(
        rawNumber: '+18005551234',
        normalizedNumber: '+18005551234',
        isContact: true,
      );

      final result = await pipeline.run(identity, DateTime.now());
      expect(result, isNotNull);
      expect(result!.isAllowed, isTrue);
      expect(result.reasonCode, equals(BlockReasonCode.contactWhitelist));
    });

    test('STIR/SHAKEN failed blocks call', () async {
      final pipeline = CheckerPipeline([
        StirShakenFailedChecker(),
        MLSpamScorerChecker(),
      ]);

      final identity = CallerIdentity(
        rawNumber: '+12127365000',
        normalizedNumber: '+12127365000',
        verificationStatus: VerificationStatus.failed,
      );

      final result = await pipeline.run(identity, DateTime.now());
      expect(result, isNotNull);
      expect(result!.isBlocked, isTrue);
      expect(result.reasonCode, equals(BlockReasonCode.stirShakenFailed));
    });

    test('Contacts-Only strict mode blocks non-contacts', () async {
      final pipeline = CheckerPipeline([
        ContactsOnlyChecker(enabled: true),
      ]);

      final identity = CallerIdentity(
        rawNumber: '+12127365000',
        normalizedNumber: '+12127365000',
        isContact: false,
      );

      final result = await pipeline.run(identity, DateTime.now());
      expect(result, isNotNull);
      expect(result!.isBlocked, isTrue);
      expect(result.reasonCode, equals(BlockReasonCode.contactsOnly));
    });
  });
}
