import '../../../core/db/app_database.dart';
import '../../../core/time/local_time.dart';
import '../domain/morning_plan.dart';

/// Joins the settings row and one weekday's row into planner inputs.
/// A missing row means no class that day.
MorningInputs morningInputsFor(Setting settings, WeekdaySchedule? row) =>
    MorningInputs(
      firstClass: row?.firstClassMinutes == null
          ? null
          : LocalTime(row!.firstClassMinutes!),
      commuteMinutes: row?.commuteMinutes ?? 30,
      prepMinutes: row?.prepMinutes ?? 30,
      breakfastMinutes: settings.breakfastMinutes,
      targetWake: LocalTime(settings.targetWakeMinutes),
    );
