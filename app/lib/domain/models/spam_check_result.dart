import 'block_reason_code.dart';
import 'call_category.dart';

enum DetectionVerdict {
  allow,
  block,
  silence,
  voicemail,
}

class SpamCheckResult {
  final DetectionVerdict verdict;
  final BlockReasonCode reasonCode;
  final String matchSource;
  final String description;
  final int confidence; // 0..100
  final double score; // 0.0..1.0
  final CallCategory category;
  final int priority;

  const SpamCheckResult({
    required this.verdict,
    required this.reasonCode,
    required this.matchSource,
    this.description = '',
    this.confidence = 100,
    this.score = 1.0,
    this.category = CallCategory.unknown,
    this.priority = 0,
  });

  bool get isBlocked => verdict == DetectionVerdict.block;
  bool get isAllowed => verdict == DetectionVerdict.allow;

  static SpamCheckResult allowed({
    required BlockReasonCode reasonCode,
    required String matchSource,
    String description = '',
    int priority = 0,
  }) {
    return SpamCheckResult(
      verdict: DetectionVerdict.allow,
      reasonCode: reasonCode,
      matchSource: matchSource,
      description: description,
      confidence: 100,
      score: 0.0,
      priority: priority,
    );
  }

  static SpamCheckResult blocked({
    required BlockReasonCode reasonCode,
    required String matchSource,
    String description = '',
    int confidence = 100,
    double score = 1.0,
    CallCategory category = CallCategory.unknown,
    int priority = 0,
  }) {
    return SpamCheckResult(
      verdict: DetectionVerdict.block,
      reasonCode: reasonCode,
      matchSource: matchSource,
      description: description,
      confidence: confidence,
      score: score,
      category: category,
      priority: priority,
    );
  }
}
