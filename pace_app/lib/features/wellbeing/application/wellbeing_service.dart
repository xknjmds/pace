import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../domain/wellbeing_rules.dart';

/// Light days, the evening mood, welcome back and steady mode. Everything
/// here is an offer the owner can ignore or undo.
class WellbeingService {
  WellbeingService({required this.db, required this.now, required this.resync});

  final AppDatabase db;
  final DateTime Function() now;

  /// Re-plans reminders after a change that affects them.
  final Future<void> Function() resync;

  /// Call once per launch, before reminders are planned. A return after
  /// [returningAfterDays] days away starts with a light day and a quiet
  /// welcome; the gap itself is never mentioned.
  Future<bool> noteOpened() async {
    final t = now();
    final s = await db.settingsDao.get();
    final back = isReturning(lastOpenedAt: s.lastOpenedAt, now: t);
    final today = dateKey(t);
    await db.settingsDao.updateSettings(
      (x) => x.copyWith(
        lastOpenedAt: Value(t.toUtc()),
        lightDayDate: Value(back ? today : x.lightDayDate),
        welcomeBackDate: Value(back ? today : x.welcomeBackDate),
      ),
    );
    return back;
  }

  Future<void> dismissWelcomeBack() => db.settingsDao.updateSettings(
    (x) => x.copyWith(welcomeBackDate: const Value(null)),
  );

  /// The evening's answer, stored on the night's date. Null clears it.
  Future<void> setMood(DateTime night, Mood? mood) =>
      db.dailyLogsDao.setMood(night, mood);

  /// Makes [day] a one-day low-energy day.
  Future<void> planLightDay(DateTime day) async {
    await db.settingsDao.updateSettings(
      (x) => x.copyWith(lightDayDate: Value(dateKey(day))),
    );
    await resync();
  }

  /// Back to the usual day.
  Future<void> clearLightDay() async {
    await db.settingsDao.updateSettings(
      (x) => x.copyWith(lightDayDate: const Value(null)),
    );
    await resync();
  }

  Future<void> setSteadyMode(bool on) async {
    await db.settingsDao.updateSettings((x) => x.copyWith(steadyMode: on));
    await resync();
  }

  Future<void> dismissSteadyOffer() => db.settingsDao.updateSettings(
    (x) => x.copyWith(steadyOfferDismissedAt: Value(now().toUtc())),
  );
}
