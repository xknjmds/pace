import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/time/clock.dart';
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
