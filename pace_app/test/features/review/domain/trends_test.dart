import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/review/domain/trends.dart';
import 'package:pace/features/review/domain/weekly_summary.dart';

void main() {
  final today = DateTime(2026, 11, 18); // Wednesday
  DateTime utc(int d, int h, [int m = 0]) => DateTime.utc(2026, 11, d, h, m);
  // A fixed +08:00 zone, so results do not depend on the machine.
  DateTime plus8(DateTime t) => t.toUtc().add(const Duration(hours: 8));

  test('no data: four empty weeks, nothing negative', () {
    final weeks = weeklyTrends(today: today, toLocal: plus8);
    expect(weeks, hasLength(4));
    expect(weeks.every((w) => w.isEmpty), isTrue);
    expect(weeks.last.monday, DateTime(2026, 11, 16));
    expect(weeks.first.monday, DateTime(2026, 10, 26));
  });

  test('partial data counts what is there', () {
    final weeks = weeklyTrends(
      today: today,
      toLocal: plus8,
      records: [
        DayRecord(
          date: DateTime(2026, 11, 16),
          routineDone: true,
          wakeAt: utc(15, 22, 40),
        ),
      ],
      plannedWakeFor: (_) => LocalTime.of(6, 30),
      movementDays: {'2026-11-17'},
    );
    final w = weeks.last;
    expect(w.routineDays, 1);
    expect(w.wakeDays, 1);
    expect(w.averageActualWake, LocalTime.of(6, 40));
    expect(w.averagePlannedWake, LocalTime.of(6, 30));
    expect(w.movementDays, 1);
    expect(w.averageSleep, isNull);
  });

  test('a bit later and after-due counts are neutral subsets', () {
    final weeks = weeklyTrends(
      today: today,
      toLocal: plus8,
      records: [
        DayRecord(date: DateTime(2026, 11, 16), routineDone: true),
        DayRecord(
          date: DateTime(2026, 11, 17),
          routineDone: true,
          anyLater: true,
        ),
        // Later but routine not done: not a routine day at all.
        DayRecord(date: DateTime(2026, 11, 18), anyLater: true),
      ],
      submittedAt: [utc(16, 2), utc(17, 2)],
      lateSubmittedAt: [utc(17, 2)],
    );
    final w = weeks.last;
    expect(w.routineDays, 2);
    expect(w.routineLaterDays, 1);
    expect(w.deadlinesSubmitted, 2);
    expect(w.deadlinesSubmittedLate, 1);
    expect(weeks.first.routineLaterDays, 0);
  });

  test('a Sunday-night instant lands in the right week (week boundary)', () {
    // 2026-11-15 15:30 UTC is Sunday 23:30 at +08:00 but Monday 00:30 at +09:00.
    final submitted = [utc(15, 15, 30)];
    final at8 = weeklyTrends(
      today: today,
      toLocal: plus8,
      submittedAt: submitted,
    );
    expect(at8[2].deadlinesSubmitted, 1); // week of Nov 9
    expect(at8[3].deadlinesSubmitted, 0);

    DateTime plus9(DateTime t) => t.toUtc().add(const Duration(hours: 9));
    final at9 = weeklyTrends(
      today: today,
      toLocal: plus9,
      submittedAt: submitted,
    );
    expect(at9[3].deadlinesSubmitted, 1); // the zone moved it to Monday
  });

  test('a full month: sleep, focus and wake averages per week', () {
    final records = <DayRecord>[];
    final focus = <FocusRecord>[];
    for (var d = 26; d <= 48; d++) {
      final date = DateTime(2026, 10, d);
      records.add(
        DayRecord(
          date: date,
          routineDone: d.isEven,
          // Bed 22:30, up 06:30 local (+08:00).
          bedAt: DateTime.utc(date.year, date.month, date.day, 14, 30),
          wakeAt: DateTime.utc(date.year, date.month, date.day - 1, 22, 30),
        ),
      );
      focus.add((
        startedAt: DateTime.utc(date.year, date.month, date.day, 2),
        minutes: 10,
      ));
    }
    final weeks = weeklyTrends(
      today: today,
      toLocal: plus8,
      records: records,
      focus: focus,
    );
    final full = weeks[1]; // Nov 2 to 8, all seven days logged
    expect(full.routineDays, anyOf(3, 4));
    expect(full.wakeDays, 7);
    expect(full.averageActualWake, LocalTime.of(6, 30));
    expect(full.averageSleep, const Duration(hours: 8));
    expect(full.focusSessions, 7);
    expect(full.focusMinutes, 70);
  });

  test('wake gap in words', () {
    expect(
      describeWakeGap(LocalTime.of(6, 30), LocalTime.of(6, 32)),
      'About on plan',
    );
    expect(
      describeWakeGap(LocalTime.of(6, 30), LocalTime.of(6, 50)),
      '20 min after plan',
    );
    expect(
      describeWakeGap(LocalTime.of(6, 30), LocalTime.of(6, 0)),
      '30 min before plan',
    );
  });
}
