import 'package:drift/native.dart';
import 'package:pace/core/db/app_database.dart';

/// In-memory database with an adjustable clock for `updated_at` asserts.
class TestDb {
  TestDb([DateTime? start]) : now = start ?? DateTime.utc(2026, 11, 14, 6) {
    db = AppDatabase(NativeDatabase.memory(), now: () => now);
  }

  late final AppDatabase db;
  DateTime now;

  void tick([Duration by = const Duration(minutes: 1)]) => now = now.add(by);

  Future<void> close() => db.close();
}
