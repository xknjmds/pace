import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/widgets/cairn_mark.dart';
import '../../../routes.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../deadlines/domain/deadline_reminders.dart';
import '../../focus/application/focus_providers.dart';
import '../../focus/domain/focus_timer.dart';
import '../../inbox/application/inbox_providers.dart';
import '../../routine/application/morning_inputs.dart';
import '../../routine/application/routine_providers.dart';
import '../../routine/domain/routine_reminder_planner.dart';
import '../application/today_providers.dart';
import '../domain/today_model.dart';
import 'top3_picker_sheet.dart';

/// Answers "what do I do right now?" in one screen: the next routine step
/// (or the one thing to do when the morning is late), today's top three,
/// deadlines inside 48 hours, and one line about tomorrow.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const deadlineWindow = Duration(hours: 48);
  static const maxDeadlinesShown = 3;

  static const _menu = <String, String>{
    'Deadlines': Routes.deadlines,
    'Inbox': Routes.inbox,
    'Focus': Routes.focus,
    'Review': Routes.review,
    'Settings': Routes.settings,
    'Reminders': Routes.notifications,
  };

  static const _kinds = {
    RoutineStep.wake: ReminderKind.wake,
    RoutineStep.eat: ReminderKind.eat,
    RoutineStep.leave: ReminderKind.leave,
  };

  Future<void> _markStep(WidgetRef ref, RoutineStep step, DateTime now) =>
      ref.read(routineRemindersProvider).done(_kinds[step]!, now.weekday);

  /// The late card's one button: out the door, routine counted as done.
  Future<void> _outTheDoor(WidgetRef ref, DateTime now) async {
    final routine = ref.read(routineRemindersProvider);
    await routine.done(ReminderKind.wake, now.weekday);
    await routine.done(ReminderKind.leave, now.weekday);
  }

  Future<void> _pickTop3(
    BuildContext context,
    WidgetRef ref,
    DateTime now,
    List<Task> pending,
    List<String> current,
  ) async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          Top3PickerSheet(tasks: pending, selected: current, now: now),
    );
    if (picked == null) return;
    await ref.read(appDatabaseProvider).dailyLogsDao.setTop3(now, picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final settings = ref.watch(settingsProvider).value;
    final schedules = ref.watch(scheduleByWeekdayProvider);
    final log = ref.watch(dailyLogProvider(dateKey(now))).value;
    final pending = ref.watch(pendingTasksProvider).value ?? const <Task>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final inboxCount = ref.watch(inboxCountProvider);
    final focus = ref.watch(activeFocusProvider).value;
    final theme = Theme.of(context);

    final hasSchedule = schedules.isNotEmpty;
    final status = settings == null
        ? null
        : routineStatus(
            now: now,
            inputs: morningInputsFor(settings, schedules[now.weekday]),
            wakeDone: log?.wakeLoggedAt != null,
            eatDone: log?.eatDoneAt != null,
            leaveDone: log?.routineDone ?? false,
            lateThresholdMinutes: settings.lateThresholdMinutes,
            lowEnergy: lowEnergy,
          );
    final tomorrow = settings == null
        ? null
        : tomorrowPreview(
            morningInputsFor(
              settings,
              schedules[now.add(const Duration(days: 1)).weekday],
            ),
          );
    final top3Ids = log?.top3TaskIds ?? const <String>[];
    final top3 = [
      for (final id in top3Ids)
        for (final t in pending)
          if (t.id == id) t,
    ];
    final soon = pending
        .where((t) => t.dueAt.toLocal().isBefore(now.add(deadlineWindow)))
        .toList();

    final empty =
        !hasSchedule && pending.isEmpty && inboxCount == 0 && focus == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (route) => Navigator.of(context).pushNamed(route),
            itemBuilder: (_) => [
              for (final entry in _menu.entries)
                PopupMenuItem(value: entry.value, child: Text(entry.key)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            if (empty) ...[
              const SizedBox(height: 16),
              const Center(child: CairnMark(size: 72)),
              const SizedBox(height: 16),
              Text(
                'Progress Always Comes Eventually',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nothing is scheduled yet. Set up your week whenever you '
                'are ready.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.tonal(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.settings),
                  child: const Text('Set up your week'),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              if (status != null)
                _RoutineCard(
                  status: status,
                  onStepDone: (step) => _markStep(ref, step, now),
                  onOutTheDoor: () => _outTheDoor(ref, now),
                ),
              if (!lowEnergy)
                _Section(
                  title: 'Top 3',
                  action: TextButton(
                    onPressed: () =>
                        _pickTop3(context, ref, now, pending, top3Ids),
                    child: Text(top3.isEmpty ? 'Pick' : 'Change'),
                  ),
                  child: top3.isEmpty
                      ? Text(
                          pending.isEmpty
                              ? 'No open deadlines. Add some, or enjoy the room.'
                              : 'Pick up to three things to move today.',
                          style: theme.textTheme.bodyMedium,
                        )
                      : Column(
                          children: [
                            for (final t in top3)
                              _TaskRow(
                                task: t,
                                now: now,
                                onSubmitted: () => ref
                                    .read(deadlineRemindersProvider)
                                    .markSubmitted(t.id),
                              ),
                          ],
                        ),
                ),
              _Section(
                title: 'Due soon',
                action: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.deadlines),
                  child: const Text('All'),
                ),
                child: soon.isEmpty
                    ? Text(
                        'Nothing due in the next two days.',
                        style: theme.textTheme.bodyMedium,
                      )
                    : Column(
                        children: [
                          for (final t in soon.take(maxDeadlinesShown))
                            _TaskRow(
                              task: t,
                              now: now,
                              onSubmitted: () => ref
                                  .read(deadlineRemindersProvider)
                                  .markSubmitted(t.id),
                            ),
                          if (soon.length > maxDeadlinesShown)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'and ${soon.length - maxDeadlinesShown} more',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
              ),
              if (focus != null)
                ListTile(
                  key: const ValueKey('focus-line'),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(Icons.timer_outlined, size: 20),
                  title: Text(switch (focusStateAt(
                    now: now,
                    startedAt: focus.startedAt.toLocal(),
                    plannedMinutes: focus.durationMinutes,
                  )) {
                    // Round up: 5:30 left reads "6 min left".
                    FocusRunning(:final remaining) =>
                      'Focus: ${(remaining.inSeconds + 59) ~/ 60} min left',
                    _ => 'Focus: time is up',
                  }, style: theme.textTheme.bodyMedium),
                  onTap: () => Navigator.of(context).pushNamed(Routes.focus),
                ),
              if (inboxCount > 0)
                ListTile(
                  key: const ValueKey('inbox-count'),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(Icons.inbox_outlined, size: 20),
                  title: Text(
                    'Inbox: $inboxCount waiting',
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () => Navigator.of(context).pushNamed(Routes.inbox),
                ),
              if (!lowEnergy && tomorrow != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text(
                    tomorrow,
                    key: const ValueKey('tomorrow-preview'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('Low-energy mode'),
              value: lowEnergy,
              onChanged: settings == null
                  ? null
                  : (on) => ref
                        .read(appDatabaseProvider)
                        .settingsDao
                        .setLowEnergy(on),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.status,
    required this.onStepDone,
    required this.onOutTheDoor,
  });

  final RoutineStatus status;
  final void Function(RoutineStep step) onStepDone;
  final VoidCallback onOutTheDoor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = switch (status) {
      NoClassToday() => Text(
        'No class today. The day is yours.',
        style: theme.textTheme.bodyLarge,
      ),
      MorningDoesNotFit() => Text(
        'Today\'s morning does not fit the times in Settings. '
        'Worth a look.',
        style: theme.textTheme.bodyLarge,
      ),
      RoutineAllDone() => Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text('Routine done for today.', style: theme.textTheme.bodyLarge),
        ],
      ),
      RunningLate(:final title, :final subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onOutTheDoor,
            child: const Text('I\'m out the door'),
          ),
        ],
      ),
      StepsRemaining(:final steps, :final next) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next: ${next.label.toLowerCase()} at ${next.at.format24()}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in steps)
                s.done
                    ? Chip(
                        avatar: Icon(
                          Icons.check,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text('${s.label} ${s.at.format24()}'),
                      )
                    : ActionChip(
                        key: ValueKey('step-${s.step.name}'),
                        avatar: const Icon(Icons.circle_outlined, size: 18),
                        label: Text('${s.label} ${s.at.format24()}'),
                        onPressed: () => onStepDone(s.step),
                      ),
            ],
          ),
        ],
      ),
    };
    return Card(
      key: const ValueKey('routine-card'),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.action,
  });

  final String title;
  final Widget child;
  final Widget action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              action,
            ],
          ),
          child,
        ],
      ),
    ),
  );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.now,
    required this.onSubmitted,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Submitted',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.radio_button_unchecked, size: 20),
        onPressed: onSubmitted,
      ),
      Expanded(
        child: Text(
          '${task.title} · ${describeDue(task.dueAt, now)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
