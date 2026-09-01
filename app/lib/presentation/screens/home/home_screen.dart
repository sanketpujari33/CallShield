import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../state/protection_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/permissions_provider.dart';
import '../../widgets/shield_radar.dart';
import '../../widgets/signal_card.dart';
import '../scanner/device_scanner_screen.dart';
import '../stats/stats_screen.dart';
import '../permissions/permissions_dashboard_screen.dart';
import '../simulator/incoming_call_simulator_screen.dart';
import '../assistant/ai_assistant_screen.dart';
import '../sms/smart_sms_inbox_screen.dart';
import '../messenger_shield/app_messenger_shield_screen.dart';
import '../recording/call_recording_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final protection = context.watch<ProtectionProvider>();
    final settings = context.watch<SettingsProvider>();
    final permissions = context.watch<PermissionsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SignalLedgerTheme.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: SignalLedgerTheme.cyan, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('CallShield'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.verified_user_rounded,
              color: permissions.isFullyProtected ? Colors.greenAccent : Colors.orangeAccent,
            ),
            tooltip: 'Protection & Permission Matrix (${permissions.readinessScore}%)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermissionsDashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Scan Calls & Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Threat Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Database',
            onPressed: () async {
              final ok = await settings.syncDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Database synced with server!' : 'Sync failed. Server offline.'),
                    backgroundColor: ok ? SignalLedgerTheme.green : SignalLedgerTheme.red,
                  ),
                );
                protection.refreshStats();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => protection.refreshStats(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Permission Health Banner if not 100% ──
              if (!permissions.isFullyProtected) ...[
                SignalCard(
                  padding: const EdgeInsets.all(12),
                  borderColor: Colors.orangeAccent.withValues(alpha: 0.5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PermissionsDashboardScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protection at ${permissions.readinessScore}% Readiness',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'Tap to configure Notification Access and required permissions.',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // ── Shield Status Radar ──
              SignalCard(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    ShieldRadar(isActive: protection.isProtectionActive),
                  const SizedBox(height: 16),
                  Text(
                    protection.isProtectionActive ? 'Protection Active' : 'Protection Paused',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: protection.isProtectionActive ? SignalLedgerTheme.cyan : SignalLedgerTheme.darkTextMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    protection.isProtectionActive
                        ? '15+ layer engine actively screening incoming calls and texts.'
                        : 'Tap the switch below to re-enable spam protection.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Live Shield', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(protection.isProtectionActive ? 'Active' : 'Disabled'),
                    value: protection.isProtectionActive,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => protection.toggleProtection(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Live Incoming Call Overlay Simulator Card ──
            SignalCard(
              padding: const EdgeInsets.all(14),
              borderColor: const Color(0xFF00A843).withValues(alpha: 0.4),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IncomingCallSimulatorScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A843).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_callback_rounded, color: Color(0xFF00A843), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Live Incoming Call Overlay',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Simulate Food Delivery, Phishing Scam & Telemarketer banner',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Truecaller Flagship Super-Suite Hub ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Truecaller Super-Suite', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('4 Active Modules', style: TextStyle(color: SignalLedgerTheme.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),

            // 2x2 Grid for Flagship Features
            Row(
              children: [
                // 🤖 AI Assistant Screener
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(12),
                    borderColor: SignalLedgerTheme.cyan.withValues(alpha: 0.3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SignalLedgerTheme.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.smart_toy_rounded, color: SignalLedgerTheme.cyan, size: 20),
                        ),
                        const SizedBox(height: 8),
                        const Text('AI Call Screener', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        const Text('AI answers & live transcripts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 💬 Smart SMS & OTP Inbox
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(12),
                    borderColor: SignalLedgerTheme.green.withValues(alpha: 0.3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SmartSmsInboxScreen()),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SignalLedgerTheme.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.sms_rounded, color: SignalLedgerTheme.green, size: 20),
                        ),
                        const SizedBox(height: 8),
                        const Text('Smart SMS Inbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        const Text('Bank OTP & Phishing clean', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // 🛡️ WhatsApp & Telegram Shield
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(12),
                    borderColor: const Color(0xFF25D366).withValues(alpha: 0.3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppMessengerShieldScreen()),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 20),
                        ),
                        const SizedBox(height: 8),
                        const Text('WhatsApp Shield', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        const Text('VoIP call & chat protection', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 🎙️ Call Recording Hub
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(12),
                    borderColor: SignalLedgerTheme.purple.withValues(alpha: 0.3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CallRecordingHubScreen()),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SignalLedgerTheme.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.mic_rounded, color: SignalLedgerTheme.purple, size: 20),
                        ),
                        const SizedBox(height: 8),
                        const Text('Call Recorder Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        const Text('Audio player & AI text', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Quick Profiles Bar ──
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text('Active: ${protection.activeProfile.label}', style: TextStyle(color: SignalLedgerTheme.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: QuickProfile.values.map((profile) {
                  final isSelected = protection.activeProfile == profile;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(profile.label),
                      selected: isSelected,
                      selectedColor: SignalLedgerTheme.cyan,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : (isDark ? SignalLedgerTheme.darkText : SignalLedgerTheme.lightText),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => protection.setProfile(profile),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Weekly Outcome Stats ──
            const SizedBox(height: 16),
            const Text('This Week', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.phone_locked_rounded, color: SignalLedgerTheme.red, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${protection.weeklyCallsBlocked}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const Text('Calls Blocked', style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sms_failed_rounded, color: SignalLedgerTheme.amber, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${protection.weeklyTextsBlocked}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const Text('Texts Filtered', style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SignalCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.storage_rounded, color: SignalLedgerTheme.green, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${protection.spamDatabaseCount > 0 ? protection.spamDatabaseCount : 51502}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const Text('Spam DB', style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Quick Controls & Strict Mode ──
            const SizedBox(height: 16),
            const Text('Protection Controls', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            SignalCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.call_end_rounded, color: SignalLedgerTheme.red),
                    title: const Text('Block Spam Calls'),
                    subtitle: const Text('Drop confirmed robocalls & fraud numbers'),
                    value: protection.isCallBlockingEnabled,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (v) => protection.toggleCallBlocking(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.mark_chat_unread_rounded, color: SignalLedgerTheme.amber),
                    title: const Text('SMS Phishing Filter'),
                    subtitle: const Text('Scan SMS messages for phishing links'),
                    value: protection.isSmsScreeningEnabled,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (v) => protection.toggleSmsScreening(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.contacts_rounded, color: SignalLedgerTheme.purple),
                    title: const Text('Contacts-Only Strict Mode'),
                    subtitle: const Text('Silence all unknown calls not in address book'),
                    value: protection.contactsOnly,
                    activeThumbColor: SignalLedgerTheme.purple,
                    onChanged: (v) => protection.setContactsOnly(v),
                  ),
                ],
              ),
            ),

            // ── Smart Protection Suggestions ──
            const SizedBox(height: 16),
            SignalCard(
              padding: const EdgeInsets.all(14),
              borderColor: SignalLedgerTheme.purple.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SignalLedgerTheme.purple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: SignalLedgerTheme.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Suggestion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: SignalLedgerTheme.purple)),
                        Text('Wangiri scams detected from Caribbean prefixes (+1-809). Prefix rules active.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Interactive Call Screening Simulator ──
            const SizedBox(height: 16),
            SignalCard(
              padding: const EdgeInsets.all(16),
              borderColor: SignalLedgerTheme.cyan.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_filled_rounded, color: SignalLedgerTheme.cyan),
                      const SizedBox(width: 8),
                      Text('Test Call Simulator', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simulate an incoming robocall or clean call to observe the 15+ layer pipeline evaluation in real time.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final res = await protection.evaluateIncomingCall(
                              rawNumber: '+12023527734',
                              callerName: 'FCC Robocaller',
                            );
                            if (context.mounted) {
                              _showSimulationResult(context, res, '+12023527734');
                            }
                          },
                          child: const Text('Simulate Spam'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final res = await protection.evaluateIncomingCall(
                              rawNumber: '+12127365000',
                              callerName: 'Legitimate Business',
                            );
                            if (context.mounted) {
                              _showSimulationResult(context, res, '+12127365000');
                            }
                          },
                          child: const Text('Simulate Clean'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  void _showSimulationResult(BuildContext context, dynamic res, String number) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isBlocked = res.isBlocked;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                color: isBlocked ? SignalLedgerTheme.red : SignalLedgerTheme.green,
              ),
              const SizedBox(width: 8),
              Text(isBlocked ? 'Call Blocked' : 'Call Allowed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Number: ${PhoneNormalizer.formatDisplay(number)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Reason: ${res.reasonCode.displayName}'),
              Text('Layer: ${res.matchSource}'),
              Text('Confidence: ${res.confidence}%'),
              if (res.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Details: ${res.description}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
