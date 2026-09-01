import 'package:flutter/material.dart';
import '../../core/theme/signal_ledger_theme.dart';
import '../../domain/models/block_reason_code.dart';

class VerdictBadge extends StatelessWidget {
  final bool isBlocked;
  final BlockReasonCode reasonCode;
  final bool isSmall;

  const VerdictBadge({
    super.key,
    required this.isBlocked,
    required this.reasonCode,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBlocked ? SignalLedgerTheme.red : SignalLedgerTheme.green;
    final text = isBlocked ? 'BLOCKED' : 'ALLOWED';
    final icon = isBlocked ? Icons.block_rounded : Icons.check_circle_outline_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
