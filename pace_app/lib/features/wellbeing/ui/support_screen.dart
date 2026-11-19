import 'package:flutter/material.dart';

import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/widgets/pastel_icon_chip.dart';
import '../domain/support_contacts.dart';

/// "If you're struggling": a few kind lines and people to reach. Works
/// offline. It is not therapy and says so.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return PacePage(
      title: 'If you\'re struggling',
      subtitle: 'You don\'t have to carry it alone.',
      leading: const PastelIconChip(
        icon: Icons.favorite_rounded,
        kind: PastelKind.evening,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hard days happen, and they pass. Rest counts as progress.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Talking helps. A friend, family, a teacher or your school '
                  'guidance counselor can listen. You can also call one of '
                  'the lines below, any time.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final c in supportContacts)
          Card(
            key: ValueKey('support-${c.name}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: theme.textTheme.titleMedium),
                  if (c.note != null) ...[
                    const SizedBox(height: 2),
                    Text(c.note!, style: muted),
                  ],
                  const SizedBox(height: 8),
                  for (final n in c.numbers)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SelectableText(
                        n,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'PACE is a routine helper, not therapy or medical care. If you '
            'feel unsafe, please call 911 or go to the nearest hospital.',
            key: const ValueKey('support-disclaimer'),
            style: muted,
          ),
        ),
      ],
    );
  }
}
