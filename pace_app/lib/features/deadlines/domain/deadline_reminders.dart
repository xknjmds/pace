import '../../../core/notifications/reminder_draft.dart';
import '../../../core/time/date_key.dart';
import '../../../core/time/local_time.dart';

/// Which of the four nudges a reminder is.
enum DeadlineNudge { threeDaysBefore, dayBefore, morningOf, twoHoursBefore }

class DeadlineReminder {
  const DeadlineReminder({required this.nudge, required this.fireAt});

  final DeadlineNudge nudge;
  final DateTime fireAt;
}

/// Pure: when to nudge about a deadline. Reminders already in the past, on
/// a muted day ("Not today"), or landing on the same minute as another are
/// left out. A deadline under two hours away may get nothing at all.
///
/// [dueAt] and [now] are local. [eveningAt] is the time of day for the
/// three-days and one-day nudges; [morningAt] for the morning-of nudge.
List<DeadlineReminder> computeDeadlineReminders({
  required DateTime dueAt,
  required DateTime now,
  required LocalTime eveningAt,
  required LocalTime morningAt,
  Set<String> mutedDates = const {},
}) {
  final dueDay = dateOnly(dueAt);
  DateTime daysBefore(int days, LocalTime at) =>
      at.onDate(DateTime(dueDay.year, dueDay.month, dueDay.day - days));

  final candidates = [
    DeadlineReminder(
      nudge: DeadlineNudge.threeDaysBefore,
      fireAt: daysBefore(3, eveningAt),
    ),
    DeadlineReminder(
      nudge: DeadlineNudge.dayBefore,
      fireAt: daysBefore(1, eveningAt),
    ),
    DeadlineReminder(
      nudge: DeadlineNudge.morningOf,
      fireAt: daysBefore(0, morningAt),
    ),
    DeadlineReminder(
      nudge: DeadlineNudge.twoHoursBefore,
      fireAt: dueAt.subtract(const Duration(hours: 2)),
    ),
  ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  final out = <DeadlineReminder>[];
  for (final c in candidates) {
    if (!c.fireAt.isAfter(now)) continue;
    if (!c.fireAt.isBefore(dueAt)) continue;
    if (mutedDates.contains(dateKey(c.fireAt))) continue;
    if (out.isNotEmpty && _sameMinute(out.last.fireAt, c.fireAt)) continue;
    out.add(c);
  }
  return out;
}

bool _sameMinute(DateTime a, DateTime b) =>
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day &&
    a.hour == b.hour &&
    a.minute == b.minute;

/// Notification text for one nudge. Never urgent in tone.
ReminderDraft deadlineDraft({
  required DeadlineReminder reminder,
  required String title,
  required String? subject,
  required DateTime dueAt,
}) {
  final what = subject == null || subject.isEmpty ? title : '$title ($subject)';
  final due = describeDue(dueAt, reminder.fireAt);
  final body = switch (reminder.nudge) {
    DeadlineNudge.threeDaysBefore => '$due. A good moment to start.',
    DeadlineNudge.dayBefore => '$due. Tomorrow is the day.',
    DeadlineNudge.morningOf => '$due. Today.',
    DeadlineNudge.twoHoursBefore => '$due. Two hours left.',
  };
  return (fireAt: reminder.fireAt, title: what, body: body);
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Pure: "Due today 23:59", "Due tomorrow 08:00", "Due Thu 23:59",
/// "Due 3 Dec 23:59", or "Was due Tue 23:59" when past.
String describeDue(DateTime dueAt, DateTime now) {
  final due = dueAt.isUtc ? dueAt.toLocal() : dueAt;
  final today = dateOnly(now);
  final days = dateOnly(due).difference(today).inDays;
  final time = LocalTime.of(due.hour, due.minute).format24();
  if (!due.isAfter(now)) {
    final day = days == 0
        ? 'today'
        : days == -1
        ? 'yesterday'
        : days > -7
        ? _weekdays[due.weekday - 1]
        : '${due.day} ${_months[due.month - 1]}';
    return 'Was due $day $time';
  }
  final day = days == 0
      ? 'today'
      : days == 1
      ? 'tomorrow'
      : days < 7
      ? _weekdays[due.weekday - 1]
      : '${due.day} ${_months[due.month - 1]}';
  return 'Due $day $time';
}
