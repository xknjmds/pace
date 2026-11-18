import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/time/clock.dart';
import '../../routine/application/morning_inputs.dart';
import '../../routine/domain/wake_schedule.dart';
import '../domain/trends.dart';
import '../domain/weekly_summary.dart';

/// Eight days of logs: the window plus the night before it.
final weekLogsProvider = StreamProvider<List<DailyLog>>((ref) {
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  return ref
      .watch(appDatabaseProvider)
      .dailyLogsDao
      .watchBetween(DateTime(today.year, today.month, today.day - 7), today);
});

final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  final logs = ref.watch(weekLogsProvider).value ?? const <DailyLog>[];
  return weeklySummary(
    today: ref.watch(clockProvider)(),
    records: [
      for (final l in logs)
        DayRecord(
          date: DateTime.parse(l.date),
          bedAt: l.bedLoggedAt,
          wakeAt: l.wakeLoggedAt,
          routineDone: l.routineDone,
        ),
    ],
  );
});

/// Four calendar weeks of trends, recomputed whenever any log changes.
final weeklyTrendsProvider = StreamProvider.autoDispose<List<WeekStats>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = ref.watch(clockProvider)();
  final from = DateTime(now.year, now.month, now.day - 35);
  final to = DateTime(now.year, now.month, now.day + 1);
  Future<List<WeekStats>> compute(List<DailyLog> logs) async {
    final settings = await db.settingsDao.get();
    final plan = wakePlanFrom(settings);
    final submitted = await db.tasksDao.submittedBetween(from, to);
    final sessions = await db.focusSessionsDao.recent(limit: 500);
    final movement = await db.habitsDao.doneDaysBetween(from, to);
    return weeklyTrends(
      today: now,
      records: [
        for (final l in logs)
          DayRecord(
            date: DateTime.parse(l.date),
            bedAt: l.bedLoggedAt,
            wakeAt: l.wakeLoggedAt,
            routineDone: l.routineDone,
          ),
      ],
      plannedWakeFor: (date) => wakeOn(plan, date),
      submittedAt: [for (final t in submitted) ?t.submittedAt],
      focus: [
        for (final s in sessions)
          (startedAt: s.startedAt, minutes: s.durationMinutes),
      ],
      movementDays: movement,
    );
  }

  return db.dailyLogsDao.watchBetween(from, to).asyncMap(compute);
});
