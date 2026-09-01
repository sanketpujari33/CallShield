import 'package:flutter/material.dart';
import '../../core/theme/signal_ledger_theme.dart';

class RiskGauge extends StatelessWidget {
  final int confidence; // 0..100
  final double score; // 0.0..1.0
  final bool isBlocked;

  const RiskGauge({
    super.key,
    required this.confidence,
    required this.score,
    required this.isBlocked,
  });

  Color get _gaugeColor {
    if (!isBlocked) return SignalLedgerTheme.green;
    if (confidence >= 80) return SignalLedgerTheme.red;
    if (confidence >= 50) return SignalLedgerTheme.amber;
    return SignalLedgerTheme.cyan;
  }

  String get _riskLabel {
    if (!isBlocked) return 'SAFE';
    if (confidence >= 85) return 'HIGH SPAM RISK';
    if (confidence >= 60) return 'LIKELY SPAM';
    return 'SUSPICIOUS';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (confidence / 100.0).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _gaugeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _riskLabel,
                  style: TextStyle(
                    color: _gaugeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              isBlocked ? '$confidence%' : 'Clean',
              style: TextStyle(
                color: _gaugeColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: isBlocked ? pct : 0.05,
            minHeight: 8,
            backgroundColor: theme.brightness == Brightness.dark
                ? SignalLedgerTheme.darkBorder
                : SignalLedgerTheme.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(_gaugeColor),
          ),
        ),
      ],
    );
  }
}
