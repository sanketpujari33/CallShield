import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/signal_ledger_theme.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/local/database_helper.dart';
import '../../data/ml/spam_ml_scorer.dart';
import '../../data/remote/callshield_api_client.dart';
import '../../data/sms/sms_content_analyzer.dart';
import '../../domain/models/call_category.dart';
import '../../domain/models/rule_models.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late CallShieldApiClient _apiClient;

  AppThemeMode _themeMode = AppThemeMode.dark;
  String _serverUrl = AppConstants.defaultDesktopApiUrl;

  // Category Call Policies
  final Map<CallCategory, CallAction> _categoryPolicies = {
    CallCategory.robocall: CallAction.block,
    CallCategory.scam: CallAction.block,
    CallCategory.telemarketer: CallAction.silence,
    CallCategory.debtCollector: CallAction.inherit,
    CallCategory.phishing: CallAction.block,
    CallCategory.survey: CallAction.inherit,
    CallCategory.political: CallAction.silence,
    CallCategory.nonprofit: CallAction.inherit,
  };

  // Quiet Hours
  bool _quietHoursEnabled = false;
  int _quietStartHour = 22;
  int _quietStartMinute = 0;
  int _quietEndHour = 7;
  int _quietEndMinute = 0;

  bool _isSyncing = false;
  String _syncStatus = 'Idle';
  String _databaseVersion = '38';
  bool _hasCompletedOnboarding = false;
  bool _isLoaded = true;

  AppThemeMode get themeMode => _themeMode;
  String get serverUrl => _serverUrl;
  Map<CallCategory, CallAction> get categoryPolicies => Map.unmodifiable(_categoryPolicies);
  bool get quietHoursEnabled => _quietHoursEnabled;
  int get quietStartHour => _quietStartHour;
  int get quietStartMinute => _quietStartMinute;
  int get quietEndHour => _quietEndHour;
  int get quietEndMinute => _quietEndMinute;
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  String get databaseVersion => _databaseVersion;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _apiClient = CallShieldApiClient(baseUrl: _serverUrl);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeStr = await _db.getSetting('theme_mode');
    if (themeStr != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => AppThemeMode.dark,
      );
    }
    final url = await _db.getSetting('server_url');
    if (url != null && url.isNotEmpty) {
      _serverUrl = url;
      _apiClient = CallShieldApiClient(baseUrl: _serverUrl);
    }
    final onboardedStr = await _db.getSetting('has_completed_onboarding');
    _hasCompletedOnboarding = onboardedStr == 'true';
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _db.setSetting('has_completed_onboarding', 'true');
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    await _db.setSetting('has_completed_onboarding', 'false');
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _db.setSetting('theme_mode', mode.name);
    notifyListeners();
  }

  void setServerUrl(String url) {
    _serverUrl = url.trim();
    _apiClient = CallShieldApiClient(baseUrl: _serverUrl);
    _db.setSetting('server_url', _serverUrl);
    notifyListeners();
  }

  void setCategoryPolicy(CallCategory category, CallAction action) {
    _categoryPolicies[category] = action;
    notifyListeners();
  }

  void setQuietHours({
    required bool enabled,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    _quietHoursEnabled = enabled;
    _quietStartHour = startHour;
    _quietStartMinute = startMinute;
    _quietEndHour = endHour;
    _quietEndMinute = endMinute;
    notifyListeners();
  }

  // Database Sync with Node.js Server
  Future<bool> syncDatabase() async {
    _isSyncing = true;
    _syncStatus = 'Checking manifest...';
    notifyListeners();

    try {
      final manifest = await _apiClient.fetchManifest();
      if (manifest == null) {
        _syncStatus = 'Server unreachable. Used cached data.';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      _databaseVersion = '${manifest['version']}';
      _syncStatus = 'Syncing hot list & spam domains...';
      notifyListeners();

      // Fetch hot numbers
      final hotData = await _apiClient.fetchHotNumbers();
      if (hotData != null && hotData['numbers'] is List) {
        final List<Map<String, dynamic>> hotRows = [];
        for (final item in hotData['numbers']) {
          final map = item as Map<String, dynamic>;
          hotRows.add({
            'number': map['number'],
            'type': map['type'] ?? 'robocall',
            'reports': map['reports'] ?? 10,
            'description': map['description'] ?? 'Hot list spammer',
            'first_seen': DateTime.now().toIso8601String(),
            'last_seen': DateTime.now().toIso8601String(),
            'sources': 'hot_list',
          });
        }
        await _db.batchInsertSpamNumbers(hotRows);
      }

      // Fetch spam domains
      final domains = await _apiClient.fetchSpamDomains();
      if (domains.isNotEmpty) {
        SmsContentAnalyzer.instance.setSpamDomains(domains);
      }

      // Fetch ML weights if updated
      final weights = await _apiClient.fetchModelWeights();
      if (weights != null) {
        SpamMLScorer.instance.loadFromJson(jsonEncode(weights));
      }

      _syncStatus = 'Sync complete! Version v$_databaseVersion';
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _syncStatus = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Export encrypted backup JSON
  Future<String> exportEncryptedBackup(String passphrase) async {
    final blocklist = await _db.getBlocklist();
    final whitelist = await _db.getWhitelist();
    final wildcards = await _db.getWildcardRules();
    final ranges = await _db.getRangePatterns();
    final smsKeywords = await _db.getSmsKeywords();

    final payload = {
      'app': 'CallShield',
      'version': AppConstants.appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'blocklist': blocklist.map((e) => e.toMap()).toList(),
      'whitelist': whitelist.map((e) => e.toMap()).toList(),
      'wildcard_rules': wildcards.map((e) => e.toMap()).toList(),
      'range_patterns': ranges.map((e) => e.toMap()).toList(),
      'sms_keywords': smsKeywords.map((e) => e.toMap()).toList(),
    };

    final jsonStr = jsonEncode(payload);
    if (passphrase.isEmpty) {
      return jsonStr;
    } else {
      return CryptoUtils.encryptBackup(jsonStr, passphrase);
    }
  }

  // Import and restore backup
  Future<bool> importBackup(String backupContent, String passphrase) async {
    try {
      String plaintext;
      if (passphrase.isNotEmpty && backupContent.contains('PBKDF2')) {
        plaintext = CryptoUtils.decryptBackup(backupContent, passphrase);
      } else {
        plaintext = backupContent;
      }

      final Map<String, dynamic> data = jsonDecode(plaintext);

      if (data['blocklist'] is List) {
        for (final item in data['blocklist']) {
          await _db.addBlocklistEntry(BlocklistEntry.fromMap(item as Map<String, dynamic>));
        }
      }
      if (data['whitelist'] is List) {
        for (final item in data['whitelist']) {
          await _db.addWhitelistEntry(WhitelistEntry.fromMap(item as Map<String, dynamic>));
        }
      }
      if (data['wildcard_rules'] is List) {
        for (final item in data['wildcard_rules']) {
          await _db.addWildcardRule(WildcardRule.fromMap(item as Map<String, dynamic>));
        }
      }
      if (data['range_patterns'] is List) {
        for (final item in data['range_patterns']) {
          await _db.addRangePattern(RangePattern.fromMap(item as Map<String, dynamic>));
        }
      }
      if (data['sms_keywords'] is List) {
        for (final item in data['sms_keywords']) {
          await _db.addSmsKeyword(SmsKeywordRule.fromMap(item as Map<String, dynamic>));
        }
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Export CSV call log
  Future<String> exportLogsToCsv() async {
    final logs = await _db.getCallLogs(limit: 1000);
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Number,CallerName,IsBlocked,ReasonCode,Confidence,Score,IsSms,Description');

    for (final l in logs) {
      buffer.writeln(
        '"${l.timestamp.toIso8601String()}","${l.number}","${l.callerName}",${l.isBlocked},"${l.reasonCode.key}",${l.confidence},${l.score},${l.isSms},"${l.description.replaceAll('"', '""')}"',
      );
    }

    return buffer.toString();
  }
}
