import 'package:flutter/widgets.dart';

import '../theme/pace_tokens.dart';

/// One-shot entrance: fades in while rising 8 px, [index] steps of 40 ms
/// after the first. Decorative, so it is skipped in low-energy mode and
/// with reduced motion, and never blocks taps.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final bool enabled;

  static const step = Duration(milliseconds: 40);
  static const length = Duration(milliseconds: 280);

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    if (!widget.enabled || !PaceMotion.of(context).decorative) return;
    final delay = FadeSlideIn.step * widget.index.clamp(0, 8);
    final total = delay + FadeSlideIn.length;
    final c = AnimationController(vsync: this, duration: total);
    _controller = c;
    _t = CurvedAnimation(
      parent: c,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: PaceMotion.easeOut,
      ),
    );
    c.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return widget.child;
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
