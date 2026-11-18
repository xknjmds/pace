import 'package:drift/drift.dart';

import '../app_database.dart';

part 'class_blocks_dao.g.dart';

@DriftAccessor(tables: [ClassBlocks])
class ClassBlocksDao extends DatabaseAccessor<AppDatabase>
    with _$ClassBlocksDaoMixin {
  ClassBlocksDao(super.db);

  SimpleSelectStatement<$ClassBlocksTable, ClassBlock> get _live =>
      select(classBlocks)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.weekday),
          (t) => OrderingTerm.asc(t.startMinutes),
        ]);

  Future<List<ClassBlock>> getAll() => _live.get();

  Stream<List<ClassBlock>> watchAll() => _live.watch();

  Future<List<ClassBlock>> forWeekday(int weekday) =>
      (_live..where((t) => t.weekday.equals(weekday))).get();

  Future<ClassBlock> add({
    required int weekday,
    required String subject,
    required int startMinutes,
    required int endMinutes,
    String? room,
    BlockSource source = BlockSource.manual,
  }) => into(classBlocks).insertReturning(
    ClassBlocksCompanion.insert(
      weekday: weekday,
      subject: subject,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      room: Value(room),
      source: Value(source),
      updatedAt: db.now(),
    ),
  );

  Future<void> edit(ClassBlock block) =>
      update(classBlocks).replace(block.copyWith(updatedAt: db.now()));

  Future<void> remove(String id) =>
      (update(classBlocks)..where((t) => t.id.equals(id))).write(_deleted());

  /// Undoes [remove].
  Future<void> restore(String id) =>
      (update(classBlocks)..where((t) => t.id.equals(id))).write(
        ClassBlocksCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(db.now()),
        ),
      );

  /// An image import replaces every earlier image-sourced block and keeps
  /// the ones typed in by hand.
  Future<void> replaceImported(List<ClassBlocksCompanion> blocks) =>
      transaction(() async {
        await (update(classBlocks)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.source.equalsValue(BlockSource.image),
            ))
            .write(_deleted());
        for (final b in blocks) {
          await into(classBlocks).insert(
            b.copyWith(
              source: const Value(BlockSource.image),
              updatedAt: Value(db.now()),
            ),
          );
        }
      });

  ClassBlocksCompanion _deleted() => ClassBlocksCompanion(
    deletedAt: Value(db.now()),
    updatedAt: Value(db.now()),
  );
}
