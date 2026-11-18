import 'package:flutter/material.dart';

import '../theme/pace_pastels.dart';

/// A small soft square holding an icon in its pastel colour. The one icon
/// treatment for rows, card titles and hub tiles.
class PastelIconChip extends StatelessWidget {
  const PastelIconChip({
    super.key,
    required this.icon,
    this.kind = PastelKind.calm,
    this.size = 32,
  });

  final IconData icon;
  final PastelKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pastel = PacePastels.of(context).forKind(kind);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: pastel.fill,
          borderRadius: BorderRadius.circular(size * .31),
        ),
        child: Icon(icon, size: size * .56, color: pastel.ink),
      ),
    );
  }
}
