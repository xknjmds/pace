import 'package:flutter/material.dart';

import '../theme/pace_pastels.dart';
import '../theme/pace_tokens.dart';

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
                      _IconChip(
                        icon: icon!,
                        pastel: PacePastels.of(context).forKind(pastel),
                      ),
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

/// A small soft square holding an icon in its pastel colour.
class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.pastel});

  final IconData icon;
  final Pastel pastel;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: pastel.fill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 18, color: pastel.ink),
  );
}
