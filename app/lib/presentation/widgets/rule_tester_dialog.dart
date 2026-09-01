import 'package:flutter/material.dart';
import '../../core/theme/signal_ledger_theme.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../domain/models/rule_models.dart';

class RuleTesterDialog extends StatefulWidget {
  const RuleTesterDialog({super.key});

  @override
  State<RuleTesterDialog> createState() => _RuleTesterDialogState();
}

class _RuleTesterDialogState extends State<RuleTesterDialog> {
  final TextEditingController _patternController = TextEditingController(text: '+1800*');
  final TextEditingController _testNumberController = TextEditingController(text: '+18005551234');
  bool _isRegex = false;
  bool? _isMatch;

  void _test() {
    final pattern = _patternController.text.trim();
    final number = _testNumberController.text.trim();
    final normalized = PhoneNormalizer.normalize(number) ?? number;

    if (pattern.isEmpty || normalized.isEmpty) {
      setState(() => _isMatch = null);
      return;
    }

    final rule = WildcardRule(
      pattern: pattern,
      isRegex: _isRegex,
    );

    setState(() {
      _isMatch = rule.matches(normalized, DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? SignalLedgerTheme.darkCard : SignalLedgerTheme.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? SignalLedgerTheme.darkBorder : SignalLedgerTheme.lightBorder),
      ),
      title: const Row(
        children: [
          Icon(Icons.science_rounded, color: SignalLedgerTheme.cyan),
          SizedBox(width: 8),
          Text('Interactive Rule Tester'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Test your pattern or regular expression against any phone number in real time:'),
            const SizedBox(height: 12),
            TextField(
              controller: _patternController,
              decoration: const InputDecoration(
                labelText: 'Pattern or Regex',
                hintText: '+1800* or ^\\+18[0-9]{9}\$',
              ),
              onChanged: (_) => _test(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isRegex,
                  activeColor: SignalLedgerTheme.cyan,
                  onChanged: (v) {
                    setState(() => _isRegex = v ?? false);
                    _test();
                  },
                ),
                const Text('Evaluate as Regular Expression (Regex)'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testNumberController,
              decoration: const InputDecoration(
                labelText: 'Test Phone Number',
                hintText: '+1 800 555 1234',
              ),
              onChanged: (_) => _test(),
            ),
            const SizedBox(height: 16),
            if (_isMatch != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isMatch! ? SignalLedgerTheme.green : SignalLedgerTheme.red).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_isMatch! ? SignalLedgerTheme.green : SignalLedgerTheme.red).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isMatch! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _isMatch! ? SignalLedgerTheme.green : SignalLedgerTheme.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isMatch! ? 'MATCH: This rule will BLOCK the number.' : 'NO MATCH: Number will pass through.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isMatch! ? SignalLedgerTheme.green : SignalLedgerTheme.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
