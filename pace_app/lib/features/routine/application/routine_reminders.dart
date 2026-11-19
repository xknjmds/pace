import '../../../core/energy/low_energy.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/notifications/reminder_actions.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../domain/morning_plan.dart';
import '../domain/routine_reminder_planner.dart';
import '../domain/wake_schedule.dart';
import '../../verse/domain/verse.dart';
import 'morning_inputs.dart';

/// Keeps the wake, eat, leave and wind-down reminders in step with settings,
/// the week's schedule and "Not today" mutes, and applies what the owner
/// does with them. Once the week is set up, every day gets a wake reminder
/// (the wake anchor) and every evening a wind-down reminder.
///
/// Owner ids: `"<weekday>"` for the planned reminder, `"<weekday>:snooze"`
/// for its single snooze.
class RoutineReminders {
  RoutineReminders({
    required this.db,
    required this.scheduler,
    required this.now,
    this.loadVerses,
  });

  final AppDatabase db;
  final ReminderScheduler scheduler;
  final DateTime Function() now;

  /// The bundled verses, for the optional line in wake reminders.
  final Future<List<Verse>> Function()? loadVerses;

  static const snoozeMinutes = 10;
  static const _steps = {
    RoutineStep.wake: ReminderKind.wake,
    RoutineStep.eat: ReminderKind.eat,
    RoutineStep.leave: ReminderKind.leave,
    RoutineStep.windDown: ReminderKind.windDown,
  };

  /// [MorningInputs] for every weekday that has a schedule row.
  Future<Map<int, MorningInputs>> inputsByWeekday() async {
    final settings = await db.settingsDao.get();
    final rows = await db.weekdayScheduleDao.getAll();
    return {for (final r in rows) r.weekday: morningInputsFor(settings, r)};
  }

  /// Recomputes the next seven days and replaces every routine owner's
  /// reminders. Call after any settings or schedule change and on launch.
  Future<void> resync() async {
    final t = now();
    await _settleFinishedShift(t);
    final settings = await db.settingsDao.get();
    final plan = wakePlanFrom(settings);
    final inputs = await inputsByWeekday();
    final mutes = await db.reminderMutesDao.between(
      t,
      t.add(const Duration(days: 7)),
    );
    final setUp = inputs.isNotEmpty;
    var verses = const <Verse>[];
    if (settings.verseEnabled && !settings.lowEnergyAt(t)) {
      // The verse is a nicety: if it cannot load, reminders go out without it.
      try {
        verses = await loadVerses?.call() ?? const [];
      } catch (_) {}
    }
    final planned = planRoutineReminders(
      now: t,
      inputsByWeekday: inputs,
      muted: {for (final m in mutes) '${m.kind.name}:${m.ownerId}:${m.date}'},
      wakeFor: (date) => wakeOn(plan, date),
      wakeAnchor: setUp,
      windDown: setUp
          ? WindDownSettings(
              wakePlan: plan,
              sleepTargetMinutes: settings.sleepTargetMinutes,
              leadMinutes: settings.windDownLeadMinutes,
            )
          : null,
      // Steady mode keeps the same short set: wake and leave only.
      lowEnergy: settings.lowEnergyAt(t) || settings.steadyMode,
      wakeLine: verses.isEmpty
          ? null
          : (date) {
              final v = verseFor(date, verses);
              return v == null ? null : '${v.text} (${v.reference})';
            },
    );
    for (final entry in _steps.entries) {
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        final drafts = [
          for (final p in planned)
            if (p.step == entry.key && p.weekday == weekday) p.draft,
        ];
        await scheduler.replaceOwner(entry.value, '$weekday', drafts);
      }
    }
  }

  /// A shift that has reached its goal becomes the plain wake time.
  Future<void> _settleFinishedShift(DateTime t) async {
    final s = await db.settingsDao.get();
    final shift = wakePlanFrom(s).shift;
    if (shift == null || dateOnly(t).isBefore(shiftReachesGoalOn(shift))) {
      return;
    }
    await db.settingsDao.updateSettings(
      (x) => x.copyWith(
        targetWakeMinutes: shift.goalMinutes,
        wakeGoalMinutes: const Value(null),
        wakeShiftFromMinutes: const Value(null),
        wakeShiftStartDate: const Value(null),
      ),
    );
  }

  /// Sets the wake time directly. Any shift under way stops.
  Future<void> setWakeTime(int minutes) async {
    await db.settingsDao.updateSettings(
      (x) => x.copyWith(
        targetWakeMinutes: minutes,
        wakeGoalMinutes: const Value(null),
        wakeShiftFromMinutes: const Value(null),
        wakeShiftStartDate: const Value(null),
      ),
    );
  }

  /// Starts moving the weekday wake time toward [goalMinutes], from the
  /// time in force today. A goal that is not earlier applies at once.
  Future<void> startGradualWake({
    required int goalMinutes,
    int stepMinutes = 15,
    int everyDays = 3,
  }) async {
    final t = now();
    final current = weekdayWakeOn(
      wakePlanFrom(await db.settingsDao.get()),
      t,
    ).minutesSinceMidnight;
    if (goalMinutes >= current) {
      await setWakeTime(goalMinutes);
      return;
    }
    await db.settingsDao.updateSettings(
      (x) => x.copyWith(
        targetWakeMinutes: current,
        wakeGoalMinutes: Value(goalMinutes),
        wakeShiftFromMinutes: Value(current),
        wakeShiftStartDate: Value(dateKey(t)),
        wakeShiftStepMinutes: stepMinutes,
        wakeShiftEveryDays: everyDays,
      ),
    );
  }

  /// "Not today": silence this step for [day] without logging anything,
  /// then let the planner drop it.
  Future<void> notToday(ReminderKind kind, int weekday, DateTime day) async {
    await db.reminderMutesDao.mute(kind, '$weekday', day);
    await scheduler.cancelOwner(kind, '$weekday$snoozeOwnerSuffix');
    await resync();
  }

  /// One extra nudge in ten minutes. The snoozed copy has no snooze button.
  Future<void> snooze(ReminderKind kind, int weekday) async {
    final at = now().add(const Duration(minutes: snoozeMinutes));
    final title = switch (kind) {
      ReminderKind.wake => 'Good morning',
      ReminderKind.eat => 'Breakfast',
      ReminderKind.windDown => 'Time to wind down',
      _ => 'Time to leave',
    };
    await scheduler.replaceOwner(kind, '$weekday$snoozeOwnerSuffix', [
      (fireAt: at, title: title, body: 'Ten minutes later, as asked.'),
    ]);
  }

  /// Marks the step done now, on time. The notification "Done" button;
  /// the check-in sheet can change it afterwards.
  Future<void> done(ReminderKind kind, int weekday) =>
      checkIn(kind, weekday, CheckInOutcome.onTime);

  /// The day a check-in for [kind] belongs to: wind-down counts for the
  /// night it started on, everything else for today.
  DateTime _dayFor(ReminderKind kind, DateTime t) =>
      kind == ReminderKind.windDown ? nightOf(t) : t;

  /// Records how [kind] went today, as the owner tells it in the check-in
  /// sheet. Done (on time or later) logs [at] (default now) in
  /// `daily_logs`, which the rest of the app reads. "Didn't happen" clears
  /// that log and quiets the step's reminders for the rest of the day.
  Future<void> checkIn(
    ReminderKind kind,
    int weekday,
    CheckInOutcome outcome, {
    DateTime? at,
    String? reason,
  }) async {
    if (!_steps.containsValue(kind)) return;
    final t = now();
    final day = _dayFor(kind, t);
    final happened = outcome != CheckInOutcome.didntHappen;
    final when = at ?? t;
    await db.checkInsDao.record(
      day,
      kind,
      outcome,
      actualAt: happened ? when : null,
      reason: reason,
    );
    await _log(kind, day, happened ? when : null);
    await scheduler.cancelOwner(kind, '$weekday$snoozeOwnerSuffix');
    if (!happened) {
      await db.reminderMutesDao.mute(kind, '$weekday', day);
      await resync();
    }
  }

  /// Starts the step over: no check-in, no log, reminders back as planned.
  Future<void> clearCheckIn(ReminderKind kind, int weekday) async {
    if (!_steps.containsValue(kind)) return;
    final day = _dayFor(kind, now());
    await db.checkInsDao.clear(day, kind);
    await _log(kind, day, null);
    await db.reminderMutesDao.unmute(kind, '$weekday', day);
    await resync();
  }

  /// Writes (or with null, clears) the step's entry in `daily_logs`.
  Future<void> _log(ReminderKind kind, DateTime day, DateTime? at) {
    final utc = Value(at?.toUtc());
    return db.dailyLogsDao.change(
      day,
      (_) => switch (kind) {
        ReminderKind.wake => DailyLogsCompanion(wakeLoggedAt: utc),
        ReminderKind.eat => DailyLogsCompanion(eatDoneAt: utc),
        ReminderKind.leave => DailyLogsCompanion(
          routineDone: Value(at != null),
        ),
        _ => DailyLogsCompanion(bedLoggedAt: utc),
      },
    );
  }

  /// Routes a notification response to the method above. Returns false for
  /// responses that are not about a routine reminder.
  Future<bool> handle(ReminderResponse response) async {
    final parsed = parseReminderPayload(response.payload);
    if (parsed == null || !_steps.containsValue(parsed.kind)) return false;
    final weekday = int.tryParse(
      parsed.ownerId.replaceFirst(snoozeOwnerSuffix, ''),
    );
    if (weekday == null) return false;
    switch (response.actionId) {
      case ReminderActionIds.done:
        await done(parsed.kind, weekday);
      case ReminderActionIds.snooze:
        await snooze(parsed.kind, weekday);
      case ReminderActionIds.notToday:
        await notToday(parsed.kind, weekday, now());
      default:
        break; // A plain tap just opens the app.
    }
    return true;
  }
}
