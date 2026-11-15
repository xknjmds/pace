import 'package:drift/drift.dart';

import '../app_database.dart';

part 'scheduled_notifications_dao.g.dart';

/// Bookkeeping for what Android has been asked to show. The scheduler in
/// `core/notifications` is the only caller that also talks to Android.
@DriftAccessor(tables: [ScheduledNotifications])
class ScheduledNotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduledNotificationsDaoMixin {
  ScheduledNotificationsDao(super.db);

  /// Android notification ids below this are reserved for fixed uses.
  static const int firstNotificationId = 1000;

  SimpleSelectStatement<$ScheduledNotificationsTable, ScheduledNotification>
  get _live => select(scheduledNotifications)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.fireAt)]);

  Future<List<ScheduledNotification>> getLive() => _live.get();

  Future<List<ScheduledNotification>> byOwner(
    ReminderKind kind,
    String ownerId,
  ) =>
      (_live..where(
            (t) => t.kind.equalsValue(kind) & t.ownerId.equals(ownerId),
          ))
          .get();

  /// Inserts one row per draft, handing out fresh Android ids. Ids are never
  /// reused, even after soft deletes, so a stale alarm can never collide.
  Future<List<ScheduledNotification>> insertAll(
    ReminderKind kind,
    String ownerId,
    List<ReminderDraft> drafts,
  ) => transaction(() async {
    final maxId = scheduledNotifications.notificationId.max();
    final row = await (selectOnly(
      scheduledNotifications,
    )..addColumns([maxId])).getSingle();
    var nextId = (row.read(maxId) ?? (firstNotificationId - 1)) + 1;
    final now = db.now();
    final inserted = <ScheduledNotification>[];
    for (final d in drafts) {
      inserted.add(
        await into(scheduledNotifications).insertReturning(
          ScheduledNotificationsCompanion.insert(
            notificationId: nextId++,
            kind: kind,
            ownerId: ownerId,
            fireAt: d.fireAt.toUtc(),
            title: d.title,
            body: d.body,
            updatedAt: now,
          ),
        ),
      );
    }
    return inserted;
  });

  Future<void> softDeleteByOwner(ReminderKind kind, String ownerId) =>
      (update(scheduledNotifications)..where(
            (t) =>
                t.kind.equalsValue(kind) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull(),
          ))
          .write(_deleted());

  Future<void> softDeleteIds(Iterable<String> ids) => (update(
    scheduledNotifications,
  )..where((t) => t.id.isIn(ids) & t.deletedAt.isNull())).write(_deleted());

  ScheduledNotificationsCompanion _deleted() => ScheduledNotificationsCompanion(
    deletedAt: Value(db.now()),
    updatedAt: Value(db.now()),
  );
}
