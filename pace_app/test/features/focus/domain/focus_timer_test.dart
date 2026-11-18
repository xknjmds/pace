import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/focus/domain/focus_timer.dart';

void main() {
  final start = DateTime(2026, 11, 14, 19);

  group('focusStateAt', () {
    test('idle without a session', () {
      expect(
        focusStateAt(now: start, startedAt: null, plannedMinutes: 10),
        isA<FocusIdle>(),
      );
    });

    test('running counts down from the start', () {
      final s =
          focusStateAt(
                now: start.add(const Duration(minutes: 3, seconds: 20)),
                startedAt: start,
                plannedMinutes: 10,
              )
              as FocusRunning;
      expect(s.remaining, const Duration(minutes: 6, seconds: 40));
      expect(s.endsAt, DateTime(2026, 11, 14, 19, 10));
    });

    test('time up at and after the end, however long the screen was off', () {
      for (final later in [
        const Duration(minutes: 10),
        const Duration(hours: 3),
      ]) {
        expect(
          focusStateAt(
            now: start.add(later),
            startedAt: start,
            plannedMinutes: 10,
          ),
          isA<FocusTimeUp>(),
        );
      }
    });
  });

  group('focusOutcome', () {
    test('full time is completed and capped at the plan', () {
      expect(
        focusOutcome(
          now: start.add(const Duration(minutes: 47)),
          startedAt: start,
          plannedMinutes: 10,
        ),
        (minutes: 10, completed: true),
      );
    });

    test('stopping early records whole minutes spent', () {
      expect(
        focusOutcome(
          now: start.add(const Duration(minutes: 4, seconds: 59)),
          startedAt: start,
          plannedMinutes: 10,
        ),
        (minutes: 4, completed: false),
      );
      expect(
        focusOutcome(
          now: start.add(const Duration(seconds: 30)),
          startedAt: start,
          plannedMinutes: 10,
        ),
        (minutes: 0, completed: false),
      );
    });

    test('a clock set backwards never gives negative minutes', () {
      expect(
        focusOutcome(
          now: start.subtract(const Duration(minutes: 5)),
          startedAt: start,
          plannedMinutes: 10,
        ).minutes,
        0,
      );
    });
  });

  test('formatRemaining rounds up and pads seconds', () {
    expect(formatRemaining(const Duration(minutes: 10)), '10:00');
    expect(
      formatRemaining(const Duration(minutes: 9, seconds: 59, milliseconds: 1)),
      '10:00',
    );
    expect(formatRemaining(const Duration(seconds: 5)), '0:05');
    expect(formatRemaining(const Duration(milliseconds: 200)), '0:01');
  });

  test('summaries are kind at any length', () {
    expect(focusSummary(10, completed: true), '10 minutes done. Nice start.');
    expect(
      focusSummary(0, completed: false),
      'Stopped. Starting is the hard part.',
    );
    expect(
      focusSummary(1, completed: false),
      'Stopped after 1 minute. That counts.',
    );
    expect(
      focusSummary(4, completed: false),
      'Stopped after 4 minutes. That counts.',
    );
  });
}
