import 'package:flutter/foundation.dart';
import '../../data/local/database_helper.dart';
import '../../domain/models/rule_models.dart';

enum ActivityFilter {
  all('All Activity'),
  blocked('Blocked'),
  allowed('Allowed'),
  sms('SMS');

  final String label;
  const ActivityFilter(this.label);
}

class ActivityProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CallLogRecord> _logs = [];
  ActivityFilter _currentFilter = ActivityFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;

  List<CallLogRecord> get logs {
    if (_searchQuery.isEmpty) return _logs;
    final q = _searchQuery.toLowerCase();
    return _logs.where((log) =>
        log.number.toLowerCase().contains(q) ||
        log.callerName.toLowerCase().contains(q) ||
        log.description.toLowerCase().contains(q)).toList();
  }

  ActivityFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  ActivityProvider() {
    loadLogs();
  }

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    bool? blockedOnly;
    bool? isSms;

    switch (_currentFilter) {
      case ActivityFilter.blocked:
        blockedOnly = true;
        break;
      case ActivityFilter.allowed:
        blockedOnly = false;
        break;
      case ActivityFilter.sms:
        isSms = true;
        break;
      case ActivityFilter.all:
        break;
    }

    _logs = await _db.getCallLogs(
      limit: 150,
      blockedOnly: blockedOnly,
      isSms: isSms,
    );

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(ActivityFilter filter) {
    _currentFilter = filter;
    loadLogs();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> blockNumber(String number, [String note = 'Added from activity log']) async {
    await _db.addBlocklistEntry(BlocklistEntry(
      number: number,
      note: note,
    ));
    await loadLogs();
  }

  Future<void> whitelistNumber(String number, [String note = 'Whitelisted from activity log']) async {
    await _db.addWhitelistEntry(WhitelistEntry(
      number: number,
      note: note,
    ));
    await loadLogs();
  }

  Future<void> temporaryAllow(String number, [Duration duration = const Duration(hours: 24)]) async {
    await _db.addWhitelistEntry(WhitelistEntry(
      number: number,
      note: 'Temporarily allowed for ${duration.inHours}h',
    ));
    await loadLogs();
  }

  Future<void> clearAll() async {
    await _db.clearAllLogs();
    await loadLogs();
  }
}
