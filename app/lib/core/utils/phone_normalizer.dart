import 'ascii_utils.dart';

class PhoneNormalizer {
  static const Set<int> formatControlCodes = {
    0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0xFEFF
  };

  static const Set<String> oneDigitCountryCodes = {'1', '7'};
  static const Set<String> twoDigitCountryCodes = {
    '20', '27',
    '30', '31', '32', '33', '34', '36', '39',
    '40', '41', '43', '44', '45', '46', '47', '48', '49',
    '51', '52', '53', '54', '55', '56', '57', '58',
    '60', '61', '62', '63', '64', '65', '66',
    '81', '82', '84', '86',
    '90', '91', '92', '93', '94', '95', '98',
  };

  static const Set<String> trunkZeroSignificantCountryCodes = {'39', '225'};

  static List<String>? splitCountryCode(String digits) {
    if (digits.isEmpty) return null;
    if (oneDigitCountryCodes.contains(digits.substring(0, 1))) {
      return [digits.substring(0, 1), digits.substring(1)];
    }
    if (digits.length >= 2 && twoDigitCountryCodes.contains(digits.substring(0, 2))) {
      return [digits.substring(0, 2), digits.substring(2)];
    }
    if (digits.length >= 3) {
      return [digits.substring(0, 3), digits.substring(3)];
    }
    return null;
  }

  static String stripNationalTrunkPrefix(String digits) {
    final split = splitCountryCode(digits);
    if (split == null) return digits;
    final countryCode = split[0];
    final national = split[1];
    if (trunkZeroSignificantCountryCodes.contains(countryCode)) return digits;
    final stripped = national.replaceFirst(RegExp(r'^0+'), '');
    if (stripped.isEmpty) return digits;
    return countryCode + stripped;
  }

  static String? normalize(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);
      if (!formatControlCodes.contains(code)) {
        buffer.writeCharCode(code);
      }
    }
    final cleaned = buffer.toString().trim();
    final explicitInternational = cleaned.startsWith('+');

    var digits = AsciiUtils.filterAsciiDigits(cleaned);
    if (digits.length < 7 || digits.length > 15) return null;

    if (!explicitInternational && digits.length == 10) {
      return '+1$digits';
    }
    if (explicitInternational) {
      digits = stripNationalTrunkPrefix(digits);
      if (digits.length < 7 || digits.length > 15) return null;
    }
    return '+$digits';
  }

  static bool isPlausibleNumber(String? e164) {
    if (e164 == null || !e164.startsWith('+')) return false;
    final digits = e164.substring(1);
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return false;
    if (digits.length < 8 || digits.length > 15) return false;
    if (digits[0] == '0') return false;

    if (digits[0] == '1') {
      if (digits.length != 11) return false;
      final npa = digits.substring(1, 4);
      final nxx = digits.substring(4, 7);
      if (npa.codeUnitAt(0) < 0x32 || npa.substring(1) == '11' || npa == '555') {
        return false;
      }
      if (nxx.codeUnitAt(0) < 0x32 || nxx == '555') return false;
    }
    return true;
  }

  static String formatDisplay(String rawNumber) {
    final normalized = normalize(rawNumber) ?? rawNumber;
    if (normalized.startsWith('+1') && normalized.length == 12) {
      final npa = normalized.substring(2, 5);
      final nxx = normalized.substring(5, 8);
      final line = normalized.substring(8, 12);
      return '+1 ($npa) $nxx-$line';
    }
    return normalized;
  }
}
