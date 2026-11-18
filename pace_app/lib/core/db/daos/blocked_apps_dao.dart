import 'package:drift/drift.dart';

import '../app_database.dart';

part 'blocked_apps_dao.g.dart';

@DriftAccessor(tables: [BlockedApps])
class BlockedAppsDao extends DatabaseAccessor<AppDatabase>
    with _$BlockedAppsDaoMixin {
  BlockedAppsDao(super.db);

  SimpleSelectStatement<$BlockedAppsTable, BlockedApp> get _live =>
      select(blockedApps)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.label)]);

  Future<List<BlockedApp>> getAll() => _live.get();

  Stream<List<BlockedApp>> watchAll() => _live.watch();

  /// Adds [packageName], reviving a soft-deleted row so the unique key holds.
  Future<void> add(String packageName, String label) => transaction(() async {
    final now = db.now();
    final existing = await (select(
      blockedApps,
    )..where((t) => t.packageName.equals(packageName))).getSingleOrNull();
    if (existing == null) {
      await into(blockedApps).insert(
        BlockedAppsCompanion.insert(
          packageName: packageName,
          label: Value(label),
          updatedAt: now,
        ),
      );
      return;
    }
    await update(blockedApps).replace(
      existing.copyWith(
        label: label,
        updatedAt: now,
        deletedAt: const Value(null),
      ),
    );
  });

  Future<void> remove(String packageName) =>
      (update(blockedApps)..where(
            (t) => t.packageName.equals(packageName) & t.deletedAt.isNull(),
          ))
          .write(
            BlockedAppsCompanion(
              deletedAt: Value(db.now()),
              updatedAt: Value(db.now()),
            ),
          );
}
