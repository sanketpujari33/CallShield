import 'block_reason_code.dart';
import 'call_category.dart';

class TimeSchedule {
  /// Bitmask for days of the week: 1=Mon, 2=Tue, 4=Wed, 8=Thu, 16=Fri, 32=Sat, 64=Sun.
  /// 0 means no day gating (active every day).
  final int daysMask;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeSchedule({
    this.daysMask = 0,
    this.startHour = 0,
    this.startMinute = 0,
    this.endHour = 23,
    this.endMinute = 59,
  });

  bool isActiveAt(DateTime dt) {
    if (daysMask != 0) {
      final dayBit = 1 << (dt.weekday - 1);
      if ((daysMask & dayBit) == 0) return false;
    }

    final currentMinutes = dt.hour * 60 + dt.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight wrap (e.g. 22:00 to 07:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  Map<String, dynamic> toMap() => {
    'days_mask': daysMask,
    'start_hour': startHour,
    'start_minute': startMinute,
    'end_hour': endHour,
    'end_minute': endMinute,
  };

  factory TimeSchedule.fromMap(Map<String, dynamic> map) => TimeSchedule(
    daysMask: map['days_mask'] as int? ?? 0,
    startHour: map['start_hour'] as int? ?? 0,
    startMinute: map['start_minute'] as int? ?? 0,
    endHour: map['end_hour'] as int? ?? 23,
    endMinute: map['end_minute'] as int? ?? 59,
  );
}

class BlocklistEntry {
  final int? id;
  final String number;
  final String note;
  final DateTime createdAt;
  final DateTime? expiresAt;

  BlocklistEntry({
    this.id,
    required this.number,
    this.note = '',
    DateTime? createdAt,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isTemporary => expiresAt != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'number': number,
    'note': note,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
  };

  factory BlocklistEntry.fromMap(Map<String, dynamic> map) => BlocklistEntry(
    id: map['id'] as int?,
    number: map['number'] as String,
    note: map['note'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at'] as String) : null,
  );
}

class WhitelistEntry {
  final int? id;
  final String number;
  final String note;
  final DateTime createdAt;

  WhitelistEntry({
    this.id,
    required this.number,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'number': number,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory WhitelistEntry.fromMap(Map<String, dynamic> map) => WhitelistEntry(
    id: map['id'] as int?,
    number: map['number'] as String,
    note: map['note'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

class WildcardRule {
  final int? id;
  final String pattern;
  final bool isRegex;
  final String note;
  final TimeSchedule schedule;
  final bool enabled;

  WildcardRule({
    this.id,
    required this.pattern,
    this.isRegex = false,
    this.note = '',
    this.schedule = const TimeSchedule(),
    this.enabled = true,
  });

  bool matches(String number, DateTime at) {
    if (!enabled) return false;
    if (!schedule.isActiveAt(at)) return false;

    if (isRegex) {
      try {
        return RegExp(pattern).hasMatch(number);
      } catch (_) {
        return false;
      }
    } else {
      // Glob pattern e.g. +1800*
      final regexPattern = '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$';
      return RegExp(regexPattern).hasMatch(number);
    }
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'pattern': pattern,
    'is_regex': isRegex ? 1 : 0,
    'note': note,
    'enabled': enabled ? 1 : 0,
    ...schedule.toMap(),
  };

  factory WildcardRule.fromMap(Map<String, dynamic> map) => WildcardRule(
    id: map['id'] as int?,
    pattern: map['pattern'] as String,
    isRegex: (map['is_regex'] as int? ?? 0) == 1,
    note: map['note'] as String? ?? '',
    enabled: (map['enabled'] as int? ?? 1) == 1,
    schedule: TimeSchedule.fromMap(map),
  );
}

class RangePattern {
  final int? id;
  final String pattern; // e.g. +33162######
  final String note;
  final TimeSchedule schedule;
  final bool enabled;

  RangePattern({
    this.id,
    required this.pattern,
    this.note = '',
    this.schedule = const TimeSchedule(),
    this.enabled = true,
  });

  bool matches(String number, DateTime at) {
    if (!enabled) return false;
    if (!schedule.isActiveAt(at)) return false;
    if (number.length != pattern.length) return false;

    for (int i = 0; i < pattern.length; i++) {
      final p = pattern[i];
      if (p == '#') {
        final code = number.codeUnitAt(i);
        if (code < 0x30 || code > 0x39) return false;
      } else if (p != number[i]) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'pattern': pattern,
    'note': note,
    'enabled': enabled ? 1 : 0,
    ...schedule.toMap(),
  };

  factory RangePattern.fromMap(Map<String, dynamic> map) => RangePattern(
    id: map['id'] as int?,
    pattern: map['pattern'] as String,
    note: map['note'] as String? ?? '',
    enabled: (map['enabled'] as int? ?? 1) == 1,
    schedule: TimeSchedule.fromMap(map),
  );
}

class SmsKeywordRule {
  final int? id;
  final String keyword;
  final bool caseSensitive;
  final String note;
  final TimeSchedule schedule;
  final bool enabled;

  SmsKeywordRule({
    this.id,
    required this.keyword,
    this.caseSensitive = false,
    this.note = '',
    this.schedule = const TimeSchedule(),
    this.enabled = true,
  });

  bool matches(String body, DateTime at) {
    if (!enabled || keyword.trim().isEmpty) return false;
    if (!schedule.isActiveAt(at)) return false;

    if (caseSensitive) {
      return body.contains(keyword);
    } else {
      return body.toLowerCase().contains(keyword.toLowerCase());
    }
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'keyword': keyword,
    'case_sensitive': caseSensitive ? 1 : 0,
    'note': note,
    'enabled': enabled ? 1 : 0,
    ...schedule.toMap(),
  };

  factory SmsKeywordRule.fromMap(Map<String, dynamic> map) => SmsKeywordRule(
    id: map['id'] as int?,
    keyword: map['keyword'] as String,
    caseSensitive: (map['case_sensitive'] as int? ?? 0) == 1,
    note: map['note'] as String? ?? '',
    enabled: (map['enabled'] as int? ?? 1) == 1,
    schedule: TimeSchedule.fromMap(map),
  );
}

class CallLogRecord {
  final int? id;
  final String number;
  final String callerName;
  final DateTime timestamp;
  final bool isBlocked;
  final BlockReasonCode reasonCode;
  final String matchSource;
  final String description;
  final int confidence;
  final double score;
  final CallCategory category;
  final bool isSms;

  CallLogRecord({
    this.id,
    required this.number,
    this.callerName = '',
    DateTime? timestamp,
    required this.isBlocked,
    required this.reasonCode,
    required this.matchSource,
    this.description = '',
    this.confidence = 100,
    this.score = 0.0,
    this.category = CallCategory.unknown,
    this.isSms = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'number': number,
    'caller_name': callerName,
    'timestamp': timestamp.toIso8601String(),
    'is_blocked': isBlocked ? 1 : 0,
    'reason_code': reasonCode.key,
    'match_source': matchSource,
    'description': description,
    'confidence': confidence,
    'score': score,
    'category': category.key,
    'is_sms': isSms ? 1 : 0,
  };

  factory CallLogRecord.fromMap(Map<String, dynamic> map) => CallLogRecord(
    id: map['id'] as int?,
    number: map['number'] as String,
    callerName: map['caller_name'] as String? ?? '',
    timestamp: DateTime.parse(map['timestamp'] as String),
    isBlocked: (map['is_blocked'] as int) == 1,
    reasonCode: BlockReasonCode.fromKey(map['reason_code'] as String?),
    matchSource: map['match_source'] as String? ?? '',
    description: map['description'] as String? ?? '',
    confidence: map['confidence'] as int? ?? 100,
    score: (map['score'] as num?)?.toDouble() ?? 0.0,
    category: CallCategory.fromKey(map['category'] as String?),
    isSms: (map['is_sms'] as int? ?? 0) == 1,
  );
}
