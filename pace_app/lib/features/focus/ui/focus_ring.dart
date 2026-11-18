import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';

/// A visual timer: a soft sky disc whose remaining-time wedge empties
/// clockwise, with the digits on a plate in the middle. Each second's step
/// glides over 240 ms; with reduced motion it simply jumps.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 248,
  });

  /// 0 = just started, 1 = time is up.
  final double progress;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pastel = PacePastels.of(context).focus;
    final motion = PaceMotion.of(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0, 1)),
        duration: motion.reduced ? Duration.zero : PaceMotion.standard,
        curve: PaceMotion.easeOut,
        builder: (context, value, child) => CustomPaint(
          painter: _PiePainter(
            remaining: 1 - value,
            disc: pastel.fill,
            wedge: Color.lerp(pastel.fill, pastel.ink, .32)!,
            plate: scheme.surface,
          ),
          child: child,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: size * .62,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.remaining,
    required this.disc,
    required this.wedge,
    required this.plate,
  });

  final double remaining;
  final Color disc;
  final Color wedge;
  final Color plate;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = disc);
    if (remaining > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        math.pi * 2 * remaining,
        true,
        Paint()..color = wedge,
      );
    }
    canvas.drawCircle(c, r * .66, Paint()..color = plate);
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.remaining != remaining ||
      old.disc != disc ||
      old.wedge != wedge ||
      old.plate != plate;
}
