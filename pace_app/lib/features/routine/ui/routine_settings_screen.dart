import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pace_tokens.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_choice_sheet.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/widgets/pace_tile.dart';
import '../../../core/widgets/section_header.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_time.dart';
import '../../today/application/reminder_resync.dart';
import '../application/morning_inputs.dart';
import '../application/routine_providers.dart';
import '../domain/morning_plan.dart';
import '../domain/wake_schedule.dart';
import '../../../routes.dart';
import '../../habits/application/habit_providers.dart';
import '../../habits/application/habit_service.dart';
import '../../habits/domain/habit_planner.dart';
import '../../habits/ui/habit_sheet.dart';
import 'weekday_edit_sheet.dart';

final weekdaySchedulesProvider = StreamProvider<List<WeekdaySchedule>>(
  (ref) => ref.watch(appDatabaseProvider).weekdayScheduleDao.watchAll(),
);

const weekdayNames = {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

/// Wake time and its gradual shift, sleep, breakfast, the week's first-class
/// times and low-energy mode. Every change re-plans all reminders.
class RoutineSettingsScreen extends ConsumerWidget {
  const RoutineSettingsScreen({super.key});

  Future<void> _afterChange(WidgetRef ref) =>
      ref.read(reminderResyncProvider)();

  static const _sleepChoices = [420, 450, 480, 510, 540];
  static const _leewayChoices = [0, 15, 30, 45, 60];
  static const _breakfastChoices = [10, 15, 20, 30];
  static const _windDownChoices = [15, 30, 45, 60];

  static String _hours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  Future<int?> _choose(
    BuildContext context,
    String title,
    List<int> values,
    String Function(int) label,
    int current, {
    Future<int?> Function()? custom,
  }) => showPaceChoiceSheet<int>(
    context: context,
    title: title,
    selected: current,
    choices: [for (final v in values) PaceChoice(v, label(v))],
    custom: custom,
  );

  Future<void> _editSleep(
    BuildContext context,
    WidgetRef ref,
    Setting s,
  ) async {
    final v = await _choose(
      context,
      'Sleep target',
      _sleepChoices,
      _hours,
      s.sleepTargetMinutes,
    );
    if (v == null) return;
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .updateSettings((x) => x.copyWith(sleepTargetMinutes: v));
    await _afterChange(ref);
  }

  Future<void> _editWindDown(
    BuildContext context,
    WidgetRef ref,
    Setting s,
  ) async {
    final v = await _choose(
      context,
      'Wind down before bed',
      _windDownChoices,
      (m) => '$m min',
      s.windDownLeadMinutes,
      custom: () => showMinutesDialog(
        context,
        title: 'Wind down before bed',
        initial: s.windDownLeadMinutes,
      ),
    );
    if (v == null) return;
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .updateSettings((x) => x.copyWith(windDownLeadMinutes: v));
    await _afterChange(ref);
  }

  Future<void> _editLeeway(
    BuildContext context,
    WidgetRef ref,
    Setting s,
  ) async {
    final v = await _choose(
      context,
      'Weekend lie-in',
      _leewayChoices,
      (m) => m == 0 ? 'Same as weekdays' : '$m min later',
      s.weekendLeewayMinutes,
    );
    if (v == null) return;
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .updateSettings((x) => x.copyWith(weekendLeewayMinutes: v));
    await _afterChange(ref);
  }

  Future<void> _startShift(
    BuildContext context,
    WidgetRef ref,
    LocalTime current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.plusMinutes(-60).hour,
        minute: current.plusMinutes(-60).minute,
      ),
      helpText: 'Wake time to work toward',
    );
    if (picked == null) return;
    await ref
        .read(routineRemindersProvider)
        .startGradualWake(goalMinutes: picked.hour * 60 + picked.minute);
    await _afterChange(ref);
  }

  Future<void> _stopShift(WidgetRef ref, LocalTime current) async {
    await ref
        .read(routineRemindersProvider)
        .setWakeTime(current.minutesSinceMidnight);
    await _afterChange(ref);
  }

  Future<void> _pickWakeTime(
    BuildContext context,
    WidgetRef ref,
    Setting s,
  ) async {
    final current = weekdayWakeOn(wakePlanFrom(s), ref.read(clockProvider)());
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Wake time',
    );
    if (picked == null) return;
    await ref
        .read(routineRemindersProvider)
        .setWakeTime(picked.hour * 60 + picked.minute);
    await _afterChange(ref);
  }

  Future<void> _editBreakfast(
    BuildContext context,
    WidgetRef ref,
    Setting s,
  ) async {
    final minutes = await _choose(
      context,
      'Breakfast',
      _breakfastChoices,
      (m) => '$m min',
      s.breakfastMinutes,
      custom: () => showMinutesDialog(
        context,
        title: 'Breakfast',
        initial: s.breakfastMinutes,
      ),
    );
    if (minutes == null) return;
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .updateSettings((x) => x.copyWith(breakfastMinutes: minutes));
    await _afterChange(ref);
  }

  Future<void> _editWeekday(
    BuildContext context,
    WidgetRef ref,
    int weekday,
    WeekdaySchedule? row,
  ) async {
    final result = await showModalBottomSheet<WeekdayEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WeekdayEditSheet(
        weekdayName: weekdayNames[weekday]!,
        initial: row == null
            ? null
            : WeekdayEdit(
                firstClassMinutes: row.firstClassMinutes,
                commuteMinutes: row.commuteMinutes,
                prepMinutes: row.prepMinutes,
              ),
      ),
    );
    if (result == null) return;
    await ref
        .read(appDatabaseProvider)
        .weekdayScheduleDao
        .upsert(
          weekday: weekday,
          firstClassMinutes: result.firstClassMinutes,
          commuteMinutes: result.commuteMinutes,
          prepMinutes: result.prepMinutes,
        );
    await _afterChange(ref);
  }

  /// The next date (today included) that falls on [weekday].
  static DateTime _nextDate(DateTime now, int weekday) {
    final d = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day + (weekday - d.weekday) % 7);
  }

  String _summary(Setting s, WeekdaySchedule? row, int weekday, DateTime now) {
    final date = _nextDate(now, weekday);
    final wake = wakeOn(wakePlanFrom(s), date);
    if (row == null || row.firstClassMinutes == null) {
      return 'No class · up at ${wake.format24()}';
    }
    final plan = computeLeaveByPlan(morningInputsFor(s, row, date: date));
    return switch (plan) {
      LeaveByPlan p =>
        'Class ${p.firstClass.format24()} · leave by ${p.leave.format24()}'
            ' · up at ${p.wake.format24()}',
      ImpossibleMorning _ => 'That morning does not fit. Check the times.',
      NoClassMorning _ => 'No class',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final rows = ref.watch(weekdaySchedulesProvider).value ?? const [];
    final byWeekday = {for (final r in rows) r.weekday: r};
    final now = ref.watch(clockProvider)();
    final features = ref.watch(platformFeaturesProvider);
    final habit = ref.watch(movementHabitProvider).value;
    final wakePlan = settings == null ? null : wakePlanFrom(settings);
    final wakeToday = wakePlan == null ? null : weekdayWakeOn(wakePlan, now);
    final shift = wakePlan?.shift;
    final tonight = settings == null
        ? null
        : nightPlan(
            plan: wakePlan!,
            night: DateTime(now.year, now.month, now.day),
            sleepTargetMinutes: settings.sleepTargetMinutes,
            windDownLeadMinutes: settings.windDownLeadMinutes,
          );
    String hm(DateTime t) => LocalTime.of(t.hour, t.minute).format24();
    String day(DateTime d) => '${d.day}/${d.month}';

    if (settings == null) {
      return const PacePage(title: 'Settings', children: []);
    }
    return PacePage(
      title: 'Settings',
      subtitle: 'Your week, mornings and evenings.',
      children: [
        const SectionHeader('Week', padding: EdgeInsets.fromLTRB(4, 8, 4, 6)),
        PaceGroup(
          children: [
            for (final weekday in weekdayNames.keys)
              PaceTile(
                key: ValueKey('weekday-$weekday'),
                leading: _DayBadge(
                  weekdayNames[weekday]!.substring(0, 2),
                  hasClass: byWeekday[weekday]?.firstClassMinutes != null,
                ),
                title: weekdayNames[weekday]!,
                subtitle: _summary(settings, byWeekday[weekday], weekday, now),
                chevron: true,
                onTap: () =>
                    _editWeekday(context, ref, weekday, byWeekday[weekday]),
              ),
          ],
        ),
        const SectionHeader('Mornings'),
        PaceGroup(
          children: [
            PaceTile(
              key: const ValueKey('wake-time'),
              icon: Icons.wb_sunny_rounded,
              kind: PastelKind.morning,
              title: 'Wake time',
              subtitle: shift == null
                  ? 'Kept steady every day, even when a class is late.'
                  : 'Moving ${shift.stepMinutes} min earlier every '
                        '${shift.everyDays} days toward '
                        '${LocalTime(shift.goalMinutes).format24()}, there by '
                        '${day(shiftReachesGoalOn(shift))}.',
              value: wakeToday!.format24(),
              onTap: () => _pickWakeTime(context, ref, settings),
            ),
            if (shift == null)
              PaceTile(
                key: const ValueKey('start-shift'),
                icon: Icons.trending_down_rounded,
                kind: PastelKind.morning,
                title: 'Move it earlier, gradually',
                subtitle:
                    '15 minutes every 3 days. A missed night does not undo '
                    'anything.',
                chevron: true,
                onTap: () => _startShift(context, ref, wakeToday),
              )
            else
              PaceTile(
                key: const ValueKey('stop-shift'),
                icon: Icons.pause_circle_outline_rounded,
                kind: PastelKind.morning,
                title: 'Stay at this time',
                subtitle: 'Keep ${wakeToday.format24()} and stop moving.',
                onTap: () => _stopShift(ref, wakeToday),
              ),
            PaceTile(
              key: const ValueKey('weekend-leeway'),
              icon: Icons.weekend_rounded,
              kind: PastelKind.morning,
              title: 'Weekend lie-in',
              subtitle: 'Saturday and Sunday stay within an hour.',
              value: settings.weekendLeewayMinutes == 0
                  ? 'None'
                  : '+${settings.weekendLeewayMinutes} min',
              onTap: () => _editLeeway(context, ref, settings),
            ),
            PaceTile(
              icon: Icons.restaurant_rounded,
              kind: PastelKind.morning,
              title: 'Breakfast',
              subtitle: 'Time set aside to eat.',
              value: '${settings.breakfastMinutes} min',
              onTap: () => _editBreakfast(context, ref, settings),
            ),
          ],
        ),
        const SectionHeader('Evenings'),
        PaceGroup(
          children: [
            PaceTile(
              key: const ValueKey('sleep-target'),
              icon: Icons.bedtime_rounded,
              kind: PastelKind.evening,
              title: 'Sleep target',
              subtitle: 'Bed around ${hm(tonight!.bedtime)} tonight.',
              value: _hours(settings.sleepTargetMinutes),
              onTap: () => _editSleep(context, ref, settings),
            ),
            PaceTile(
              key: const ValueKey('wind-down'),
              icon: Icons.nights_stay_rounded,
              kind: PastelKind.evening,
              title: 'Wind down',
              subtitle: features.reminders
                  ? 'A gentle reminder at ${hm(tonight.windDownAt)}.'
                  : 'From ${hm(tonight.windDownAt)}. The reminder is on the '
                        'Android app.',
              value: '${settings.windDownLeadMinutes} min before',
              onTap: () => _editWindDown(context, ref, settings),
            ),
          ],
        ),
        const SectionHeader('Energy'),
        PaceGroup(
          children: [
            PaceTile.toggle(
              key: const ValueKey('low-energy-setting'),
              icon: Icons.spa_rounded,
              title: 'Low-energy mode',
              subtitle:
                  'Only wake, leave and what is due in two days. Other '
                  'reminders pause.',
              value: settings.lowEnergyEnabled,
              onChanged: (on) => ref.read(setLowEnergyProvider)(on),
            ),
          ],
        ),
        const SectionHeader('Extras'),
        PaceGroup(
          children: [
            PaceTile.toggle(
              key: const ValueKey('verse-setting'),
              icon: Icons.menu_book_rounded,
              kind: PastelKind.evening,
              title: 'Daily verse',
              subtitle:
                  'On Today and in the wake-up reminder. Hidden in '
                  'low-energy mode.',
              value: settings.verseEnabled,
              onChanged: (on) async {
                await ref
                    .read(appDatabaseProvider)
                    .settingsDao
                    .updateSettings((s) => s.copyWith(verseEnabled: on));
                await _afterChange(ref);
              },
            ),
            PaceTile(
              key: const ValueKey('habit-setting'),
              icon: Icons.directions_walk_rounded,
              kind: PastelKind.morning,
              title: 'Movement',
              subtitle: habit == null || !habit.active
                  ? 'Off'
                  : '${habit.name} · ${describeHabitTime(HabitService.pointFor(habit.anchor), habit.offsetMinutes).toLowerCase()}',
              chevron: true,
              onTap: () => showHabitSheet(context, ref),
            ),
            PaceTile(
              icon: Icons.school_rounded,
              kind: PastelKind.leave,
              title: 'Class schedule',
              chevron: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.schedule),
            ),
            if (features.appBlocking)
              PaceTile(
                icon: Icons.do_not_disturb_on_rounded,
                kind: PastelKind.evening,
                title: 'App gate',
                subtitle: settings.gateEnabled ? 'On' : 'Off',
                chevron: true,
                onTap: () => Navigator.of(context).pushNamed(Routes.gate),
              ),
            if (features.calendarSync)
              PaceTile(
                icon: Icons.event_rounded,
                kind: PastelKind.focus,
                title: 'Google Calendar',
                subtitle: settings.calendarSyncedAt == null
                    ? 'Not connected (optional)'
                    : 'Connected',
                chevron: true,
                onTap: () => Navigator.of(context).pushNamed(Routes.calendar),
              ),
          ],
        ),
      ],
    );
  }
}

/// Two-letter day marker; filled on class days.
class _DayBadge extends StatelessWidget {
  const _DayBadge(this.label, {required this.hasClass});

  final String label;
  final bool hasClass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedContainer(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasClass ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(PaceRadius.s),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: hasClass ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
