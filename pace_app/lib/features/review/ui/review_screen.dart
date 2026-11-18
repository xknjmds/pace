import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/pace_tile.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes.dart';
import '../application/review_providers.dart';
import '../domain/weekly_summary.dart';
import 'trends_section.dart';
import '../../../core/widgets/pace_page.dart';

/// The last seven days in plain counts: what got done, when you got up,
/// how you slept. Nothing here goes down or turns red.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _showNights = false;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _hm(DateTime t) => LocalTime.of(t.hour, t.minute).format24();

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(weeklySummaryProvider);
    final lowEnergy = ref.watch(lowEnergyProvider);
    final theme = Theme.of(context);
    final nightsVisible = !lowEnergy || _showNights;
    final avgSleep = summary.averageSleep;

    final scheme = theme.colorScheme;
    final pastels = PacePastels.of(context);

    return PacePage(
      title: 'Review',
      subtitle: 'The last 7 days, in plain counts.',
      children: [
        Card(
          color: pastels.evening.fill,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(Routes.checkIn),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              child: Row(
                children: [
                  _IconBadge(
                    Icons.nights_stay_outlined,
                    color: pastels.evening.ink,
                    background: scheme.surfaceContainerLowest.withValues(
                      alpha: .6,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evening check-in',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Look at tomorrow, then rest.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: pastels.evening.ink),
                ],
              ),
            ),
          ),
        ),
        const SectionHeader('Last 7 days'),
        PaceGroup(
          children: [
            PaceTile(
              key: const ValueKey('routine-days'),
              leading: summary.routineDays == 0
                  ? const _IconBadge(Icons.check_circle_outline_rounded)
                  : _NumberBadge(summary.routineDays),
              title: summary.routineDays == 0
                  ? 'No routine days logged yet'
                  : 'Routine done on ${summary.routineDays} '
                        '${summary.routineDays == 1 ? 'day' : 'days'}',
            ),
            PaceTile(
              key: const ValueKey('average-wake'),
              leading: _IconBadge(
                Icons.wb_sunny_outlined,
                color: pastels.morning.ink,
                background: pastels.morning.fill,
              ),
              title: summary.averageWake == null
                  ? 'No wake times logged yet'
                  : 'Up around ${summary.averageWake!.format24()} '
                        'on average',
              subtitle: summary.wakeDays == 0
                  ? 'Tap "I\'m up" on Today to log one.'
                  : 'From ${summary.wakeDays} '
                        '${summary.wakeDays == 1 ? 'morning' : 'mornings'}',
            ),
            PaceTile(
              key: const ValueKey('average-sleep'),
              leading: _IconBadge(
                Icons.bedtime_outlined,
                color: pastels.evening.ink,
                background: pastels.evening.fill,
              ),
              title: avgSleep == null
                  ? 'No full nights logged yet'
                  : 'About ${formatSleep(avgSleep)} of sleep a night',
            ),
          ],
        ),
        SectionHeader(
          'Sleep log',
          action: lowEnergy && summary.sleep.isNotEmpty
              ? TextButton(
                  onPressed: () => setState(() => _showNights = !_showNights),
                  child: Text(_showNights ? 'Hide' : 'Show'),
                )
              : null,
        ),
        AnimatedSize(
          duration: PaceMotion.standard,
          curve: PaceMotion.easeOut,
          alignment: Alignment.topCenter,
          child: summary.sleep.isEmpty
              ? _Note(
                  'Nothing yet. "Going to bed" in the evening and "I\'m up" '
                  'in the morning fill this in.',
                )
              : nightsVisible
              ? PaceGroup(
                  children: [
                    for (final e in summary.sleep)
                      PaceTile(
                        icon: Icons.bedtime_rounded,
                        kind: PastelKind.evening,
                        title: '${_weekdays[e.night.weekday - 1]} night',
                        subtitle:
                            '${e.bedAt == null ? 'bed not logged' : 'bed ${_hm(e.bedAt!)}'}'
                            ' · '
                            '${e.wakeAt == null ? 'up not logged' : 'up ${_hm(e.wakeAt!)}'}',
                        value: e.slept == null ? null : formatSleep(e.slept!),
                      ),
                  ],
                )
              : _Note(
                  '${summary.sleep.length} '
                  '${summary.sleep.length == 1 ? 'night' : 'nights'} logged.',
                ),
        ),
        const TrendsSection(),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon, {this.color, this.background});

  final IconData icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(PaceRadius.s),
      ),
      child: Icon(icon, size: 22, color: color ?? scheme.onPrimaryContainer),
    );
  }
}

/// A count shown big: the number of good days, never a gap.
class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(PaceRadius.s),
      ),
      child: Text(
        '$value',
        style: theme.textTheme.titleLarge?.copyWith(color: scheme.onSecondary),
      ),
    );
  }
}
