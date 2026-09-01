import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../domain/models/block_reasoning.dart';
import '../../../domain/models/rule_models.dart';
import '../../../data/identity/caller_identity_service.dart';
import '../../state/activity_provider.dart';
import '../../widgets/caller_details_sheet.dart';
import '../../widgets/risk_gauge.dart';
import '../../widgets/signal_card.dart';
import '../../widgets/verdict_badge.dart';
import '../simulator/incoming_call_simulator_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final theme = Theme.of(context);
    final logs = activity.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All Activity?'),
                  content: const Text('This will delete your recorded call and message screening history.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                  ],
                ),
              );
              if (confirm == true) {
                activity.clearAll();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search number, caller name, or keyword...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (val) => activity.setSearchQuery(val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ActivityFilter.values.map((filter) {
                final isSelected = activity.currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    selectedColor: SignalLedgerTheme.cyan,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (_) => activity.setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ── History List ──
          Expanded(
            child: activity.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: SignalLedgerTheme.darkTextMuted),
                            const SizedBox(height: 12),
                            Text('No activity recorded', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Screened incoming calls and filtered texts will appear here.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return SignalCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => _showDetailsModal(context, log),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: (log.isBlocked ? SignalLedgerTheme.red : SignalLedgerTheme.green)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    log.isSms
                                        ? Icons.sms_rounded
                                        : (log.isBlocked ? Icons.phone_disabled_rounded : Icons.phone_forwarded_rounded),
                                    color: log.isBlocked ? SignalLedgerTheme.red : SignalLedgerTheme.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        PhoneNormalizer.formatDisplay(log.number),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        log.callerName.isNotEmpty ? log.callerName : log.reasonCode.displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.brightness == Brightness.dark
                                              ? SignalLedgerTheme.darkTextMuted
                                              : SignalLedgerTheme.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    VerdictBadge(isBlocked: log.isBlocked, reasonCode: log.reasonCode, isSmall: true),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(log.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.brightness == Brightness.dark
                                              ? SignalLedgerTheme.darkTextMuted
                                              : SignalLedgerTheme.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetailsModal(BuildContext context, CallLogRecord log) {
    final explanation = BlockReasoning.explain(
      reasonCode: log.reasonCode,
      description: log.description,
      confidence: log.confidence,
      matchSource: log.matchSource,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    PhoneNormalizer.formatDisplay(log.number),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  VerdictBadge(isBlocked: log.isBlocked, reasonCode: log.reasonCode),
                ],
              ),
              if (log.callerName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(log.callerName, style: const TextStyle(fontSize: 14, color: SignalLedgerTheme.cyan)),
              ],
              const SizedBox(height: 16),
              RiskGauge(
                confidence: log.confidence,
                score: log.score,
                isBlocked: log.isBlocked,
              ),
              const SizedBox(height: 20),
              Text(
                explanation.headline,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...explanation.bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(b, style: const TextStyle(fontSize: 13, height: 1.3))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text('Caller Details'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final identity = CallerIdentityService.instance.resolve(log.number, contactName: log.callerName);
                        CallerDetailsSheet.show(context, identity);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone_callback_rounded, size: 16),
                      label: const Text('Test Banner'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final identity = CallerIdentityService.instance.resolve(log.number, contactName: log.callerName);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IncomingCallSimulatorScreen(initialCaller: identity),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SignalLedgerTheme.red,
                        side: BorderSide(color: SignalLedgerTheme.red.withValues(alpha: 0.5)),
                      ),
                      onPressed: () {
                        context.read<ActivityProvider>().blockNumber(log.number);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${log.number} to Blocklist')),
                        );
                      },
                      child: const Text('Block Number'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ActivityProvider>().temporaryAllow(log.number);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Allowed ${log.number} for 24 hours')),
                        );
                      },
                      child: const Text('Allow 24h'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
