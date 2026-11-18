import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/section_header.dart';
import '../application/calendar_providers.dart';
import '../application/calendar_service.dart';
import '../../../core/widgets/pace_page.dart';

/// Optional, read-only Google Calendar. Events are cached and still show
/// offline. PACE works fully without this ever being set up.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _busy = false;
  SyncResult? _last;

  Future<void> _run(Future<SyncResult> Function() action) async {
    setState(() => _busy = true);
    SyncResult result;
    try {
      result = await action();
    } catch (_) {
      result = SyncResult.needsReconnect;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _last = result;
      });
    }
  }

  String? _message(SyncResult? r) => switch (r) {
    SyncResult.synced => 'Up to date.',
    SyncResult.needsReconnect =>
      'Google needs you to connect again. That happens now and then; '
          'nothing was lost.',
    SyncResult.offline => 'Could not reach Google. Showing what was saved.',
    SyncResult.notConfigured => null,
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final service = ref.read(calendarServiceProvider);
    final configured = ref.watch(calendarAuthProvider).configured;
    final connected = settings?.calendarSyncedAt != null;
    final now = ref.watch(clockProvider)();
    final lowEnergy = ref.watch(lowEnergyProvider);
    final theme = Theme.of(context);
    final message = _message(_last);

    return PacePage(
      title: 'Calendar',
      subtitle: 'Your Google Calendar, read-only.',
      children: [
        Text(
          'Shows your Google Calendar events next to your classes on '
          'Today and on the widget. Read-only: PACE never changes your '
          'calendar. Completely optional.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (!configured)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Not set up in this build'),
              subtitle: Text(
                'Calendar sync needs a Google Cloud OAuth client id, passed '
                'when building: --dart-define=PACE_GOOGLE_CLIENT_ID=… '
                'Everything else works without it.',
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(connected ? 'Connected' : 'Not connected'),
                  subtitle: connected
                      ? Text(
                          'Last updated '
                          '${_ago(settings!.calendarSyncedAt!.toLocal(), now)}',
                        )
                      : null,
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(message, style: theme.textTheme.bodyMedium),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  )
                else
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      if (connected)
                        TextButton(
                          onPressed: () async {
                            await service.signOut();
                            setState(() => _last = null);
                          },
                          child: const Text('Sign out'),
                        ),
                      if (connected && _last != SyncResult.needsReconnect)
                        FilledButton.tonal(
                          onPressed: () => _run(service.refresh),
                          child: const Text('Refresh'),
                        )
                      else
                        FilledButton(
                          key: const ValueKey('calendar-connect'),
                          onPressed: () => _run(service.connect),
                          child: Text(connected ? 'Reconnect' : 'Connect'),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        if (connected && !lowEnergy) ...[
          const SectionHeader('Next two weeks'),
          _Upcoming(now: now),
        ],
      ],
    );
  }

  static String _ago(DateTime t, DateTime now) {
    final m = now.difference(t).inMinutes;
    if (m < 1) return 'just now';
    if (m < 60) return '$m min ago';
    if (m < 24 * 60) return '${m ~/ 60} h ago';
    return 'on ${t.day}/${t.month}';
  }
}

class _Upcoming extends ConsumerWidget {
  const _Upcoming({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(appDatabaseProvider)
        .calendarEventsDao
        .watchBetween(now, now.add(const Duration(days: 14)));
    return StreamBuilder<List<CalendarEvent>>(
      stream: stream,
      builder: (context, snap) {
        final events = snap.data ?? const <CalendarEvent>[];
        if (events.isEmpty) {
          return const Card(child: ListTile(title: Text('No events')));
        }
        return Card(
          child: Column(
            children: [
              for (final e in events)
                ListTile(title: Text(e.title), subtitle: Text(_describe(e))),
            ],
          ),
        );
      },
    );
  }

  static String _describe(CalendarEvent e) {
    final s = e.startAt.toLocal();
    final day = '${s.day}/${s.month}';
    if (e.allDay) return '$day · all day';
    final f = e.endAt.toLocal();
    return '$day · ${LocalTime.of(s.hour, s.minute).format24()}–'
        '${LocalTime.of(f.hour, f.minute).format24()}';
  }
}
