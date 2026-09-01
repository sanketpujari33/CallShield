import '../../core/constants/app_constants.dart';
import '../../domain/models/block_reason_code.dart';
import '../../domain/models/call_category.dart';
import '../../domain/models/caller_identity.dart';
import '../../domain/models/spam_check_result.dart';
import '../heuristics/spam_heuristics.dart';
import '../local/database_helper.dart';
import '../ml/spam_ml_scorer.dart';
import '../sms/sms_content_analyzer.dart';
import 'i_checker.dart';

class ManualWhitelistChecker extends IChecker {
  final DatabaseHelper db;
  ManualWhitelistChecker(this.db);

  @override
  int get priority => AppConstants.priorityManualWhitelist;
  @override
  String get name => 'Manual Whitelist';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final isWhitelisted = await db.isNumberInWhitelist(identity.normalizedNumber);
    if (isWhitelisted) {
      return SpamCheckResult.allowed(
        reasonCode: BlockReasonCode.manualWhitelist,
        matchSource: 'manual_whitelist',
        description: 'Allowed by personal whitelist',
        priority: priority,
      );
    }
    return null;
  }
}

class ContactWhitelistChecker extends IChecker {
  @override
  int get priority => AppConstants.priorityContactWhitelist;
  @override
  String get name => 'Contact Whitelist';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    if (identity.isContact) {
      return SpamCheckResult.allowed(
        reasonCode: BlockReasonCode.contactWhitelist,
        matchSource: 'contact_whitelist',
        description: 'Caller is in phone contacts',
        priority: priority,
      );
    }
    return null;
  }
}

class ContactsOnlyChecker extends IChecker {
  bool enabled;
  ContactsOnlyChecker({this.enabled = false});

  @override
  int get priority => AppConstants.priorityContactsOnly;
  @override
  String get name => 'Contacts Only Mode';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    if (enabled && !identity.isContact) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.contactsOnly,
        matchSource: 'contacts_only',
        description: 'Non-contact blocked by strict Contacts-Only mode',
        priority: priority,
      );
    }
    return null;
  }
}

class StirShakenFailedChecker extends IChecker {
  @override
  int get priority => AppConstants.priorityStirShakenFailed;
  @override
  String get name => 'STIR/SHAKEN Verification Failed';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    if (identity.verificationStatus == VerificationStatus.failed) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.stirShakenFailed,
        matchSource: 'stir_shaken_failed',
        description: 'Carrier caller ID verification failed (spoofed)',
        confidence: 95,
        priority: priority,
      );
    }
    return null;
  }
}

class UserBlocklistChecker extends IChecker {
  final DatabaseHelper db;
  UserBlocklistChecker(this.db);

  @override
  int get priority => AppConstants.priorityUserBlocklist;
  @override
  String get name => 'User Blocklist';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final isBlocked = await db.isNumberInBlocklist(identity.normalizedNumber);
    if (isBlocked) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.userBlocklist,
        matchSource: 'user_blocklist',
        description: 'Blocked by your personal blocklist',
        confidence: 100,
        priority: priority,
      );
    }
    return null;
  }
}

class WildcardRuleChecker extends IChecker {
  final DatabaseHelper db;
  WildcardRuleChecker(this.db);

  @override
  int get priority => AppConstants.priorityWildcardRule;
  @override
  String get name => 'Wildcard / Regex Rules';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final rules = await db.getWildcardRules();
    for (final rule in rules) {
      if (rule.matches(identity.normalizedNumber, timestamp)) {
        return SpamCheckResult.blocked(
          reasonCode: BlockReasonCode.wildcard,
          matchSource: rule.pattern,
          description: rule.note.isNotEmpty ? rule.note : 'Matched pattern ${rule.pattern}',
          confidence: 100,
          priority: priority,
        );
      }
    }
    return null;
  }
}

class RangePatternChecker extends IChecker {
  final DatabaseHelper db;
  RangePatternChecker(this.db);

  @override
  int get priority => AppConstants.priorityRangePattern;
  @override
  String get name => 'Range Patterns';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final ranges = await db.getRangePatterns();
    for (final r in ranges) {
      if (r.matches(identity.normalizedNumber, timestamp)) {
        return SpamCheckResult.blocked(
          reasonCode: BlockReasonCode.rangePattern,
          matchSource: r.pattern,
          description: r.note.isNotEmpty ? r.note : 'Matched range pattern ${r.pattern}',
          confidence: 100,
          priority: priority,
        );
      }
    }
    return null;
  }
}

class PrefixRuleChecker extends IChecker {
  @override
  int get priority => AppConstants.priorityPrefixRule;
  @override
  String get name => 'Prefix Rules';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final h = SpamHeuristics.instance;
    if (h.isCaribbeanWangiri(identity.normalizedNumber)) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.prefixRule,
        matchSource: 'caribbean_wangiri',
        description: 'Caribbean premium callback scam prefix',
        confidence: 90,
        category: CallCategory.scam,
        priority: priority,
      );
    }
    if (h.isInternationalWangiri(identity.normalizedNumber)) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.prefixRule,
        matchSource: 'international_wangiri',
        description: 'International high-fraud callback destination',
        confidence: 90,
        category: CallCategory.scam,
        priority: priority,
      );
    }
    return null;
  }
}

class StirShakenAuthenticatedChecker extends IChecker {
  @override
  int get priority => AppConstants.priorityStirShakenAuthenticated;
  @override
  String get name => 'STIR/SHAKEN Authenticated';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    if (identity.attestationLevel == AttestationLevel.a) {
      return SpamCheckResult.allowed(
        reasonCode: BlockReasonCode.stirShakenAuthenticated,
        matchSource: 'stir_shaken_authenticated',
        description: 'Verified carrier identity (A-Level attestation)',
        priority: priority,
      );
    }
    return null;
  }
}

class SpamDatabaseChecker extends IChecker {
  final DatabaseHelper db;
  SpamDatabaseChecker(this.db);

  @override
  int get priority => AppConstants.prioritySpamDatabase;
  @override
  String get name => 'Spam Database';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final record = await db.lookupSpamNumber(identity.normalizedNumber);
    if (record != null) {
      final cat = CallCategory.fromKey(record['type'] as String?);
      final desc = record['description'] as String? ?? 'Confirmed community spam record';
      final reports = record['reports'] as int? ?? 1;
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.database,
        matchSource: 'database',
        description: desc,
        confidence: (70 + reports * 5).clamp(70, 99),
        category: cat,
        priority: priority,
      );
    }
    return null;
  }
}

class HeuristicChecker extends IChecker {
  @override
  int get priority => AppConstants.priorityHeuristics;
  @override
  String get name => 'Heuristic Engine';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final eval = SpamHeuristics.instance.evaluate(identity.normalizedNumber);
    if (eval.isSpam) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.heuristic,
        matchSource: 'heuristics',
        description: eval.reasons.join(', '),
        confidence: eval.confidence,
        score: eval.confidence / 100.0,
        category: CallCategory.robocall,
        priority: priority,
      );
    }
    return null;
  }
}

class MLSpamScorerChecker extends IChecker {
  @override
  int get priority => AppConstants.priorityMlSpamScorer;
  @override
  String get name => 'Machine Learning Scorer';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    final scorer = SpamMLScorer.instance;
    final score = scorer.score(identity.normalizedNumber, timestamp.hour);
    if (score >= scorer.threshold) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.mlScorer,
        matchSource: 'ml_scorer',
        description: 'Gradient-Boosted Tree score: ${(score * 100).toStringAsFixed(1)}%',
        confidence: (score * 100).round(),
        score: score,
        category: CallCategory.robocall,
        priority: priority,
      );
    }
    return null;
  }
}

class SmsKeywordChecker extends IChecker {
  final DatabaseHelper db;
  SmsKeywordChecker(this.db);

  @override
  int get priority => AppConstants.priorityWildcardRule;
  @override
  String get name => 'SMS Keyword Rules';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    if (messageBody == null || messageBody.isEmpty) return null;
    final keywords = await db.getSmsKeywords();
    for (final kw in keywords) {
      if (kw.matches(messageBody, timestamp)) {
        return SpamCheckResult.blocked(
          reasonCode: BlockReasonCode.smsKeyword,
          matchSource: kw.keyword,
          description: kw.note.isNotEmpty ? kw.note : 'Blocked by SMS keyword "${kw.keyword}"',
          confidence: 100,
          category: CallCategory.phishing,
          priority: priority,
        );
      }
    }
    return null;
  }
}

class SmsContentChecker extends IChecker {
  @override
  int get priority => AppConstants.prioritySmsContent;
  @override
  String get name => 'SMS Phishing / Content Analysis';

  @override
  Future<SpamCheckResult?> check(CallerIdentity identity, DateTime timestamp, {String? messageBody}) async {
    if (messageBody == null || messageBody.isEmpty) return null;
    final analysis = SmsContentAnalyzer.instance.analyze(messageBody);
    if (analysis.isSpam) {
      return SpamCheckResult.blocked(
        reasonCode: BlockReasonCode.smsContent,
        matchSource: 'sms_content',
        description: analysis.reasons.join(', '),
        confidence: analysis.confidence,
        score: analysis.confidence / 100.0,
        category: CallCategory.phishing,
        priority: priority,
      );
    }
    return null;
  }
}
