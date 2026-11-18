import 'package:flutter/widgets.dart';

/// Spacing scale. Use these instead of ad-hoc numbers so screens line up.
abstract final class PaceSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Side gutter of every scrolling screen.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(16, 4, 16, 96);
}

abstract final class PaceRadius {
  static const double s = 14;
  static const double m = 18;
  static const double card = 26;
  static const double sheet = 32;
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));

  /// The one soft lift used for floating things (nav bar, Now card).
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0F1C2622), blurRadius: 20, offset: Offset(0, 4)),
  ];
}

/// Motion rules for the whole app: short, ease-out, purposeful.
///
/// Read with [PaceMotion.of]. When the system asks for reduced motion,
/// things fade instead of moving. When low-energy mode is on (or motion is
/// reduced), decorative motion such as entrance staggers is skipped.
@immutable
class PaceMotion {
  const PaceMotion({this.reduced = false, this.calm = false});

  /// System "remove animations" is on: no movement, fades only.
  final bool reduced;

  /// Low-energy mode: no decorative motion.
  final bool calm;

  static const press = Duration(milliseconds: 150);
  static const quick = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 240);
  static const emphasized = Duration(milliseconds: 300);

  /// Strong ease-out: instant response, soft landing.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// For things moving across the screen.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// Distance in logical pixels, or zero when movement is reduced.
  double offset(double px) => reduced ? 0 : px;

  /// Whether purely decorative motion (staggers, Tuck's life motion) plays.
  bool get decorative => !reduced && !calm;

  static PaceMotion of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaceMotionScope>();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return PaceMotion(reduced: reduced, calm: scope?.calm ?? false);
  }
}

/// Puts low-energy mode where [PaceMotion.of] can see it.
class PaceMotionScope extends InheritedWidget {
  const PaceMotionScope({super.key, required this.calm, required super.child});

  final bool calm;

  @override
  bool updateShouldNotify(PaceMotionScope oldWidget) => calm != oldWidget.calm;
}
