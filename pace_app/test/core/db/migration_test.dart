import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;

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
    await verifier.migrateAndValidate(db, 8);

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
    await verifier.migrateAndValidate(db, 8);

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
    await verifier.migrateAndValidate(db, 8);
    expect(await db.focusSessionsDao.getActive(), isNull);
    final s = (await db.focusSessionsDao.recent()).single;
    expect(s.endedAt, DateTime.utc(2026, 11, 15, 19));
  });

  test('a v4 database upgrades to v5 with sleep defaults', () async {
    final schema = await verifier.schemaAt(4);
    final old = v4.DatabaseAtV4(schema.newConnection());
    await old
        .into(old.settings)
        .insert(
          v4.SettingsCompanion.insert(
            id: const Value(1),
            targetWakeMinutes: const Value(7 * 60),
            updatedAt: '2026-11-17T00:00:00.000Z',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 8);
    final s = await db.settingsDao.get();
    expect(s.targetWakeMinutes, 7 * 60);
    expect(s.weekendLeewayMinutes, 60);
    expect(s.wakeGoalMinutes, isNull);
    expect(s.wakeShiftStepMinutes, 15);
    expect(s.wakeShiftEveryDays, 3);
  });

  test('a v5 database upgrades to v6 and keeps tasks', () async {
    final schema = await verifier.schemaAt(5);
    final old = v5.DatabaseAtV5(schema.newConnection());
    await old
        .into(old.tasks)
        .insert(
          v5.TasksCompanion.insert(
            id: 't-1',
            title: 'Essay',
            dueAt: '2026-11-20T08:00:00.000Z',
            status: const Value('submitted'),
            createdAt: '2026-11-17T00:00:00.000Z',
            updatedAt: '2026-11-17T00:00:00.000Z',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 8);
    final s = await db.settingsDao.get();
    expect(s.verseEnabled, isTrue);
    expect(s.gateEnabled, isFalse);
    expect(s.unlockMinutes, 10);
    expect(s.currencyCode, '');
    final task = (await db.tasksDao.getAll()).single;
    expect(task.title, 'Essay');
    expect(task.submittedAt, isNull);
    expect(await db.classBlocksDao.getAll(), isEmpty);
    expect(await db.notesDao.getAll(), isEmpty);
  });

  test('a v6 database upgrades to v7 and keeps submitted tasks', () async {
    final schema = await verifier.schemaAt(6);
    final old = v6.DatabaseAtV6(schema.newConnection());
    await old
        .into(old.tasks)
        .insert(
          v6.TasksCompanion.insert(
            id: 't-1',
            title: 'Essay',
            dueAt: '2026-11-20T08:00:00.000Z',
            status: const Value('submitted'),
            createdAt: '2026-11-17T00:00:00.000Z',
            updatedAt: '2026-11-17T00:00:00.000Z',
            submittedAt: const Value('2026-11-19T08:00:00.000Z'),
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 8);
    final task = (await db.tasksDao.getAll()).single;
    expect(task.status, TaskStatus.submitted);
    expect(task.submittedAt, isNotNull);
    expect(task.submitNote, isNull);
    expect(
      await db.checkInsDao.between(DateTime(2026), DateTime(2027)),
      isEmpty,
    );
  });

  test('a v7 install counts as already set up', () async {
    final schema = await verifier.schemaAt(7);
    final old = v7.DatabaseAtV7(schema.newConnection());
    await old
        .into(old.settings)
        .insert(
          v7.SettingsCompanion.insert(
            id: const Value(1),
            updatedAt: '2026-11-18T00:00:00.000Z',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 8);
    final s = await db.settingsDao.get();
    expect(s.onboardedAt, DateTime.utc(2026, 11, 18));
  });

  test('a fresh install has not been set up yet', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect((await db.settingsDao.get()).onboardedAt, isNull);
  });

  test('a fresh database matches the v8 snapshot', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 8);
  });
}
