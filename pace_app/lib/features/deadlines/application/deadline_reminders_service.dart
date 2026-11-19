import '../../../core/energy/low_energy.dart';
import '../../../core/db/app_database.dart';
import '../../../core/notifications/reminder_actions.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/time/local_time.dart';
import '../../routine/application/morning_inputs.dart';
import '../../routine/domain/wake_schedule.dart';
import '../domain/deadline_reminders.dart';

/// Keeps each pending task's reminders in step with its due time, its
/// "Not today" mutes and the clock. Owner id is the task id.
class DeadlineReminders {
  DeadlineReminders({
    required this.db,
    required this.scheduler,
    required this.now,
  });

  final AppDatabase db;
  final ReminderScheduler scheduler;
  final DateTime Function() now;

  /// Three-days and one-day nudges land in the evening.
  static final eveningAt = LocalTime.of(19, 0);

  /// Morning-of nudge: half an hour after the target wake time, so it does
  /// not share a minute with the wake reminder.
  static const morningOffsetMinutes = 30;

  Future<void> resyncTask(String taskId) async {
    final task = await db.tasksDao.getById(taskId);
    if (task == null || task.status != TaskStatus.pending) {
      await scheduler.cancelOwner(ReminderKind.deadline, taskId);
      return;
    }
    final settings = await db.settingsDao.get();
    final t = now();
    final mutes = await db.reminderMutesDao.between(t, task.dueAt.toLocal());
    final reminders = computeDeadlineReminders(
      dueAt: task.dueAt.toLocal(),
      now: t,
      eveningAt: eveningAt,
      // The wake time in force on the due date: shift and weekend aware.
      morningAt: wakeOn(
        wakePlanFrom(settings),
        task.dueAt.toLocal(),
      ).plusMinutes(morningOffsetMinutes),
      lowEnergy: settings.lowEnergyAt(t),
      mutedDates: {
        for (final m in mutes)
          if (m.kind == ReminderKind.deadline && m.ownerId == taskId) m.date,
      },
    );
    await scheduler.replaceOwner(ReminderKind.deadline, taskId, [
      for (final r in reminders)
        deadlineDraft(
          reminder: r,
          title: task.title,
          subject: task.subject,
          dueAt: task.dueAt.toLocal(),
        ),
    ]);
  }

  /// On launch and after settings changes.
  Future<void> resyncAll() async {
    for (final task in await db.tasksDao.getAll()) {
      await resyncTask(task.id);
    }
  }

  Future<Task> add({
    required String title,
    String? subject,
    required DateTime dueAt,
  }) async {
    final task = await db.tasksDao.add(
      title: title,
      subject: subject,
      dueAt: dueAt,
    );
    await resyncTask(task.id);
    return task;
  }

  Future<void> edit(Task task) async {
    await db.tasksDao.edit(task);
    await resyncTask(task.id);
  }

  /// Submitted now: the remaining reminders go away.
  Future<void> markSubmitted(String taskId) => submit(taskId);

  /// Submitted at [at] (default now), with an optional [note], from the
  /// check-in sheet. The remaining reminders go away.
  Future<void> submit(String taskId, {DateTime? at, String? note}) async {
    await db.tasksDao.setStatus(
      taskId,
      TaskStatus.submitted,
      at: at,
      note: note,
    );
    await scheduler.cancelOwner(ReminderKind.deadline, taskId);
  }

  /// Couldn't submit: the task closes quietly, reminders go away. It can
  /// be reopened from Deadlines.
  Future<void> letGo(String taskId, {String? note}) async {
    await db.tasksDao.setStatus(taskId, TaskStatus.letGo, note: note);
    await scheduler.cancelOwner(ReminderKind.deadline, taskId);
  }

  /// Back to pending, reminders re-planned.
  Future<void> markPending(String taskId) async {
    await db.tasksDao.setStatus(taskId, TaskStatus.pending);
    await resyncTask(taskId);
  }

  Future<void> remove(String taskId) async {
    await scheduler.cancelOwner(ReminderKind.deadline, taskId);
    await db.tasksDao.remove(taskId);
  }

  /// Undoes [remove]: the task comes back with its reminders re-planned.
  Future<void> restore(String taskId) async {
    await db.tasksDao.restore(taskId);
    await resyncTask(taskId);
  }

  /// Silences this task's reminders for [day] only.
  Future<void> notToday(String taskId, DateTime day) async {
    await db.reminderMutesDao.mute(ReminderKind.deadline, taskId, day);
    await resyncTask(taskId);
  }

  Future<bool> handle(ReminderResponse response) async {
    final parsed = parseReminderPayload(response.payload);
    if (parsed == null || parsed.kind != ReminderKind.deadline) return false;
    switch (response.actionId) {
      case ReminderActionIds.done:
        await markSubmitted(parsed.ownerId);
      case ReminderActionIds.notToday:
        await notToday(parsed.ownerId, now());
      default:
        break;
    }
    return true;
  }
}
