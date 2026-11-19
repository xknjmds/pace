import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_choice_sheet.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/widgets/tuck.dart';
import '../application/growth_providers.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The school year so far, in kind totals. Nothing here can go down.
class YearReviewScreen extends ConsumerWidget {
  const YearReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(yearInReviewProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final theme = Theme.of(context);
    final pastel = PacePastels.of(context).forKind(PastelKind.evening);
    return PacePage(
      title: 'Your school year',
      subtitle: year == null
          ? null
          : 'Since ${year.from.day} ${_monthNames[year.from.month - 1]} '
                '${year.from.year}.',
      children: [
        if (year != null)
          Card(
            key: const ValueKey('year-card'),
            color: pastel.fill,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Tuck(
                      pose: year.isEmpty ? TuckPose.idle : TuckPose.proud,
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (year.isEmpty)
                    Text(
                      'The year is just getting started. Whatever you do '
                      'from here gathers on this page.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    )
                  else
                    for (final line in year.lines)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: pastel.ink,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                line,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        if (settings != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              key: const ValueKey('school-year-start'),
              onPressed: () async {
                final m = await showPaceChoiceSheet<int>(
                  context: context,
                  title: 'School year starts in',
                  selected: settings.schoolYearStartMonth,
                  choices: [
                    for (var i = 1; i <= 12; i++)
                      PaceChoice(i, _monthNames[i - 1]),
                  ],
                );
                if (m == null) return;
                await ref
                    .read(appDatabaseProvider)
                    .settingsDao
                    .updateSettings((s) => s.copyWith(schoolYearStartMonth: m));
                ref.invalidate(yearInReviewProvider);
              },
              child: Text(
                'School year starts in '
                '${_monthNames[settings.schoolYearStartMonth - 1]} · Change',
              ),
            ),
          ),
      ],
    );
  }
}
