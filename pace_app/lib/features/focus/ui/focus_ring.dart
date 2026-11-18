import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/pace_tokens.dart';

/// A round progress track for the focus timer. Each second's step glides
/// over 240 ms instead of jumping; with reduced motion it simply jumps.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 248,
    this.color,
  });

  /// 0 = just started, 1 = time is up.
  final double progress;
  final Widget child;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = PaceMotion.of(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0, 1)),
        duration: motion.reduced ? Duration.zero : PaceMotion.standard,
        curve: PaceMotion.easeOut,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(
            value: value,
            color: color ?? scheme.primary,
            track: scheme.surfaceContainerHigh,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
