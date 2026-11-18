import '../../../core/notifications/reminder_draft.dart';
import '../../../core/time/date_key.dart';
import '../../routine/domain/day_routine_times.dart';

/// Where a habit reminder hangs in the routine. Mirrors the Drift enum by
/// name so this file stays free of Drift.
enum HabitPoint { wake, eat, leave, windDown }

/// Pure: when the habit's reminder goes off on one day. Breakfast and
/// leaving fall back to waking on days without a class.
DateTime habitReminderAt(DayRoutineTimes day, HabitPoint point, int offset) {
  final base = switch (point) {
    HabitPoint.wake => day.wake,
    HabitPoint.eat => day.eat ?? day.wake,
    HabitPoint.leave => day.leave ?? day.wake,
    HabitPoint.windDown => day.windDown,
  };
  return base.add(Duration(minutes: offset));
}

/// Pure: the habit's reminders for the next [days] days. Days already
/// done or muted ("Not today") get none, nor do times already past.
/// Low-energy mode drops habit reminders altogether: only wake, leave and
/// deadlines remain.
List<ReminderDraft> planHabitReminders({
  required DateTime now,
  required String name,
  required HabitPoint point,
  required int offsetMinutes,
  required DayRoutineTimes? Function(DateTime date) timesFor,
  Set<String> doneDays = const {},
  Set<String> mutedDays = const {},
  bool lowEnergy = false,
  int days = 7,
}) {
  if (lowEnergy) return const [];
  final today = dateOnly(now);
  final out = <ReminderDraft>[];
  for (var i = 0; i < days; i++) {
    final date = DateTime(today.year, today.month, today.day + i);
    final key = dateKey(date);
    if (doneDays.contains(key) || mutedDays.contains(key)) continue;
    final times = timesFor(date);
    if (times == null) continue;
    final at = habitReminderAt(times, point, offsetMinutes);
    if (!at.isAfter(now)) continue;
    out.add((fireAt: at, title: name, body: 'A small one. Any amount counts.'));
  }
  return out;
}

/// "after waking", "30 min before winding down".
String describeHabitTime(HabitPoint point, int offset) {
  final what = switch (point) {
    HabitPoint.wake => 'waking',
    HabitPoint.eat => 'breakfast',
    HabitPoint.leave => 'leaving',
    HabitPoint.windDown => 'winding down',
  };
  if (offset == 0) return 'At $what';
  final m = offset.abs();
  return '$m min ${offset > 0 ? 'after' : 'before'} $what';
}
