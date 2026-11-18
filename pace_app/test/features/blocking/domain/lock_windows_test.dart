import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/blocking/domain/lock_windows.dart';
import 'package:pace/features/routine/domain/day_routine_times.dart';

DayRoutineTimes day(DateTime d) {
  final classDay = d.weekday <= 5;
  return DayRoutineTimes(
    date: d,
    wake: DateTime(d.year, d.month, d.day, 6, 30),
    eat: classDay ? DateTime(d.year, d.month, d.day, 6, 45) : null,
    leave: classDay ? DateTime(d.year, d.month, d.day, 7, 20) : null,
    windDown: DateTime(d.year, d.month, d.day, 21, 45),
    bedtime: DateTime(d.year, d.month, d.day, 22, 30),
    nextWake: DateTime(d.year, d.month, d.day + 1, 6, 30),
  );
}

void main() {
  final wed = DateTime(2026, 11, 18, 5, 0);

  test('morning lock runs from waking to leaving, wind-down until waking', () {
    final w = lockWindows(
      now: wed,
      timesFor: day,
      morningLock: true,
      windDownLock: true,
      days: 1,
    );
    expect(w, [
      // Last night's wind-down is still under way at 05:00.
      LockWindow(
        DateTime(2026, 11, 17, 21, 45),
        DateTime(2026, 11, 18, 6, 30),
        LockReason.windDown,
      ),
      LockWindow(
        DateTime(2026, 11, 18, 6, 30),
        DateTime(2026, 11, 18, 7, 20),
        LockReason.morning,
      ),
      LockWindow(
        DateTime(2026, 11, 18, 21, 45),
        DateTime(2026, 11, 19, 6, 30),
        LockReason.windDown,
      ),
    ]);
  });

  test('a done routine removes that morning lock at once', () {
    final w = lockWindows(
      now: DateTime(2026, 11, 18, 6, 50),
      timesFor: day,
      morningLock: true,
      windDownLock: false,
      routineDoneDays: {'2026-11-18'},
      days: 1,
    );
    expect(activeWindow(w, DateTime(2026, 11, 18, 6, 50)), isNull);
  });

  test('days without class lock the first 90 minutes', () {
    final sat = DateTime(2026, 11, 21);
    final w = lockWindows(
      now: sat,
      timesFor: day,
      morningLock: true,
      windDownLock: false,
      days: 1,
    );
    expect(w.single.end, DateTime(2026, 11, 21, 8, 0));
  });

  test('low-energy mode loosens both windows', () {
    final w = lockWindows(
      now: DateTime(2026, 11, 18, 6, 0),
      timesFor: day,
      morningLock: true,
      windDownLock: true,
      lowEnergy: true,
      days: 1,
    );
    final morning = w.firstWhere((x) => x.reason == LockReason.morning);
    expect(morning.end, DateTime(2026, 11, 18, 7, 0));
    final evening = w.lastWhere((x) => x.reason == LockReason.windDown);
    expect(evening.start, DateTime(2026, 11, 18, 22, 30));
  });

  test('both switches off means no windows at all', () {
    expect(
      lockWindows(
        now: wed,
        timesFor: day,
        morningLock: false,
        windDownLock: false,
      ),
      isEmpty,
    );
  });

  test('windows that are over are dropped', () {
    final w = lockWindows(
      now: DateTime(2026, 11, 18, 12),
      timesFor: day,
      morningLock: true,
      windDownLock: false,
      days: 1,
    );
    expect(w, isEmpty);
  });
}
