import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_section_card.dart';
import '../../../core/time/date_key.dart';
import '../application/habit_providers.dart';
import '../application/habit_service.dart';
import '../domain/habit_planner.dart';

/// The movement habit on Today: one tap to mark it done. Hidden when the
/// habit is off and in low-energy mode. Not doing it shows nothing at all.
class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = ref.watch(movementHabitProvider).value;
    if (habit == null || !habit.active || ref.watch(lowEnergyProvider)) {
      return const SizedBox.shrink();
    }
    final done = ref.watch(habitDoneProvider(dateKey(now))).value ?? false;
    final theme = Theme.of(context);
    return PaceSectionCard(
      key: const ValueKey('habit-card'),
      title: habit.name,
      icon: Icons.directions_walk_rounded,
      pastel: PastelKind.focus,
      action: done
          ? TextButton(
              onPressed: () =>
                  ref.read(habitServiceProvider).setDoneToday(false),
              child: const Text('Undo'),
            )
          : FilledButton.tonal(
              key: const ValueKey('habit-done'),
              onPressed: () =>
                  ref.read(habitServiceProvider).setDoneToday(true),
              child: const Text('Done'),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Text(
          done
              ? 'Done today. Any amount counts.'
              : describeHabitTime(
                  HabitService.pointFor(habit.anchor),
                  habit.offsetMinutes,
                ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
