import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../../../core/time/local_time.dart';
import '../../../routes.dart';
import '../application/review_providers.dart';
import '../domain/weekly_summary.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.nights_stay_outlined),
                title: const Text('Evening check-in'),
                subtitle: const Text('Look at tomorrow, then rest.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(Routes.checkIn),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text('Last 7 days', style: theme.textTheme.titleSmall),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const ValueKey('routine-days'),
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                      summary.routineDays == 0
                          ? 'No routine days logged yet'
                          : 'Routine done on ${summary.routineDays} '
                                '${summary.routineDays == 1 ? 'day' : 'days'}',
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('average-wake'),
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: Text(
                      summary.averageWake == null
                          ? 'No wake times logged yet'
                          : 'Up around ${summary.averageWake!.format24()} '
                                'on average',
                    ),
                    subtitle: summary.wakeDays == 0
                        ? const Text('Tap "I\'m up" on Today to log one.')
                        : Text(
                            'From ${summary.wakeDays} '
                            '${summary.wakeDays == 1 ? 'morning' : 'mornings'}',
                          ),
                  ),
                  ListTile(
                    key: const ValueKey('average-sleep'),
                    leading: const Icon(Icons.bedtime_outlined),
                    title: Text(
                      avgSleep == null
                          ? 'No full nights logged yet'
                          : 'About ${formatSleep(avgSleep)} of sleep a night',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Sleep log', style: theme.textTheme.titleSmall),
                  ),
                  if (lowEnergy && summary.sleep.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _showNights = !_showNights),
                      child: Text(_showNights ? 'Hide' : 'Show'),
                    ),
                ],
              ),
            ),
            if (summary.sleep.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Nothing yet. "Going to bed" in the evening and "I\'m up" '
                  'in the morning fill this in.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else if (nightsVisible)
              Card(
                child: Column(
                  children: [
                    for (final e in summary.sleep)
                      ListTile(
                        dense: true,
                        title: Text('${_weekdays[e.night.weekday - 1]} night'),
                        subtitle: Text(
                          '${e.bedAt == null ? 'bed not logged' : 'bed ${_hm(e.bedAt!)}'}'
                          ' · '
                          '${e.wakeAt == null ? 'up not logged' : 'up ${_hm(e.wakeAt!)}'}',
                        ),
                        trailing: e.slept == null
                            ? null
                            : Text(formatSleep(e.slept!)),
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${summary.sleep.length} '
                  '${summary.sleep.length == 1 ? 'night' : 'nights'} logged.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
