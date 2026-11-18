import '../../../core/db/app_database.dart';
import '../domain/day_routine_times.dart';
import 'morning_inputs.dart';

/// Reads settings and the week once, then answers "where is the routine on
/// this date?" for any date. Null for every date until the week is set up,
/// since the routine has no fixed points before then.
Future<DayRoutineTimes? Function(DateTime date)> loadRoutineTimes(
  AppDatabase db,
) async {
  final settings = await db.settingsDao.get();
  final rows = {
    for (final r in await db.weekdayScheduleDao.getAll()) r.weekday: r,
  };
  if (rows.isEmpty) return (_) => null;
  final plan = wakePlanFrom(settings);
  return (date) => routineTimesOn(
    date: date,
    inputs: morningInputsFor(settings, rows[date.weekday], date: date),
    plan: plan,
    sleepTargetMinutes: settings.sleepTargetMinutes,
    windDownLeadMinutes: settings.windDownLeadMinutes,
  );
}
