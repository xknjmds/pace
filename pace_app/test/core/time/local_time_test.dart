import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';

void main() {
  test('LocalTime.of stores minutes since midnight', () {
    expect(LocalTime.of(6, 30).minutesSinceMidnight, 390);
  });

  test('hour and minute are derived from minutes since midnight', () {
    const t = LocalTime(390);
    expect(t.hour, 6);
    expect(t.minute, 30);
  });

  test('format24 pads hours and minutes', () {
    expect(LocalTime.of(6, 5).format24(), '06:05');
    expect(LocalTime.of(23, 59).format24(), '23:59');
  });

  test('plusMinutes wraps around midnight in both directions', () {
    expect(LocalTime.of(23, 30).plusMinutes(45), LocalTime.of(0, 15));
    expect(LocalTime.of(0, 15).plusMinutes(-45), LocalTime.of(23, 30));
  });

  test('onDate places the time on the given calendar day', () {
    final d = LocalTime.of(7, 15).onDate(DateTime(2026, 11, 14, 22, 0));
    expect(d, DateTime(2026, 11, 14, 7, 15));
  });

  test('LocalTime values compare and sort by minutes', () {
    final sorted = [LocalTime.of(9, 0), LocalTime.of(6, 30), LocalTime.of(7, 0)]
      ..sort();
    expect(sorted, [
      LocalTime.of(6, 30),
      LocalTime.of(7, 0),
      LocalTime.of(9, 0),
    ]);
    expect(LocalTime.of(6, 30) == const LocalTime(390), isTrue);
  });
}
