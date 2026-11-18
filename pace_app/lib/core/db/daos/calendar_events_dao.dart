import 'package:drift/drift.dart';

import '../app_database.dart';

part 'calendar_events_dao.g.dart';

/// A fetched event, before it is cached.
typedef FetchedEvent = ({
  String externalId,
  String title,
  DateTime startAt,
  DateTime endAt,
  bool allDay,
});

@DriftAccessor(tables: [CalendarEvents])
class CalendarEventsDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarEventsDaoMixin {
  CalendarEventsDao(super.db);

  /// Events overlapping [from] to [to], soonest first.
  Stream<List<CalendarEvent>> watchBetween(DateTime from, DateTime to) =>
      (select(calendarEvents)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.startAt.isSmallerThanValue(to.toUtc()) &
                  t.endAt.isBiggerThanValue(from.toUtc()),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
          .watch();

  Future<List<CalendarEvent>> between(DateTime from, DateTime to) =>
      watchBetween(from, to).first;

  /// Makes the cache match [events] exactly: new ones inserted, changed
  /// ones updated, ones no longer returned soft-deleted.
  Future<void> replaceAll(List<FetchedEvent> events) => transaction(() async {
    final now = db.now();
    final existing = {
      for (final e in await select(calendarEvents).get()) e.externalId: e,
    };
    final keep = <String>{};
    for (final f in events) {
      keep.add(f.externalId);
      final old = existing[f.externalId];
      if (old == null) {
        await into(calendarEvents).insert(
          CalendarEventsCompanion.insert(
            externalId: f.externalId,
            title: f.title,
            startAt: f.startAt.toUtc(),
            endAt: f.endAt.toUtc(),
            allDay: Value(f.allDay),
            cachedAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await update(calendarEvents).replace(
          old.copyWith(
            title: f.title,
            startAt: f.startAt.toUtc(),
            endAt: f.endAt.toUtc(),
            allDay: f.allDay,
            cachedAt: now,
            updatedAt: now,
            deletedAt: const Value(null),
          ),
        );
      }
    }
    for (final old in existing.values) {
      if (!keep.contains(old.externalId) && old.deletedAt == null) {
        await (update(calendarEvents)..where((t) => t.id.equals(old.id))).write(
          CalendarEventsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
      }
    }
  });

  /// Signing out forgets every cached event.
  Future<void> clear() =>
      (update(calendarEvents)..where((t) => t.deletedAt.isNull())).write(
        CalendarEventsCompanion(
          deletedAt: Value(db.now()),
          updatedAt: Value(db.now()),
        ),
      );
}
