import 'package:drift/drift.dart';

import '../app_database.dart';

part 'rewards_dao.g.dart';

@DriftAccessor(tables: [Rewards])
class RewardsDao extends DatabaseAccessor<AppDatabase> with _$RewardsDaoMixin {
  RewardsDao(super.db);

  SimpleSelectStatement<$RewardsTable, Reward> get _live => select(rewards)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  Future<List<Reward>> getAll() => _live.get();

  Stream<List<Reward>> watchAll() => _live.watch();

  Future<Reward> add({required String title, required int daysNeeded}) {
    assert(daysNeeded > 0);
    final now = db.now();
    return into(rewards).insertReturning(
      RewardsCompanion.insert(
        title: title,
        daysNeeded: daysNeeded,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> edit(
    String id, {
    required String title,
    required int daysNeeded,
  }) => _write(
    id,
    RewardsCompanion(title: Value(title), daysNeeded: Value(daysNeeded)),
  );

  /// Null un-claims it.
  Future<void> setClaimed(String id, DateTime? at) =>
      _write(id, RewardsCompanion(claimedAt: Value(at?.toUtc())));

  Future<void> remove(String id) =>
      _write(id, RewardsCompanion(deletedAt: Value(db.now())));

  /// Undo for [remove]: the reward comes back with its days intact.
  Future<void> restore(String id) =>
      _write(id, const RewardsCompanion(deletedAt: Value(null)));

  Future<void> _write(String id, RewardsCompanion patch) =>
      (update(rewards)..where((t) => t.id.equals(id))).write(
        patch.copyWith(updatedAt: Value(db.now())),
      );
}
