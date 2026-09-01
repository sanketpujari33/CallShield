import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../state/stats_provider.dart';
import '../../widgets/signal_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spam Analytics & Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => stats.loadStats(),
          ),
        ],
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => stats.loadStats(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // ── Hero Overview Card ──
                  SignalCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Weekly Blocked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (stats.weeklyDelta >= 0 ? SignalLedgerTheme.amber : SignalLedgerTheme.green)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    stats.weeklyDelta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 14,
                                    color: stats.weeklyDelta >= 0 ? SignalLedgerTheme.amber : SignalLedgerTheme.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    stats.weeklyDelta >= 0 ? '+${stats.weeklyDelta} vs last week' : '${stats.weeklyDelta} vs last week',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: stats.weeklyDelta >= 0 ? SignalLedgerTheme.amber : SignalLedgerTheme.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${stats.weeklyTotal}',
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: SignalLedgerTheme.cyan),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: SignalLedgerTheme.darkTextMuted),
                            const SizedBox(width: 6),
                            Text('Peak Spam Window: ${stats.peakHour}', style: TextStyle(fontSize: 12, color: isDark ? SignalLedgerTheme.darkTextMuted : SignalLedgerTheme.lightTextMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Daily Distribution Bar Chart ──
                  const SizedBox(height: 16),
                  const Text('Daily Threat Volume (7 Days)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  SignalCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 110,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: stats.dailyStats.map((d) {
                              final maxCount = stats.dailyStats.map((e) => e.count).fold(0, max);
                              final heightPct = maxCount > 0 ? (d.count / maxCount) : 0.05;
                              final isPeak = d.count == maxCount && d.count > 0;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${d.count}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPeak ? SignalLedgerTheme.cyan : null)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 24,
                                    height: (heightPct * 65).clamp(4.0, 65.0),
                                    decoration: BoxDecoration(
                                      color: isPeak ? SignalLedgerTheme.cyan : SignalLedgerTheme.cyan.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(d.dayLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Hourly Activity Histogram ──
                  const SizedBox(height: 16),
                  const Text('24-Hour Threat Distribution', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  SignalCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 70,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(24, (h) {
                              final count = stats.hourlyDistribution[h];
                              final maxH = stats.hourlyDistribution.fold(0, max);
                              final pct = maxH > 0 ? (count / maxH) : 0.05;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: Container(
                                    height: (pct * 55).clamp(3.0, 55.0),
                                    decoration: BoxDecoration(
                                      color: count > 0 ? SignalLedgerTheme.purple : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('12 AM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('6 AM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('12 PM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('6 PM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('11 PM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Top Detection Sources Breakdown ──
                  const SizedBox(height: 16),
                  const Text('Top Detection Layers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  SignalCard(
                    child: stats.topReasons.isEmpty
                        ? const Text('No detection records yet', style: TextStyle(color: Colors.grey))
                        : Column(
                            children: stats.topReasons.take(5).map((r) {
                              final total = stats.allTimeBlocked > 0 ? stats.allTimeBlocked : 1;
                              final pct = r.count / total;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(r.reason.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text('${r.count} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                        valueColor: const AlwaysStoppedAnimation<Color>(SignalLedgerTheme.cyan),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  // ── Top Origin Area Codes ──
                  const SizedBox(height: 16),
                  const Text('Top Spam Origin Area Codes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  SignalCard(
                    child: stats.topAreaCodes.isEmpty
                        ? const Text('No regional spam data recorded', style: TextStyle(color: Colors.grey))
                        : Column(
                            children: stats.topAreaCodes.take(5).map((a) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SignalLedgerTheme.cyan.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '(${a.areaCode})',
                                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: SignalLedgerTheme.cyan),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(a.location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    ),
                                    Text('${a.count} calls', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
