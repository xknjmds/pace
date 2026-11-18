import 'package:flutter/material.dart';

/// The one heading style for groups inside a screen.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 6),
  });

  final String title;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: .6,
                ),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
