import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../routes.dart';
import '../application/growth_providers.dart';
import '../domain/next_routine.dart';

/// One gentle idea for the next routine, once mornings are steady. Hidden
/// in low-energy mode.
class NextRoutineCard extends ConsumerWidget {
  const NextRoutineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(lowEnergyProvider)) return const SizedBox.shrink();
    final idea = ref.watch(nextRoutineProvider).value;
    if (idea == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final route = switch (idea) {
      NextRoutine.sleep => Routes.checkIn,
      NextRoutine.study => Routes.focus,
      NextRoutine.budget => Routes.money,
    };
    return Card(
      key: ValueKey('next-routine-${idea.name}'),
      color: PacePastels.of(context).forKind(PastelKind.morning).fill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next idea: ${idea.title.toLowerCase()}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(idea.body, style: theme.textTheme.bodyMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('next-routine-dismiss'),
                  onPressed: () => ref.read(dismissNextRoutineProvider)(idea),
                  child: const Text('Not now'),
                ),
                TextButton(
                  key: const ValueKey('next-routine-go'),
                  onPressed: () => Navigator.of(context).pushNamed(route),
                  child: Text(idea.action),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
