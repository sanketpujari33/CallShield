import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../data/areacodes/area_code_lookup.dart';
import '../../data/local/database_helper.dart';
import '../../domain/models/block_reason_code.dart';

class DailyCount {
  final String dayLabel;
  final int count;
  DailyCount(this.dayLabel, this.count);
}

class ReasonCount {
  final BlockReasonCode reason;
  final int count;
  ReasonCount(this.reason, this.count);
}

class AreaCodeCount {
  final String areaCode;
  final String location;
  final int count;
  AreaCodeCount(this.areaCode, this.location, this.count);
}

class StatsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = false;
  int _weeklyTotal = 0;
  int _previousWeekTotal = 0;
  int _allTimeBlocked = 0;
  int _allTimeAllowed = 0;
  List<DailyCount> _dailyStats = [];
  List<int> _hourlyDistribution = List.filled(24, 0);
  List<ReasonCount> _topReasons = [];
  List<AreaCodeCount> _topAreaCodes = [];
  String _peakHour = 'None';

  bool get isLoading => _isLoading;
  int get weeklyTotal => _weeklyTotal;
  int get previousWeekTotal => _previousWeekTotal;
  int get weeklyDelta => _weeklyTotal - _previousWeekTotal;
  int get allTimeBlocked => _allTimeBlocked;
  int get allTimeAllowed => _allTimeAllowed;
  List<DailyCount> get dailyStats => _dailyStats;
  List<int> get hourlyDistribution => _hourlyDistribution;
  List<ReasonCount> get topReasons => _topReasons;
  List<AreaCodeCount> get topAreaCodes => _topAreaCodes;
  String get peakHour => _peakHour;

  StatsProvider() {
    loadStats();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    final allLogs = await _db.getCallLogs(limit: 500);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekAgo = todayStart.subtract(const Duration(days: 7));
    final twoWeeksAgo = todayStart.subtract(const Duration(days: 14));

    _allTimeBlocked = allLogs.where((l) => l.isBlocked).length;
    _allTimeAllowed = allLogs.where((l) => !l.isBlocked).length;

    _weeklyTotal = allLogs.where((l) => l.isBlocked && l.timestamp.isAfter(weekAgo)).length;
    _previousWeekTotal = allLogs.where((l) => l.isBlocked && l.timestamp.isAfter(twoWeeksAgo) && l.timestamp.isBefore(weekAgo)).length;

    // Daily breakdown for last 7 days
    final Map<String, int> daysMap = {};
    for (int i = 6; i >= 0; i--) {
      final d = todayStart.subtract(Duration(days: i));
      final label = DateFormat('E').format(d);
      daysMap[label] = 0;
    }

    final hours = List.filled(24, 0);
    final Map<BlockReasonCode, int> reasonsMap = {};
    final Map<String, int> areaCodesMap = {};

    for (final log in allLogs) {
      if (log.isBlocked) {
        // Daily bucket
        if (log.timestamp.isAfter(weekAgo)) {
          final label = DateFormat('E').format(log.timestamp);
          if (daysMap.containsKey(label)) {
            daysMap[label] = (daysMap[label] ?? 0) + 1;
          }
        }

        // Hourly bucket
        hours[log.timestamp.hour]++;

        // Reason bucket
        reasonsMap[log.reasonCode] = (reasonsMap[log.reasonCode] ?? 0) + 1;

        // Area code bucket
        final code = AreaCodeLookup.getAreaCode(log.number);
        if (code != null) {
          areaCodesMap[code] = (areaCodesMap[code] ?? 0) + 1;
        }
      }
    }

    _dailyStats = daysMap.entries.map((e) => DailyCount(e.key, e.value)).toList();
    _hourlyDistribution = hours;

    // Peak hour
    int maxHourIndex = 0;
    int maxHourCount = 0;
    for (int h = 0; h < 24; h++) {
      if (hours[h] > maxHourCount) {
        maxHourCount = hours[h];
        maxHourIndex = h;
      }
    }
    if (maxHourCount > 0) {
      final start = maxHourIndex % 12 == 0 ? 12 : maxHourIndex % 12;
      final startAm = maxHourIndex < 12 ? 'AM' : 'PM';
      final endHour = (maxHourIndex + 1) % 24;
      final end = endHour % 12 == 0 ? 12 : endHour % 12;
      final endAm = endHour < 12 ? 'AM' : 'PM';
      _peakHour = '$start $startAm - $end $endAm';
    } else {
      _peakHour = 'No peak detected';
    }

    _topReasons = reasonsMap.entries
        .map((e) => ReasonCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    _topAreaCodes = areaCodesMap.entries
        .map((e) => AreaCodeCount(e.key, AreaCodeLookup.areaCodes[e.key] ?? 'Unknown', e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    _isLoading = false;
    notifyListeners();
  }
}
