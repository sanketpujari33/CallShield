import 'package:flutter/material.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../widgets/signal_card.dart';

class AppMessengerShieldScreen extends StatefulWidget {
  const AppMessengerShieldScreen({super.key});

  @override
  State<AppMessengerShieldScreen> createState() => _AppMessengerShieldScreenState();
}

class _AppMessengerShieldScreenState extends State<AppMessengerShieldScreen> {
  bool _whatsAppCallShield = true;
  bool _whatsAppChatShield = true;
  bool _telegramCallShield = true;
  bool _viberShield = true;
  bool _autoBlockInternationalSpam = true;

  void _testWhatsAppCallOverlay() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 24),
            SizedBox(width: 10),
            Text(
              'WhatsApp Call Overlay',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gpp_bad_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'WhatsApp Audio Call',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '+92 300 8491029 • International VoIP',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🚨 HIGH-RISK SCAM CALL: Reported as lottery scam & fake WhatsApp verification takeover by 2,140 users.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caller Blocked & Reported to CallShield Cloud!')),
              );
            },
            child: const Text('Block Number'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp & Messenger Shield'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Card ──
            SignalCard(
              padding: const EdgeInsets.all(18),
              borderColor: const Color(0xFF25D366).withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF25D366), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OTT App Protection',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Identify unknown callers and scam texts on WhatsApp, Telegram, and Viber with live overlays.',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Test Banner Simulation ──
            SignalCard(
              padding: const EdgeInsets.all(14),
              onTap: _testWhatsAppCallOverlay,
              child: const Row(
                children: [
                  Icon(Icons.visibility_rounded, color: Color(0xFF25D366), size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview WhatsApp Call Overlay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Simulate live scam banner on incoming WhatsApp call', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Protected Apps ──
            const Text(
              'PROTECTED MESSENGERS & VOIP APPS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            SignalCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                    title: const Text('WhatsApp Call Shield', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Show Caller ID overlay for unknown WhatsApp audio/video calls', style: TextStyle(fontSize: 12)),
                    value: _whatsAppCallShield,
                    activeThumbColor: const Color(0xFF25D366),
                    onChanged: (val) => setState(() => _whatsAppCallShield = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366)),
                    title: const Text('WhatsApp Unknown Message Scanner', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Intercept phishing links & crypto scam pitches in unknown chats', style: TextStyle(fontSize: 12)),
                    value: _whatsAppChatShield,
                    activeThumbColor: const Color(0xFF25D366),
                    onChanged: (val) => setState(() => _whatsAppChatShield = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.send_rounded, color: Color(0xFF2AABEE)),
                    title: const Text('Telegram Call & Channel Shield', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Identify suspicious Telegram bot calls and fraud campaigns', style: TextStyle(fontSize: 12)),
                    value: _telegramCallShield,
                    activeThumbColor: const Color(0xFF2AABEE),
                    onChanged: (val) => setState(() => _telegramCallShield = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF7360F2)),
                    title: const Text('Viber Call Screener', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Real-time caller reputation verification on Viber', style: TextStyle(fontSize: 12)),
                    value: _viberShield,
                    activeThumbColor: const Color(0xFF7360F2),
                    onChanged: (val) => setState(() => _viberShield = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Advanced OTT Rules ──
            const Text(
              'THREAT INTERCEPTION SETTINGS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            SignalCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SwitchListTile(
                title: const Text('Auto-Mute Unknown International VoIP Calls', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Silences WhatsApp/Telegram calls from unfamiliar country codes (+92, +234, +7)', style: TextStyle(fontSize: 12)),
                value: _autoBlockInternationalSpam,
                activeThumbColor: SignalLedgerTheme.cyan,
                onChanged: (val) => setState(() => _autoBlockInternationalSpam = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
