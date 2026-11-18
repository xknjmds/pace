import 'package:flutter/material.dart';

import '../theme/pace_pastels.dart';
import '../theme/pace_tokens.dart';
import 'pastel_icon_chip.dart';
import 'press_scale.dart';

/// One row of a [PaceGroup]: a pastel icon chip, a title, an optional
/// subtitle and a trailing value, switch or chevron. The PACE replacement
/// for a Material `ListTile`.
class PaceTile extends StatelessWidget {
  const PaceTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.kind = PastelKind.calm,
    this.leading,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = false,
  });

  /// A row whose whole surface flips a switch. The switch stays the one
  /// semantic control, labelled by the row's text.
  factory PaceTile.toggle({
    Key? key,
    required String title,
    String? subtitle,
    IconData? icon,
    PastelKind kind = PastelKind.calm,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) => PaceTile(
    key: key,
    title: title,
    subtitle: subtitle,
    icon: icon,
    kind: kind,
    onTap: onChanged == null ? null : () => onChanged(!value),
    trailing: Switch(value: value, onChanged: onChanged),
  );

  final String title;
  final String? subtitle;
  final IconData? icon;
  final PastelKind kind;

  /// A custom leading widget in place of the icon chip.
  final Widget? leading;

  /// A short trailing value such as "06:30" or "15 min".
  final String? value;

  /// Any other trailing widget (a switch, a button).
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Shows that the row opens something.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (leading != null || icon != null) ...[
              leading ?? PastelIconChip(icon: icon!, kind: kind),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (chevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return MergeSemantics(child: row);
    return MergeSemantics(
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PaceRadius.m),
          child: row,
        ),
      ),
    );
  }
}

/// A soft white card holding [PaceTile]s. Rows are separated by space,
/// not lines.
class PaceGroup extends StatelessWidget {
  const PaceGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
}
