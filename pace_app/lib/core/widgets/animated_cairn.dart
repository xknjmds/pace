import 'package:flutter/material.dart';

import '../theme/pace_tokens.dart';

/// The cairn, built one stone at a time from the bottom up (about 0.6 s,
/// once). Used for rare moments: the first open, the end of a check-in.
/// Static in low-energy mode or with reduced motion.
class AnimatedCairn extends StatefulWidget {
  const AnimatedCairn({super.key, this.size = 88, this.color});

  /// Width of the bottom stone.
  final double size;
  final Color? color;

  @override
  State<AnimatedCairn> createState() => _AnimatedCairnState();
}

class _AnimatedCairnState extends State<AnimatedCairn>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  static const _stones = [(176.0, 56.0), (124.0, 50.0), (72.0, 44.0)];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null || !PaceMotion.of(context).decorative) return;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    )..forward();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final unit = widget.size / 176;
    final c = _c;

    Widget stone(int i) {
      final (w, h) = _stones[i];
      final box = Container(
        width: w * unit,
        height: h * unit,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(h * unit / 2),
        ),
      );
      if (c == null) return box;
      // Bottom stone first; each one settles from slightly above.
      final t = CurvedAnimation(
        parent: c,
        curve: Interval(i * .22, .56 + i * .22, curve: PaceMotion.easeOut),
      );
      return AnimatedBuilder(
        animation: t,
        builder: (_, child) => Opacity(
          opacity: t.value,
          child: Transform.translate(
            offset: Offset(0, -14 * unit * (1 - t.value)),
            child: child,
          ),
        ),
        child: box,
      );
    }

    return Semantics(
      label: 'PACE',
      image: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          stone(2),
          SizedBox(height: 12 * unit),
          stone(1),
          SizedBox(height: 12 * unit),
          stone(0),
        ],
      ),
    );
  }
}
