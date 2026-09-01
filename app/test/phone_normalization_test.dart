import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/core/utils/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer', () {
    test('strips national trunk zero for non-exempt countries', () {
      expect(PhoneNormalizer.stripNationalTrunkPrefix('8605586468536'), equals('865586468536'));
      expect(PhoneNormalizer.stripNationalTrunkPrefix('4402079460999'), equals('442079460999'));
    });

    test('preserves trunk zero for Italy (+39) and Cote d\'Ivoire (+225)', () {
      expect(PhoneNormalizer.stripNationalTrunkPrefix('39061234567'), equals('39061234567'));
      expect(PhoneNormalizer.stripNationalTrunkPrefix('2250708091011'), equals('2250708091011'));
    });

    test('normalizes 10-digit US number to +1 E.164', () {
      expect(PhoneNormalizer.normalize('2127365000'), equals('+12127365000'));
      expect(PhoneNormalizer.normalize('(212) 736-5000'), equals('+12127365000'));
    });

    test('normalizes international numbers with leading +', () {
      expect(PhoneNormalizer.normalize('+44 20 7946 0999'), equals('+442079460999'));
      expect(PhoneNormalizer.normalize('+86 0558 646 8536'), equals('+865586468536'));
    });

    test('validates plausible numbers vs fictional/invalid numbers', () {
      expect(PhoneNormalizer.isPlausibleNumber('+12127365000'), isTrue);
      expect(PhoneNormalizer.isPlausibleNumber('+442079460999'), isTrue);

      // Fictional 555 exchange is rejected
      expect(PhoneNormalizer.isPlausibleNumber('+12125551234'), isFalse);

      // Invalid area codes
      expect(PhoneNormalizer.isPlausibleNumber('+10125551234'), isFalse);
      expect(PhoneNormalizer.isPlausibleNumber('+11125551234'), isFalse);
      expect(PhoneNormalizer.isPlausibleNumber('+19115551234'), isFalse);

      // Overlong / too short
      expect(PhoneNormalizer.isPlausibleNumber('+123'), isFalse);
      expect(PhoneNormalizer.isPlausibleNumber('+1234567890123456'), isFalse);
    });

    test('formats display string nicely', () {
      expect(PhoneNormalizer.formatDisplay('+12127365000'), equals('+1 (212) 736-5000'));
    });
  });
}
