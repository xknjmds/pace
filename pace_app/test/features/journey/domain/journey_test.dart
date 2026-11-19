import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/date_key.dart';
import 'package:pace/features/journey/domain/journey.dart';

void main() {
  Set<String> days(DateTime from, int count, {int every = 1}) => {
    for (var i = 0; i < count; i++)
      dateKey(DateTime(from.year, from.month, from.day + i * every)),
  };

  test('no data: before the first step, nothing reached', () {
    final j = journeyFrom(const JourneyInputs());
    expect(j.daysDone, 0);
    expect(j.reached, isNull);
    expect(j.next.name, 'The first step');
    expect(j.daysToNext, 1);
    expect(j.milestones, isEmpty);
    expect(j.stretchProgress, 0);
  });

  test('one day reaches the first step', () {
    final j = journeyFrom(JourneyInputs(routineDays: {'2026-11-16'}));
    expect(j.reached!.name, 'The first step');
    expect(j.next.name, 'Clover patch');
    expect(j.milestones, {Milestone.firstDay});
  });

  test('the same day counted from several sources is one day', () {
    final j = journeyFrom(
      const JourneyInputs(
        routineDays: {'2026-11-16'},
        movementDays: {'2026-11-16'},
        submittedDays: {'2026-11-16', '2026-11-17'},
      ),
    );
    expect(j.daysDone, 2);
  });

  test('gaps never move Tuck back', () {
    // Every other day for ten days, then a long break, then one more.
    final sparse = days(DateTime(2026, 9, 1), 10, every: 2);
    final before = journeyFrom(JourneyInputs(routineDays: sparse));
    final after = journeyFrom(
      JourneyInputs(routineDays: {...sparse, '2026-11-18'}),
    );
    expect(after.daysDone, greaterThan(before.daysDone));
    expect(after.reached!.day, greaterThanOrEqualTo(before.reached!.day));
  });

  test('progress is monotonic as days are added one by one', () {
    var previous = -1;
    final all = <String>{};
    for (var i = 0; i < 400; i++) {
      all.add(dateKey(DateTime(2026, 1, 1 + i * 3)));
      final j = journeyFrom(JourneyInputs(movementDays: all));
      final position = j.daysDone;
      expect(position, greaterThan(previous));
      expect(j.daysToNext, greaterThan(0));
      expect(j.stretchProgress, inInclusiveRange(0, 1));
      previous = position;
    }
  });

  test('past the last stop the open sea keeps going', () {
    final j = journeyFrom(
      JourneyInputs(routineDays: days(DateTime(2025, 1, 1), 480)),
    );
    expect(j.reached!.name, 'Open sea 1');
    expect(j.next.name, 'Open sea 2');
    expect(j.next.day, 565);
  });

  test('a steady week needs three routine days in one calendar week', () {
    // Sunday, Monday, Tuesday: split across two weeks.
    final split = journeyFrom(
      const JourneyInputs(
        routineDays: {'2026-11-15', '2026-11-16', '2026-11-17'},
      ),
    );
    expect(split.milestones, isNot(contains(Milestone.steadyWeek)));
    final week = journeyFrom(
      const JourneyInputs(
        routineDays: {'2026-11-16', '2026-11-18', '2026-11-20'},
      ),
    );
    expect(week.milestones, contains(Milestone.steadyWeek));
  });

  test('count milestones', () {
    final j = journeyFrom(
      JourneyInputs(
        movementDays: days(DateTime(2026, 10, 1), 30),
        focusSessions: 10,
        deadlinesSubmitted: 10,
      ),
    );
    expect(
      j.milestones,
      containsAll([
        Milestone.fiveMovement,
        Milestone.tenFocus,
        Milestone.tenSubmitted,
        Milestone.thirtyDays,
      ]),
    );
  });
}
