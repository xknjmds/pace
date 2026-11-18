import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/habits/domain/habit_planner.dart';
import 'package:pace/features/routine/domain/day_routine_times.dart';

DayRoutineTimes day(DateTime d, {bool classDay = true}) => DayRoutineTimes(
  date: d,
  wake: DateTime(d.year, d.month, d.day, 6, 30),
  eat: classDay ? DateTime(d.year, d.month, d.day, 6, 45) : null,
  leave: classDay ? DateTime(d.year, d.month, d.day, 7, 20) : null,
  windDown: DateTime(d.year, d.month, d.day, 21, 45),
  bedtime: DateTime(d.year, d.month, d.day, 22, 30),
  nextWake: DateTime(d.year, d.month, d.day + 1, 6, 30),
);

void main() {
  final now = DateTime(2026, 11, 18, 6, 0); // Wednesday

  test('reminder sits at the anchor plus the offset', () {
    final t = day(DateTime(2026, 11, 18));
    expect(habitReminderAt(t, HabitPoint.wake, 30), DateTime(2026, 11, 18, 7));
    expect(
      habitReminderAt(t, HabitPoint.windDown, -15),
      DateTime(2026, 11, 18, 21, 30),
    );
  });

  test('breakfast and leaving fall back to waking on days without class', () {
    final t = day(DateTime(2026, 11, 21), classDay: false);
    expect(
      habitReminderAt(t, HabitPoint.leave, 10),
      DateTime(2026, 11, 21, 6, 40),
    );
  });

  test('one reminder a day for a week, skipping done and muted days', () {
    final drafts = planHabitReminders(
      now: now,
      name: 'Move',
      point: HabitPoint.wake,
      offsetMinutes: 30,
      timesFor: day,
      doneDays: {'2026-11-19'},
      mutedDays: {'2026-11-20'},
    );
    expect(drafts.map((d) => d.fireAt.day), [18, 21, 22, 23, 24]);
  });

  test('times already past are dropped', () {
    final drafts = planHabitReminders(
      now: DateTime(2026, 11, 18, 8),
      name: 'Move',
      point: HabitPoint.wake,
      offsetMinutes: 30,
      timesFor: day,
      days: 2,
    );
    expect(drafts.single.fireAt, DateTime(2026, 11, 19, 7));
  });

  test('low-energy mode plans no habit reminders', () {
    expect(
      planHabitReminders(
        now: now,
        name: 'Move',
        point: HabitPoint.wake,
        offsetMinutes: 30,
        timesFor: day,
        lowEnergy: true,
      ),
      isEmpty,
    );
  });

  test('describes the time in words', () {
    expect(describeHabitTime(HabitPoint.wake, 30), '30 min after waking');
    expect(
      describeHabitTime(HabitPoint.windDown, -20),
      '20 min before winding down',
    );
    expect(describeHabitTime(HabitPoint.eat, 0), 'At breakfast');
  });
}
