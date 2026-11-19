import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/activity/domain/sleep_estimate.dart';

void main() {
  final from = DateTime(2026, 11, 19, 20);
  final to = DateTime(2026, 11, 20, 12);
  ScreenEvent on(int day, int h, [int m = 0]) =>
      ScreenEvent(DateTime(2026, 11, day, h, m), on: true);
  ScreenEvent off(int day, int h, [int m = 0]) =>
      ScreenEvent(DateTime(2026, 11, day, h, m), on: false);

  test('no events: nothing to say', () {
    expect(estimateSleep(events: const [], from: from, to: to), isNull);
  });

  test('a plain night: last use to first use', () {
    final s = estimateSleep(
      events: [on(19, 21), off(19, 23, 10), on(20, 6, 40), off(20, 7)],
      from: from,
      to: to,
    )!;
    expect(s.start, DateTime(2026, 11, 19, 23, 10));
    expect(s.end, DateTime(2026, 11, 20, 6, 40));
    expect(s.confident, isTrue);
  });

  test('checking the time at 3am does not split the night', () {
    final s = estimateSleep(
      events: [
        off(19, 23),
        on(20, 3),
        off(20, 3, 1),
        on(20, 6, 30),
        off(20, 7),
      ],
      from: from,
      to: to,
    )!;
    expect(s.start, DateTime(2026, 11, 19, 23));
    expect(s.end, DateTime(2026, 11, 20, 6, 30));
  });

  test('scrolling at 1am for twenty minutes moves the start', () {
    final s = estimateSleep(
      events: [
        off(19, 23),
        on(20, 1),
        off(20, 1, 20),
        on(20, 7),
        off(20, 7, 30),
      ],
      from: from,
      to: to,
    )!;
    expect(s.start, DateTime(2026, 11, 20, 1, 20));
    expect(s.end, DateTime(2026, 11, 20, 7));
  });

  test('events arrive in any order', () {
    final s = estimateSleep(
      events: [on(20, 6, 40), off(19, 23, 10), off(20, 7), on(19, 21)],
      from: from,
      to: to,
    )!;
    expect(s.start, DateTime(2026, 11, 19, 23, 10));
  });

  test('screen already off at the window start', () {
    final s = estimateSleep(
      events: [on(20, 6), off(20, 6, 30)],
      from: from,
      to: to,
    )!;
    expect(s.start, from);
    expect(s.end, DateTime(2026, 11, 20, 6));
  });

  test('a phone left alone until noon has no wake-up to suggest', () {
    expect(
      estimateSleep(events: [on(19, 21), off(19, 22)], from: from, to: to),
      isNull,
    );
  });

  test('a short nap is not a night', () {
    final s = estimateSleep(
      events: [
        on(19, 20),
        off(19, 21),
        on(19, 22),
        off(19, 23, 59),
        on(20, 0, 30),
        off(20, 11, 50),
      ],
      from: from,
      to: to,
    );
    expect(s, isNull);
  });

  test('an estimate under four hours is not confident', () {
    final s = estimateSleep(
      events: [off(20, 2), on(20, 5), off(20, 5, 30)],
      from: from,
      to: to,
    )!;
    expect(s.confident, isFalse);
  });
}
