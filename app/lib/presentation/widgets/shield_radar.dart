import 'package:flutter/material.dart';
import '../../core/theme/signal_ledger_theme.dart';

class ShieldRadar extends StatefulWidget {
  final bool isActive;
  final double size;

  const ShieldRadar({
    super.key,
    required this.isActive,
    this.size = 140,
  });

  @override
  State<ShieldRadar> createState() => _ShieldRadarState();
}

class _ShieldRadarState extends State<ShieldRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isActive ? SignalLedgerTheme.cyan : SignalLedgerTheme.darkTextMuted;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RadarPulsePainter(
                    progress: _controller.value,
                    color: SignalLedgerTheme.cyan,
                  ),
                );
              },
            ),
          Container(
            width: widget.size * 0.62,
            height: widget.size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isActive
                  ? SignalLedgerTheme.cyan.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: SignalLedgerTheme.cyan.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                widget.isActive ? Icons.shield_rounded : Icons.shield_outlined,
                size: widget.size * 0.34,
                color: activeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarPulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 2; i++) {
      final p = (progress + (i * 0.5)) % 1.0;
      final radius = (size.width * 0.31) + (maxRadius - size.width * 0.31) * p;
      final opacity = (1.0 - p).clamp(0.0, 1.0) * 0.4;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
