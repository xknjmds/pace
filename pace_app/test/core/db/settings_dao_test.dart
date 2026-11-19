import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

void main() {
  late DateTime now;
  late AppDatabase db;

  setUp(() {
    now = DateTime.utc(2026, 11, 14, 6, 0);
    db = AppDatabase(NativeDatabase.memory(), now: () => now);
  });

  tearDown(() => db.close());

  test('a fresh database has one settings row with calm defaults', () async {
    final s = await db.settingsDao.get();
    expect(s.targetWakeMinutes, 6 * 60 + 30);
    expect(s.sleepTargetMinutes, 8 * 60);
    expect(s.windDownLeadMinutes, 45);
    expect(s.breakfastMinutes, 15);
    expect(s.lateThresholdMinutes, 20);
    expect(s.lowEnergyEnabled, isFalse);
    expect(s.deletedAt, isNull);
  });

  test('setLowEnergy persists the flag and bumps updatedAt', () async {
    final before = await db.settingsDao.get();
    now = now.add(const Duration(minutes: 5));
    await db.settingsDao.setLowEnergy(true);
    final after = await db.settingsDao.get();
    expect(after.lowEnergyEnabled, isTrue);
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
    expect(after.updatedAt, now);
  });

  test(
    'watch emits the current row, then the new row after a change',
    () async {
      final seen = <bool>[];
      final sub = db.settingsDao
          .watch()
          .map((s) => s.lowEnergyEnabled)
          .listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(seen, [false]);
      await db.settingsDao.setLowEnergy(true);
      await pumpEventQueue();
      expect(seen, [false, true]);
    },
  );

  test('updateSettings changes several fields in one write', () async {
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(targetWakeMinutes: 6 * 60, breakfastMinutes: 20),
    );
    final s = await db.settingsDao.get();
    expect(s.targetWakeMinutes, 360);
    expect(s.breakfastMinutes, 20);
    expect(s.windDownLeadMinutes, 45);
  });

  test('hints are saved once and Getting started can be hidden', () async {
    await db.settingsDao.markHintSeen('inbox');
    await db.settingsDao.markHintSeen('inbox');
    await db.settingsDao.markHintSeen('focus');
    expect((await db.settingsDao.get()).seenHints, ['inbox', 'focus']);

    await db.settingsDao.setGettingStartedClosed(true);
    expect((await db.settingsDao.get()).gettingStartedClosedAt, isNotNull);
    await db.settingsDao.setGettingStartedClosed(false);
    expect((await db.settingsDao.get()).gettingStartedClosedAt, isNull);
  });
}
