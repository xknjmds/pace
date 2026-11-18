import 'package:flutter/material.dart';

/// The PACE wordmark, drawn from the master geometry in
/// branding/archive/cairn/final/pace-wordmark.svg (four round-capped strokes). It is
/// constructed, never typed in a font.
class PaceWordmark extends StatelessWidget {
  const PaceWordmark({super.key, this.height = 20, this.color});

  /// Cap height of the letters.
  final double height;
  final Color? color;

  // Visible bounds of the master, stroke included.
  static const _left = 0.0, _top = 64.0, _w = 559.0, _h = 139.0;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return Semantics(
      label: 'PACE',
      child: CustomPaint(
        size: Size(height * _w / _h, height),
        painter: _WordmarkPainter(c),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height / PaceWordmark._h;
    canvas
      ..save()
      ..scale(k)
      ..translate(-PaceWordmark._left, -PaceWordmark._top);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // P
    final p = Path()
      ..moveTo(11, 192)
      ..lineTo(11, 75)
      ..lineTo(60, 75)
      ..arcToPoint(const Offset(60, 141), radius: const Radius.circular(33))
      ..lineTo(11, 141);
    // A
    final a = Path()
      ..moveTo(153, 192)
      ..lineTo(201.46, 75)
      ..lineTo(249.93, 192)
      ..moveTo(170.40, 150)
      ..lineTo(232.53, 150);
    // C
    final cPath = Path()
      ..moveTo(408.35, 91.07)
      ..arcToPoint(
        const Offset(408.35, 175.93),
        radius: const Radius.circular(60),
        largeArc: true,
        clockwise: false,
      );
    // E
    final e = Path()
      ..moveTo(547.93, 75)
      ..lineTo(481.93, 75)
      ..lineTo(481.93, 192)
      ..lineTo(547.93, 192)
      ..moveTo(481.93, 133.5)
      ..lineTo(535.93, 133.5);
    for (final path in [p, a, cPath, e]) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) => old.color != color;
}
