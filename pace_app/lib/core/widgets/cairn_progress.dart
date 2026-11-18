import 'package:flutter/material.dart';

import '../theme/pace_tokens.dart';

/// The routine as a cairn: one stone per step, the first step at the
/// bottom. A stone fills when its step is done. It only ever grows, it
/// never shows anything as missed.
class CairnProgress extends StatelessWidget {
  const CairnProgress({
    super.key,
    required this.done,
    this.width = 56,
    this.color,
    this.trackColor,
  });

  /// Done state per step, in routine order (first step = bottom stone).
  final List<bool> done;
  final double width;
  final Color? color;
  final Color? trackColor;

  // Stone sizes from the 256-unit master, bottom stone first.
  static const _stones = [(176.0, 56.0), (124.0, 50.0), (72.0, 44.0)];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? scheme.secondary;
    final track = trackColor ?? fill.withValues(alpha: .18);
    final unit = width / 176;
    final n = done.length.clamp(1, 3);
    final count = done.where((d) => d).length;
    // With fewer than three steps the stack starts from the bottom stone.
    final stones = [
      for (var i = n - 1; i >= 0; i--)
        Padding(
          padding: EdgeInsets.only(top: i == n - 1 ? 0 : 10 * unit),
          child: AnimatedContainer(
            duration: PaceMotion.standard,
            curve: PaceMotion.easeOut,
            width: _stones[i].$1 * unit,
            height: _stones[i].$2 * unit,
            decoration: BoxDecoration(
              color: done[i] ? fill : track,
              borderRadius: BorderRadius.circular(_stones[i].$2 * unit / 2),
            ),
          ),
        ),
    ];
    return Semantics(
      label: '$count of $n steps done',
      child: ExcludeSemantics(
        child: Column(mainAxisSize: MainAxisSize.min, children: stones),
      ),
    );
  }
}
