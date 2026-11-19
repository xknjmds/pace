import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/check_in/check_in_outcome.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/core/check_in/check_in_rules.dart';

void main() {
  final planned = LocalTime.of(6, 30);

  group('suggestOutcome', () {
    test('inside the grace window is on time', () {
      expect(
        suggestOutcome(
          planned: planned,
          actual: LocalTime.of(6, 50),
          graceMinutes: 20,
        ),
        CheckInOutcome.onTime,
      );
      expect(
        suggestOutcome(
          planned: planned,
          actual: LocalTime.of(6, 0),
          graceMinutes: 20,
        ),
        CheckInOutcome.onTime,
      );
    });

    test('past the grace window is a bit later', () {
      expect(
        suggestOutcome(
          planned: planned,
          actual: LocalTime.of(6, 51),
          graceMinutes: 20,
        ),
        CheckInOutcome.later,
      );
    });

    test('wraps around midnight', () {
      expect(
        suggestOutcome(
          planned: LocalTime.of(22, 30),
          actual: LocalTime.of(0, 40),
          graceMinutes: 20,
        ),
        CheckInOutcome.later,
      );
      expect(
        suggestOutcome(
          planned: LocalTime.of(0, 10),
          actual: LocalTime.of(23, 55),
          graceMinutes: 20,
        ),
        CheckInOutcome.onTime,
      );
    });

    test('no plan means on time', () {
      expect(
        suggestOutcome(
          planned: null,
          actual: LocalTime.of(9, 0),
          graceMinutes: 20,
        ),
        CheckInOutcome.onTime,
      );
    });
  });

  group('checkInNote', () {
    test('never shames', () {
      for (final outcome in CheckInOutcome.values) {
        final note = checkInNote(outcome, LocalTime.of(7, 5));
        expect(note.toLowerCase(), isNot(contains('miss')));
        expect(note.toLowerCase(), isNot(contains('fail')));
        expect(note.toLowerCase(), isNot(contains('late')));
      }
    });

    test('names the time when there is one', () {
      expect(
        checkInNote(CheckInOutcome.later, LocalTime.of(7, 5)),
        contains('07:05'),
      );
    });
  });

  group('resolvePickedTime', () {
    final now = DateTime(2026, 11, 19, 0, 30);

    test('earlier today stays today', () {
      expect(
        resolvePickedTime(now, LocalTime.of(0, 10)),
        DateTime(2026, 11, 19, 0, 10),
      );
    });

    test('a time still ahead means yesterday', () {
      expect(
        resolvePickedTime(now, LocalTime.of(23, 40)),
        DateTime(2026, 11, 18, 23, 40),
      );
    });
  });
}
