import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../domain/models/assistant_screener_models.dart';
import '../../widgets/signal_card.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  AssistantPersona _selectedPersona = AssistantPersona.friendly;
  bool _autoScreenSpam = true;
  bool _autoScreenUnknown = true;
  bool _recordTranscripts = true;

  // Simulator state
  bool _isScreeningActive = false;
  List<TranscriptMessage> _transcript = [];
  Timer? _simulationTimer;
  int _step = 0;

  void _startSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _isScreeningActive = true;
      _step = 0;
      _transcript = [
        TranscriptMessage(
          speaker: ScreenerSpeaker.system,
          text: 'Incoming Call from +1 (800) 555-0199 (Suspected Unknown Caller). AI Screener answering...',
          timestamp: DateTime.now(),
        ),
      ];
    });

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (!mounted) return;
      setState(() {
        _step++;
        if (_step == 1) {
          _transcript.add(
            TranscriptMessage(
              speaker: ScreenerSpeaker.assistant,
              text: 'Hello! I am the CallShield AI Assistant. The person you called is currently unavailable. May I ask who is calling and what this is regarding?',
              timestamp: DateTime.now(),
            ),
          );
        } else if (_step == 2) {
          _transcript.add(
            TranscriptMessage(
              speaker: ScreenerSpeaker.caller,
              text: 'Hi there, this is Marcus from Solar Green Energy. We are calling to check if you qualify for zero-cost home solar panels...',
              timestamp: DateTime.now(),
            ),
          );
        } else if (_step == 3) {
          _transcript.add(
            TranscriptMessage(
              speaker: ScreenerSpeaker.system,
              text: '⚡ AI Detection: Commercial telemarketing solicitation pitch detected (94% confidence).',
              timestamp: DateTime.now(),
            ),
          );
          timer.cancel();
        }
      });
    });
  }

  void _sendAssistantPrompt(String promptText, String replyText) {
    setState(() {
      _transcript.add(
        TranscriptMessage(
          speaker: ScreenerSpeaker.assistant,
          text: promptText,
          timestamp: DateTime.now(),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _transcript.add(
            TranscriptMessage(
              speaker: ScreenerSpeaker.caller,
              text: replyText,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  void _endCall({required bool blocked}) {
    _simulationTimer?.cancel();
    setState(() {
      _isScreeningActive = false;
      _transcript.add(
        TranscriptMessage(
          speaker: ScreenerSpeaker.system,
          text: blocked ? '🚫 Call terminated by user. Caller added to Blocklist.' : '✅ Call accepted and connected to user voice line.',
          timestamp: DateTime.now(),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(blocked ? 'Call Terminated & Blocked.' : 'Call Picked Up!'),
        backgroundColor: blocked ? SignalLedgerTheme.red : SignalLedgerTheme.green,
      ),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CallShield AI Assistant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner ──
            SignalCard(
              padding: const EdgeInsets.all(18),
              borderColor: SignalLedgerTheme.cyan.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SignalLedgerTheme.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: SignalLedgerTheme.cyan, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call Screening by AI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let AI answer unknown callers, transcribe the reason in real-time, and protect your focus.',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Live Simulator Sandbox ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LIVE CALL SCREENING SIMULATOR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                ),
                TextButton.icon(
                  onPressed: _startSimulation,
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: const Text('Test Simulation'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              height: 260,
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF14181D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isScreeningActive ? SignalLedgerTheme.cyan : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: _transcript.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.record_voice_over_rounded, size: 40, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap "Test Simulation" to watch AI Screen a live incoming call in real time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transcript.length,
                      itemBuilder: (context, index) {
                        final msg = _transcript[index];
                        if (msg.speaker == ScreenerSpeaker.system) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: Text(
                                msg.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ),
                          );
                        }
                        final isAssistant = msg.speaker == ScreenerSpeaker.assistant;
                        return Align(
                          alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAssistant
                                  ? SignalLedgerTheme.cyan.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAssistant
                                    ? SignalLedgerTheme.cyan.withValues(alpha: 0.4)
                                    : Colors.white24,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isAssistant ? '🤖 AI Assistant' : '👤 Caller (+1-800-555-0199)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAssistant ? SignalLedgerTheme.cyan : Colors.amberAccent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  msg.text,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isScreeningActive) ...[
              const SizedBox(height: 12),
              // Quick action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.help_outline_rounded, size: 14),
                    label: const Text('Ask details', style: TextStyle(fontSize: 11)),
                    onPressed: () => _sendAssistantPrompt(
                      'Could you please clarify what company you are representing?',
                      'Sure, this is Solar Green national branch.',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.alarm_off_rounded, size: 14),
                    label: const Text('I am busy', style: TextStyle(fontSize: 11)),
                    onPressed: () => _sendAssistantPrompt(
                      'The recipient is in a conference right now and asked you to call back later.',
                      'Understood, thank you. We will call back.',
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: SignalLedgerTheme.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 14),
                    label: const Text('Pick Up', style: TextStyle(fontSize: 11, color: Colors.black)),
                    onPressed: () => _endCall(blocked: false),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: SignalLedgerTheme.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.block_rounded, size: 14),
                    label: const Text('Block Call', style: TextStyle(fontSize: 11)),
                    onPressed: () => _endCall(blocked: true),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ── Persona Selector ──
            const Text(
              'ASSISTANT VOICE & PERSONA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            ...AssistantPersona.values.map((persona) {
              final isSelected = _selectedPersona == persona;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SignalCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderColor: isSelected ? SignalLedgerTheme.cyan : null,
                  onTap: () => setState(() => _selectedPersona = persona),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? SignalLedgerTheme.cyan : Colors.grey,
                            width: 2,
                          ),
                          color: isSelected ? SignalLedgerTheme.cyan : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.black)
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(persona.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(persona.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── Automation Rules ──
            const Text(
              'AUTOMATIC SCREENING RULES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            SignalCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Screen Suspected Spam Calls', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Let AI automatically challenge callers with high threat scores', style: TextStyle(fontSize: 12)),
                    value: _autoScreenSpam,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => setState(() => _autoScreenSpam = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Screen All Unknown Numbers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Ask any non-contact caller for their name and purpose before ringing', style: TextStyle(fontSize: 12)),
                    value: _autoScreenUnknown,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => setState(() => _autoScreenUnknown = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Save Speech Transcripts to Activity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Archive conversation text for future lookup and threat auditing', style: TextStyle(fontSize: 12)),
                    value: _recordTranscripts,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => setState(() => _recordTranscripts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
