import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  group('class blocks', () {
    test('re-importing replaces image blocks and keeps manual ones', () async {
      final dao = t.db.classBlocksDao;
      await dao.add(
        weekday: 1,
        subject: 'Club',
        startMinutes: 900,
        endMinutes: 960,
      );
      await dao.replaceImported([
        ClassBlocksCompanion.insert(
          weekday: 1,
          subject: 'Old math',
          startMinutes: 480,
          endMinutes: 540,
          updatedAt: t.now,
        ),
      ]);
      await dao.replaceImported([
        ClassBlocksCompanion.insert(
          weekday: 2,
          subject: 'Math',
          startMinutes: 480,
          endMinutes: 540,
          updatedAt: t.now,
        ),
      ]);
      final all = await dao.getAll();
      expect(all.map((b) => (b.subject, b.source)), [
        ('Club', BlockSource.manual),
        ('Math', BlockSource.image),
      ]);
    });

    test('remove is a soft delete', () async {
      final dao = t.db.classBlocksDao;
      final b = await dao.add(
        weekday: 3,
        subject: 'Art',
        startMinutes: 600,
        endMinutes: 660,
      );
      t.tick();
      await dao.remove(b.id);
      expect(await dao.getAll(), isEmpty);
      final raw = await t.db.select(t.db.classBlocks).getSingle();
      expect(raw.deletedAt, t.now);
    });
  });

  group('habits', () {
    test('one movement habit, created inactive, done days by date', () async {
      final dao = t.db.habitsDao;
      final h = await dao.ensureMovement();
      expect(h.active, isFalse);
      expect((await dao.ensureMovement()).id, h.id);
      final day = DateTime(2026, 11, 18);
      await dao.setDone(h.id, day, true);
      expect(await dao.isDone(h.id, day), isTrue);
      await dao.setDone(h.id, day, false);
      await dao.setDone(h.id, day, true); // re-uses the row, unique key holds
      expect(
        await dao.doneDaysBetween(
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 22),
        ),
        {'2026-11-18'},
      );
    });
  });

  group('blocked apps', () {
    test('removing and re-adding revives the row', () async {
      final dao = t.db.blockedAppsDao;
      await dao.add('com.example.video', 'Video');
      await dao.remove('com.example.video');
      expect(await dao.getAll(), isEmpty);
      await dao.add('com.example.video', 'Video');
      expect((await dao.getAll()).single.packageName, 'com.example.video');
    });
  });

  group('notes', () {
    test('search finds text in titles and bodies, any case', () async {
      final dao = t.db.notesDao;
      await dao.add(title: 'Recipe', body: 'eggs and rice');
      await dao.add(title: 'Ideas', body: 'A RICE cooker');
      await dao.add(title: 'Other', body: 'nothing here');
      expect((await dao.search('rice')).map((n) => n.title).toSet(), {
        'Recipe',
        'Ideas',
      });
      expect((await dao.search('recipe')).single.title, 'Recipe');
      expect(await dao.search('100%'), isEmpty);
      expect(await dao.search(''), hasLength(3));
    });

    test('deleted notes stay out of every read', () async {
      final dao = t.db.notesDao;
      final n = await dao.add(title: 'Gone');
      await dao.remove(n.id);
      expect(await dao.getAll(), isEmpty);
      expect(await dao.getById(n.id), isNull);
    });
  });

  group('finance', () {
    test('only the newest budget counts; null clears it', () async {
      final dao = t.db.financeDao;
      await dao.setBudget(BudgetPeriod.weekly, 50000);
      t.tick();
      await dao.setBudget(BudgetPeriod.monthly, 200000);
      final b = await dao.getBudget();
      expect(b!.period, BudgetPeriod.monthly);
      expect(b.amountMinor, 200000);
      await dao.setBudget(null, 0);
      expect(await dao.getBudget(), isNull);
    });

    test('expenses store UTC and soft delete', () async {
      final dao = t.db.financeDao;
      final e = await dao.addExpense(
        amountMinor: 1250,
        category: 'Food',
        spentAt: DateTime(2026, 11, 18, 12),
      );
      expect(e.spentAt.isUtc, isTrue);
      await dao.removeExpense(e.id);
      expect(await dao.getAll(), isEmpty);
    });
  });

  group('calendar events', () {
    test(
      'replaceAll inserts, updates, and drops what Google no longer has',
      () async {
        final dao = t.db.calendarEventsDao;
        final s = DateTime.utc(2026, 11, 18, 7);
        await dao.replaceAll([
          (
            externalId: 'a',
            title: 'A',
            startAt: s,
            endAt: s.add(const Duration(hours: 1)),
            allDay: false,
          ),
          (
            externalId: 'b',
            title: 'B',
            startAt: s,
            endAt: s.add(const Duration(hours: 1)),
            allDay: false,
          ),
        ]);
        await dao.replaceAll([
          (
            externalId: 'a',
            title: 'A moved',
            startAt: s,
            endAt: s.add(const Duration(hours: 2)),
            allDay: false,
          ),
        ]);
        final events = await dao.between(
          s.subtract(const Duration(days: 1)),
          s.add(const Duration(days: 1)),
        );
        expect(events.map((e) => e.title), ['A moved']);
      },
    );

    test('clear forgets every cached event', () async {
      final dao = t.db.calendarEventsDao;
      final s = DateTime.utc(2026, 11, 18, 7);
      await dao.replaceAll([
        (
          externalId: 'a',
          title: 'A',
          startAt: s,
          endAt: s.add(const Duration(hours: 1)),
          allDay: false,
        ),
      ]);
      await dao.clear();
      expect(
        await dao.between(
          s.subtract(const Duration(days: 1)),
          s.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
    });
  });

  test(
    'submitted tasks carry when they were submitted, reopening clears it',
    () async {
      final dao = t.db.tasksDao;
      final task = await dao.add(
        title: 'Essay',
        dueAt: DateTime.utc(2026, 11, 20),
      );
      await dao.markSubmitted(task.id);
      expect((await dao.getById(task.id))!.submittedAt, t.now);
      expect(
        await dao.submittedBetween(
          t.now.subtract(const Duration(days: 1)),
          t.now.add(const Duration(days: 1)),
        ),
        hasLength(1),
      );
      await dao.setStatus(task.id, TaskStatus.pending);
      expect((await dao.getById(task.id))!.submittedAt, isNull);
    },
  );

  test('new settings have calm defaults', () async {
    final s = await t.db.settingsDao.get();
    expect(s.verseEnabled, isTrue);
    expect(s.gateEnabled, isFalse);
    expect(s.morningLockEnabled, isTrue);
    expect(s.unlockMinutes, 10);
    expect(s.calendarSyncedAt, isNull);
    await t.db.settingsDao.updateSettings(
      (x) => x.copyWith(calendarSyncedAt: Value(t.now)),
    );
    expect((await t.db.settingsDao.get()).calendarSyncedAt, t.now);
  });
}
