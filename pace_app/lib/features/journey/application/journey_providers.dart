import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/time/clock.dart';
import '../domain/journey.dart';

/// Everything since the first day, gathered into [JourneyInputs]. Updates
/// whenever a day's log changes. Rewards count the same days.
final journeyInputsProvider = StreamProvider.autoDispose<JourneyInputs>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = ref.watch(clockProvider)();
  final from = DateTime(2000);
  final to = DateTime(now.year, now.month, now.day + 1);

  Future<JourneyInputs> compute(List<DailyLog> logs) async {
    final submitted = [
      for (final t in await db.tasksDao.getAll())
        if (t.status == TaskStatus.submitted && t.submittedAt != null) t,
    ];
    final sessions = await db.focusSessionsDao.recent(limit: 100000);
    return JourneyInputs(
      routineDays: {
        for (final l in logs)
          if (l.routineDone) l.date,
      },
      movementDays: await db.habitsDao.doneDaysBetween(from, to),
      submittedDays: {for (final t in submitted) dateKey(t.submittedAt!)},
      focusSessions: sessions.where((s) => s.endedAt != null).length,
      deadlinesSubmitted: submitted.length,
    );
  }

  return db.dailyLogsDao.watchBetween(from, to).asyncMap(compute);
});

/// Tuck's journey from [journeyInputsProvider].
final journeyProvider = Provider.autoDispose<AsyncValue<Journey>>(
  (ref) => ref.watch(journeyInputsProvider).whenData(journeyFrom),
);
