import '../../../core/notifications/reminder_draft.dart';
import '../../../core/time/date_key.dart';
import '../../../core/time/local_time.dart';
import 'morning_plan.dart';
import 'wake_schedule.dart';

/// Routine reminder kinds, as strings so this file stays free of Drift.
/// Their names match `ReminderKind.name`.
enum RoutineStep { wake, eat, leave, windDown }

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

/// Sleep settings for planning wind-down reminders.
class WindDownSettings {
  const WindDownSettings({
    required this.wakePlan,
    required this.sleepTargetMinutes,
    required this.leadMinutes,
  });

  final WakePlan wakePlan;
  final int sleepTargetMinutes;
  final int leadMinutes;
}

/// Pure: turns the week's schedule into concrete reminders for the next
/// [days] days, skipping times already past and days muted with "Not today".
///
/// [inputsByWeekday] holds a [MorningInputs] per weekday that has a row;
/// missing weekdays have no class. [muted] holds `"step:weekday:yyyy-MM-dd"`.
///
/// [wakeFor] gives the wake time per date (gradual shift, weekend leeway);
/// without it each weekday's own target is used. [wakeAnchor] adds a wake
/// reminder on days without class. [windDown] adds an evening reminder per
/// night, owned by the evening's weekday. [lowEnergy] keeps only wake and
/// leave. [wakeLine] adds an optional closing line (the daily verse) to
/// each wake reminder.
List<PlannedRoutineReminder> planRoutineReminders({
  required DateTime now,
  required Map<int, MorningInputs> inputsByWeekday,
  required Set<String> muted,
  LocalTime Function(DateTime date)? wakeFor,
  bool wakeAnchor = false,
  WindDownSettings? windDown,
  bool lowEnergy = false,
  int days = 7,
  String? Function(DateTime date)? wakeLine,
}) {
  final out = <PlannedRoutineReminder>[];
  final today = dateOnly(now);
  for (var offset = 0; offset < days; offset++) {
    final date = DateTime(today.year, today.month, today.day + offset);
    final weekday = date.weekday;
    final key = dateKey(date);
    bool isMuted(RoutineStep s) => muted.contains('${s.name}:$weekday:$key');
    void add(RoutineStep step, DateTime fireAt, String title, String body) {
      if (!fireAt.isAfter(now) || isMuted(step)) return;
      final extra = step == RoutineStep.wake ? wakeLine?.call(date) : null;
      if (extra != null) body = '$body\n$extra';
      out.add(
        PlannedRoutineReminder(
          step: step,
          weekday: weekday,
          draft: (fireAt: fireAt, title: title, body: body),
        ),
      );
    }

    final row = inputsByWeekday[weekday];
    final inputs = row == null && !wakeAnchor
        ? null
        : _withWake(row, wakeFor?.call(date));
    final plan = inputs == null ? null : computeLeaveByPlan(inputs);

    if (plan is LeaveByPlan) {
      final leaveBy = 'Leave by ${plan.leave.format24()}.';
      final classAt = 'Class at ${plan.firstClass.format24()}.';
      final eatWithWake = plan.slackMinutes == 0 || lowEnergy;
      add(
        RoutineStep.wake,
        plan.wake.onDate(date),
        'Good morning',
        [
          classAt,
          if (plan.slackMinutes == 0 && !lowEnergy) 'Breakfast first.',
          if (plan.wakeTooLate)
            'A little earlier than usual so the morning fits.',
          leaveBy,
        ].join(' '),
      );
      if (!eatWithWake) {
        add(
          RoutineStep.eat,
          plan.eatStart.onDate(date),
          'Breakfast',
          'A few minutes to eat before getting ready. $leaveBy',
        );
      }
      add(
        RoutineStep.leave,
        plan.leave.onDate(date),
        'Time to leave',
        '$classAt Head out now and you arrive on time.',
      );
    } else if (plan is NoClassMorning && wakeAnchor && inputs != null) {
      add(
        RoutineStep.wake,
        inputs.targetWake.onDate(date),
        'Good morning',
        'No class today. Getting up at a steady time keeps sleep steady.',
      );
    }

    if (windDown != null && !lowEnergy) {
      final night = nightPlan(
        plan: windDown.wakePlan,
        night: date,
        sleepTargetMinutes: windDown.sleepTargetMinutes,
        windDownLeadMinutes: windDown.leadMinutes,
      );
      final tomorrow = DateTime(date.year, date.month, date.day + 1);
      final next = inputsByWeekday[tomorrow.weekday];
      final nextPlan = next == null
          ? null
          : computeLeaveByPlan(_withWake(next, wakeFor?.call(tomorrow)));
      final first = switch (nextPlan) {
        LeaveByPlan p =>
          'Tomorrow: class ${p.firstClass.format24()}, '
              'leave by ${p.leave.format24()}.',
        _ => 'Tomorrow has no class.',
      };
      add(
        RoutineStep.windDown,
        night.windDownAt,
        'Time to wind down',
        'Bed around ${_hm(night.bedtime)}, up at ${_hm(night.wakeAt)}. $first',
      );
    }
  }
  return out;
}

MorningInputs _withWake(MorningInputs? i, LocalTime? wake) => MorningInputs(
  firstClass: i?.firstClass,
  commuteMinutes: i?.commuteMinutes ?? 30,
  prepMinutes: i?.prepMinutes ?? 30,
  breakfastMinutes: i?.breakfastMinutes ?? 15,
  targetWake: wake ?? i?.targetWake ?? LocalTime.of(6, 30),
);

String _hm(DateTime t) => LocalTime.of(t.hour, t.minute).format24();
