import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    int current,
  ) => showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (final v in values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(v),
            child: Row(
              children: [
                Icon(
                  v == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(label(v)),
              ],
            ),
          ),
      ],
    ),
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
    final v = await showMinutesDialog(
      context,
      title: 'Wind down before bed',
      initial: s.windDownLeadMinutes,
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
    final minutes = await showMinutesDialog(
      context,
      title: 'Breakfast',
      initial: s.breakfastMinutes,
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
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final features = ref.watch(platformFeaturesProvider);
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _SectionLabel('Mornings'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        key: const ValueKey('wake-time'),
                        title: const Text('Wake time'),
                        subtitle: Text(
                          shift == null
                              ? 'Kept steady every day, even when a class is '
                                    'late.'
                              : 'Moving ${shift.stepMinutes} min earlier '
                                    'every ${shift.everyDays} days toward '
                                    '${LocalTime(shift.goalMinutes).format24()}'
                                    ', there by '
                                    '${day(shiftReachesGoalOn(shift))}.',
                        ),
                        trailing: Text(
                          wakeToday!.format24(),
                          style: theme.textTheme.titleMedium,
                        ),
                        onTap: () => _pickWakeTime(context, ref, settings),
                      ),
                      if (shift == null)
                        ListTile(
                          key: const ValueKey('start-shift'),
                          title: const Text('Move it earlier, gradually'),
                          subtitle: const Text(
                            '15 minutes every 3 days. A missed night does '
                            'not undo anything.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _startShift(context, ref, wakeToday),
                        )
                      else
                        ListTile(
                          key: const ValueKey('stop-shift'),
                          title: const Text('Stay at this time'),
                          subtitle: Text(
                            'Keep ${wakeToday.format24()} and stop moving.',
                          ),
                          onTap: () => _stopShift(ref, wakeToday),
                        ),
                      ListTile(
                        key: const ValueKey('weekend-leeway'),
                        title: const Text('Weekend lie-in'),
                        subtitle: const Text(
                          'Saturday and Sunday stay within an hour.',
                        ),
                        trailing: Text(
                          settings.weekendLeewayMinutes == 0
                              ? 'None'
                              : '+${settings.weekendLeewayMinutes} min',
                          style: theme.textTheme.titleMedium,
                        ),
                        onTap: () => _editLeeway(context, ref, settings),
                      ),
                      ListTile(
                        title: const Text('Breakfast'),
                        subtitle: const Text('Time set aside to eat.'),
                        trailing: Text(
                          '${settings.breakfastMinutes} min',
                          style: theme.textTheme.titleMedium,
                        ),
                        onTap: () => _editBreakfast(context, ref, settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Evenings'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        key: const ValueKey('sleep-target'),
                        title: const Text('Sleep target'),
                        subtitle: Text(
                          'Bed around ${hm(tonight!.bedtime)} tonight.',
                        ),
                        trailing: Text(
                          _hours(settings.sleepTargetMinutes),
                          style: theme.textTheme.titleMedium,
                        ),
                        onTap: () => _editSleep(context, ref, settings),
                      ),
                      ListTile(
                        key: const ValueKey('wind-down'),
                        title: const Text('Wind down'),
                        subtitle: Text(
                          features.reminders
                              ? 'A gentle reminder at ${hm(tonight.windDownAt)}.'
                              : 'From ${hm(tonight.windDownAt)}. The reminder '
                                    'is on the Android app.',
                        ),
                        trailing: Text(
                          '${settings.windDownLeadMinutes} min before',
                          style: theme.textTheme.titleMedium,
                        ),
                        onTap: () => _editWindDown(context, ref, settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Energy'),
                Card(
                  child: SwitchListTile(
                    key: const ValueKey('low-energy-setting'),
                    title: const Text('Low-energy mode'),
                    subtitle: const Text(
                      'Only wake, leave and what is due in two days. Other '
                      'reminders pause.',
                    ),
                    value: settings.lowEnergyEnabled,
                    onChanged: (on) => ref.read(setLowEnergyProvider)(on),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Week'),
                Card(
                  child: Column(
                    children: [
                      for (final weekday in weekdayNames.keys)
                        ListTile(
                          key: ValueKey('weekday-$weekday'),
                          title: Text(weekdayNames[weekday]!),
                          subtitle: Text(
                            _summary(
                              settings,
                              byWeekday[weekday],
                              weekday,
                              now,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _editWeekday(
                            context,
                            ref,
                            weekday,
                            byWeekday[weekday],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
