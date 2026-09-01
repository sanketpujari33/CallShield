import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/platform/callshield_platform.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../widgets/signal_card.dart';

class SetupChecklistScreen extends StatefulWidget {
  const SetupChecklistScreen({super.key});

  @override
  State<SetupChecklistScreen> createState() => _SetupChecklistScreenState();
}

class _SetupChecklistScreenState extends State<SetupChecklistScreen> {
  final CallShieldPlatform _platform = CallShieldPlatform.instance;

  bool _isScreeningRoleGranted = false;
  bool _isContactsGranted = false;
  bool _isSmsGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);

    final screening = await _platform.isCallScreeningEnabled();
    final contacts = await _platform.getContactsPermissionStatus();
    final sms = await _platform.getSmsPermissionStatus();

    setState(() {
      _isScreeningRoleGranted = screening;
      _isContactsGranted = contacts;
      _isSmsGranted = sms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIos = !kIsWeb && Platform.isIOS;

    final allReady = _isScreeningRoleGranted && _isContactsGranted && (isIos || _isSmsGranted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Setup & Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Status Banner ──
                SignalCard(
                  padding: const EdgeInsets.all(18),
                  borderColor: allReady ? SignalLedgerTheme.green : SignalLedgerTheme.amber,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (allReady ? SignalLedgerTheme.green : SignalLedgerTheme.amber)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          allReady ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                          color: allReady ? SignalLedgerTheme.green : SignalLedgerTheme.amber,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              allReady ? 'All Protection Systems Active' : 'Setup Incomplete',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              allReady
                                  ? 'CallShield is fully integrated with system call screening.'
                                  : 'Complete the steps below to enable automatic background screening.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? SignalLedgerTheme.darkTextMuted : SignalLedgerTheme.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text('Required Setup Steps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),

                // ── Step 1: Call Screening Role / Extension ──
                SignalCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isScreeningRoleGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: _isScreeningRoleGranted ? SignalLedgerTheme.green : SignalLedgerTheme.amber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isIos ? '1. Enable Call Blocking in iOS Settings' : '1. Set as Default Caller ID & Spam App',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          isIos
                            ? 'Open iOS Settings > Phone > Call Blocking & Identification and enable CallShield.'
                            : 'Grants Android Telecom permission to screen and reject incoming robocalls before ringing.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _platform.requestCallScreeningRole();
                            await _refreshStatus();
                          },
                          child: Text(_isScreeningRoleGranted ? 'Re-verify Status' : (isIos ? 'Open Phone Settings' : 'Grant Role')),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Step 2: Contacts Whitelisting ──
                SignalCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isContactsGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: _isContactsGranted ? SignalLedgerTheme.green : SignalLedgerTheme.amber,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '2. Allow Contacts Whitelisting',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          'Allows CallShield to check your address book locally so friends, family, and trusted contacts are never blocked.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isContactsGranted
                              ? null
                              : () async {
                                  await _platform.requestContactsPermission();
                                  await _refreshStatus();
                                },
                          child: Text(_isContactsGranted ? 'Granted' : 'Allow Contacts'),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Step 3: SMS Phishing Filter (Android) ──
                if (!isIos) ...[
                  SignalCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isSmsGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: _isSmsGranted ? SignalLedgerTheme.green : SignalLedgerTheme.amber,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '3. Enable SMS Phishing Protection',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 34),
                          child: Text(
                            'Scans incoming SMS texts on-device to filter out smishing links and scam domains.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSmsGranted
                                ? null
                                : () async {
                                    await _platform.requestSmsPermission();
                                    await _refreshStatus();
                                  },
                            child: Text(_isSmsGranted ? 'Granted' : 'Enable SMS Filter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('Open System App Settings'),
                    onPressed: () => _platform.openAppSettings(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
