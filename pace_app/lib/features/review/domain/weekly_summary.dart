import '../../../core/time/date_key.dart';
import '../../../core/time/local_time.dart';

/// One day's log, as the weekly view needs it. Plain values (no Drift).
class DayRecord {
  const DayRecord({
    required this.date,
    this.bedAt,
    this.wakeAt,
    this.routineDone = false,
    this.anyLater = false,
  });

  /// Local calendar day.
  final DateTime date;

  /// "Going to bed" for the night that starts on [date].
  final DateTime? bedAt;

  /// "I'm up" on the morning of [date].
  final DateTime? wakeAt;
  final bool routineDone;

  /// A step that day was checked in as "a bit later". Only ever shown as a
  /// neutral count next to the routine days.
  final bool anyLater;
}

/// One night: bed on [night], up the next morning. Either may be missing.
class SleepEntry {
  const SleepEntry({required this.night, this.bedAt, this.wakeAt});

  final DateTime night;
  final DateTime? bedAt;
  final DateTime? wakeAt;

  /// Only when both ends are known and make sense (under 16 hours).
  Duration? get slept {
    final b = bedAt;
    final w = wakeAt;
    if (b == null || w == null || !w.isAfter(b)) return null;
    final d = w.difference(b);
    return d > const Duration(hours: 16) ? null : d;
  }
}

class WeeklySummary {
  const WeeklySummary({
    required this.from,
    required this.to,
    required this.routineDays,
    this.laterDays = 0,
    required this.averageWake,
    required this.wakeDays,
    required this.sleep,
  });

  final DateTime from;
  final DateTime to;

  /// Days in the window with the routine marked done. Only ever counts up.
  final int routineDays;

  /// Of [routineDays], the ones with a step done a bit later. A neutral
  /// detail, never a miss.
  final int laterDays;

  /// Mean of the logged wake times; null when none were logged.
  final LocalTime? averageWake;
  final int wakeDays;

  /// Nights with anything logged, newest first.
  final List<SleepEntry> sleep;

  /// Average of the nights with a known length; null when there are none.
  Duration? get averageSleep {
    final known = [for (final e in sleep) ?e.slept];
    if (known.isEmpty) return null;
    final total = known.fold(Duration.zero, (a, b) => a + b);
    return Duration(minutes: total.inMinutes ~/ known.length);
  }
}

/// Pure: the last seven days ending on [today], from whatever was logged.
/// Missing days are simply not counted; nothing here goes down or resets.
WeeklySummary weeklySummary({
  required DateTime today,
  required List<DayRecord> records,
}) {
  final to = dateOnly(today);
  final from = DateTime(to.year, to.month, to.day - 6);
  final byDay = {for (final r in records) dateKey(r.date): r};
  final inWindow = [
    for (var i = 0; i < 7; i++)
      ?byDay[dateKey(DateTime(from.year, from.month, from.day + i))],
  ];

  final wakes = [
    for (final r in inWindow)
      if (r.wakeAt case final w?) w.isUtc ? w.toLocal() : w,
  ];
  final averageWake = wakes.isEmpty
      ? null
      : LocalTime(
          wakes.map((w) => w.hour * 60 + w.minute).reduce((a, b) => a + b) ~/
              wakes.length,
        );

  // Nights from the one before the window through last night.
  final sleep = <SleepEntry>[];
  for (var i = 6; i >= 0; i--) {
    final night = DateTime(to.year, to.month, to.day - 7 + i);
    final morning = DateTime(night.year, night.month, night.day + 1);
    final bed = byDay[dateKey(night)]?.bedAt;
    final wake = byDay[dateKey(morning)]?.wakeAt;
    if (bed == null && wake == null) continue;
    sleep.add(
      SleepEntry(
        night: night,
        bedAt: bed?.isUtc == true ? bed!.toLocal() : bed,
        wakeAt: wake?.isUtc == true ? wake!.toLocal() : wake,
      ),
    );
  }

  return WeeklySummary(
    from: from,
    to: to,
    routineDays: inWindow.where((r) => r.routineDone).length,
    laterDays: inWindow.where((r) => r.routineDone && r.anyLater).length,
    averageWake: averageWake,
    wakeDays: wakes.length,
    sleep: sleep,
  );
}

/// "7 h 40 min", "8 h".
String formatSleep(Duration d) {
  final h = d.inMinutes ~/ 60;
  final m = d.inMinutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
