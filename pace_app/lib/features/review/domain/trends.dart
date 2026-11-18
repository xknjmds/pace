import '../../../core/time/date_key.dart';
import '../../../core/time/local_time.dart';
import 'weekly_summary.dart';

/// One calendar week (Monday to Sunday) in plain counts and averages.
/// Nothing here can go down because of a missed day: counts only grow.
class WeekStats {
  const WeekStats({
    required this.monday,
    required this.routineDays,
    required this.wakeDays,
    required this.averagePlannedWake,
    required this.averageActualWake,
    required this.averageSleep,
    required this.deadlinesSubmitted,
    required this.focusSessions,
    required this.focusMinutes,
    required this.movementDays,
  });

  final DateTime monday;
  final int routineDays;
  final int wakeDays;

  /// Planned wake on the same mornings a wake was logged, so the two
  /// averages compare like with like.
  final LocalTime? averagePlannedWake;
  final LocalTime? averageActualWake;
  final Duration? averageSleep;
  final int deadlinesSubmitted;
  final int focusSessions;
  final int focusMinutes;
  final int movementDays;

  bool get isEmpty =>
      routineDays == 0 &&
      wakeDays == 0 &&
      averageSleep == null &&
      deadlinesSubmitted == 0 &&
      focusSessions == 0 &&
      movementDays == 0;
}

/// A focus session as the trends need it.
typedef FocusRecord = ({DateTime startedAt, int minutes});

/// Monday of the week holding [day] (local calendar).
DateTime mondayOf(DateTime day) {
  final d = dateOnly(day);
  return DateTime(d.year, d.month, d.day - (d.weekday - 1));
}

/// Pure: the last [weeks] calendar weeks, oldest first, ending with the
/// week holding [today].
///
/// [toLocal] turns stored UTC instants into local wall time. It defaults to
/// the device zone; tests pass a fixed offset to check that a zone change
/// moves an instant into the right day and week.
List<WeekStats> weeklyTrends({
  required DateTime today,
  int weeks = 4,
  List<DayRecord> records = const [],
  LocalTime? Function(DateTime date)? plannedWakeFor,
  List<DateTime> submittedAt = const [],
  List<FocusRecord> focus = const [],
  Set<String> movementDays = const {},
  DateTime Function(DateTime instant)? toLocal,
}) {
  DateTime local(DateTime t) =>
      toLocal != null ? toLocal(t) : (t.isUtc ? t.toLocal() : t);
  DateTime day(DateTime t) {
    final l = local(t);
    return DateTime(l.year, l.month, l.day);
  }

  final byDay = {for (final r in records) dateKey(r.date): r};
  final lastMonday = mondayOf(today);
  final out = <WeekStats>[];
  for (var w = weeks - 1; w >= 0; w--) {
    final monday = DateTime(
      lastMonday.year,
      lastMonday.month,
      lastMonday.day - 7 * w,
    );
    final next = DateTime(monday.year, monday.month, monday.day + 7);
    bool inWeek(DateTime d) => !d.isBefore(monday) && d.isBefore(next);
    final dates = [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];

    var routine = 0;
    final actual = <int>[];
    final planned = <int>[];
    final slept = <Duration>[];
    var movement = 0;
    for (final date in dates) {
      final key = dateKey(date);
      final r = byDay[key];
      if (r != null && r.routineDone) routine++;
      if (movementDays.contains(key)) movement++;
      final wake = r?.wakeAt;
      if (wake != null) {
        final l = local(wake);
        actual.add(l.hour * 60 + l.minute);
        final p = plannedWakeFor?.call(date);
        if (p != null) planned.add(p.minutesSinceMidnight);
      }
      // The night that starts on this date.
      final bed = r?.bedAt;
      final morning = DateTime(date.year, date.month, date.day + 1);
      final up = byDay[dateKey(morning)]?.wakeAt;
      final s = SleepEntry(
        night: date,
        bedAt: bed == null ? null : local(bed),
        wakeAt: up == null ? null : local(up),
      ).slept;
      if (s != null) slept.add(s);
    }
    final sessions = [
      for (final f in focus)
        if (inWeek(day(f.startedAt))) f,
    ];
    out.add(
      WeekStats(
        monday: monday,
        routineDays: routine,
        wakeDays: actual.length,
        averagePlannedWake: _mean(planned),
        averageActualWake: _mean(actual),
        averageSleep: slept.isEmpty
            ? null
            : Duration(
                minutes:
                    slept.fold(0, (a, b) => a + b.inMinutes) ~/ slept.length,
              ),
        deadlinesSubmitted: submittedAt.where((t) => inWeek(day(t))).length,
        focusSessions: sessions.length,
        focusMinutes: sessions.fold(0, (a, b) => a + b.minutes),
        movementDays: movement,
      ),
    );
  }
  return out;
}

LocalTime? _mean(List<int> minutes) => minutes.isEmpty
    ? null
    : LocalTime(minutes.reduce((a, b) => a + b) ~/ minutes.length);

/// "12 min later than planned", "right on plan", "5 min earlier".
String describeWakeGap(LocalTime planned, LocalTime actual) {
  final gap = actual.minutesSinceMidnight - planned.minutesSinceMidnight;
  if (gap.abs() < 5) return 'About on plan';
  return '${gap.abs()} min ${gap > 0 ? 'after' : 'before'} plan';
}
