import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../mascot/tuck_pose.dart';
import '../theme/pace_tokens.dart';

export '../mascot/tuck_pose.dart';

/// Tuck the turtle, PACE's mascot, in one of its [TuckPose]s.
///
/// Tuck is quietly alive: a slow breath, a small sway, the odd blink, and a
/// few pose-specific touches. All of it is small enough to notice only if you
/// look. With reduced motion Tuck is a still image; in low-energy mode only
/// the slow breath stays. Tapping Tuck gets a small squash and a blink, and
/// does nothing else.
class Tuck extends StatefulWidget {
  const Tuck({
    super.key,
    this.pose = TuckPose.idle,
    this.size = 120,
    this.random,
    this.greet = false,
  });

  final TuckPose pose;

  /// Width and height of the square frame. Tuck's feet sit near its bottom.
  final double size;

  /// For deterministic blink timing in tests.
  final math.Random? random;

  /// Says hello once it has settled in: the tap squash and a blink, with no
  /// haptic. Used by the splash hand-off.
  final bool greet;

  /// Turned off for the whole test suite in `test/flutter_test_config.dart`,
  /// because a living loop would keep `pumpAndSettle` from ever settling.
  @visibleForTesting
  static bool debugLifeMotion = true;

  static String asset(TuckPose pose) => 'assets/mascot/tuck_${pose.file}.png';
  static const blinkAsset = 'assets/mascot/tuck_blink.png';

  @override
  State<Tuck> createState() => _TuckState();
}

class _TuckState extends State<Tuck> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final _t = ValueNotifier<double>(0); // seconds since Tuck appeared
  late math.Random _rng;

  double _nextBlink = 0;
  double? _blinkAt;
  bool _doubleBlink = false;
  double _poseAt = 0; // when the current pose arrived
  double? _tapAt;
  bool _firstPose = true;

  @override
  void initState() {
    super.initState();
    _rng = widget.random ?? math.Random();
    _nextBlink = 2 + _rng.nextDouble() * 3;
    if (widget.greet) {
      // Lands just as the entrance settles (it ends at .42 s).
      _tapAt = .36;
      _blinkAt = .44;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage(Tuck.asset(widget.pose)), context);
    if (widget.pose == TuckPose.idle) {
      precacheImage(const AssetImage(Tuck.blinkAsset), context);
    }
    final reduced = PaceMotion.of(context).reduced;
    if (reduced || !Tuck.debugLifeMotion) {
      _ticker?.dispose();
      _ticker = null;
    } else {
      _ticker ??= createTicker(_tick)..start();
    }
  }

  @override
  void didUpdateWidget(Tuck old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) {
      _poseAt = _t.value;
      _firstPose = false;
      _blinkAt = null;
      precacheImage(AssetImage(Tuck.asset(widget.pose)), context);
    }
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (t >= _nextBlink) {
      _blinkAt = t;
      _doubleBlink = _rng.nextInt(6) == 0;
      _nextBlink = t + 3 + _rng.nextDouble() * 4;
    }
    _t.value = t;
  }

  void _onTap() {
    if (_ticker == null) return;
    _tapAt = _t.value;
    _blinkAt = _t.value + .08;
    _doubleBlink = false;
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = widget.pose;
    final size = widget.size;
    Widget image() => AnimatedSwitcher(
      duration: PaceMotion.standard,
      switchInCurve: PaceMotion.easeOut,
      child: _ImageFor(
        key: ValueKey(pose),
        pose: pose,
        size: size,
        closed: pose == TuckPose.idle && _blinking(),
      ),
    );

    Widget body;
    if (_ticker == null) {
      body = image();
    } else {
      final calm = PaceMotion.of(context).calm;
      body = AnimatedBuilder(
        animation: _t,
        builder: (context, _) => _alive(context, _t.value, calm, image()),
      );
    }

    return Semantics(
      label: 'Tuck the turtle',
      image: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _onTap,
        child: RepaintBoundary(
          child: SizedBox.square(dimension: size, child: body),
        ),
      ),
    );
  }

  bool _blinking() {
    final b = _blinkAt;
    if (b == null || _ticker == null) return false;
    final dt = _t.value - b;
    if (dt >= 0 && dt < .12) return true;
    return _doubleBlink && dt >= .26 && dt < .38;
  }

  Widget _alive(BuildContext context, double t, bool calm, Widget image) {
    final pose = widget.pose;
    final unit = widget.size / 160; // offsets are tuned at 160 px
    const tau = 2 * math.pi;

    // Breath: the shell rises and settles, anchored at the feet.
    final breathPeriod = switch (pose) {
      TuckPose.resting || TuckPose.evening => 6.0,
      TuckPose.focus => 5.0,
      _ => calm ? 6.0 : 3.6,
    };
    final breath = (1 - math.cos(tau * t / breathPeriod)) / 2; // 0..1
    var sy = 1 + .018 * breath;
    var sx = 1 - .005 * breath;
    var angle = 0.0;
    var dx = 0.0;
    var dy = 0.0;
    var opacity = 1.0;

    if (!calm) {
      // Idle sway, out of phase with the breath so it never looks mechanical.
      angle += .8 * math.pi / 180 * math.sin(tau * t / 7 + 1.3);

      switch (pose) {
        case TuckPose.leaving:
          final w = math.sin(tau * t / 1.2);
          angle += 1.5 * math.pi / 180 * w;
          dx += 1.5 * unit * w;
        case TuckPose.note:
          dy += -2 * unit * (1 - math.cos(tau * t / 2.8)) / 2;
        default:
      }

      // Entrance: settle in from a little lower with a soft overshoot.
      if (_firstPose && t < .42) {
        final e = Curves.easeOutBack.transform((t / .42).clamp(0, 1));
        dy += 6 * unit * (1 - e);
        opacity = (t / .24).clamp(0, 1);
      }

      // Pose change: a small hop.
      final sincePose = t - _poseAt;
      if (!_firstPose && sincePose < .3) {
        dy -= 4 * unit * math.sin(math.pi * sincePose / .3);
      }

      final shown = t - (_firstPose ? 0 : _poseAt);
      if (pose == TuckPose.morning && shown < .7) {
        // A wake-up stretch on arrival.
        sy *= 1 + .03 * math.sin(tau * shown / .7) * (1 - shown / .7);
      }
      if (pose == TuckPose.proud && shown < .5) {
        dy -= 5 * unit * math.sin(math.pi * shown / .5);
      }
    }

    // Tap: a small squash, then a soft recover.
    final tap = _tapAt;
    if (tap != null && t - tap < .28) {
      final p = (t - tap) / .28;
      final s = p < .35
          ? 1 - .04 * (p / .35)
          : .96 +
                .07 * math.sin(math.pi * (p - .35) / .65) +
                .04 * ((p - .35) / .65);
      sx *= s;
      sy *= 2 - s;
    }

    final overlays = calm ? const <Widget>[] : _overlays(t, unit);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(sx, sy, 1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: image),
                ...overlays,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Small extras drawn in Flutter: z's while resting, sparkles when proud.
  List<Widget> _overlays(double t, double unit) {
    final size = widget.size;
    final color = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CC3B4)
        : const Color(0xFF35665A);
    switch (widget.pose) {
      case TuckPose.resting || TuckPose.evening:
        // One "z" every ~4.5 s: drifts up and fades.
        const period = 4.5, life = 2.4;
        final p = (t % period) / life;
        if (p >= 1) return const [];
        final (ax, ay) = widget.pose == TuckPose.resting ? (.8, .6) : (.7, .3);
        final o = math.sin(math.pi * p);
        return [
          Positioned(
            left: size * ax + 10 * unit * p,
            top: size * ay - 22 * unit * p,
            child: Opacity(
              opacity: o * .8,
              child: Text(
                'z',
                style: TextStyle(
                  fontSize: (11 + 5 * p) * unit,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
            ),
          ),
        ];
      case TuckPose.proud:
        final shown = t - (_firstPose ? 0 : _poseAt);
        if (shown > 1.6) return const [];
        const spots = [(.86, .3, 0.0), (.93, .46, .25), (.62, .26, .45)];
        return [
          for (final (x, y, delay) in spots)
            if (shown > delay)
              Positioned(
                left: size * x - 5 * unit,
                top: size * y - 5 * unit,
                child: Opacity(
                  opacity: math.sin(
                    math.pi * ((shown - delay) / (1.6 - delay)).clamp(0, 1),
                  ),
                  child: CustomPaint(
                    size: Size.square(10 * unit),
                    painter: _SparklePainter(const Color(0xFFE9C46A)),
                  ),
                ),
              ),
        ];
      default:
        return const [];
    }
  }
}

class _ImageFor extends StatelessWidget {
  const _ImageFor({
    super.key,
    required this.pose,
    required this.size,
    required this.closed,
  });

  final TuckPose pose;
  final double size;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      closed ? Tuck.blinkAsset : Tuck.asset(pose),
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// A four-point star.
class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// Tuck's head and shell: the small brand mark (app bar, side rail).
class TuckMark extends StatelessWidget {
  const TuckMark({super.key, this.size = 36});

  final double size;

  static const asset = 'assets/mascot/tuck_icon.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'PACE',
    image: true,
    child: Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    ),
  );
}
