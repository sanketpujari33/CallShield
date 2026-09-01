import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../data/checker/checker_pipeline.dart';
import '../../data/checker/checkers.dart';
import '../../data/local/database_helper.dart';
import '../../data/remote/callshield_api_client.dart';
import '../../domain/models/block_reason_code.dart';
import '../../domain/models/caller_identity.dart';
import '../../domain/models/rule_models.dart';
import '../../domain/models/spam_check_result.dart';

enum QuickProfile {
  work('Work'),
  personal('Personal'),
  sleep('Sleep'),
  maximum('Maximum'),
  off('Off');

  final String label;
  const QuickProfile(this.label);
}

class ProtectionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isProtectionActive = true;
  bool _isCallBlockingEnabled = true;
  bool _isSmsScreeningEnabled = true;
  bool _contactsOnly = false;
  QuickProfile _activeProfile = QuickProfile.personal;

  int _weeklyCallsBlocked = 0;
  int _weeklyTextsBlocked = 0;
  int _spamDatabaseCount = 0;
  String _lastSyncTime = 'Bundled snapshot ready';
  bool _isSyncing = false;

  late CheckerPipeline _pipeline;

  bool get isProtectionActive => _isProtectionActive;
  bool get isCallBlockingEnabled => _isCallBlockingEnabled;
  bool get isSmsScreeningEnabled => _isSmsScreeningEnabled;
  bool get contactsOnly => _contactsOnly;
  QuickProfile get activeProfile => _activeProfile;
  int get weeklyCallsBlocked => _weeklyCallsBlocked;
  int get weeklyTextsBlocked => _weeklyTextsBlocked;
  int get spamDatabaseCount => _spamDatabaseCount;
  String get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  CheckerPipeline get pipeline => _pipeline;

  ProtectionProvider() {
    _init();
  }

  Future<void> _init() async {
    _pipeline = CheckerPipeline([
      ManualWhitelistChecker(_db),
      ContactWhitelistChecker(),
      ContactsOnlyChecker(enabled: _contactsOnly),
      StirShakenFailedChecker(),
      UserBlocklistChecker(_db),
      WildcardRuleChecker(_db),
      RangePatternChecker(_db),
      PrefixRuleChecker(),
      StirShakenAuthenticatedChecker(),
      SpamDatabaseChecker(_db),
      HeuristicChecker(),
      MLSpamScorerChecker(),
      SmsKeywordChecker(_db),
      SmsContentChecker(),
    ]);

    await refreshStats();
  }

  Future<void> refreshStats() async {
    _weeklyCallsBlocked = await _db.getWeeklyBlockedCount();
    _weeklyTextsBlocked = await _db.getWeeklyTextBlockedCount();
    _spamDatabaseCount = await _db.getSpamNumberCount();
    notifyListeners();
  }

  Future<bool> syncDatabase() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = CallShieldApiClient();
      final hotNumbers = await client.fetchHotNumbers();
      if (hotNumbers != null && hotNumbers['numbers'] is List) {
        final list = (hotNumbers['numbers'] as List).cast<String>();
        final nowStr = DateTime.now().toIso8601String();
        final rows = list.map((phone) => {
          'number': phone,
          'type': 'robocall',
          'reports': 5,
          'description': 'High-velocity robocall campaign',
          'first_seen': nowStr,
          'last_seen': nowStr,
          'sources': 'hot_list_sync',
        }).toList();
        await _db.batchInsertSpamNumbers(rows);
      }
      _lastSyncTime = DateFormat.jm().format(DateTime.now());
      await refreshStats();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  void toggleProtection(bool value) {
    _isProtectionActive = value;
    _isCallBlockingEnabled = value;
    _isSmsScreeningEnabled = value;
    if (!value) _activeProfile = QuickProfile.off;
    notifyListeners();
  }

  void toggleCallBlocking(bool value) {
    _isCallBlockingEnabled = value;
    _isProtectionActive = _isCallBlockingEnabled || _isSmsScreeningEnabled;
    notifyListeners();
  }

  void toggleSmsScreening(bool value) {
    _isSmsScreeningEnabled = value;
    _isProtectionActive = _isCallBlockingEnabled || _isSmsScreeningEnabled;
    notifyListeners();
  }

  void setContactsOnly(bool value) {
    _contactsOnly = value;
    for (final c in _pipeline.checkers) {
      if (c is ContactsOnlyChecker) {
        c.enabled = value;
      }
    }
    notifyListeners();
  }

  void setProfile(QuickProfile profile) {
    _activeProfile = profile;
    switch (profile) {
      case QuickProfile.work:
        _isProtectionActive = true;
        _isCallBlockingEnabled = true;
        _isSmsScreeningEnabled = true;
        _contactsOnly = false;
        break;
      case QuickProfile.personal:
        _isProtectionActive = true;
        _isCallBlockingEnabled = true;
        _isSmsScreeningEnabled = true;
        _contactsOnly = false;
        break;
      case QuickProfile.sleep:
        _isProtectionActive = true;
        _isCallBlockingEnabled = true;
        _isSmsScreeningEnabled = true;
        _contactsOnly = true;
        break;
      case QuickProfile.maximum:
        _isProtectionActive = true;
        _isCallBlockingEnabled = true;
        _isSmsScreeningEnabled = true;
        _contactsOnly = true;
        break;
      case QuickProfile.off:
        _isProtectionActive = false;
        _isCallBlockingEnabled = false;
        _isSmsScreeningEnabled = false;
        break;
    }
    notifyListeners();
  }

  Future<SpamCheckResult> evaluateIncomingCall({
    required String rawNumber,
    String callerName = '',
    bool isContact = false,
    VerificationStatus verificationStatus = VerificationStatus.notVerified,
    AttestationLevel attestationLevel = AttestationLevel.none,
  }) async {
    final normalized = PhoneNormalizer.normalize(rawNumber) ?? rawNumber;
    final identity = CallerIdentity(
      rawNumber: rawNumber,
      normalizedNumber: normalized,
      displayName: callerName,
      isContact: isContact,
      verificationStatus: verificationStatus,
      attestationLevel: attestationLevel,
    );

    final result = await _pipeline.run(identity, DateTime.now());
    final outcome = result ??
        SpamCheckResult.allowed(
          reasonCode: BlockReasonCode.unknown,
          matchSource: 'clean',
          description: 'Clean number, no spam patterns detected',
        );

    // Save to call logs
    final log = CallLogRecord(
      number: normalized,
      callerName: callerName,
      isBlocked: outcome.isBlocked,
      reasonCode: outcome.reasonCode,
      matchSource: outcome.matchSource,
      description: outcome.description,
      confidence: outcome.confidence,
      score: outcome.score,
      category: outcome.category,
      isSms: false,
    );
    await _db.addCallLog(log);
    await refreshStats();

    return outcome;
  }
}
