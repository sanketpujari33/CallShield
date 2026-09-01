import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../domain/models/block_reason_code.dart';
import '../../state/lookup_provider.dart';
import '../../state/protection_provider.dart';
import '../../../data/identity/caller_identity_service.dart';
import '../../widgets/caller_details_sheet.dart';
import '../../widgets/risk_gauge.dart';
import '../../widgets/signal_card.dart';
import '../../widgets/verdict_badge.dart';
import '../simulator/incoming_call_simulator_screen.dart';

class LookupScreen extends StatefulWidget {
  const LookupScreen({super.key});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerLookup() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      final pipeline = context.read<ProtectionProvider>().pipeline;
      context.read<LookupProvider>().performLookup(query, pipeline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Lookup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Input ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number (+1 212 555 1234)...',
                      prefixIcon: const Icon(Icons.dialpad_rounded),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _triggerLookup(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _controller.text.trim().isNotEmpty ? _triggerLookup : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: const Text('Check'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (lookup.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (lookup.currentQuery.isNotEmpty) ...[
              // ── On-Device Verdict Card ──
              SignalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          PhoneNormalizer.formatDisplay(lookup.currentQuery),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        if (lookup.localResult != null)
                          VerdictBadge(
                            isBlocked: lookup.localResult!.isBlocked,
                            reasonCode: lookup.localResult!.reasonCode,
                          )
                        else
                          VerdictBadge(
                            isBlocked: false,
                            reasonCode: BlockReasonCode.unknown,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RiskGauge(
                      confidence: lookup.localResult?.confidence ?? 0,
                      score: lookup.localResult?.score ?? 0.0,
                      isBlocked: lookup.localResult?.isBlocked ?? false,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detection verdict: ${lookup.localResult?.description ?? "No spam patterns matched"}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.badge_outlined, size: 16),
                            label: const Text('Caller Details'),
                            onPressed: () {
                              final resolved = CallerIdentityService.instance.resolve(lookup.currentQuery);
                              CallerDetailsSheet.show(context, resolved);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00A843),
                            ),
                            icon: const Icon(Icons.phone_callback_rounded, size: 16),
                            label: const Text('Test Overlay'),
                            onPressed: () {
                              final resolved = CallerIdentityService.instance.resolve(lookup.currentQuery);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IncomingCallSimulatorScreen(initialCaller: resolved),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text('Multi-Source Caller ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),

              // ── External Sources List ──
              if (lookup.externalSources.isEmpty)
                SignalCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: SignalLedgerTheme.cyan),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No external reports on file for this number. It is clean across SkipCalls, PhoneBlock, and WhoCalledMe.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...lookup.externalSources.map((s) {
                  return SignalCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          s.isSpam ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                          color: s.isSpam ? SignalLedgerTheme.red : SignalLedgerTheme.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.source, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              if (s.detail.isNotEmpty)
                                Text(s.detail, style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                            ],
                          ),
                        ),
                        if (s.reports > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: SignalLedgerTheme.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${s.reports} reports',
                              style: const TextStyle(color: SignalLedgerTheme.red, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // ── SIT Tone Player ──
              SignalCard(
                borderColor: SignalLedgerTheme.purple.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SignalLedgerTheme.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        lookup.isPlayingSitTone ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: SignalLedgerTheme.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ITU-T E.180 SIT Tone', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            'Plays 3-tone anti-autodialer disconnect signal',
                            style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: SignalLedgerTheme.purple),
                      onPressed: lookup.isPlayingSitTone ? null : () => lookup.playSitTone(),
                      child: Text(lookup.isPlayingSitTone ? 'Playing...' : 'Play'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Quick Decision Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.block_rounded, color: SignalLedgerTheme.red),
                      label: const Text('Block'),
                      onPressed: () {
                        lookup.blockCurrentNumber();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Blocklist')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.verified_user_rounded, color: SignalLedgerTheme.green),
                      label: const Text('Allow'),
                      onPressed: () {
                        lookup.whitelistCurrentNumber();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Whitelist')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.report_gmailerrorred_rounded),
                      label: const Text('Report'),
                      onPressed: () => _showReportDialog(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final lookup = context.read<LookupProvider>();
    String selectedType = 'robocall';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Report Spam to Community DB'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select spam category:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'robocall', child: Text('Robocall')),
                      DropdownMenuItem(value: 'scam', child: Text('Scam / Fraud')),
                      DropdownMenuItem(value: 'telemarketer', child: Text('Telemarketing')),
                      DropdownMenuItem(value: 'debt_collector', child: Text('Debt Collector')),
                      DropdownMenuItem(value: 'ai_voice', child: Text('AI Voice Bot')),
                      DropdownMenuItem(value: 'sms_spam', child: Text('SMS Spam')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlgState(() => selectedType = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await lookup.reportSpam(selectedType);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Spam report submitted anonymously!' : 'Report submission failed'),
                          backgroundColor: success ? SignalLedgerTheme.green : SignalLedgerTheme.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
