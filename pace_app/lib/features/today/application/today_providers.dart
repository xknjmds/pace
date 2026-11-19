import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/time/clock.dart';
import '../../routine/ui/routine_settings_screen.dart';

/// Fires once a minute so Today re-reads the clock while open.
final minuteTickProvider = StreamProvider.autoDispose<int>(
  (_) => Stream.periodic(const Duration(minutes: 1), (i) => i),
);

/// Daily log for the day keyed `yyyy-MM-dd`.
final dailyLogProvider = StreamProvider.family<DailyLog?, String>(
  (ref, key) =>
      ref.watch(appDatabaseProvider).dailyLogsDao.watch(DateTime.parse(key)),
);

/// Weekday rows by weekday, for quick lookups.
final scheduleByWeekdayProvider = Provider<Map<int, WeekdaySchedule>>((ref) {
  final rows = ref.watch(weekdaySchedulesProvider).value ?? const [];
  return {for (final r in rows) r.weekday: r};
});

/// Local "now", refreshed each minute while watched.
final nowProvider = Provider.autoDispose<DateTime>((ref) {
  ref.watch(minuteTickProvider);
  return ref.watch(clockProvider)();
});

/// Weekdays (1 = Monday) of the week starting on [mondayKey] (`yyyy-MM-dd`)
/// with the routine done. Only ever grows through the week.
final weekRoutineDoneProvider = StreamProvider.family<Set<int>, String>((
  ref,
  mondayKey,
) {
  final from = DateTime.parse(mondayKey);
  return ref
      .watch(appDatabaseProvider)
      .dailyLogsDao
      .watchBetween(from, from.add(const Duration(days: 6)))
      .map(
        (logs) => {
          for (final l in logs)
            if (l.routineDone) DateTime.parse(l.date).weekday,
        },
      );
});

/// The day's routine check-ins (keyed `yyyy-MM-dd`), by step.
final checkInsProvider =
    StreamProvider.family<Map<ReminderKind, CheckIn>, String>(
      (ref, key) => ref
          .watch(appDatabaseProvider)
          .checkInsDao
          .watchDay(DateTime.parse(key)),
    );
