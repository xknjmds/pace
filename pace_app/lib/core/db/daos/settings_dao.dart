import 'package:drift/drift.dart';

import '../app_database.dart';

part 'settings_dao.g.dart';

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

  Future<void> setCaptureShortcut(bool enabled) =>
      updateSettings((s) => s.copyWith(captureShortcutEnabled: enabled));

  /// Closes a one-time hint for good. Saving an id twice is harmless.
  Future<void> markHintSeen(String id) => updateSettings(
    (s) => s.seenHints.contains(id)
        ? s
        : s.copyWith(seenHints: [...s.seenHints, id]),
  );

  /// Hides (or with [closed] false, brings back) Today's Getting started.
  Future<void> setGettingStartedClosed(bool closed) => updateSettings(
    (s) => s.copyWith(gettingStartedClosedAt: Value(closed ? db.now() : null)),
  );
}
