import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/energy/low_energy.dart';
import 'package:pace/features/wellbeing/domain/wellbeing_rules.dart';

void main() {
  final now = DateTime(2026, 11, 20, 7);

  group('isReturning', () {
    test('the first open is not a return', () {
      expect(isReturning(lastOpenedAt: null, now: now), isFalse);
    });

    test('four days away is not yet a return, five is', () {
      expect(
        isReturning(lastOpenedAt: DateTime(2026, 11, 16, 23), now: now),
        isFalse,
      );
      expect(
        isReturning(lastOpenedAt: DateTime(2026, 11, 15, 8), now: now),
        isTrue,
      );
    });

    test('counts calendar days, so a late-night open still counts', () {
      // 23:59 five days back is still five calendar days.
      expect(
        isReturning(lastOpenedAt: DateTime(2026, 11, 15, 23, 59), now: now),
        isTrue,
      );
    });

    test('works with UTC timestamps from the database', () {
      expect(
        isReturning(lastOpenedAt: DateTime(2026, 11, 10, 12).toUtc(), now: now),
        isTrue,
      );
    });
  });

  group('light day', () {
    test('only the stored date is light', () {
      expect(isLightDay('2026-11-20', now), isTrue);
      expect(isLightDay('2026-11-19', now), isFalse);
      expect(isLightDay('2026-11-21', now), isFalse);
      expect(isLightDay(null, now), isFalse);
    });

    test('effective low energy is the switch or a light day', () {
      expect(
        effectiveLowEnergy(enabled: false, lightDayDate: null, now: now),
        isFalse,
      );
      expect(
        effectiveLowEnergy(enabled: true, lightDayDate: null, now: now),
        isTrue,
      );
      expect(
        effectiveLowEnergy(
          enabled: false,
          lightDayDate: '2026-11-20',
          now: now,
        ),
        isTrue,
      );
      expect(
        effectiveLowEnergy(
          enabled: false,
          lightDayDate: '2026-11-19',
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('shouldOfferSteady', () {
    List<DateTime> days(int count, {int startAgo = 0}) => [
      for (var i = 0; i < count; i++)
        DateTime(now.year, now.month, now.day - startAgo - i),
    ];

    test('twelve done mornings in three weeks is steady', () {
      expect(
        shouldOfferSteady(
          routineDoneDates: days(12),
          now: now,
          steadyMode: false,
          dismissedAt: null,
        ),
        isTrue,
      );
    });

    test('eleven is not yet', () {
      expect(
        shouldOfferSteady(
          routineDoneDates: days(11),
          now: now,
          steadyMode: false,
          dismissedAt: null,
        ),
        isFalse,
      );
    });

    test('old mornings beyond three weeks do not count', () {
      expect(
        shouldOfferSteady(
          routineDoneDates: days(12, startAgo: 15),
          now: now,
          steadyMode: false,
          dismissedAt: null,
        ),
        isFalse,
      );
    });

    test('never offered when already on', () {
      expect(
        shouldOfferSteady(
          routineDoneDates: days(20),
          now: now,
          steadyMode: true,
          dismissedAt: null,
        ),
        isFalse,
      );
    });

    test('a no thanks waits sixty days', () {
      expect(
        shouldOfferSteady(
          routineDoneDates: days(20),
          now: now,
          steadyMode: false,
          dismissedAt: DateTime(2026, 10, 1),
        ),
        isFalse,
      );
      expect(
        shouldOfferSteady(
          routineDoneDates: days(20),
          now: now,
          steadyMode: false,
          dismissedAt: DateTime(2026, 9, 1),
        ),
        isTrue,
      );
    });

    test('the same date twice counts once', () {
      expect(
        shouldOfferSteady(
          routineDoneDates: [...days(6), ...days(6)],
          now: now,
          steadyMode: false,
          dismissedAt: null,
        ),
        isFalse,
      );
    });
  });

  group('moodSummary', () {
    test('nothing answered says nothing', () {
      expect(moodSummary(good: 0, okay: 0, drained: 0), isNull);
    });

    test('lists only what was answered, in a fixed order', () {
      expect(
        moodSummary(good: 2, okay: 0, drained: 1),
        'Evenings: 2 good · 1 drained',
      );
      expect(moodSummary(good: 0, okay: 3, drained: 0), 'Evenings: 3 okay');
    });
  });
}
