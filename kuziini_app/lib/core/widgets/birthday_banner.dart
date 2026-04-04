import 'dart:js_util' as js_util;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/birthday_service.dart';
import 'confetti_widget.dart';

/// Persistent birthday banner — sits at the top of every screen.
/// Shows confetti + plays "La Multi Ani" melody once per day.
class BirthdayBanner extends ConsumerStatefulWidget {
  const BirthdayBanner({super.key});

  @override
  ConsumerState<BirthdayBanner> createState() => _BirthdayBannerState();
}

class _BirthdayBannerState extends ConsumerState<BirthdayBanner> {
  bool _showConfetti = false;
  bool _melodyPlayed = false;

  @override
  void initState() {
    super.initState();
    _checkAndPlayMelody();
  }

  Future<void> _checkAndPlayMelody() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'birthday_melody_${today.year}_${today.month}_${today.day}';
    if (prefs.getBool(key) == true) {
      _melodyPlayed = true;
      return;
    }
    // Will play after first frame when we know there are birthday users
    setState(() => _showConfetti = true);
  }

  void _playMelody() {
    if (_melodyPlayed) return;
    _melodyPlayed = true;
    _saveMelodyPlayed();
    _playLaMultiAniMelody();
  }

  Future<void> _saveMelodyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'birthday_melody_${today.year}_${today.month}_${today.day}';
    await prefs.setBool(key, true);
  }

  @override
  Widget build(BuildContext context) {
    final birthdayUsers = ref.watch(todayBirthdayUsersProvider);
    if (birthdayUsers.isEmpty) return const SizedBox.shrink();

    // Play melody on first build with birthday users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_melodyPlayed && birthdayUsers.isNotEmpty) {
        _playMelody();
      }
    });

    final names = birthdayUsers.map((u) => u.displayName).toList();
    final message = names.length == 1
        ? 'La Multi Ani, ${names.first}!'
        : 'La Multi Ani, ${names.join(' & ')}!';

    final theme = Theme.of(context);

    return Stack(
      children: [
        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFFA751), Color(0xFFFF6B9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎂', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('🎂', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -1, end: 0, duration: 500.ms, curve: Curves.easeOut),

        // Confetti
        if (_showConfetti)
          const Positioned.fill(
            child: ConfettiOverlay(duration: Duration(seconds: 5)),
          ),
      ],
    );
  }
}

// ── "La Multi Ani" melody using Web Audio API ──

void _playLaMultiAniMelody() {
  try {
    final global = js_util.globalThis;
    final ctxCtor = js_util.getProperty(global, 'AudioContext') ??
        js_util.getProperty(global, 'webkitAudioContext');
    if (ctxCtor == null) return;

    final audioCtx = js_util.callConstructor(ctxCtor, []);

    // "La Multi Ani" melody — note frequencies & durations (simplified, recognizable)
    // Notes: C D E F G A B in octave 5
    const notes = <_Note>[
      // "La mul-ti a-ni"
      _Note(523.25, 0.3), // C5
      _Note(523.25, 0.3), // C5
      _Note(587.33, 0.6), // D5
      _Note(523.25, 0.6), // C5
      _Note(698.46, 0.6), // F5
      _Note(659.25, 1.0), // E5
      // pause
      _Note(0, 0.2),
      // "La mul-ti a-ni"
      _Note(523.25, 0.3), // C5
      _Note(523.25, 0.3), // C5
      _Note(587.33, 0.6), // D5
      _Note(523.25, 0.6), // C5
      _Note(783.99, 0.6), // G5
      _Note(698.46, 1.0), // F5
      // pause
      _Note(0, 0.2),
      // "La mul-ti ani cu fe-ri-cire"
      _Note(523.25, 0.3), // C5
      _Note(523.25, 0.3), // C5
      _Note(1046.50, 0.6), // C6
      _Note(880.00, 0.6), // A5
      _Note(698.46, 0.6), // F5
      _Note(659.25, 0.6), // E5
      _Note(587.33, 1.0), // D5
      // pause
      _Note(0, 0.2),
      // "Mult-i ani cu sănă-ta-te"
      _Note(932.33, 0.3), // Bb5
      _Note(932.33, 0.3), // Bb5
      _Note(880.00, 0.6), // A5
      _Note(698.46, 0.6), // F5
      _Note(783.99, 0.6), // G5
      _Note(698.46, 1.2), // F5
    ];

    double startTime =
        (js_util.getProperty(audioCtx, 'currentTime') as num).toDouble() + 0.1;

    for (final note in notes) {
      if (note.freq > 0) {
        // Create oscillator
        final osc = js_util.callMethod(audioCtx, 'createOscillator', []);
        final gain = js_util.callMethod(audioCtx, 'createGain', []);
        final dest = js_util.getProperty(audioCtx, 'destination');

        // Set waveform to a softer sound
        js_util.setProperty(osc, 'type', 'sine');

        // Set frequency
        final freqParam = js_util.getProperty(js_util.getProperty(osc, 'frequency')!, 'value');
        js_util.setProperty(js_util.getProperty(osc, 'frequency')!, 'value', note.freq);

        // Set gain envelope (soft attack/release)
        final gainParam = js_util.getProperty(gain, 'gain')!;
        js_util.callMethod(gainParam, 'setValueAtTime', [0.0, startTime]);
        js_util.callMethod(gainParam, 'linearRampToValueAtTime', [0.15, startTime + 0.05]);
        js_util.callMethod(gainParam, 'linearRampToValueAtTime', [0.12, startTime + note.duration * 0.7]);
        js_util.callMethod(gainParam, 'linearRampToValueAtTime', [0.0, startTime + note.duration]);

        // Connect: osc → gain → destination
        js_util.callMethod(osc, 'connect', [gain]);
        js_util.callMethod(gain, 'connect', [dest]);

        // Schedule play
        js_util.callMethod(osc, 'start', [startTime]);
        js_util.callMethod(osc, 'stop', [startTime + note.duration + 0.05]);
      }
      startTime += note.duration;
    }
  } catch (_) {
    // Audio not supported — silently ignore
  }
}

class _Note {
  final double freq;
  final double duration;
  const _Note(this.freq, this.duration);
}

/// Animated rainbow border decoration for birthday week users
class BirthdayBorderWrapper extends StatefulWidget {
  const BirthdayBorderWrapper({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.strokeWidth = 2.5,
  });

  final Widget child;
  final double borderRadius;
  final double strokeWidth;

  @override
  State<BirthdayBorderWrapper> createState() => _BirthdayBorderWrapperState();
}

class _BirthdayBorderWrapperState extends State<BirthdayBorderWrapper>
    with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _RainbowBorderPainter(
          progress: _controller.value,
          borderRadius: widget.borderRadius,
          strokeWidth: widget.strokeWidth,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _RainbowBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double strokeWidth;

  _RainbowBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius),
    );

    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
      const Color(0xFF4D96FF),
      const Color(0xFFFF6BD6),
      const Color(0xFFA855F7),
      const Color(0xFFFF6B6B),
    ];

    final shader = SweepGradient(
      startAngle: progress * 2 * pi,
      endAngle: progress * 2 * pi + 2 * pi,
      colors: colors,
      tileMode: TileMode.repeated,
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RainbowBorderPainter old) => old.progress != progress;
}
