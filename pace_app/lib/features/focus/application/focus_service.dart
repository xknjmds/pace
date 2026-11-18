import '../../../core/db/app_database.dart';
import '../../../core/notifications/reminder_actions.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../domain/focus_timer.dart';

/// Starts, stops and extends "just start" sessions and keeps the time-up
/// notification in step. Owner id is the session id.
class FocusService {
  FocusService({required this.db, required this.scheduler, required this.now});

  final AppDatabase db;
  final ReminderScheduler scheduler;
  final DateTime Function() now;

  FocusSessionsDao get _dao => db.focusSessionsDao;

  /// Starts [minutes] on [taskId] (or nothing in particular). A session
  /// still live is ended first, so there is only ever one.
  Future<FocusSession> start({
    String? taskId,
    int minutes = focusMinutes,
  }) async {
    final active = await _dao.getActive();
    if (active != null) await _end(active);
    final t = now();
    final session = await _dao.start(
      taskId: taskId,
      startedAt: t,
      durationMinutes: minutes,
    );
    final task = taskId == null ? null : await db.tasksDao.getById(taskId);
    await scheduler.replaceOwner(ReminderKind.focusEnd, session.id, [
      (
        fireAt: focusEndsAt(t, minutes),
        title: '$minutes minutes done',
        body: task == null
            ? 'Stop here, or keep going for ten more.'
            : '${task.title}: stop here, or keep going for ten more.',
      ),
    ]);
    return session;
  }

  /// Ends the live session with the minutes actually spent. Returns the
  /// outcome, or null when nothing was running.
  Future<({int minutes, bool completed})?> stop() async {
    final active = await _dao.getActive();
    if (active == null) return null;
    return _end(active);
  }

  /// Banks the finished ten minutes and starts ten more on the same task.
  Future<FocusSession?> keepGoing() async {
    final active = await _dao.getActive();
    if (active == null) return null;
    await _end(active);
    return start(taskId: active.taskId);
  }

  Future<({int minutes, bool completed})> _end(FocusSession s) async {
    final t = now();
    final outcome = focusOutcome(
      now: t,
      startedAt: s.startedAt,
      plannedMinutes: s.durationMinutes,
    );
    await _dao.finish(
      s.id,
      durationMinutes: outcome.minutes,
      completed: outcome.completed,
      endedAt: t,
    );
    await scheduler.cancelOwner(ReminderKind.focusEnd, s.id);
    return outcome;
  }

  /// Stop here / Keep going on the time-up notification. Stale buttons
  /// (for a session already ended) do nothing.
  Future<bool> handle(ReminderResponse response) async {
    final parsed = parseReminderPayload(response.payload);
    if (parsed == null || parsed.kind != ReminderKind.focusEnd) return false;
    final active = await _dao.getActive();
    if (active == null || active.id != parsed.ownerId) return true;
    switch (response.actionId) {
      case ReminderActionIds.done:
        await stop();
      case ReminderActionIds.snooze:
        await keepGoing();
      default:
        break; // A plain tap opens the app on the time-up screen.
    }
    return true;
  }
}
