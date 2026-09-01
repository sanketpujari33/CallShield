import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/data/identity/caller_identity_service.dart';
import 'package:callshield_app/domain/models/caller_identity_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallerIdentityService & Model Tests', () {
    test('resolves Food Delivery preset with verified status and green theme attributes', () {
      final identity = CallerIdentityService.instance.resolve('+918172033604');
      expect(identity.name, equals('Food Delivery'));
      expect(identity.type, equals(CallerType.verifiedDelivery));
      expect(identity.isVerified, isTrue);
      expect(identity.isSpam, isFalse);
      expect(identity.highlightMessage, contains('Your biryani order is at your office reception.'));
    });

    test('resolves IRS Tax Fraud preset with malicious threat score', () {
      final identity = CallerIdentityService.instance.resolve('+18005550199');
      expect(identity.name, contains('IRS'));
      expect(identity.type, equals(CallerType.scamPhishing));
      expect(identity.isSpam, isTrue);
      expect(identity.spamScore, greaterThanOrEqualTo(90));
      expect(identity.reportCount, greaterThan(1000));
      expect(identity.attestation, equals(StirShakenAttestation.spoofed));
    });

    test('resolves Auto Warranty robocall preset with telemarketing category', () {
      final identity = CallerIdentityService.instance.resolve('+18884440123');
      expect(identity.type, equals(CallerType.telemarketing));
      expect(identity.isSpam, isTrue);
      expect(identity.tags, contains('Telemarketing'));
    });

    test('resolves personal contact when contactName is supplied', () {
      final identity = CallerIdentityService.instance.resolve('+14155559988', contactName: 'John Doe');
      expect(identity.name, equals('John Doe'));
      expect(identity.type, equals(CallerType.personalContact));
      expect(identity.isVerified, isTrue);
      expect(identity.spamScore, equals(0));
    });

    test('resolves unlisted number with Area Code geolocation and ML evaluation', () {
      final identity = CallerIdentityService.instance.resolve('+12127778899');
      expect(identity.location, contains('New York'));
      expect(identity.formattedNumber, contains('212'));
    });
  });
}
