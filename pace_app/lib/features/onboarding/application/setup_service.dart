import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../routine/application/routine_reminders.dart';
import '../domain/setup_plan.dart';

/// Saves the first-run setup. Everything it writes can be changed later in
/// settings; nothing here is special.
class SetupService {
  SetupService({
    required this.db,
    required this.routine,
    required this.resync,
    required this.now,
  });

  final AppDatabase db;
  final RoutineReminders routine;

  /// Re-plans every reminder once the routine is in place.
  final Future<void> Function() resync;
  final DateTime Function() now;

  Future<void> apply(SetupPlan plan) async {
    for (final entry in plan.days.entries) {
      await db.weekdayScheduleDao.upsert(
        weekday: entry.key,
        firstClassMinutes: entry.value.firstClassMinutes,
        commuteMinutes: entry.value.commuteMinutes,
        prepMinutes: entry.value.prepMinutes,
      );
    }
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(
        sleepTargetMinutes: plan.sleepTargetMinutes,
        weekendLeewayMinutes: plan.weekendLeewayMinutes,
        breakfastMinutes: plan.breakfastMinutes,
      ),
    );
    switch (plan.wake) {
      case WakeNow(:final minutes):
        await routine.setWakeTime(minutes);
      case WakeGradually(
        :final fromMinutes,
        :final goalMinutes,
        :final stepMinutes,
        :final everyDays,
      ):
        await routine.setWakeTime(fromMinutes);
        await routine.startGradualWake(
          goalMinutes: goalMinutes,
          stepMinutes: stepMinutes,
          everyDays: everyDays,
        );
    }
    await _markDone();
    await resync();
  }

  /// "Skip for now": the app opens on Today with its calm defaults.
  Future<void> skip() => _markDone();

  Future<void> _markDone() => db.settingsDao.updateSettings(
    (s) => s.copyWith(onboardedAt: Value(now().toUtc())),
  );
}
