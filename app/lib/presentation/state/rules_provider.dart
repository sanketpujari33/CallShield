import 'package:flutter/foundation.dart';
import '../../data/local/database_helper.dart';
import '../../domain/models/rule_models.dart';

enum RuleTab {
  blocklist('Blocklist'),
  whitelist('Whitelist'),
  wildcard('Patterns & Regex'),
  range('Ranges'),
  sms('SMS Keywords');

  final String label;
  const RuleTab(this.label);
}

class RulesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  RuleTab _activeTab = RuleTab.blocklist;
  List<BlocklistEntry> _blocklist = [];
  List<WhitelistEntry> _whitelist = [];
  List<WildcardRule> _wildcardRules = [];
  List<RangePattern> _rangePatterns = [];
  List<SmsKeywordRule> _smsKeywords = [];

  bool _isLoading = false;

  RuleTab get activeTab => _activeTab;
  List<BlocklistEntry> get blocklist => _blocklist;
  List<WhitelistEntry> get whitelist => _whitelist;
  List<WildcardRule> get wildcardRules => _wildcardRules;
  List<RangePattern> get rangePatterns => _rangePatterns;
  List<SmsKeywordRule> get smsKeywords => _smsKeywords;
  bool get isLoading => _isLoading;

  RulesProvider() {
    loadAllRules();
  }

  void setTab(RuleTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  Future<void> loadAllRules() async {
    _isLoading = true;
    notifyListeners();

    _blocklist = await _db.getBlocklist();
    _whitelist = await _db.getWhitelist();
    _wildcardRules = await _db.getWildcardRules();
    _rangePatterns = await _db.getRangePatterns();
    _smsKeywords = await _db.getSmsKeywords();

    _isLoading = false;
    notifyListeners();
  }

  // Blocklist
  bool isNumberBlocked(String number) {
    return _blocklist.any((b) => b.number == number);
  }

  Future<void> addBlock(String number, String note, [DateTime? expiresAt]) async {
    await _db.addBlocklistEntry(BlocklistEntry(number: number, note: note, expiresAt: expiresAt));
    await loadAllRules();
  }

  Future<void> removeBlock(int id) async {
    await _db.removeBlocklistEntry(id);
    await loadAllRules();
  }

  Future<void> removeBlockByNumber(String number) async {
    final entry = _blocklist.where((b) => b.number == number).firstOrNull;
    if (entry != null && entry.id != null) {
      await removeBlock(entry.id!);
    }
  }

  // Whitelist
  Future<void> addWhitelist(String number, String note) async {
    await _db.addWhitelistEntry(WhitelistEntry(number: number, note: note));
    await loadAllRules();
  }

  Future<void> removeWhitelist(int id) async {
    await _db.removeWhitelistEntry(id);
    await loadAllRules();
  }

  // Wildcard Rules
  Future<void> addWildcardRule(String pattern, {bool isRegex = false, String note = '', TimeSchedule schedule = const TimeSchedule()}) async {
    await _db.addWildcardRule(WildcardRule(
      pattern: pattern,
      isRegex: isRegex,
      note: note,
      schedule: schedule,
    ));
    await loadAllRules();
  }

  Future<void> toggleWildcardRule(WildcardRule rule) async {
    final updated = WildcardRule(
      id: rule.id,
      pattern: rule.pattern,
      isRegex: rule.isRegex,
      note: rule.note,
      schedule: rule.schedule,
      enabled: !rule.enabled,
    );
    await _db.updateWildcardRule(updated);
    await loadAllRules();
  }

  Future<void> removeWildcardRule(int id) async {
    await _db.removeWildcardRule(id);
    await loadAllRules();
  }

  // Range Patterns
  Future<void> addRangePattern(String pattern, {String note = '', TimeSchedule schedule = const TimeSchedule()}) async {
    await _db.addRangePattern(RangePattern(
      pattern: pattern,
      note: note,
      schedule: schedule,
    ));
    await loadAllRules();
  }

  Future<void> toggleRangePattern(RangePattern pattern) async {
    final updated = RangePattern(
      id: pattern.id,
      pattern: pattern.pattern,
      note: pattern.note,
      schedule: pattern.schedule,
      enabled: !pattern.enabled,
    );
    await _db.updateRangePattern(updated);
    await loadAllRules();
  }

  Future<void> removeRangePattern(int id) async {
    await _db.removeRangePattern(id);
    await loadAllRules();
  }

  // SMS Keywords
  Future<void> addSmsKeyword(String keyword, {bool caseSensitive = false, String note = '', TimeSchedule schedule = const TimeSchedule()}) async {
    await _db.addSmsKeyword(SmsKeywordRule(
      keyword: keyword,
      caseSensitive: caseSensitive,
      note: note,
      schedule: schedule,
    ));
    await loadAllRules();
  }

  Future<void> toggleSmsKeyword(SmsKeywordRule rule) async {
    final updated = SmsKeywordRule(
      id: rule.id,
      keyword: rule.keyword,
      caseSensitive: rule.caseSensitive,
      note: rule.note,
      schedule: rule.schedule,
      enabled: !rule.enabled,
    );
    await _db.updateSmsKeyword(updated);
    await loadAllRules();
  }

  Future<void> removeSmsKeyword(int id) async {
    await _db.removeSmsKeyword(id);
    await loadAllRules();
  }
}
