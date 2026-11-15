import 'package:drift/drift.dart';

import '../app_database.dart';

part 'inbox_dao.g.dart';

@DriftAccessor(tables: [InboxItems])
class InboxDao extends DatabaseAccessor<AppDatabase> with _$InboxDaoMixin {
  InboxDao(super.db);

  SimpleSelectStatement<$InboxItemsTable, InboxItem> get _unprocessed =>
      select(inboxItems)
        ..where((t) => t.deletedAt.isNull() & t.processed.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  Future<InboxItem> add(String text) {
    final now = db.now();
    return into(inboxItems).insertReturning(
      InboxItemsCompanion.insert(body: text, createdAt: now, updatedAt: now),
    );
  }

  Future<List<InboxItem>> getUnprocessed() => _unprocessed.get();

  Stream<List<InboxItem>> watchUnprocessed() => _unprocessed.watch();

  Stream<int> watchUnprocessedCount() =>
      watchUnprocessed().map((items) => items.length);

  /// The item became a task or was dealt with; it leaves the inbox.
  Future<void> markProcessed(String id) =>
      (update(inboxItems)..where((t) => t.id.equals(id))).write(
        InboxItemsCompanion(
          processed: const Value(true),
          updatedAt: Value(db.now()),
        ),
      );

  Future<void> remove(String id) =>
      (update(inboxItems)..where((t) => t.id.equals(id))).write(
        InboxItemsCompanion(
          deletedAt: Value(db.now()),
          updatedAt: Value(db.now()),
        ),
      );
}
