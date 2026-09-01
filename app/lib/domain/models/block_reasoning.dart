import 'block_reason_code.dart';

class ReasoningExplanation {
  final String headline;
  final List<String> bullets;

  const ReasoningExplanation({
    required this.headline,
    required this.bullets,
  });
}

class BlockReasoning {
  static ReasoningExplanation explain({
    required BlockReasonCode reasonCode,
    String description = '',
    int confidence = 100,
    String matchSource = '',
  }) {
    final bullets = <String>[];
    String headline;

    switch (reasonCode) {
      case BlockReasonCode.userBlocklist:
        headline = 'You personally blocked this number.';
        bullets.add('Matched your custom blocklist rule.');
        if (description.isNotEmpty) bullets.add('Note: "$description"');
        break;

      case BlockReasonCode.temporaryBlock:
        headline = 'Temporarily blocked.';
        bullets.add('Matched an active temporary block rule.');
        break;

      case BlockReasonCode.database:
        headline = 'This number is in CallShield\'s spam database.';
        bullets.add('Matched confirmed community spam record.');
        if (description.isNotEmpty) bullets.add('Reported type: $description');
        break;

      case BlockReasonCode.dbPrefixExpansion:
        headline = 'Matches a known spam database prefix.';
        bullets.add('Shares the first 8–9 digits with confirmed spam campaign numbers.');
        break;

      case BlockReasonCode.prefixRule:
        headline = 'Blocked by international / premium rate prefix rules.';
        bullets.add('Originates from a known Wangiri callback scam or premium rate range.');
        break;

      case BlockReasonCode.wildcard:
        headline = 'Matched your custom pattern / wildcard rule.';
        bullets.add('Matched pattern: $matchSource');
        if (description.isNotEmpty) bullets.add('Rule note: $description');
        break;

      case BlockReasonCode.rangePattern:
        headline = 'Matched a length-locked range pattern.';
        bullets.add('Pattern: $matchSource');
        break;

      case BlockReasonCode.temporaryAllow:
        headline = 'Temporarily allowed by you.';
        bullets.add('You marked this number as temporarily safe.');
        break;

      case BlockReasonCode.manualWhitelist:
        headline = 'You whitelisted this number.';
        bullets.add('Explicitly allowed in your whitelist.');
        break;

      case BlockReasonCode.contactWhitelist:
        headline = 'This number is in your contacts.';
        bullets.add('Always allowed through.');
        break;

      case BlockReasonCode.contactsOnly:
        headline = 'Blocked by Contacts-Only strict mode.';
        bullets.add('Number is not present in your address book.');
        break;

      case BlockReasonCode.stirShakenFailed:
        headline = 'Carrier identity verification failed (STIR/SHAKEN).';
        bullets.add('The caller ID was flagged as spoofed or invalid by telecom carriers.');
        break;

      case BlockReasonCode.stirShakenAuthenticated:
        headline = 'Carrier identity authenticated (STIR/SHAKEN A-level).';
        bullets.add('Originating carrier verified the legitimate owner of this number.');
        break;

      case BlockReasonCode.recentlyDialed:
        headline = 'You recently called this number.';
        bullets.add('Allowed because of outbound communication within the last 24 hours.');
        break;

      case BlockReasonCode.emergencyCallback:
        headline = 'Emergency callback grace window active.';
        bullets.add('Allowed following a recent outgoing emergency call.');
        break;

      case BlockReasonCode.answeredCaller:
        headline = 'You frequently answer calls from this number.';
        bullets.add('Trusted based on repeated answered incoming call history.');
        break;

      case BlockReasonCode.repeatedUrgent:
        headline = 'Repeated urgent caller allowed.';
        bullets.add('Called twice in under 5 minutes to bypass filters for urgency.');
        break;

      case BlockReasonCode.quietHours:
        headline = 'Blocked during Quiet Hours.';
        bullets.add('Non-contact call blocked according to your scheduled quiet window.');
        break;

      case BlockReasonCode.heuristic:
        headline = 'Flagged by on-device heuristic pattern analysis.';
        bullets.add('Confidence: $confidence%');
        if (description.isNotEmpty) bullets.add('Signals: $description');
        break;

      case BlockReasonCode.mlScorer:
        headline = 'Flagged by on-device Machine Learning model.';
        bullets.add('Gradient-Boosted Tree evaluated 20 behavioral & number features.');
        bullets.add('ML Confidence: $confidence%');
        break;

      case BlockReasonCode.campaignBurst:
        headline = 'Coordinated NPA-NXX spam campaign burst detected.';
        bullets.add('High concentration of rapid calls from same exchange within 1 hour.');
        break;

      case BlockReasonCode.smsKeyword:
        headline = 'Blocked by SMS keyword rule.';
        bullets.add('Message contained blocked keyword: $matchSource');
        break;

      case BlockReasonCode.smsContent:
        headline = 'Flagged by SMS phishing & content analysis.';
        bullets.add('Detected suspicious URLs, shorteners, or phishing keywords.');
        break;

      default:
        headline = 'Call evaluated by CallShield.';
        bullets.add('Detection layer: ${reasonCode.displayName}');
    }

    return ReasoningExplanation(headline: headline, bullets: bullets);
  }
}
