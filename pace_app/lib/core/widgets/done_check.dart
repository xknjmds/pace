import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/pace_tokens.dart';

/// A round check: tap it and it fills, then [onDone] runs. The short fill
/// confirms the tap before the item moves away.
class DoneCheck extends StatefulWidget {
  const DoneCheck({
    super.key,
    required this.onDone,
    this.tooltip = 'Submitted',
    this.size = 24,
  });

  final VoidCallback onDone;
  final String tooltip;
  final double size;

  @override
  State<DoneCheck> createState() => _DoneCheckState();
}

class _DoneCheckState extends State<DoneCheck>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final _t = CurvedAnimation(parent: _c, curve: PaceMotion.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_c.isAnimating || _c.isCompleted) return;
    HapticFeedback.lightImpact();
    await _c.forward();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = widget.size;
    // Reduced motion: the check fades in without growing.
    final reduced = PaceMotion.of(context).reduced;
    return IconButton(
      tooltip: widget.tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: _tap,
      icon: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final v = _t.value;
          return SizedBox.square(
            dimension: s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(Colors.transparent, scheme.secondary, v),
                border: Border.all(
                  color: Color.lerp(scheme.outline, scheme.secondary, v)!,
                  width: 1.8,
                ),
              ),
              child: Opacity(
                opacity: v,
                child: Transform.scale(
                  scale: reduced ? 1 : .6 + .4 * v,
                  child: Icon(
                    Icons.check_rounded,
                    size: s * .7,
                    color: scheme.onSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
