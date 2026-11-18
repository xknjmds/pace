import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/deadlines/domain/deadline_reminders.dart';

void main() {
  final evening = LocalTime.of(19, 0);
  final morning = LocalTime.of(7, 0);
  // Due Friday 20 Nov 2026, 23:59.
  final due = DateTime(2026, 11, 20, 23, 59);

  List<DeadlineReminder> compute(
    DateTime now, {
    Set<String> muted = const {},
  }) => computeDeadlineReminders(
    dueAt: due,
    now: now,
    eveningAt: evening,
    morningAt: morning,
    mutedDates: muted,
  );

  test('a week out gets all four nudges in order', () {
    final r = compute(DateTime(2026, 11, 13, 12));
    expect(r.map((x) => x.nudge), [
      DeadlineNudge.threeDaysBefore,
      DeadlineNudge.dayBefore,
      DeadlineNudge.morningOf,
      DeadlineNudge.twoHoursBefore,
    ]);
    expect(r.map((x) => x.fireAt), [
      DateTime(2026, 11, 17, 19),
      DateTime(2026, 11, 19, 19),
      DateTime(2026, 11, 20, 7),
      DateTime(2026, 11, 20, 21, 59),
    ]);
  });

  test('nudges already past are skipped', () {
    final r = compute(DateTime(2026, 11, 20, 8));
    expect(r.map((x) => x.nudge), [DeadlineNudge.twoHoursBefore]);
  });

  test('under two hours away: nothing is left to say', () {
    expect(compute(DateTime(2026, 11, 20, 22, 30)), isEmpty);
  });

  test('a muted day drops that day\'s nudges only', () {
    final r = compute(DateTime(2026, 11, 13, 12), muted: {'2026-11-20'});
    expect(r.map((x) => x.nudge), [
      DeadlineNudge.threeDaysBefore,
      DeadlineNudge.dayBefore,
    ]);
  });

  test('nudges that would land on the same minute collapse into one', () {
    final r = computeDeadlineReminders(
      dueAt: DateTime(2026, 11, 20, 9), // two hours before = 07:00 = morning
      now: DateTime(2026, 11, 19, 20),
      eveningAt: evening,
      morningAt: morning,
    );
    expect(r, hasLength(1));
    expect(r.single.fireAt, DateTime(2026, 11, 20, 7));
  });

  test('nudges never land after the deadline itself', () {
    final r = computeDeadlineReminders(
      dueAt: DateTime(2026, 11, 20, 6), // morning-of 07:00 is after due
      now: DateTime(2026, 11, 19, 12),
      eveningAt: evening,
      morningAt: morning,
    );
    expect(r.map((x) => x.nudge), [
      DeadlineNudge.dayBefore,
      DeadlineNudge.twoHoursBefore,
    ]);
    expect(r.last.fireAt, DateTime(2026, 11, 20, 4));
  });

  test('low-energy mode keeps only nudges inside the last 48 hours', () {
    final r = computeDeadlineReminders(
      dueAt: due,
      now: DateTime(2026, 11, 13, 12),
      eveningAt: evening,
      morningAt: morning,
      lowEnergy: true,
    );
    expect(r.map((x) => x.nudge), [
      DeadlineNudge.dayBefore,
      DeadlineNudge.morningOf,
      DeadlineNudge.twoHoursBefore,
    ]);
  });

  group('describeDue', () {
    final now = DateTime(2026, 11, 14, 10); // Saturday
    test('upcoming', () {
      expect(
        describeDue(DateTime(2026, 11, 14, 23, 59), now),
        'Due today 23:59',
      );
      expect(describeDue(DateTime(2026, 11, 15, 8), now), 'Due tomorrow 08:00');
      expect(describeDue(DateTime(2026, 11, 19, 23, 59), now), 'Due Thu 23:59');
      expect(
        describeDue(DateTime(2026, 12, 3, 23, 59), now),
        'Due 3 Dec 23:59',
      );
    });
    test('past', () {
      expect(
        describeDue(DateTime(2026, 11, 14, 9), now),
        'Was due today 09:00',
      );
      expect(
        describeDue(DateTime(2026, 11, 13, 23, 59), now),
        'Was due yesterday 23:59',
      );
      expect(
        describeDue(DateTime(2026, 11, 10, 23, 59), now),
        'Was due Tue 23:59',
      );
      expect(
        describeDue(DateTime(2026, 10, 30, 23, 59), now),
        'Was due 30 Oct 23:59',
      );
    });
    test('UTC input is shown in local time', () {
      final utc = DateTime(2026, 11, 15, 8).toUtc();
      expect(describeDue(utc, now), 'Due tomorrow 08:00');
    });
  });
}
