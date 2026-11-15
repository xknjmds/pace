import '../../../core/db/app_database.dart';
import '../../../core/notifications/reminder_actions.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/time/local_time.dart';
import '../domain/morning_plan.dart';
import '../domain/routine_reminder_planner.dart';

/// Keeps the wake, eat and leave reminders in step with settings, the week's
/// schedule and "Not today" mutes, and applies what the owner does with them.
///
/// Owner ids: `"<weekday>"` for the planned reminder, `"<weekday>:snooze"`
/// for its single snooze.
class RoutineReminders {
  RoutineReminders({
    required this.db,
    required this.scheduler,
    required this.now,
  });

  final AppDatabase db;
  final ReminderScheduler scheduler;
  final DateTime Function() now;

  static const snoozeMinutes = 10;
  static const _steps = {
    RoutineStep.wake: ReminderKind.wake,
    RoutineStep.eat: ReminderKind.eat,
    RoutineStep.leave: ReminderKind.leave,
  };

  /// [MorningInputs] for every weekday that has a schedule row.
  Future<Map<int, MorningInputs>> inputsByWeekday() async {
    final settings = await db.settingsDao.get();
    final rows = await db.weekdayScheduleDao.getAll();
    return {
      for (final r in rows)
        r.weekday: MorningInputs(
          firstClass: r.firstClassMinutes == null
              ? null
              : LocalTime(r.firstClassMinutes!),
          commuteMinutes: r.commuteMinutes,
          prepMinutes: r.prepMinutes,
          breakfastMinutes: settings.breakfastMinutes,
          targetWake: LocalTime(settings.targetWakeMinutes),
        ),
    };
  }

  /// Recomputes the next seven days and replaces every routine owner's
  /// reminders. Call after any settings or schedule change and on launch.
  Future<void> resync() async {
    final t = now();
    final inputs = await inputsByWeekday();
    final mutes = await db.reminderMutesDao.between(
      t,
      t.add(const Duration(days: 7)),
    );
    final planned = planRoutineReminders(
      now: t,
      inputsByWeekday: inputs,
      muted: {for (final m in mutes) '${m.kind.name}:${m.ownerId}:${m.date}'},
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
      _ => 'Time to leave',
    };
    await scheduler.replaceOwner(kind, '$weekday$snoozeOwnerSuffix', [
      (fireAt: at, title: title, body: 'Ten minutes later, as asked.'),
    ]);
  }

  /// Marks the step done for today in `daily_logs` and drops any snooze.
  Future<void> done(ReminderKind kind, int weekday) async {
    final t = now();
    final logs = db.dailyLogsDao;
    switch (kind) {
      case ReminderKind.wake:
        await logs.logWake(t, t);
      case ReminderKind.eat:
        await logs.logEat(t, t);
      case ReminderKind.leave:
        await logs.setRoutineDone(t, true);
      default:
        return;
    }
    await scheduler.cancelOwner(kind, '$weekday$snoozeOwnerSuffix');
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
