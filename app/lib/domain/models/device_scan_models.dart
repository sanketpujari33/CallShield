enum DeviceScanType {
  call('Calls', '📞'),
  sms('SMS Messages', '💬'),
  contact('Contacts', '👤');

  final String label;
  final String icon;
  const DeviceScanType(this.label, this.icon);
}

enum DeviceScanVerdict {
  spam('Spam / Fraud', '🚨'),
  marketing('Marketing / Promo', '📢'),
  normal('Normal / Clean', '✅');

  final String label;
  final String emoji;
  const DeviceScanVerdict(this.label, this.emoji);
}

class DeviceScanItem {
  final String id;
  final String number;
  final String displayName;
  final String snippet;
  final DateTime timestamp;
  final DeviceScanType scanType;
  final DeviceScanVerdict verdict;
  final int confidence;
  final String matchReason;
  final String category;
  bool isReported;

  DeviceScanItem({
    required this.id,
    required this.number,
    required this.displayName,
    required this.snippet,
    required this.timestamp,
    required this.scanType,
    required this.verdict,
    required this.confidence,
    required this.matchReason,
    required this.category,
    this.isReported = false,
  });

  bool get isSpam => verdict == DeviceScanVerdict.spam;
  bool get isMarketing => verdict == DeviceScanVerdict.marketing;
  bool get isNormal => verdict == DeviceScanVerdict.normal;
}

class DeviceScanSummary {
  final int totalScanned;
  final int spamCount;
  final int marketingCount;
  final int normalCount;
  final List<DeviceScanItem> items;
  final String? error;

  const DeviceScanSummary({
    required this.totalScanned,
    required this.spamCount,
    required this.marketingCount,
    required this.normalCount,
    required this.items,
    this.error,
  });

  static const empty = DeviceScanSummary(
    totalScanned: 0,
    spamCount: 0,
    marketingCount: 0,
    normalCount: 0,
    items: [],
  );
}
