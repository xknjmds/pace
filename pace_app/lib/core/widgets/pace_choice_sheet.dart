import 'package:flutter/material.dart';

/// One option in [showPaceChoiceSheet].
class PaceChoice<T> {
  const PaceChoice(this.value, this.label);

  final T value;
  final String label;
}

/// Picks one value from a short list, as soft pills in a bottom sheet.
/// The current choice is filled and carries a check, so it is not marked
/// by colour alone.
///
/// With [custom], a "Custom…" pill closes the sheet and runs it (for a
/// free-form value); its result is returned.
Future<T?> showPaceChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<PaceChoice<T>> choices,
  T? selected,
  String? message,
  Future<T?> Function()? custom,
}) async {
  const customPicked = Object();
  final picked = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in choices)
                    _ChoicePill(
                      label: c.label,
                      selected: c.value == selected,
                      onTap: () => Navigator.of(context).pop(_Picked(c.value)),
                    ),
                  if (custom != null)
                    _ChoicePill(
                      label: 'Custom…',
                      selected: false,
                      onTap: () => Navigator.of(context).pop(customPicked),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (picked is _Picked) return picked.value as T;
  if (identical(picked, customPicked) && custom != null) return custom();
  return null;
}

class _Picked {
  const _Picked(this.value);

  final Object? value;
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
