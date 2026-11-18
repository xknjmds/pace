import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../../../core/widgets/section_header.dart';
import '../application/review_providers.dart';
import '../domain/trends.dart';
import '../domain/weekly_summary.dart';

/// Four weeks side by side, in counts and averages. Nothing is red and
/// nothing goes down for a missed day (CLAUDE.md rule 12). Low-energy mode
/// shows only this week.
class TrendsSection extends ConsumerWidget {
  const TrendsSection({super.key});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = ref.watch(weeklyTrendsProvider).value;
    if (weeks == null) return const SizedBox.shrink();
    final lowEnergy = ref.watch(lowEnergyProvider);
    final shown = (lowEnergy ? [weeks.last] : weeks.reversed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Weeks'),
        for (final (i, w) in shown.indexed)
          _WeekCard(
            key: ValueKey('week-${w.monday.month}-${w.monday.day}'),
            week: w,
            label: i == 0
                ? 'This week'
                : 'Week of ${w.monday.day} ${_months[w.monday.month - 1]}',
          ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({super.key, required this.week, required this.label});

  final WeekStats week;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = week;
    String plural(int n, String one, String many) =>
        '$n ${n == 1 ? one : many}';
    final lines = <(IconData, String)>[
      if (w.routineDays > 0)
        (
          Icons.check_circle_outline_rounded,
          'Routine: ${plural(w.routineDays, 'day', 'days')}',
        ),
      if (w.averageActualWake case final actual?)
        (
          Icons.wb_sunny_outlined,
          w.averagePlannedWake == null
              ? 'Woke around ${actual.format24()}'
              : 'Woke around ${actual.format24()} · '
                    '${describeWakeGap(w.averagePlannedWake!, actual)}',
        ),
      if (w.averageSleep case final sleep?)
        (Icons.bedtime_outlined, 'About ${formatSleep(sleep)} of sleep'),
      if (w.deadlinesSubmitted > 0)
        (
          Icons.event_available_outlined,
          '${plural(w.deadlinesSubmitted, 'deadline', 'deadlines')} submitted',
        ),
      if (w.focusSessions > 0)
        (
          Icons.timer_outlined,
          '${plural(w.focusSessions, 'focus session', 'focus sessions')}, ${w.focusMinutes} min',
        ),
      if (w.movementDays > 0)
        (
          Icons.directions_walk_rounded,
          'Movement: ${plural(w.movementDays, 'day', 'days')}',
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            if (lines.isEmpty)
              Text(
                'Nothing logged. That is fine.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final (icon, text) in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
