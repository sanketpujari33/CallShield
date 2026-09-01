import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../domain/models/call_recording_models.dart';
import '../../widgets/signal_card.dart';

class CallRecordingHubScreen extends StatefulWidget {
  const CallRecordingHubScreen({super.key});

  @override
  State<CallRecordingHubScreen> createState() => _CallRecordingHubScreenState();
}

class _CallRecordingHubScreenState extends State<CallRecordingHubScreen> {
  bool _autoRecordCalls = true;
  bool _autoTranscribe = true;
  bool _recordUnknownOnly = false;

  String? _currentlyPlayingId;
  bool _isPlaying = false;
  int _playbackProgressSeconds = 0;
  Timer? _playbackTimer;

  final List<CallRecording> _recordings = [
    CallRecording(
      id: 'rec_1',
      callerName: 'Food Delivery Courier',
      phoneNumber: '+91-81720 33604',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      durationSeconds: 42,
      filePath: '/storage/emulated/0/CallShield/Recordings/rec_20260830_1420.m4a',
      fileSizeFormatted: '840 KB',
      isIncoming: true,
      transcript: 'Driver: "Hello sir, I have arrived at the lobby reception with your biryani order."\nUser: "Great, please leave it with security desk, I will pick it up in 2 minutes."',
      waveform: [0.2, 0.5, 0.9, 0.7, 0.4, 0.8, 1.0, 0.6, 0.3, 0.7, 0.9, 0.4, 0.2],
    ),
    CallRecording(
      id: 'rec_2',
      callerName: 'Amazon Customer Support',
      phoneNumber: '+1 (212) 555-0144',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      durationSeconds: 95,
      filePath: '/storage/emulated/0/CallShield/Recordings/rec_20260829_0915.m4a',
      fileSizeFormatted: '1.9 MB',
      isIncoming: true,
      transcript: 'Support: "Thank you for contacting Amazon Logistics. Your replacement package has been dispatched under tracking number AMZ-94819."\nUser: "Thank you for the quick resolution!"',
      waveform: [0.3, 0.6, 0.8, 0.5, 0.9, 0.4, 0.7, 0.8, 0.6, 0.3, 0.7, 0.5, 0.2],
    ),
    CallRecording(
      id: 'rec_3',
      callerName: 'Auto Warranty Sales Pitch',
      phoneNumber: '+1 (888) 444-0123',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      durationSeconds: 28,
      filePath: '/storage/emulated/0/CallShield/Recordings/rec_20260828_1730.m4a',
      fileSizeFormatted: '560 KB',
      isIncoming: true,
      transcript: 'Robocall: "We have been trying to reach you regarding your vehicle warranty that is expiring..." [Flagged as unsolicited telemarketing by CallShield AI]',
      waveform: [0.1, 0.3, 0.6, 0.8, 0.9, 0.9, 0.7, 0.4, 0.2, 0.1],
    ),
  ];

  void _togglePlayback(CallRecording recording) {
    if (_currentlyPlayingId == recording.id && _isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      _playbackTimer?.cancel();
      setState(() {
        _currentlyPlayingId = recording.id;
        _isPlaying = true;
        _playbackProgressSeconds = 0;
      });

      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_playbackProgressSeconds < recording.durationSeconds) {
            _playbackProgressSeconds++;
          } else {
            _isPlaying = false;
            _playbackProgressSeconds = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  void _showTranscript(CallRecording recording) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recording.callerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  recording.durationFormatted,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              recording.phoneNumber,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI SPEECH TRANSCRIPT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1, color: SignalLedgerTheme.cyan),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                recording.transcript,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Export Audio'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exporting ${recording.fileSizeFormatted} audio file...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Recording Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Card ──
            SignalCard(
              padding: const EdgeInsets.all(18),
              borderColor: SignalLedgerTheme.purple.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SignalLedgerTheme.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mic_rounded, color: SignalLedgerTheme.purple, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'In-App Call Recording',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record incoming & outgoing calls with automated AI transcripts and waveform playback.',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Recording Controls ──
            const Text(
              'CALL RECORDING PREFERENCES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            SignalCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto-Record All Calls', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Seamlessly capture both sides of incoming and outgoing calls', style: TextStyle(fontSize: 12)),
                    value: _autoRecordCalls,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => setState(() => _autoRecordCalls = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Generate AI Speech Transcripts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Converts recorded audio to text on-device for easy searching', style: TextStyle(fontSize: 12)),
                    value: _autoTranscribe,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => setState(() => _autoTranscribe = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Record Unknown Numbers Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Skip recording calls from your saved contact list', style: TextStyle(fontSize: 12)),
                    value: _recordUnknownOnly,
                    activeThumbColor: SignalLedgerTheme.cyan,
                    onChanged: (val) => setState(() => _recordUnknownOnly = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Recorded Calls List ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECORDED CALLS (${_recordings.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                ),
                Text(
                  '3.3 MB Storage Used',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._recordings.map((recording) {
              final isCurrent = _currentlyPlayingId == recording.id;
              final isPlayingThis = isCurrent && _isPlaying;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SignalCard(
                  padding: const EdgeInsets.all(14),
                  borderColor: isPlayingThis ? SignalLedgerTheme.cyan : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Play/Pause button + Name/Phone + Duration
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlayingThis ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                              color: SignalLedgerTheme.cyan,
                              size: 38,
                            ),
                            onPressed: () => _togglePlayback(recording),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recording.callerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${recording.phoneNumber} • ${recording.fileSizeFormatted}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isPlayingThis
                                    ? '${_formatDuration(_playbackProgressSeconds)} / ${recording.durationFormatted}'
                                    : recording.durationFormatted,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _showTranscript(recording),
                                child: const Text(
                                  'Transcript',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: SignalLedgerTheme.cyan,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Waveform visualizer bar
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: recording.waveform.map((bar) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                height: 28 * bar,
                                decoration: BoxDecoration(
                                  color: isPlayingThis
                                      ? SignalLedgerTheme.cyan.withValues(alpha: 0.8)
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
