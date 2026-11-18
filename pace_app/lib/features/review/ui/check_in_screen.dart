import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_time.dart';
import '../../../routes.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../deadlines/domain/deadline_reminders.dart';
import '../../routine/application/morning_inputs.dart';
import '../../routine/application/routine_providers.dart';
import '../../routine/domain/morning_plan.dart';
import '../../routine/domain/wake_schedule.dart';
import '../../routine/ui/routine_settings_screen.dart';
import '../../today/application/today_providers.dart';
import '../../today/ui/top3_picker_sheet.dart';

/// The evening check-in: look at tomorrow, pick its top three, confirm the
/// wake reminder, then go to bed. Every step can be skipped.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  /// Deadlines this close to tomorrow morning are worth seeing tonight.
  static const lookAhead = Duration(hours: 48);

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

enum _Step { tomorrow, top3, alarm, finish }

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  int _index = 0;
  bool _done = false;

  List<_Step> _steps(bool lowEnergy) => [
    _Step.tomorrow,
    if (!lowEnergy) _Step.top3,
    _Step.alarm,
    _Step.finish,
  ];

  static String _hm(DateTime t) => LocalTime.of(t.hour, t.minute).format24();

  Future<void> _goToBed(DateTime night) async {
    await ref
        .read(routineRemindersProvider)
        .done(ReminderKind.windDown, night.weekday);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final settings = ref.watch(settingsProvider).value;
    final lowEnergy = ref.watch(lowEnergyProvider);
    final schedules = ref.watch(weekdaySchedulesProvider).value ?? const [];
    final pending = ref.watch(pendingTasksProvider).value ?? const <Task>[];
    final permissions = ref.watch(notificationPermissionsProvider).value;
    final theme = Theme.of(context);

    if (settings == null) return const Scaffold();

    final night = nightOf(now);
    final tomorrow = DateTime(night.year, night.month, night.day + 1);
    final plan = nightPlan(
      plan: wakePlanFrom(settings),
      night: night,
      sleepTargetMinutes: settings.sleepTargetMinutes,
      windDownLeadMinutes: settings.windDownLeadMinutes,
    );
    final row = schedules.where((r) => r.weekday == tomorrow.weekday);
    final morning = computeLeaveByPlan(
      morningInputsFor(
        settings,
        row.isEmpty ? null : row.first,
        date: tomorrow,
      ),
    );
    final due = pending
        .where(
          (t) =>
              t.dueAt.toLocal().isBefore(tomorrow.add(CheckInScreen.lookAhead)),
        )
        .take(3)
        .toList();
    final tomorrowLog = ref.watch(dailyLogProvider(dateKey(tomorrow))).value;
    final top3Ids = tomorrowLog?.top3TaskIds ?? const <String>[];

    final steps = _steps(lowEnergy);
    final index = _index.clamp(0, steps.length - 1);
    final step = steps[index];
    final isLast = index == steps.length - 1;

    final body = switch (step) {
      _Step.tomorrow => [
        Text('Tomorrow', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          switch (morning) {
            LeaveByPlan p =>
              'Up at ${p.wake.format24()}, leave by ${p.leave.format24()} '
                  'for class at ${p.firstClass.format24()}.',
            _ => 'No class. Up at ${_hm(plan.wakeAt)} keeps sleep steady.',
          },
          key: const ValueKey('check-in-tomorrow'),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        if (due.isEmpty)
          Text(
            'Nothing due in the next two days.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          Text('Coming up', style: theme.textTheme.titleSmall),
          for (final t in due)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(t.title),
              subtitle: Text(describeDue(t.dueAt, now)),
            ),
        ],
      ],
      _Step.top3 => [
        Text('Top 3 for tomorrow', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (top3Ids.isEmpty)
          Text(
            'Choosing now means less to decide in the morning.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final id in top3Ids)
            for (final t in pending.where((t) => t.id == id))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, size: 20),
                title: Text(t.title),
              ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            final picked = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              builder: (_) =>
                  Top3PickerSheet(tasks: pending, selected: top3Ids, now: now),
            );
            if (picked == null) return;
            await ref
                .read(appDatabaseProvider)
                .dailyLogsDao
                .setTop3(tomorrow, picked);
          },
          child: Text(top3Ids.isEmpty ? 'Pick' : 'Change'),
        ),
      ],
      _Step.alarm => [
        Text('Wake reminder', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          'Tomorrow at ${_hm(plan.wakeAt)}.',
          key: const ValueKey('check-in-alarm'),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        if (permissions != null && !permissions.notificationsGranted)
          Text(
            'Reminders are off on this phone, so it will not ring.',
            style: theme.textTheme.bodyMedium,
          )
        else if (permissions != null && !permissions.exactAlarmsAllowed)
          Text(
            'It may arrive a few minutes late. Exact alarms are off.',
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            if (permissions != null && !permissions.reliable)
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.notifications),
                child: const Text('Set up reminders'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
              child: const Text('Change wake time'),
            ),
          ],
        ),
      ],
      _Step.finish => [
        Text(
          _done ? 'Sleep well.' : 'That is everything.',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          _done
              ? 'Bedtime logged. Tomorrow is ready.'
              : 'Bed around ${_hm(plan.bedtime)} gives you '
                    '${settings.sleepTargetMinutes ~/ 60} hours.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        if (!_done)
          FilledButton(
            key: const ValueKey('going-to-bed'),
            onPressed: () => _goToBed(night),
            child: const Text('Going to bed'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(_done ? 'Close' : 'Not yet'),
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: Text('Check-in ${index + 1} of ${steps.length}')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                children: body,
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    if (index > 0)
                      TextButton(
                        onPressed: () => setState(() => _index = index - 1),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    FilledButton(
                      key: const ValueKey('check-in-next'),
                      onPressed: () => setState(() => _index = index + 1),
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
