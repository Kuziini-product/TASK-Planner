import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight confetti animation using CustomPainter
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.duration = const Duration(seconds: 6)});
  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiPiece> _pieces;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _pieces = List.generate(80, (_) => _ConfettiPiece(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              pieces: _pieces,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double x; // 0..1 horizontal position
  final double speed; // fall speed multiplier
  final double size;
  final double drift; // horizontal drift
  final double rotationSpeed;
  final Color color;
  final double delay; // 0..0.3 start delay

  _ConfettiPiece(Random r)
      : x = r.nextDouble(),
        speed = 0.5 + r.nextDouble() * 0.8,
        size = 4 + r.nextDouble() * 6,
        drift = (r.nextDouble() - 0.5) * 0.3,
        rotationSpeed = r.nextDouble() * 4,
        delay = r.nextDouble() * 0.3,
        color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFFFF6B6B), // red
    Color(0xFFFFD93D), // yellow
    Color(0xFF6BCB77), // green
    Color(0xFF4D96FF), // blue
    Color(0xFFFF6BD6), // pink
    Color(0xFFFF9F43), // orange
    Color(0xFFA855F7), // purple
    Color(0xFF00D2FF), // cyan
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out in the last 30%
    final opacity = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;
    if (opacity <= 0) return;

    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1.0 - piece.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final px = piece.x * size.width + sin(t * piece.rotationSpeed * pi) * piece.drift * size.width;
      final py = -piece.size + t * (size.height + piece.size * 2) * piece.speed;

      if (py < -piece.size || py > size.height + piece.size) continue;

      final paint = Paint()
        ..color = piece.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(t * piece.rotationSpeed * pi);

      // Draw small rectangles (confetti shape)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
