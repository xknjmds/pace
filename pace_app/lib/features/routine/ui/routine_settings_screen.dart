import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/local_time.dart';
import '../application/routine_providers.dart';
import '../domain/morning_plan.dart';
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

/// Wake time, breakfast length and the week's first-class times. Every
/// change re-plans the routine reminders.
class RoutineSettingsScreen extends ConsumerWidget {
  const RoutineSettingsScreen({super.key});

  Future<void> _afterChange(WidgetRef ref) =>
      ref.read(routineRemindersProvider).resync();

  Future<void> _pickWakeTime(
    BuildContext context,
    WidgetRef ref,
    Setting s,
  ) async {
    final current = LocalTime(s.targetWakeMinutes);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Wake time',
    );
    if (picked == null) return;
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .updateSettings(
          (x) =>
              x.copyWith(targetWakeMinutes: picked.hour * 60 + picked.minute),
        );
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

  String _summary(Setting s, WeekdaySchedule? row) {
    if (row == null || row.firstClassMinutes == null) return 'No class';
    final plan = computeLeaveByPlan(
      MorningInputs(
        firstClass: LocalTime(row.firstClassMinutes!),
        commuteMinutes: row.commuteMinutes,
        prepMinutes: row.prepMinutes,
        breakfastMinutes: s.breakfastMinutes,
        targetWake: LocalTime(s.targetWakeMinutes),
      ),
    );
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
                        title: const Text('Wake time'),
                        subtitle: const Text(
                          'Kept steady every day, even when a class is late.',
                        ),
                        trailing: Text(
                          LocalTime(settings.targetWakeMinutes).format24(),
                          style: theme.textTheme.titleMedium,
                        ),
                        onTap: () => _pickWakeTime(context, ref, settings),
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
                _SectionLabel('Week'),
                Card(
                  child: Column(
                    children: [
                      for (final weekday in weekdayNames.keys)
                        ListTile(
                          key: ValueKey('weekday-$weekday'),
                          title: Text(weekdayNames[weekday]!),
                          subtitle: Text(
                            _summary(settings, byWeekday[weekday]),
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
