import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../data/identity/caller_identity_service.dart';
import '../../../domain/models/caller_identity_models.dart';
import '../../widgets/caller_details_sheet.dart';
import '../../widgets/incoming_call_overlay.dart';

class IncomingCallSimulatorScreen extends StatefulWidget {
  final CallerIdentity? initialCaller;

  const IncomingCallSimulatorScreen({super.key, this.initialCaller});

  @override
  State<IncomingCallSimulatorScreen> createState() => _IncomingCallSimulatorScreenState();
}

class _IncomingCallSimulatorScreenState extends State<IncomingCallSimulatorScreen>
    with SingleTickerProviderStateMixin {
  late CallerIdentity _currentCaller;
  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentCaller = widget.initialCaller ?? CallerIdentityService.presets.first;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _acceptCall() {
    setState(() {
      _isCallActive = true;
      _callDurationSeconds = 0;
    });
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _declineCall({bool blocked = false}) {
    _callTimer?.cancel();
    final wasActive = _isCallActive;
    setState(() {
      _isCallActive = false;
      _callDurationSeconds = 0;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            blocked
                ? 'Call Blocked & Terminated.'
                : wasActive
                    ? 'Call Ended.'
                    : 'Call Declined.',
          ),
          backgroundColor: blocked ? SignalLedgerTheme.red : SignalLedgerTheme.darkSurface,
        ),
      );
    }
  }

  void _switchCaller(CallerIdentity caller) {
    _callTimer?.cancel();
    setState(() {
      _currentCaller = caller;
      _isCallActive = false;
      _callDurationSeconds = 0;
    });
  }

  void _promptCustomNumber() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Custom Number Overlay'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter phone number (e.g. +18005550199)',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final resolved = CallerIdentityService.instance.resolve(text);
                _switchCaller(resolved);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simulate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1015), // Deep OLED phone background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Incoming Call Simulator',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dialpad_rounded, color: Colors.white),
            tooltip: 'Enter Custom Number',
            onPressed: _promptCustomNumber,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scenario Quick Picker Ribbon ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: CallerIdentityService.presets.map((preset) {
                final isSelected = preset.rawNumber == _currentCaller.rawNumber;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(preset.name),
                    selected: isSelected,
                    onSelected: (_) => _switchCaller(preset),
                    selectedColor: _getChipColor(preset.type),
                    backgroundColor: const Color(0xFF1F2029),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Background Phone Call View ──
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Dynamic Island / Top status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isCallActive
                            ? 'Connected • ${_formatDuration(_callDurationSeconds)}'
                            : 'Incoming Call...',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentCaller.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentCaller.formattedNumber,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),

                    // ── Heads-Up Overlay Banner floating on screen ──
                    if (!_isCallActive)
                      IncomingCallOverlay(
                        caller: _currentCaller,
                        onClose: () => _declineCall(),
                        onViewDetails: () => CallerDetailsSheet.show(context, _currentCaller),
                      ),

                    const Spacer(),

                    // ── Bottom Call Action Buttons (Decline & Accept) ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 48, left: 36, right: 36),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Decline / End Button
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _declineCall(),
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent,
                                        blurRadius: 16,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),

                          // Accept / Speaker Button
                          if (!_isCallActive)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _acceptCall,
                                  child: AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00C853),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.greenAccent.withValues(
                                                alpha: 0.4 + (_pulseController.value * 0.4),
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 2 + (_pulseController.value * 4),
                                            ),
                                          ],
                                        ),
                                        child: child,
                                      );
                                    },
                                    child: const Icon(
                                      Icons.call_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Accept', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            )
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Speaker', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getChipColor(CallerType type) {
    switch (type) {
      case CallerType.verifiedDelivery:
        return const Color(0xFF00A843);
      case CallerType.verifiedBusiness:
        return const Color(0xFF00897B);
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

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
