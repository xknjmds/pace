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
