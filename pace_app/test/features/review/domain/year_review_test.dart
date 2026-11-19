import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/review/domain/year_review.dart';

void main() {
  test('the school year starts on the 1st of the start month', () {
    expect(schoolYearStart(DateTime(2026, 11, 20), 6), DateTime(2026, 6));
    expect(schoolYearStart(DateTime(2027, 3, 1), 6), DateTime(2026, 6));
    expect(schoolYearStart(DateTime(2026, 6, 1, 8), 6), DateTime(2026, 6));
    expect(schoolYearStart(DateTime(2026, 5, 31), 6), DateTime(2025, 6));
  });

  test('only days inside the school year count', () {
    final y = yearInReview(
      today: DateTime(2026, 11, 20),
      startMonth: 6,
      routineDays: {'2026-05-31', '2026-06-01', '2026-11-20', '2026-11-21'},
      movementDays: {'2026-06-01', '2026-07-01'},
      bedtimeNights: {'2026-05-30', '2026-10-10'},
    );
    expect(y.routineDays, 2);
    expect(y.movementDays, 2);
    expect(y.daysDone, 3);
    expect(y.nightsLogged, 1);
  });

  test('focus sessions and hours', () {
    final y = yearInReview(
      today: DateTime(2026, 11, 20),
      startMonth: 6,
      focus: [
        (startedAt: DateTime(2026, 9, 1, 15), minutes: 50),
        (startedAt: DateTime(2026, 9, 2, 15), minutes: 25),
        (startedAt: DateTime(2026, 4, 2, 15), minutes: 25),
      ],
    );
    expect(y.focusSessions, 2);
    expect(y.focusMinutes, 75);
    expect(y.lines, ['2 focus sessions, about 1 hour']);
  });

  test('an empty year says so and lists nothing', () {
    final y = yearInReview(today: DateTime(2026, 11, 20), startMonth: 6);
    expect(y.isEmpty, isTrue);
    expect(y.lines, isEmpty);
  });

  test('lines are positive totals only', () {
    final y = yearInReview(
      today: DateTime(2026, 11, 20),
      startMonth: 6,
      routineDays: {'2026-11-19'},
      deadlinesSubmitted: 4,
      rewardsEnjoyed: 1,
    );
    expect(y.lines, [
      '1 day with something done',
      '1 morning out the door with the routine done',
      '4 deadlines handed in',
      '1 reward enjoyed',
    ]);
    for (final l in y.lines) {
      expect(l.toLowerCase(), isNot(contains('miss')));
      expect(l, isNot(contains('%')));
    }
  });
}
