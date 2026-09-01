import '../../core/utils/ascii_utils.dart';

class HeuristicEvaluation {
  final bool isSpam;
  final int confidence;
  final List<String> reasons;

  const HeuristicEvaluation({
    required this.isSpam,
    required this.confidence,
    required this.reasons,
  });
}

class SpamHeuristics {
  static final SpamHeuristics instance = SpamHeuristics();

  static const Set<String> tollFreePrefixes = {'800', '888', '877', '866', '855', '844', '833'};

  static const Set<String> caribbeanWangiriNpas = {
    '284', '649', '767', '809', '829', '849', '876', '268',
    '473', '664', '721', '758', '784', '868', '869',
  };

  static const Set<String> internationalWangiriCountryCodes = {
    '232', '252', '222', '263', '248', '241', '247', '290', '688', '677',
  };

  static const Set<String> highSpamVoipNpanxx = {
    '202555', '213226', '213555', '310555', '310400',
    '323555', '347555', '404555', '404430', '415555',
    '503555', '512555', '617555', '646555', '702555',
    '713555', '718555', '786555', '813555', '832555',
    '917555', '929555', '206455', '312454', '415523',
    '617286', '646397', '713291', '720420', '720660',
  };

  bool isNeighborSpoof(String incomingNumber, String? userNumber) {
    if (userNumber == null || userNumber.isEmpty) return false;
    final userDigits = AsciiUtils.filterAsciiDigitsLast(userNumber, 10);
    final inDigits = AsciiUtils.filterAsciiDigitsLast(incomingNumber, 10);

    if (userDigits.length < 10 || inDigits.length < 10) return false;
    if (userDigits == inDigits) return false;

    // Same area code (3 digits) + exchange (3 digits)
    return userDigits.substring(0, 6) == inDigits.substring(0, 6);
  }

  bool isTollFree(String number) {
    final digits = AsciiUtils.filterAsciiDigitsLast(number, 10);
    if (digits.length < 10) return false;
    return tollFreePrefixes.contains(digits.substring(0, 3));
  }

  bool isCaribbeanWangiri(String number) {
    if (!number.startsWith('+1') && !number.startsWith('1')) return false;
    final digits = AsciiUtils.filterAsciiDigitsLast(number, 10);
    if (digits.length < 10) return false;
    return caribbeanWangiriNpas.contains(digits.substring(0, 3));
  }

  bool isInternationalWangiri(String number) {
    if (!number.startsWith('+') || number.startsWith('+1')) return false;
    final digits = AsciiUtils.filterAsciiDigits(number);
    for (int len = 3; len >= 2; len--) {
      if (digits.length >= len) {
        final cc = digits.substring(0, len);
        if (internationalWangiriCountryCodes.contains(cc)) return true;
      }
    }
    return false;
  }

  bool isVoipSpamRange(String number) {
    final digits = AsciiUtils.filterAsciiDigitsLast(number, 10);
    if (digits.length < 10) return false;
    return highSpamVoipNpanxx.contains(digits.substring(0, 6));
  }

  HeuristicEvaluation evaluate(String number, {String? userNumber}) {
    final reasons = <String>[];
    int score = 0;

    if (isNeighborSpoof(number, userNumber)) {
      reasons.add('neighbor_spoof');
      score += 45;
    }

    if (isVoipSpamRange(number)) {
      reasons.add('voip_spam_range');
      score += 40;
    }

    if (isCaribbeanWangiri(number)) {
      reasons.add('caribbean_wangiri');
      score += 55;
    }

    if (isInternationalWangiri(number)) {
      reasons.add('international_wangiri');
      score += 60;
    }

    final digits = AsciiUtils.filterAsciiDigitsLast(number, 10);
    if (digits.length == 10) {
      final nxx = digits.substring(3, 6);
      if (nxx == '555') {
        reasons.add('nxx_555');
        score += 35;
      }
      if (nxx.startsWith('0') || nxx.startsWith('1')) {
        reasons.add('invalid_exchange');
        score += 50;
      }
      final sub = digits.substring(6, 10);
      if (sub == '0000') {
        reasons.add('last4_zero');
        score += 25;
      }
      if (sub.runes.toSet().length == 1) {
        reasons.add('subscriber_all_same');
        score += 30;
      }
    }

    final isSpam = score >= 50;
    final confidence = score.clamp(0, 100);

    return HeuristicEvaluation(
      isSpam: isSpam,
      confidence: confidence,
      reasons: reasons,
    );
  }
}
