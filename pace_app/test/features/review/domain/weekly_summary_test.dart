import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/review/domain/weekly_summary.dart';

void main() {
  final today = DateTime(2026, 11, 18, 20); // Wednesday evening

  test('empty data reads as nothing yet, not as failure', () {
    final s = weeklySummary(today: today, records: const []);
    expect(s.routineDays, 0);
    expect(s.averageWake, isNull);
    expect(s.wakeDays, 0);
    expect(s.sleep, isEmpty);
    expect(s.averageSleep, isNull);
    expect(s.from, DateTime(2026, 11, 12));
    expect(s.to, DateTime(2026, 11, 18));
  });

  test('later days count only among routine days', () {
    final s = weeklySummary(
      today: today,
      records: [
        DayRecord(date: DateTime(2026, 11, 16), routineDone: true),
        DayRecord(
          date: DateTime(2026, 11, 17),
          routineDone: true,
          anyLater: true,
        ),
        DayRecord(date: DateTime(2026, 11, 18), anyLater: true),
      ],
    );
    expect(s.routineDays, 2);
    expect(s.laterDays, 1);
  });

  test('partial data: counts what is there, averages what is known', () {
    final s = weeklySummary(
      today: today,
      records: [
        DayRecord(
          date: DateTime(2026, 11, 16),
          wakeAt: DateTime(2026, 11, 16, 6, 40),
          bedAt: DateTime(2026, 11, 16, 22, 50),
          routineDone: true,
        ),
        DayRecord(
          date: DateTime(2026, 11, 17),
          wakeAt: DateTime(2026, 11, 17, 7, 0),
          routineDone: true,
        ),
        // Bed logged, morning not: a half night.
        DayRecord(date: DateTime(2026, 11, 18), routineDone: false),
        // Outside the window: ignored for counts.
        DayRecord(
          date: DateTime(2026, 11, 10),
          wakeAt: DateTime(2026, 11, 10, 9),
          routineDone: true,
        ),
      ],
    );
    expect(s.routineDays, 2);
    expect(s.averageWake, LocalTime.of(6, 50));
    expect(s.wakeDays, 2);
    // Monday night: bed 22:50, up Tuesday 07:00.
    final monday = s.sleep.singleWhere(
      (e) => e.night == DateTime(2026, 11, 16),
    );
    expect(monday.slept, const Duration(hours: 8, minutes: 10));
    expect(s.averageSleep, const Duration(hours: 8, minutes: 10));
    // Sunday night only has the Monday wake: listed, length unknown.
    final sunday = s.sleep.singleWhere(
      (e) => e.night == DateTime(2026, 11, 15),
    );
    expect(sunday.bedAt, isNull);
    expect(sunday.slept, isNull);
    // Newest first.
    expect(s.sleep.first.night, DateTime(2026, 11, 16));
  });

  test('UTC timestamps from the database are read as local times', () {
    final wake = DateTime(2026, 11, 17, 6, 30);
    final s = weeklySummary(
      today: today,
      records: [DayRecord(date: DateTime(2026, 11, 17), wakeAt: wake.toUtc())],
    );
    expect(s.averageWake, LocalTime.of(6, 30));
  });

  test('nonsense nights (wake before bed, or very long) have no length', () {
    expect(
      SleepEntry(
        night: DateTime(2026, 11, 16),
        bedAt: DateTime(2026, 11, 16, 23),
        wakeAt: DateTime(2026, 11, 16, 22),
      ).slept,
      isNull,
    );
    expect(
      SleepEntry(
        night: DateTime(2026, 11, 16),
        bedAt: DateTime(2026, 11, 16, 12),
        wakeAt: DateTime(2026, 11, 17, 6),
      ).slept,
      isNull,
    );
  });

  test('formatSleep', () {
    expect(formatSleep(const Duration(hours: 8)), '8 h');
    expect(formatSleep(const Duration(hours: 7, minutes: 40)), '7 h 40 min');
  });
}
