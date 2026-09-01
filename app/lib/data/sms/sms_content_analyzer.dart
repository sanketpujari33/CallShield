class SmsAnalysisResult {
  final bool isSpam;
  final int confidence;
  final List<String> reasons;
  final List<String> extractedDomains;

  const SmsAnalysisResult({
    required this.isSpam,
    required this.confidence,
    required this.reasons,
    required this.extractedDomains,
  });
}

class SmsContentAnalyzer {
  static final SmsContentAnalyzer instance = SmsContentAnalyzer();

  static final List<RegExp> phishingPatterns = [
    RegExp(r'\b(urgent|immediate|action required)\b.*(account|suspended|locked|verify)', caseSensitive: false),
    RegExp(r'\b(bank|paypal|chase|wells fargo|citi|apple id)\b.*(verify|unlock|unusual activity)', caseSensitive: false),
    RegExp(r'\b(parcel|package|delivery|usps|fedex|ups|dhl)\b.*(track|claim|fee|reschedule)', caseSensitive: false),
    RegExp(r'\b(tax refund|irs|cra|hmrc)\b.*(claim|rebate|audit|lawsuit)', caseSensitive: false),
    RegExp(r'\b(win|winner|lottery|prize|reward|gift card)\b.*(claim|congratulations)', caseSensitive: false),
    RegExp(r'\b(crypto|bitcoin|eth|investment|payout|guaranteed return)\b', caseSensitive: false),
    RegExp(r'\b(click here|tap here|visit link|login at)\b\s*https?://', caseSensitive: false),
  ];

  static const Set<String> urlShorteners = {
    'bit.ly', 'tinyurl.com', 't.co', 'is.gd', 'cutt.ly', 'ow.ly',
    'goo.gl', 'shorte.st', 'trib.al', 'tiny.cc', 'rb.gy', 'v.gd',
  };

  Set<String> knownSpamDomains = {};

  void setSpamDomains(List<String> domains) {
    knownSpamDomains = domains.map((d) => d.toLowerCase().trim()).toSet();
  }

  List<String> extractDomains(String text) {
    final urlRegex = RegExp(r'https?://([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', caseSensitive: false);
    final matches = urlRegex.allMatches(text);
    final domains = <String>[];

    for (final m in matches) {
      final host = m.group(1)?.toLowerCase();
      if (host != null) {
        domains.add(host);
      }
    }
    return domains;
  }

  SmsAnalysisResult analyze(String messageBody) {
    final reasons = <String>[];
    int score = 0;
    final domains = extractDomains(messageBody);

    for (final pattern in phishingPatterns) {
      if (pattern.hasMatch(messageBody)) {
        reasons.add('phishing_pattern');
        score += 35;
        break;
      }
    }

    for (final domain in domains) {
      if (urlShorteners.contains(domain)) {
        reasons.add('url_shortener:$domain');
        score += 30;
      }
      if (knownSpamDomains.contains(domain)) {
        reasons.add('known_spam_domain:$domain');
        score += 60;
      }
    }

    final isSpam = score >= 50;
    final confidence = score.clamp(0, 100);

    return SmsAnalysisResult(
      isSpam: isSpam,
      confidence: confidence,
      reasons: reasons,
      extractedDomains: domains,
    );
  }
}
