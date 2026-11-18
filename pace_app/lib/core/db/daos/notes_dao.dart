import 'package:drift/drift.dart';

import '../app_database.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  SimpleSelectStatement<$NotesTable, Note> get _live => select(notes)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

  Future<List<Note>> getAll() => _live.get();

  /// Notes whose title or body contains [query] (any case), newest first.
  /// An empty query lists everything.
  Stream<List<Note>> watchSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return _live.watch();
    final pattern =
        '%${q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    return (_live..where(
          (t) =>
              t.title.like(pattern, escapeChar: r'\') |
              t.body.like(pattern, escapeChar: r'\'),
        ))
        .watch();
  }

  Future<List<Note>> search(String query) => watchSearch(query).first;

  Future<Note?> getById(String id) =>
      (_live..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Note> add({String title = '', String body = ''}) {
    final now = db.now();
    return into(notes).insertReturning(
      NotesCompanion.insert(
        title: Value(title),
        body: Value(body),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> edit(String id, {required String title, required String body}) =>
      (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          title: Value(title),
          body: Value(body),
          updatedAt: Value(db.now()),
        ),
      );

  Future<void> remove(String id) =>
      (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(deletedAt: Value(db.now()), updatedAt: Value(db.now())),
      );
}
