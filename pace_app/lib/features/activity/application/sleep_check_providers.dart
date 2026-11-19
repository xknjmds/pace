import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/platform/device_settings.dart';
import '../../../core/time/clock.dart';
import '../domain/sleep_estimate.dart';

/// One night in the D8 spike: what was logged beside what the phone saw.
typedef SleepCheckNight = ({
  DateTime night,
  DateTime? bedLogged,
  DateTime? wakeLogged,
  SleepEstimate? estimate,
});

/// The last three nights, newest first. Read-only; nothing is saved.
final sleepCheckProvider = FutureProvider.autoDispose<List<SleepCheckNight>>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final device = ref.watch(deviceSettingsProvider);
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final out = <SleepCheckNight>[];
  for (var i = 1; i <= 3; i++) {
    final night = DateTime(today.year, today.month, today.day - i);
    final morning = DateTime(night.year, night.month, night.day + 1);
    final from = DateTime(night.year, night.month, night.day, 20);
    final to = DateTime(morning.year, morning.month, morning.day, 12);
    final events = await device.screenEvents(from, to);
    out.add((
      night: night,
      bedLogged: (await db.dailyLogsDao.get(night))?.bedLoggedAt?.toLocal(),
      wakeLogged: (await db.dailyLogsDao.get(morning))?.wakeLoggedAt?.toLocal(),
      estimate: estimateSleep(
        events: [for (final (t, on) in events) ScreenEvent(t, on: on)],
        from: from,
        to: to.isAfter(now) ? now : to,
      ),
    ));
  }
  return out;
});
