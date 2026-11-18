import 'package:flutter/material.dart';

import '../theme/pace_pastels.dart';
import '../theme/pace_tokens.dart';
import 'pastel_icon_chip.dart';

/// A card with a title row (and optional action) above its content.
/// Height changes (a row arriving or leaving) glide instead of jumping.
class PaceSectionCard extends StatelessWidget {
  const PaceSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.icon,
    this.pastel = PastelKind.calm,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final IconData? icon;

  /// Soft colour of the icon chip.
  final PastelKind pastel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 10),
        child: AnimatedSize(
          duration: PaceMotion.standard,
          curve: PaceMotion.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      PastelIconChip(icon: icon!, kind: pastel),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.only(right: 8), child: child),
            ],
          ),
        ),
      ),
    );
  }
}
