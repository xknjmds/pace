import '../../../core/notifications/reminder_draft.dart';
import '../../../core/time/date_key.dart';
import '../../../core/time/local_time.dart';
import 'morning_plan.dart';

/// Routine reminder kinds, as strings so this file stays free of Drift.
/// They match `ReminderKind.name` for wake, eat and leave.
enum RoutineStep { wake, eat, leave }

/// A reminder the planner wants scheduled, addressed by step and weekday.
class PlannedRoutineReminder {
  const PlannedRoutineReminder({
    required this.step,
    required this.weekday,
    required this.draft,
  });

  final RoutineStep step;

  /// [DateTime.monday] to [DateTime.sunday]; the reminder's owner id.
  final int weekday;
  final ReminderDraft draft;
}

/// Pure: turns the week's schedule into concrete reminders for the next
/// [days] days, skipping times already past and days muted with "Not today".
///
/// [inputsByWeekday] holds a [MorningInputs] per weekday that has a row;
/// missing weekdays have no class. [muted] holds `"step:weekday:yyyy-MM-dd"`.
List<PlannedRoutineReminder> planRoutineReminders({
  required DateTime now,
  required Map<int, MorningInputs> inputsByWeekday,
  required Set<String> muted,
  int days = 7,
}) {
  final out = <PlannedRoutineReminder>[];
  final today = dateOnly(now);
  for (var offset = 0; offset < days; offset++) {
    final date = DateTime(today.year, today.month, today.day + offset);
    final weekday = date.weekday;
    final inputs = inputsByWeekday[weekday];
    if (inputs == null) continue;
    final plan = computeLeaveByPlan(inputs);
    if (plan is! LeaveByPlan) continue;

    final key = dateKey(date);
    bool isMuted(RoutineStep s) => muted.contains('${s.name}:$weekday:$key');
    void add(RoutineStep step, LocalTime at, String title, String body) {
      final fireAt = at.onDate(date);
      if (!fireAt.isAfter(now) || isMuted(step)) return;
      out.add(
        PlannedRoutineReminder(
          step: step,
          weekday: weekday,
          draft: (fireAt: fireAt, title: title, body: body),
        ),
      );
    }

    final leaveBy = 'Leave by ${plan.leave.format24()}.';
    final classAt = 'Class at ${plan.firstClass.format24()}.';
    final eatWithWake = plan.slackMinutes == 0;

    add(
      RoutineStep.wake,
      plan.wake,
      'Good morning',
      [
        classAt,
        if (eatWithWake) 'Breakfast first.',
        if (plan.wakeTooLate)
          'A little earlier than usual so the morning fits.',
        leaveBy,
      ].join(' '),
    );
    if (!eatWithWake) {
      add(
        RoutineStep.eat,
        plan.eatStart,
        'Breakfast',
        'A few minutes to eat before getting ready. $leaveBy',
      );
    }
    add(
      RoutineStep.leave,
      plan.leave,
      'Time to leave',
      '$classAt Head out now and you arrive on time.',
    );
  }
  return out;
}
