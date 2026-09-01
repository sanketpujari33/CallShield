import 'package:flutter/foundation.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../data/checker/checker_pipeline.dart';
import '../../data/local/database_helper.dart';
import '../../data/remote/callshield_api_client.dart';
import '../../domain/models/caller_identity.dart';
import '../../domain/models/rule_models.dart';
import '../../domain/models/spam_check_result.dart';

class ExternalSourceCardData {
  final String source;
  final bool isSpam;
  final int reports;
  final String detail;
  final String status;

  const ExternalSourceCardData({
    required this.source,
    required this.isSpam,
    required this.reports,
    required this.detail,
    required this.status,
  });
}

class LookupProvider extends ChangeNotifier {
  final CallShieldApiClient _apiClient = CallShieldApiClient();
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _currentQuery = '';
  bool _isLoading = false;
  SpamCheckResult? _localResult;
  Map<String, dynamic>? _remoteResult;
  List<ExternalSourceCardData> _externalSources = [];
  bool _isPlayingSitTone = false;

  String get currentQuery => _currentQuery;
  bool get isLoading => _isLoading;
  SpamCheckResult? get localResult => _localResult;
  Map<String, dynamic>? get remoteResult => _remoteResult;
  List<ExternalSourceCardData> get externalSources => _externalSources;
  bool get isPlayingSitTone => _isPlayingSitTone;

  Future<void> performLookup(String rawNumber, CheckerPipeline pipeline) async {
    final clean = rawNumber.trim();
    if (clean.isEmpty) return;

    _currentQuery = clean;
    _isLoading = true;
    _localResult = null;
    _remoteResult = null;
    _externalSources = [];
    notifyListeners();

    final normalized = PhoneNormalizer.normalize(clean) ?? clean;
    final identity = CallerIdentity(
      rawNumber: clean,
      normalizedNumber: normalized,
    );

    // 1. Evaluate on-device
    _localResult = await pipeline.run(identity, DateTime.now());

    // 2. Query external multi-source API via backend
    try {
      final remote = await _apiClient.lookupCaller(normalized);
      if (remote != null) {
        _remoteResult = remote;
        final rawSources = remote['sources'] as List? ?? [];
        _externalSources = rawSources.map((s) {
          final map = s as Map<String, dynamic>;
          return ExternalSourceCardData(
            source: map['source'] as String? ?? 'Unknown',
            isSpam: map['isSpam'] as bool? ?? false,
            reports: map['reports'] as int? ?? 0,
            detail: map['detail'] as String? ?? '',
            status: map['status'] as String? ?? 'SUCCESS',
          );
        }).toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> reportSpam(String type) async {
    if (_currentQuery.isEmpty) return false;
    final normalized = PhoneNormalizer.normalize(_currentQuery) ?? _currentQuery;
    final success = await _apiClient.submitSpamReport(
      number: normalized,
      type: type,
    );
    return success;
  }

  Future<void> blockCurrentNumber([String note = 'Blocked from Lookup']) async {
    if (_currentQuery.isEmpty) return;
    final normalized = PhoneNormalizer.normalize(_currentQuery) ?? _currentQuery;
    await _db.addBlocklistEntry(BlocklistEntry(number: normalized, note: note));
    notifyListeners();
  }

  Future<void> whitelistCurrentNumber([String note = 'Whitelisted from Lookup']) async {
    if (_currentQuery.isEmpty) return;
    final normalized = PhoneNormalizer.normalize(_currentQuery) ?? _currentQuery;
    await _db.addWhitelistEntry(WhitelistEntry(number: normalized, note: note));
    notifyListeners();
  }

  void playSitTone() {
    _isPlayingSitTone = true;
    notifyListeners();
    // SIT tone duration is ~1 second
    Future.delayed(const Duration(milliseconds: 1100), () {
      _isPlayingSitTone = false;
      notifyListeners();
    });
  }
}
