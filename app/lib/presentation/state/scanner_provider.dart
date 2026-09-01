import 'package:flutter/foundation.dart';
import '../../data/checker/checker_pipeline.dart';
import '../../data/local/database_helper.dart';
import '../../data/scanner/device_scanner_service.dart';
import '../../domain/models/device_scan_models.dart';
import '../../domain/models/rule_models.dart';

enum ScanFilter {
  all('All Items'),
  spam('🚨 Spam / Fraud'),
  marketing('📢 Marketing'),
  normal('✅ Clean / Normal');

  final String label;
  const ScanFilter(this.label);
}

class ScannerProvider extends ChangeNotifier {
  final DeviceScannerService _scannerService = DeviceScannerService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  DeviceScanType _currentType = DeviceScanType.call;
  ScanFilter _currentFilter = ScanFilter.all;
  bool _isScanning = false;
  bool _isSyncing = false;
  String? _statusMessage;

  DeviceScanSummary _summary = DeviceScanSummary.empty;

  DeviceScanType get currentType => _currentType;
  ScanFilter get currentFilter => _currentFilter;
  bool get isScanning => _isScanning;
  bool get isSyncing => _isSyncing;
  String? get statusMessage => _statusMessage;
  DeviceScanSummary get summary => _summary;

  List<DeviceScanItem> get items {
    switch (_currentFilter) {
      case ScanFilter.spam:
        return _summary.items.where((i) => i.isSpam).toList();
      case ScanFilter.marketing:
        return _summary.items.where((i) => i.isMarketing).toList();
      case ScanFilter.normal:
        return _summary.items.where((i) => i.isNormal).toList();
      case ScanFilter.all:
        return _summary.items;
    }
  }

  void setType(DeviceScanType type) {
    _currentType = type;
    notifyListeners();
  }

  void setFilter(ScanFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> runScan(DeviceScanType type, CheckerPipeline pipeline) async {
    _currentType = type;
    _isScanning = true;
    _statusMessage = 'Scanning device ${type.label.toLowerCase()}...';
    notifyListeners();

    try {
      switch (type) {
        case DeviceScanType.call:
          _summary = await _scannerService.scanCalls(pipeline);
          break;
        case DeviceScanType.sms:
          _summary = await _scannerService.scanSms(pipeline);
          break;
        case DeviceScanType.contact:
          _summary = await _scannerService.scanContacts(pipeline);
          break;
      }
      _statusMessage = 'Scan complete: ${_summary.totalScanned} scanned, ${_summary.spamCount} spam, ${_summary.marketingCount} marketing.';
    } catch (e) {
      _statusMessage = 'Scan failed: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<int> syncSpamToServer() async {
    _isSyncing = true;
    _statusMessage = 'Syncing identified spam with community server...';
    notifyListeners();

    try {
      final count = await _scannerService.sendReportsToServer(_summary.items);
      _statusMessage = count > 0
          ? 'Successfully contributed $count spam reports to community database!'
          : 'All current spam items are already synchronized.';
      _isSyncing = false;
      notifyListeners();
      return count;
    } catch (e) {
      _statusMessage = 'Server sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return 0;
    }
  }

  Future<void> blockItem(DeviceScanItem item) async {
    await _db.addBlocklistEntry(BlocklistEntry(
      number: item.number,
      note: 'Auto-blocked from ${item.scanType.label} scanner: ${item.matchReason}',
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> whitelistItem(DeviceScanItem item) async {
    await _db.addWhitelistEntry(WhitelistEntry(
      number: item.number,
      note: 'Whitelisted from ${item.scanType.label} scanner: ${item.displayName}',
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }
}
