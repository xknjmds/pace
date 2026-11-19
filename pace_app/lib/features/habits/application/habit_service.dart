import '../../../core/energy/low_energy.dart';
import '../../../core/db/app_database.dart';
import '../../../core/notifications/reminder_actions.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../routine/application/day_times.dart';
import '../domain/habit_planner.dart';

/// The movement habit: its reminder, rebuilt from data like every other
/// (CLAUDE.md rule 2), and the one-tap "done". Owner id is the habit id.
class HabitService {
  HabitService({required this.db, required this.scheduler, required this.now});

  final AppDatabase db;
  final ReminderScheduler scheduler;
  final DateTime Function() now;

  static HabitPoint pointFor(HabitAnchor a) => HabitPoint.values.byName(a.name);

  /// Replans the habit's reminders for the coming week. Call after any
  /// routine, settings or habit change, and on launch.
  Future<void> resync() async {
    final habit = await db.habitsDao.ensureMovement();
    if (!habit.active) {
      await scheduler.cancelOwner(ReminderKind.habit, habit.id);
      return;
    }
    final t = now();
    final settings = await db.settingsDao.get();
    final timesFor = await loadRoutineTimes(db);
    final end = t.add(const Duration(days: 7));
    final mutes = await db.reminderMutesDao.between(t, end);
    final drafts = planHabitReminders(
      now: t,
      name: habit.name,
      point: pointFor(habit.anchor),
      offsetMinutes: habit.offsetMinutes,
      timesFor: timesFor,
      doneDays: await db.habitsDao.doneDaysBetween(t, end),
      mutedDays: {
        for (final m in mutes)
          if (m.kind == ReminderKind.habit && m.ownerId == habit.id) m.date,
      },
      lowEnergy: settings.lowEnergyAt(t),
    );
    await scheduler.replaceOwner(ReminderKind.habit, habit.id, drafts);
  }

  /// Done (or undone) today. A done tap drops today's remaining reminder.
  Future<void> setDoneToday(bool done) async {
    final habit = await db.habitsDao.ensureMovement();
    await db.habitsDao.setDone(habit.id, now(), done);
    await resync();
  }

  Future<void> update(Habit habit) async {
    await db.habitsDao.edit(habit);
    await resync();
  }

  Future<bool> handle(ReminderResponse response) async {
    final parsed = parseReminderPayload(response.payload);
    if (parsed == null || parsed.kind != ReminderKind.habit) return false;
    switch (response.actionId) {
      case ReminderActionIds.done:
        await db.habitsDao.setDone(parsed.ownerId, now(), true);
        await resync();
      case ReminderActionIds.notToday:
        await db.reminderMutesDao.mute(
          ReminderKind.habit,
          parsed.ownerId,
          now(),
        );
        await resync();
      default:
        break;
    }
    return true;
  }
}
