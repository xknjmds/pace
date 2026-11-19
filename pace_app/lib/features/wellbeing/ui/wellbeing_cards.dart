import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/tuck.dart';
import '../application/wellbeing_providers.dart';

/// Today, after time away: a warm hello and a light plan. Never mentions
/// how long it has been.
class WelcomeBackCard extends ConsumerWidget {
  const WelcomeBackCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pastel = PacePastels.of(context).forKind(PastelKind.calm);
    return Card(
      key: const ValueKey('welcome-back'),
      color: pastel.fill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Tuck(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Good to see you. Today is a light day: just the main '
                    'steps. We pick up from here.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('welcome-back-close'),
                      onPressed: () => ref
                          .read(wellbeingServiceProvider)
                          .dismissWelcomeBack(),
                      child: const Text('Thanks, Tuck'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A one-day light day is on: says so, with a way back to the usual day.
class LightDayLine extends ConsumerWidget {
  const LightDayLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.spa_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Light day: only the main steps today.',
              key: const ValueKey('light-day-line'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('light-day-off'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: PaceSpace.s),
            ),
            onPressed: () => ref.read(wellbeingServiceProvider).clearLightDay(),
            child: const Text('Full day'),
          ),
        ],
      ),
    );
  }
}
