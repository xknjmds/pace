import 'package:flutter/widgets.dart';

import '../theme/pace_tokens.dart';

/// Shrinks its child to 96 % over 150 ms while a finger is down, so every
/// tap feels heard. It only listens, so the child's own gestures still
/// work. Pass [enabled] false for a disabled control: it never scales.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = .96,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final motion = PaceMotion.of(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.enabled && !motion.reduced ? widget.scale : 1,
        duration: PaceMotion.press,
        curve: PaceMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
