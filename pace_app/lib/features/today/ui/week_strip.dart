import 'package:flutter/material.dart';

import '../../../core/theme/pace_tokens.dart';

/// This week as seven soft day pills. Today is filled; days with the
/// routine done get a small dot. Empty days are just days, never gaps.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.today, required this.doneWeekdays});

  final DateTime today;
  final Set<int> doneWeekdays;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final count = doneWeekdays.length;
    return Semantics(
      label: count == 0
          ? 'This week'
          : 'Routine done on $count ${count == 1 ? 'day' : 'days'} this week',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _DayPill(
                  letter: _letters[i],
                  day: monday.add(Duration(days: i)).day,
                  isToday: i == today.weekday - 1,
                  done: doneWeekdays.contains(i + 1),
                  scheme: scheme,
                  theme: theme,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.letter,
    required this.day,
    required this.isToday,
    required this.done,
    required this.scheme,
    required this.theme,
  });

  final String letter;
  final int day;
  final bool isToday;
  final bool done;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final fg = isToday ? scheme.onPrimaryContainer : scheme.onSurface;
    return AnimatedContainer(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PaceRadius.m),
      ),
      child: Column(
        children: [
          Text(
            letter,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$day',
            style: theme.textTheme.titleSmall?.copyWith(
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: PaceMotion.standard,
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? scheme.secondary : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
