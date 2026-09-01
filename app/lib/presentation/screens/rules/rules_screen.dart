import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../domain/models/rule_models.dart';
import '../../state/rules_provider.dart';
import '../../widgets/rule_tester_dialog.dart';
import '../../widgets/schedule_picker_dialog.dart';
import '../../widgets/signal_card.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<RulesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protection Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Rule Tester',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const RuleTesterDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tab Bar ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: RuleTab.values.map((tab) {
                final isSelected = rules.activeTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab.label),
                    selected: isSelected,
                    selectedColor: SignalLedgerTheme.cyan,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (_) => rules.setTab(tab),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Rules List ──
          Expanded(
            child: rules.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTabContent(context, rules),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SignalLedgerTheme.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(_fabLabel(rules.activeTab)),
        onPressed: () => _showAddDialog(context, rules.activeTab),
      ),
    );
  }

  String _fabLabel(RuleTab tab) {
    switch (tab) {
      case RuleTab.blocklist:
        return 'Add Block';
      case RuleTab.whitelist:
        return 'Add Whitelist';
      case RuleTab.wildcard:
        return 'Add Pattern';
      case RuleTab.range:
        return 'Add Range';
      case RuleTab.sms:
        return 'Add Keyword';
    }
  }

  Widget _buildTabContent(BuildContext context, RulesProvider rules) {
    switch (rules.activeTab) {
      case RuleTab.blocklist:
        return _buildBlocklist(context, rules);
      case RuleTab.whitelist:
        return _buildWhitelist(context, rules);
      case RuleTab.wildcard:
        return _buildWildcards(context, rules);
      case RuleTab.range:
        return _buildRanges(context, rules);
      case RuleTab.sms:
        return _buildSmsKeywords(context, rules);
    }
  }

  Widget _buildBlocklist(BuildContext context, RulesProvider rules) {
    final list = rules.blocklist;
    if (list.isEmpty) return _emptyState('No numbers in blocklist');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return SignalCard(
          child: Row(
            children: [
              const Icon(Icons.block_rounded, color: SignalLedgerTheme.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(PhoneNormalizer.formatDisplay(item.number), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (item.note.isNotEmpty)
                      Text(item.note, style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                    if (item.isTemporary)
                      Text('Temporary until ${item.expiresAt}', style: const TextStyle(fontSize: 11, color: SignalLedgerTheme.amber)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () => rules.removeBlock(item.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhitelist(BuildContext context, RulesProvider rules) {
    final list = rules.whitelist;
    if (list.isEmpty) return _emptyState('No numbers in whitelist');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return SignalCard(
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: SignalLedgerTheme.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(PhoneNormalizer.formatDisplay(item.number), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (item.note.isNotEmpty)
                      Text(item.note, style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () => rules.removeWhitelist(item.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWildcards(BuildContext context, RulesProvider rules) {
    final list = rules.wildcardRules;
    if (list.isEmpty) return _emptyState('No wildcard or regex rules');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return SignalCard(
          child: Row(
            children: [
              Switch(
                value: item.enabled,
                activeThumbColor: SignalLedgerTheme.cyan,
                onChanged: (_) => rules.toggleWildcardRule(item),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.pattern, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
                    if (item.note.isNotEmpty)
                      Text(item.note, style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                    if (item.schedule.daysMask != 0)
                      const Text('Active on scheduled days/hours', style: TextStyle(fontSize: 11, color: SignalLedgerTheme.cyan)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.schedule_rounded, color: SignalLedgerTheme.cyan),
                onPressed: () async {
                  final schedule = await showDialog<TimeSchedule>(
                    context: context,
                    builder: (_) => SchedulePickerDialog(initialSchedule: item.schedule),
                  );
                  if (schedule != null) {
                    rules.addWildcardRule(item.pattern, isRegex: item.isRegex, note: item.note, schedule: schedule);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () => rules.removeWildcardRule(item.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRanges(BuildContext context, RulesProvider rules) {
    final list = rules.rangePatterns;
    if (list.isEmpty) return _emptyState('No range patterns (+33162######)');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return SignalCard(
          child: Row(
            children: [
              Switch(
                value: item.enabled,
                activeThumbColor: SignalLedgerTheme.cyan,
                onChanged: (_) => rules.toggleRangePattern(item),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.pattern, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
                    if (item.note.isNotEmpty)
                      Text(item.note, style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () => rules.removeRangePattern(item.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmsKeywords(BuildContext context, RulesProvider rules) {
    final list = rules.smsKeywords;
    if (list.isEmpty) return _emptyState('No SMS keyword rules');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return SignalCard(
          child: Row(
            children: [
              Switch(
                value: item.enabled,
                activeThumbColor: SignalLedgerTheme.cyan,
                onChanged: (_) => rules.toggleSmsKeyword(item),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('"${item.keyword}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (item.note.isNotEmpty)
                      Text(item.note, style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () => rules.removeSmsKeyword(item.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_rounded, size: 54, color: SignalLedgerTheme.darkTextMuted),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: SignalLedgerTheme.darkTextMuted)),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, RuleTab tab) {
    final textController = TextEditingController();
    final noteController = TextEditingController();
    final rules = context.read<RulesProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add to ${_tabName(tab)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: _inputLabel(tab),
                  hintText: _inputHint(tab),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Telemarketer robocall',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final value = textController.text.trim();
                final note = noteController.text.trim();
                if (value.isNotEmpty) {
                  switch (tab) {
                    case RuleTab.blocklist:
                      rules.addBlock(value, note);
                      break;
                    case RuleTab.whitelist:
                      rules.addWhitelist(value, note);
                      break;
                    case RuleTab.wildcard:
                      rules.addWildcardRule(value, note: note);
                      break;
                    case RuleTab.range:
                      rules.addRangePattern(value, note: note);
                      break;
                    case RuleTab.sms:
                      rules.addSmsKeyword(value, note: note);
                      break;
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Rule'),
            ),
          ],
        );
      },
    );
  }

  String _tabName(RuleTab tab) {
    switch (tab) {
      case RuleTab.blocklist:
        return 'Blocklist';
      case RuleTab.whitelist:
        return 'Whitelist';
      case RuleTab.wildcard:
        return 'Wildcard Pattern';
      case RuleTab.range:
        return 'Range Pattern';
      case RuleTab.sms:
        return 'SMS Keywords';
    }
  }

  String _inputLabel(RuleTab tab) {
    switch (tab) {
      case RuleTab.blocklist:
      case RuleTab.whitelist:
        return 'Phone Number';
      case RuleTab.wildcard:
        return 'Pattern or Regex';
      case RuleTab.range:
        return 'Range Pattern (#)';
      case RuleTab.sms:
        return 'Keyword or Phrase';
    }
  }

  String _inputHint(RuleTab tab) {
    switch (tab) {
      case RuleTab.blocklist:
      case RuleTab.whitelist:
        return '+1 212 555 1234';
      case RuleTab.wildcard:
        return '+1800* or ^\\+1[0-9]{10}\$';
      case RuleTab.range:
        return '+33162######';
      case RuleTab.sms:
        return 'urgent action required';
    }
  }
}
