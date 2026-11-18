import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a v1 database upgrades to the latest and keeps settings', () async {
    final schema = await verifier.schemaAt(1);

    // A real v1 install with one changed setting.
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old
        .into(old.settings)
        .insert(
          v1.SettingsCompanion.insert(
            id: const Value(1),
            // Raw column types: bools are ints, dates are ISO text.
            lowEnergyEnabled: const Value(1),
            breakfastMinutes: const Value(25),
            updatedAt: '2026-11-01T00:00:00.000Z',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    final s = await db.settingsDao.get();
    expect(s.lowEnergyEnabled, isTrue);
    expect(s.breakfastMinutes, 25);
    expect(s.captureShortcutEnabled, isTrue);
    expect(await db.tasksDao.getAll(), isEmpty);
    expect(await db.weekdayScheduleDao.getAll(), isEmpty);
    expect(await db.scheduledNotificationsDao.getLive(), isEmpty);
  });

  test('a v2 database upgrades to the latest and keeps its rows', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old
        .into(old.settings)
        .insert(
          v2.SettingsCompanion.insert(
            id: const Value(1),
            targetWakeMinutes: const Value(7 * 60),
            updatedAt: '2026-11-10T00:00:00.000Z',
          ),
        );
    await old
        .into(old.inboxItems)
        .insert(
          v2.InboxItemsCompanion.insert(
            id: 'item-1',
            text$: 'buy index cards',
            createdAt: '2026-11-10T08:00:00.000Z',
            updatedAt: '2026-11-10T08:00:00.000Z',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    final s = await db.settingsDao.get();
    expect(s.targetWakeMinutes, 7 * 60);
    expect(s.captureShortcutEnabled, isTrue);
    expect((await db.inboxDao.getUnprocessed()).single.body, 'buy index cards');
  });

  test('v3 focus sessions become history, not live timers', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    await old
        .into(old.focusSessions)
        .insert(
          v3.FocusSessionsCompanion.insert(
            id: 'f-1',
            startedAt: '2026-11-15T19:00:00.000Z',
            durationMinutes: 10,
            updatedAt: '2026-11-15T19:10:00.000Z',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);
    expect(await db.focusSessionsDao.getActive(), isNull);
    final s = (await db.focusSessionsDao.recent()).single;
    expect(s.endedAt, DateTime.utc(2026, 11, 15, 19));
  });

  test('a fresh database matches the v4 snapshot', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);
  });
}
