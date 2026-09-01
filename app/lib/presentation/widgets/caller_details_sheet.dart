import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/signal_ledger_theme.dart';
import '../../domain/models/caller_identity_models.dart';
import '../state/rules_provider.dart';

class CallerDetailsSheet extends StatelessWidget {
  final CallerIdentity caller;

  const CallerDetailsSheet({super.key, required this.caller});

  static void show(BuildContext context, CallerIdentity caller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CallerDetailsSheet(caller: caller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = context.watch<RulesProvider>();
    final isBlocked = rules.isNumberBlocked(caller.rawNumber);

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Top Profile Card
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _getThemeColor().withValues(alpha: 0.15),
                    child: Icon(
                      _getAvatarIcon(),
                      color: _getThemeColor(),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                caller.name,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (caller.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          caller.formattedNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${caller.location} • ${caller.carrier}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons Row (Call, SMS, Block, Share)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    color: SignalLedgerTheme.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dialing ${caller.formattedNumber}...')),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.message_rounded,
                    label: 'SMS',
                    color: SignalLedgerTheme.cyan,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening SMS composer for ${caller.formattedNumber}...')),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: isBlocked ? Icons.check_circle_outline : Icons.block_rounded,
                    label: isBlocked ? 'Blocked' : 'Block',
                    color: SignalLedgerTheme.red,
                    onTap: () async {
                      if (isBlocked) {
                        await rules.removeBlockByNumber(caller.rawNumber);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Number unblocked.')),
                          );
                        }
                      } else {
                        await rules.addBlock(
                          caller.rawNumber,
                          'Blocked from Caller ID: ${caller.name}',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Number added to blacklist!')),
                          );
                        }
                      }
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    color: Colors.grey,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: caller.rawNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Number copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Threat Score Gauge & Community Telemetry
              Text(
                'SPAM & THREAT REPUTATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getThemeColor().withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          caller.isSpam
                              ? '🚨 High-Risk Spam Flagged'
                              : caller.isVerified
                                  ? '✅ Verified Trusted Identity'
                                  : 'ℹ️ Standard Regional Number',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getThemeColor(),
                          ),
                        ),
                        Text(
                          '${caller.spamScore}/100 Risk',
                          style: TextStyle(
                            color: _getThemeColor(),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: caller.spamScore / 100.0,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(_getThemeColor()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          caller.reportCount > 0
                              ? 'Reported by ${caller.reportCount} community users'
                              : '0 Spam reports recorded',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        Text(
                          _getAttestationText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: caller.attestation == StirShakenAttestation.spoofed
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Highlight Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getThemeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getThemeColor().withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Threat & Identity Summary',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getThemeColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caller.highlightMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Community Tags
              if (caller.tags.isNotEmpty) ...[
                Text(
                  'COMMUNITY TAGS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: caller.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor() {
    switch (caller.type) {
      case CallerType.verifiedDelivery:
      case CallerType.verifiedBusiness:
        return const Color(0xFF00A843);
      case CallerType.personalContact:
        return const Color(0xFF1976D2);
      case CallerType.telemarketing:
        return const Color(0xFFE65100);
      case CallerType.scamPhishing:
      case CallerType.spamRobocall:
        return const Color(0xFFD32F2F);
      case CallerType.unknown:
        return const Color(0xFF455A64);
    }
  }

  IconData _getAvatarIcon() {
    switch (caller.type) {
      case CallerType.verifiedDelivery:
        return Icons.delivery_dining_rounded;
      case CallerType.verifiedBusiness:
        return Icons.business_rounded;
      case CallerType.personalContact:
        return Icons.person_rounded;
      case CallerType.telemarketing:
        return Icons.campaign_rounded;
      case CallerType.scamPhishing:
      case CallerType.spamRobocall:
        return Icons.gpp_bad_rounded;
      case CallerType.unknown:
        return Icons.phone_in_talk_rounded;
    }
  }

  String _getAttestationText() {
    switch (caller.attestation) {
      case StirShakenAttestation.fullA:
        return 'STIR/SHAKEN Level A (Verified)';
      case StirShakenAttestation.partialB:
        return 'STIR/SHAKEN Level B (Customer)';
      case StirShakenAttestation.gatewayC:
        return 'STIR/SHAKEN Level C (Gateway)';
      case StirShakenAttestation.spoofed:
        return 'STIR/SHAKEN: Spoofed';
      case StirShakenAttestation.unavailable:
        return 'Carrier Attestation N/A';
    }
  }
}
