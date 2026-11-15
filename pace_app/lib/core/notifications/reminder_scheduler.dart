import '../db/app_database.dart';
import 'notification_gateway.dart';
import 'reminder_actions.dart';

/// The one place that both writes `scheduled_notifications` and talks to
/// Android (CLAUDE.md rule 2). Features never touch notification ids: they
/// hand over drafts for an owner, and cancel by owner.
class ReminderScheduler {
  ReminderScheduler({
    required this.db,
    required this.gateway,
    required this.now,
  });

  final AppDatabase db;
  final NotificationGateway gateway;
  final DateTime Function() now;

  ScheduledNotificationsDao get _dao => db.scheduledNotificationsDao;

  /// Removes every pending reminder of [kind] for [ownerId], in Android and
  /// in the table.
  Future<void> cancelOwner(ReminderKind kind, String ownerId) async {
    final rows = await _dao.byOwner(kind, ownerId);
    for (final row in rows) {
      await gateway.cancel(row.notificationId);
    }
    await _dao.softDeleteByOwner(kind, ownerId);
  }

  /// Replaces the owner's reminders with [drafts]. Drafts already in the past
  /// are dropped silently: there is nothing to show for them.
  Future<List<ScheduledNotification>> replaceOwner(
    ReminderKind kind,
    String ownerId,
    List<ReminderDraft> drafts,
  ) async {
    await cancelOwner(kind, ownerId);
    final t = now();
    final upcoming = drafts.where((d) => d.fireAt.isAfter(t)).toList();
    final rows = await _dao.insertAll(kind, ownerId, upcoming);
    for (final row in rows) {
      await _schedule(row);
    }
    return rows;
  }

  /// Makes Android match the table: drops rows whose time has passed,
  /// cancels whatever Android still holds, and schedules every future row.
  /// Run on every app launch; cheap for the few dozen rows PACE keeps.
  Future<void> rebuildAll() async {
    final t = now();
    final rows = await _dao.getLive();
    final past = rows.where((r) => !r.fireAt.isAfter(t)).map((r) => r.id);
    if (past.isNotEmpty) await _dao.softDeleteIds(past.toList());
    for (final pending in await gateway.pending()) {
      await gateway.cancel(pending.id);
    }
    for (final row in rows.where((r) => r.fireAt.isAfter(t))) {
      await _schedule(row);
    }
  }

  Future<void> _schedule(ScheduledNotification row) => gateway.schedule(
    id: row.notificationId,
    title: row.title,
    body: row.body,
    fireAt: row.fireAt,
    payload: reminderPayload(row.kind, row.ownerId),
    actions: actionsFor(row.kind, row.ownerId),
  );
}
