import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/platform/callshield_platform.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../state/settings_provider.dart';
import '../../widgets/shield_radar.dart';
import '../../widgets/signal_card.dart';
import '../main_navigation_shell.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  final CallShieldPlatform _platform = CallShieldPlatform.instance;

  int _currentPage = 0;
  bool _isScreeningRoleGranted = false;
  bool _isCallLogGranted = false;
  bool _isSmsGranted = false;
  bool _isContactsGranted = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final screening = await _platform.isCallScreeningEnabled();
    final callLog = await _platform.getCallLogPermissionStatus();
    final sms = await _platform.getSmsPermissionStatus();
    final contacts = await _platform.getContactsPermissionStatus();

    if (mounted) {
      setState(() {
        _isScreeningRoleGranted = screening;
        _isCallLogGranted = callLog;
        _isSmsGranted = sms;
        _isContactsGranted = contacts;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await context.read<SettingsProvider>().completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Progress Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: SignalLedgerTheme.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_rounded, color: SignalLedgerTheme.cyan, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CallShield Setup',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = index == _currentPage;
                      final isPast = index < _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? SignalLedgerTheme.cyan
                              : (isPast ? SignalLedgerTheme.cyan.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ── Main Page Carousel ──
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  _refreshPermissions();
                },
                children: [
                  _buildIntroStep(context),
                  _buildPermissionsStep(context),
                  _buildCallScreeningStep(context),
                  _buildNotificationsStep(context),
                  _buildReadyStep(context),
                ],
              ),
            ),

            // ── Bottom Navigation Controls ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    )
                  else
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('Skip for now', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SignalLedgerTheme.cyan,
                      foregroundColor: Colors.black,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _nextPage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == 4 ? 'Enter CallShield' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Icon(_currentPage == 4 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Welcome & Privacy Architecture ──
  Widget _buildIntroStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 180, child: ShieldRadar(isActive: true)),
          const SizedBox(height: 24),
          const Text(
            '100% On-Device Protection',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'CallShield screens incoming spam, scam calls, and phishing messages locally using a 15-layer engine and local GBDT Machine Learning.',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SignalCard(
            padding: const EdgeInsets.all(12),
            borderColor: SignalLedgerTheme.green.withValues(alpha: 0.3),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: SignalLedgerTheme.green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Zero Cloud Telemetry: Your call history and contacts never leave your phone.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Runtime Device Permissions ──
  Widget _buildPermissionsStep(BuildContext context) {
    final isIos = !kIsWeb && Platform.isIOS;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.security_rounded, size: 54, color: SignalLedgerTheme.cyan),
        const SizedBox(height: 16),
        const Text(
          'Grant Device Permissions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'CallShield needs permission to inspect caller numbers, scan SMS for phishing links, and protect against unknown robocalls.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        _buildPermissionTile(
          title: 'Call Log Access',
          subtitle: 'Required to screen incoming calls and identify Wangiri scams',
          icon: Icons.phone_callback_rounded,
          isGranted: _isCallLogGranted,
          onRequest: () async {
            await _platform.requestCallLogPermission();
            await _refreshPermissions();
          },
        ),
        const SizedBox(height: 10),

        if (!isIos) ...[
          _buildPermissionTile(
            title: 'SMS Inbox & Phishing Scanner',
            subtitle: 'Detects fake bank fraud and malicious URL shorteners',
            icon: Icons.mark_chat_unread_rounded,
            isGranted: _isSmsGranted,
            onRequest: () async {
              await _platform.requestSmsPermission();
              await _refreshPermissions();
            },
          ),
          const SizedBox(height: 10),
        ],

        _buildPermissionTile(
          title: 'Contacts Whitelist',
          subtitle: 'Ensures your friends, family, and colleagues never get blocked',
          icon: Icons.contacts_rounded,
          isGranted: _isContactsGranted,
          onRequest: () async {
            await _platform.requestContactsPermission();
            await _refreshPermissions();
          },
        ),

        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: SignalLedgerTheme.cyan.withValues(alpha: 0.15),
            foregroundColor: SignalLedgerTheme.cyan,
            side: const BorderSide(color: SignalLedgerTheme.cyan),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.playlist_add_check_rounded),
          label: const Text('Request All Permissions', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () async {
            await _platform.requestCallLogPermission();
            await _platform.requestSmsPermission();
            await _platform.requestContactsPermission();
            await _refreshPermissions();
          },
        ),
      ],
    );
  }

  // ── Step 3: Default Call Screening Role ──
  Widget _buildCallScreeningStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.phone_paused_rounded, size: 54, color: SignalLedgerTheme.purple),
        const SizedBox(height: 16),
        const Text(
          'Enable Call Screening Role',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Allow CallShield to screen and silence spam calls before your phone even rings.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        SignalCard(
          padding: const EdgeInsets.all(16),
          borderColor: _isScreeningRoleGranted ? SignalLedgerTheme.green : SignalLedgerTheme.purple.withValues(alpha: 0.4),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_isScreeningRoleGranted ? SignalLedgerTheme.green : SignalLedgerTheme.purple)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isScreeningRoleGranted ? Icons.verified_rounded : Icons.shield_rounded,
                      color: _isScreeningRoleGranted ? SignalLedgerTheme.green : SignalLedgerTheme.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isScreeningRoleGranted ? 'Call Screening Active' : 'System Role Required',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          _isScreeningRoleGranted
                              ? 'Android CallScreeningService is enabled and protecting device.'
                              : 'Set CallShield as your Default Call Screening App in Android settings.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScreeningRoleGranted ? SignalLedgerTheme.green : SignalLedgerTheme.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await _platform.requestCallScreeningRole();
                    await _refreshPermissions();
                  },
                  child: Text(_isScreeningRoleGranted ? 'Role Granted ✓' : 'Set as Call Screener'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 4: Heads-Up & Notifications ──
  Widget _buildNotificationsStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.notifications_active_rounded, size: 54, color: SignalLedgerTheme.amber),
        const SizedBox(height: 16),
        const Text(
          'Threat Notifications & Alerts',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Receive instant silent notifications when spam is filtered or preview live risk scores for incoming callers.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        SignalCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: SignalLedgerTheme.red, size: 20),
                  SizedBox(width: 8),
                  Text('Example Block Alert', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SignalLedgerTheme.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gpp_bad_rounded, color: SignalLedgerTheme.red, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🚨 Blocked: +1 (809) 555-0199', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('High-risk Wangiri fraud dialer silenced automatically.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 5: Ready & Review ──
  Widget _buildReadyStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SignalLedgerTheme.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: SignalLedgerTheme.green.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.verified_user_rounded, size: 64, color: SignalLedgerTheme.green),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Shield is Ready',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'CallShield is fully initialized with 100,000+ spam signatures, GBDT machine learning models, and real-time screening protection.',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SignalCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildStatusRow('15-Layer Engine', 'Active', SignalLedgerTheme.green),
                const Divider(height: 16),
                _buildStatusRow('Offline Database', '100,000+ Hashes', SignalLedgerTheme.cyan),
                const Divider(height: 16),
                _buildStatusRow('GBDT ML Scorer', 'Pre-Loaded', SignalLedgerTheme.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return SignalCard(
      padding: const EdgeInsets.all(12),
      borderColor: isGranted ? SignalLedgerTheme.green.withValues(alpha: 0.4) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isGranted ? SignalLedgerTheme.green : Colors.grey).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGranted ? SignalLedgerTheme.green : Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle_rounded, color: SignalLedgerTheme.green, size: 22)
          else
            TextButton(
              onPressed: onRequest,
              child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
