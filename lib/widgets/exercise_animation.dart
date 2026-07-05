import 'dart:math';
import 'package:flutter/material.dart';

/// Movement patterns used to animate the exercise icon — grouped by
/// how the body moves during the rep, not by exact biomechanics.
enum MotionPattern { press, pull, squat, curl, hold, dynamic }

/// Maps an exercise to a motion pattern based on its name/muscle
/// group, so every exercise gets a fitting animation without needing
/// per-exercise custom data.
MotionPattern motionPatternFor(String exerciseName, String muscleGroup) {
  final name = exerciseName.toLowerCase();
  if (name.contains('plank') || name.contains('hold')) {
    return MotionPattern.hold;
  }
  if (name.contains('curl') || name.contains('dip')) return MotionPattern.curl;
  if (name.contains('squat') ||
      name.contains('lunge') ||
      name.contains('press') && muscleGroup == 'Legs') {
    return MotionPattern.squat;
  }
  if (name.contains('pull') ||
      name.contains('row') ||
      name.contains('deadlift')) {
    return MotionPattern.pull;
  }
  if (name.contains('burpee') ||
      name.contains('swing') ||
      name.contains('mountain') ||
      name.contains('twist')) {
    return MotionPattern.dynamic;
  }
  if (muscleGroup == 'Chest' || muscleGroup == 'Shoulders') {
    return MotionPattern.press;
  }
  return MotionPattern.press;
}

/// A premium, glowing, looping motion graphic representing an
/// exercise's rep pattern — built entirely with Flutter animations
/// (no video/image assets required). Pair with the "Watch Video Demo"
/// button for an accurate real-world reference.
class ExerciseAnimation extends StatefulWidget {
  final IconData icon;
  final Color color;
  final MotionPattern pattern;
  final double size;

  const ExerciseAnimation({
    super.key,
    required this.icon,
    required this.color,
    required this.pattern,
    this.size = 180,
  });

  @override
  State<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends State<ExerciseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value; // 0.0 -> 1.0 looping
          final wave = sin(t * 2 * pi); // -1 -> 1 smooth cycle
          final wave01 = (wave + 1) / 2; // 0 -> 1

          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow rings
              _GlowRing(color: widget.color, phase: t, scale: 1.0),
              _GlowRing(
                  color: widget.color, phase: (t + 0.33) % 1.0, scale: 0.85),
              _GlowRing(
                  color: widget.color, phase: (t + 0.66) % 1.0, scale: 0.7),

              // Motion trail (ghost copies fading behind main icon)
              ..._buildTrail(wave01),

              // Main animated icon
              Transform.translate(
                offset: _translationFor(widget.pattern, wave, wave01),
                child: Transform.rotate(
                  angle: _rotationFor(widget.pattern, wave),
                  child: Transform.scale(
                    scale: _scaleFor(widget.pattern, wave01),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [widget.color, widget.color.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTrail(double wave01) {
    if (widget.pattern == MotionPattern.hold) return const [];
    return List.generate(3, (i) {
      final delay = (i + 1) * 0.08;
      final t = (_controller.value - delay) % 1.0;
      final w = (sin(t * 2 * pi) + 1) / 2;
      return Opacity(
        opacity: 0.12 - i * 0.03,
        child: Transform.translate(
          offset: _translationFor(widget.pattern, sin(t * 2 * pi), w),
          child: Container(
            width: 60,
            height: 60,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
        ),
      );
    });
  }

  Offset _translationFor(MotionPattern pattern, double wave, double wave01) {
    switch (pattern) {
      case MotionPattern.press:
        return Offset(0, wave * 22); // vertical press up/down
      case MotionPattern.pull:
        return Offset(0, -wave * 20); // pull down/up
      case MotionPattern.squat:
        return Offset(0, wave01 * 26); // dip down and back up
      case MotionPattern.curl:
        return const Offset(0, 0);
      case MotionPattern.hold:
        return Offset(
            0, sin(_controller.value * 2 * pi) * 3); // subtle breathing
      case MotionPattern.dynamic:
        return Offset(wave * 14, -wave01 * 24); // explosive diagonal bounce
    }
  }

  double _rotationFor(MotionPattern pattern, double wave) {
    switch (pattern) {
      case MotionPattern.curl:
        return wave * 0.5; // arm curl rotation
      case MotionPattern.dynamic:
        return wave * 0.25;
      default:
        return 0;
    }
  }

  double _scaleFor(MotionPattern pattern, double wave01) {
    switch (pattern) {
      case MotionPattern.squat:
        return 1.0 - wave01 * 0.12; // compress on the way down
      case MotionPattern.hold:
        return 1.0 + sin(_controller.value * 2 * pi) * 0.02; // breathing pulse
      default:
        return 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _GlowRing extends StatelessWidget {
  final Color color;
  final double phase; // 0 -> 1
  final double scale;

  const _GlowRing(
      {required this.color, required this.phase, required this.scale});

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - phase) * 0.35;
    final size = 90 + phase * 90 * scale;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
