import '../../../core/time/date_key.dart';
import '../../routine/domain/day_routine_times.dart';

/// A stretch of time when blocked apps wait. [reason] is what the block
/// screen says.
class LockWindow {
  const LockWindow(this.start, this.end, this.reason);

  final DateTime start;
  final DateTime end;
  final LockReason reason;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is LockWindow &&
      other.start == start &&
      other.end == end &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(start, end, reason);

  @override
  String toString() => 'LockWindow($start – $end, ${reason.name})';
}

enum LockReason { morning, windDown }

/// How long the morning lock lasts on a day without a class.
const noClassMorningMinutes = 90;

/// The shorter windows used in low-energy mode.
const lowEnergyMorningMinutes = 30;

/// Pure: lock windows from now through the next [days] days.
///
/// Morning: from waking until leaving (or [noClassMorningMinutes] on days
/// without a class), and gone as soon as that day's routine is done.
/// Wind-down: from the wind-down reminder until waking. Low-energy mode
/// loosens both: the morning lock is only the first
/// [lowEnergyMorningMinutes], and the evening lock starts at bedtime.
/// Windows already over are dropped; one under way is kept.
List<LockWindow> lockWindows({
  required DateTime now,
  required DayRoutineTimes? Function(DateTime date) timesFor,
  required bool morningLock,
  required bool windDownLock,
  Set<String> routineDoneDays = const {},
  bool lowEnergy = false,
  int days = 7,
}) {
  final today = dateOnly(now);
  final out = <LockWindow>[];
  // Start a day early so last night's wind-down lock is included.
  for (var i = -1; i < days; i++) {
    final date = DateTime(today.year, today.month, today.day + i);
    final t = timesFor(date);
    if (t == null) continue;
    if (morningLock && !routineDoneDays.contains(dateKey(date))) {
      final end = lowEnergy
          ? t.wake.add(const Duration(minutes: lowEnergyMorningMinutes))
          : t.leave ??
                t.wake.add(const Duration(minutes: noClassMorningMinutes));
      if (end.isAfter(t.wake)) {
        out.add(LockWindow(t.wake, end, LockReason.morning));
      }
    }
    if (windDownLock) {
      final start = lowEnergy ? t.bedtime : t.windDown;
      if (t.nextWake.isAfter(start)) {
        out.add(LockWindow(start, t.nextWake, LockReason.windDown));
      }
    }
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return [
    for (final w in out)
      if (w.end.isAfter(now)) w,
  ];
}

/// The window [t] falls in, if any.
LockWindow? activeWindow(List<LockWindow> windows, DateTime t) {
  for (final w in windows) {
    if (w.contains(t)) return w;
  }
  return null;
}
