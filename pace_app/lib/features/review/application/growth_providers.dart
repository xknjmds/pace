import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/clock.dart';
import '../../journey/application/journey_providers.dart';
import '../domain/next_routine.dart';
import '../domain/year_review.dart';

/// The one next-routine idea to show on Review, if any.
final nextRoutineProvider = StreamProvider.autoDispose<NextRoutine?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = ref.watch(clockProvider)();
  final settings = ref.watch(settingsProvider).value;
  if (settings == null) return Stream.value(null);
  final today = DateTime(now.year, now.month, now.day);
  final from21 = DateTime(today.year, today.month, today.day - 20);
  final from14 = DateTime(today.year, today.month, today.day - 13);

  Future<NextRoutine?> compute(List<DailyLog> logs) async {
    final sessions = await db.focusSessionsDao.recent(limit: 200);
    final budget = await db.financeDao.getBudget();
    return nextRoutineSuggestion(
      routineDaysLast21: logs.where((l) => l.routineDone).length,
      bedtimesLast14: logs
          .where(
            (l) =>
                l.bedLoggedAt != null && l.date.compareTo(dateKey(from14)) >= 0,
          )
          .length,
      focusSessionsLast14: sessions
          .where((s) => !s.startedAt.toLocal().isBefore(from14))
          .length,
      budgetSet: budget != null,
      dismissed: settings.dismissedSuggestions.toSet(),
    );
  }

  return db.dailyLogsDao.watchBetween(from21, today).asyncMap(compute);
});

/// "Not now" for a suggestion, remembered for good.
final dismissNextRoutineProvider = Provider<Future<void> Function(NextRoutine)>(
  (ref) =>
      (r) => ref
          .read(appDatabaseProvider)
          .settingsDao
          .updateSettings(
            (s) => s.copyWith(
              dismissedSuggestions: {
                ...s.dismissedSuggestions,
                r.name,
              }.toList(),
            ),
          ),
);

/// The school year so far.
final yearInReviewProvider = FutureProvider.autoDispose<YearInReview>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final now = ref.watch(clockProvider)();
  final settings = await ref.watch(settingsProvider.future);
  final inputs = await ref.watch(journeyInputsProvider.future);
  final start = schoolYearStart(now, settings.schoolYearStartMonth);
  final logs = await db.dailyLogsDao.between(start, now);
  final sessions = await db.focusSessionsDao.recent(limit: 100000);
  final submitted = [
    for (final t in await db.tasksDao.getAll())
      if (t.status == TaskStatus.submitted &&
          t.submittedAt != null &&
          !t.submittedAt!.toLocal().isBefore(start))
        t,
  ];
  final rewards = await db.rewardsDao.getAll();
  return yearInReview(
    today: now,
    startMonth: settings.schoolYearStartMonth,
    routineDays: inputs.routineDays,
    movementDays: inputs.movementDays,
    submittedDays: inputs.submittedDays,
    deadlinesSubmitted: submitted.length,
    focus: [
      for (final s in sessions)
        if (s.endedAt != null)
          (startedAt: s.startedAt.toLocal(), minutes: s.durationMinutes),
    ],
    bedtimeNights: {
      for (final l in logs)
        if (l.bedLoggedAt != null) l.date,
    },
    rewardsEnjoyed: rewards
        .where(
          (r) => r.claimedAt != null && !r.claimedAt!.toLocal().isBefore(start),
        )
        .length,
  );
});
