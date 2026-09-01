enum CallCategory {
  robocall('robocall', 'Robocall'),
  scam('scam', 'Scam / Fraud'),
  telemarketer('telemarketer', 'Telemarketing'),
  debtCollector('debt_collector', 'Debt Collector'),
  phishing('phishing', 'Phishing'),
  survey('survey', 'Survey / Research'),
  political('political', 'Political'),
  nonprofit('nonprofit', 'Charity / Nonprofit'),
  aiVoice('ai_voice', 'AI Generated Voice'),
  generalSpam('spam', 'Spam'),
  unknown('unknown', 'Unknown');

  final String key;
  final String displayName;

  const CallCategory(this.key, this.displayName);

  static CallCategory fromKey(String? key) {
    if (key == null) return CallCategory.unknown;
    for (final cat in CallCategory.values) {
      if (cat.key == key) return cat;
    }
    return CallCategory.unknown;
  }
}

enum CallAction {
  inherit('inherit', 'Use Global Policy'),
  ring('ring', 'Allow & Ring'),
  silence('silence', 'Silence Call'),
  voicemail('voicemail', 'Send to Voicemail'),
  block('block', 'Block Call');

  final String key;
  final String label;

  const CallAction(this.key, this.label);

  static CallAction fromKey(String? key) {
    if (key == null) return CallAction.inherit;
    for (final a in CallAction.values) {
      if (a.key == key) return a;
    }
    return CallAction.inherit;
  }
}
