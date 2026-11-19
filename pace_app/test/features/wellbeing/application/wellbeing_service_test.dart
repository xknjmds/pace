import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/energy/low_energy.dart';
import 'package:pace/features/wellbeing/application/wellbeing_service.dart';

import '../../../core/db/test_db.dart';

void main() {
  late TestDb t;
  late WellbeingService service;
  var resyncs = 0;

  setUp(() {
    t = TestDb(DateTime(2026, 11, 20, 7).toUtc());
    resyncs = 0;
    service = WellbeingService(
      db: t.db,
      now: () => t.now.toLocal(),
      resync: () async => resyncs++,
    );
  });
  tearDown(() => t.close());

  test('the first open records the time and is not a return', () async {
    expect(await service.noteOpened(), isFalse);
    final s = await t.db.settingsDao.get();
    expect(s.lastOpenedAt, isNotNull);
    expect(s.welcomeBackDate, isNull);
    expect(s.lightDayDate, isNull);
  });

  test('a return after five days starts a light day and a welcome', () async {
    await service.noteOpened();
    t.tick(const Duration(days: 6));
    expect(await service.noteOpened(), isTrue);
    final s = await t.db.settingsDao.get();
    expect(s.welcomeBackDate, '2026-11-26');
    expect(s.lightDayDate, '2026-11-26');
    expect(s.lowEnergyAt(t.now.toLocal()), isTrue);
    // The next day is a normal day again.
    expect(
      s.lowEnergyAt(t.now.toLocal().add(const Duration(days: 1))),
      isFalse,
    );

    await service.dismissWelcomeBack();
    expect((await t.db.settingsDao.get()).welcomeBackDate, isNull);
  });

  test('opening again the same day keeps the welcome once', () async {
    await service.noteOpened();
    t.tick(const Duration(days: 7));
    await service.noteOpened();
    await service.dismissWelcomeBack();
    t.tick(const Duration(hours: 2));
    expect(await service.noteOpened(), isFalse);
    expect((await t.db.settingsDao.get()).welcomeBackDate, isNull);
  });

  test('mood is stored on the night and can be cleared', () async {
    final night = DateTime(2026, 11, 19);
    await service.setMood(night, Mood.drained);
    expect((await t.db.dailyLogsDao.get(night))!.mood, Mood.drained);
    await service.setMood(night, null);
    expect((await t.db.dailyLogsDao.get(night))!.mood, isNull);
  });

  test('a planned light day affects only that date', () async {
    await service.planLightDay(DateTime(2026, 11, 21));
    final s = await t.db.settingsDao.get();
    expect(s.lowEnergyAt(DateTime(2026, 11, 20, 20)), isFalse);
    expect(s.lowEnergyAt(DateTime(2026, 11, 21, 8)), isTrue);
    expect(s.lowEnergyAt(DateTime(2026, 11, 22, 8)), isFalse);
    expect(resyncs, 1);
    await service.clearLightDay();
    expect((await t.db.settingsDao.get()).lightDayDate, isNull);
  });

  test(
    'steady mode can be turned on and off, and the offer declined',
    () async {
      await service.setSteadyMode(true);
      expect((await t.db.settingsDao.get()).steadyMode, isTrue);
      await service.setSteadyMode(false);
      expect((await t.db.settingsDao.get()).steadyMode, isFalse);
      expect(resyncs, 2);
      await service.dismissSteadyOffer();
      expect((await t.db.settingsDao.get()).steadyOfferDismissedAt, isNotNull);
    },
  );
}
