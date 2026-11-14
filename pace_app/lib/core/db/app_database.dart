import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Columns every table carries so a later sync layer can diff and merge rows.
///
/// Rows are never hard-deleted: DAOs set [deletedAt] and reads filter it out.
mixin SyncColumns on Table {
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Single-row table (id = 1) holding the owner's preferences.
/// Times of day are minutes since midnight; durations are minutes.
class Settings extends Table with SyncColumns {
  IntColumn get id => integer()();
  IntColumn get targetWakeMinutes =>
      integer().withDefault(const Constant(6 * 60 + 30))();
  IntColumn get sleepTargetMinutes =>
      integer().withDefault(const Constant(8 * 60))();
  IntColumn get windDownLeadMinutes =>
      integer().withDefault(const Constant(45))();
  IntColumn get breakfastMinutes => integer().withDefault(const Constant(15))();
  IntColumn get lateThresholdMinutes =>
      integer().withDefault(const Constant(20))();
  BoolColumn get lowEnergyEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Settings], daos: [SettingsDao])
class AppDatabase extends _$AppDatabase {
  /// [now] supplies the UTC timestamp written to `updated_at`. Injectable so
  /// tests can assert exact values.
  AppDatabase(super.executor, {DateTime Function()? now})
    : now = now ?? _utcNow;

  /// Opens the on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'pace'));

  final DateTime Function() now;

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) => settingsDao.ensureRow(),
  );
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static const int _rowId = 1;

  SimpleSelectStatement<$SettingsTable, Setting> get _row =>
      select(settings)
        ..where((t) => t.id.equals(_rowId) & t.deletedAt.isNull());

  /// Inserts the defaults row if it does not exist yet.
  Future<void> ensureRow() => into(settings).insert(
    SettingsCompanion.insert(id: const Value(_rowId), updatedAt: db.now()),
    mode: InsertMode.insertOrIgnore,
  );

  Future<Setting> get() => _row.getSingle();

  Stream<Setting> watch() => _row.watchSingle();

  /// Applies [change] to the current row and stamps `updated_at`.
  Future<void> updateSettings(Setting Function(Setting current) change) async {
    final current = await get();
    final next = change(current).copyWith(updatedAt: db.now());
    await update(settings).replace(next);
  }

  Future<void> setLowEnergy(bool enabled) =>
      updateSettings((s) => s.copyWith(lowEnergyEnabled: enabled));
}
