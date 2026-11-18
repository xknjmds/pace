import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/startup_report.dart';
import '../../../core/time/local_time.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/cairn_progress.dart';
import '../../../core/widgets/done_check.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pace_section_card.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/tuck.dart';
import '../../../routes.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../deadlines/domain/deadline_reminders.dart';
import '../../focus/application/focus_providers.dart';
import '../../focus/domain/focus_timer.dart';
import '../../inbox/application/inbox_providers.dart';
import '../../routine/application/morning_inputs.dart';
import '../../routine/application/routine_providers.dart';
import '../../routine/domain/morning_plan.dart';
import '../../routine/domain/routine_reminder_planner.dart';
import '../../routine/domain/wake_schedule.dart';
import '../../shell/home_shell.dart';
import '../../shell/shell_tabs.dart';
import '../application/reminder_resync.dart';
import '../application/today_providers.dart';
import '../domain/day_timeline.dart';
import '../domain/today_model.dart';
import '../domain/tuck_pose_for.dart';
import 'day_timeline_view.dart';
import 'top3_picker_sheet.dart';
import 'week_strip.dart';

/// Answers "what do I do right now?" in one screen: the next routine step
/// (or the one thing to do when the morning is late), today's top three,
/// deadlines inside 48 hours, and one line about tomorrow.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const deadlineWindow = Duration(hours: 48);
  static const maxDeadlinesShown = 3;

  /// Screens that sit on top of the tabs.
  static const _menu = [
    ('Review', Routes.review, Icons.insights_outlined),
    ('Settings', Routes.settings, Icons.tune_rounded),
    ('Reminders', Routes.notifications, Icons.notifications_none_rounded),
  ];

  /// Shows a tab in the home shell, or pushes the screen when Today runs
  /// on its own.
  static void _go(BuildContext context, ShellTab tab, {bool capture = false}) {
    if (!HomeShell.open(context, tab, capture: capture)) {
      Navigator.of(
        context,
      ).pushNamed(capture ? Routes.inboxCapture : tab.route);
    }
  }

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
    final startup = ref.watch(startupReportProvider);
    final features = ref.watch(platformFeaturesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasSchedule = schedules.isNotEmpty;
    final status = settings == null
        ? null
        : routineStatus(
            now: now,
            inputs: morningInputsFor(
              settings,
              schedules[now.weekday],
              date: now,
            ),
            wakeDone: log?.wakeLoggedAt != null,
            eatDone: log?.eatDoneAt != null,
            leaveDone: log?.routineDone ?? false,
            lateThresholdMinutes: settings.lateThresholdMinutes,
            lowEnergy: lowEnergy,
            wakeAnchor: hasSchedule,
          );
    final night = settings == null
        ? null
        : nightPlan(
            plan: wakePlanFrom(settings),
            night: nightOf(now),
            sleepTargetMinutes: settings.sleepTargetMinutes,
            windDownLeadMinutes: settings.windDownLeadMinutes,
          );
    final nightLog = night == null
        ? null
        : ref.watch(dailyLogProvider(dateKey(night.night))).value;
    final evening =
        hasSchedule &&
        night != null &&
        showEveningCard(
          now: now,
          night: night,
          bedLogged: nightLog?.bedLoggedAt != null,
        );
    final tomorrow = settings == null
        ? null
        : tomorrowPreview(
            morningInputsFor(
              settings,
              schedules[now.add(const Duration(days: 1)).weekday],
              date: now.add(const Duration(days: 1)),
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

    final todayInputs = settings == null
        ? null
        : morningInputsFor(settings, schedules[now.weekday], date: now);
    final timeline = todayInputs == null || !hasSchedule
        ? const <TimelineEntry>[]
        : dayTimeline(
            day: now,
            morning: computeLeaveByPlan(todayInputs),
            noClassWake: todayInputs.targetWake,
            wakeDone: log?.wakeLoggedAt != null,
            eatDone: log?.eatDoneAt != null,
            leaveDone: log?.routineDone ?? false,
            tasks: [
              for (final t in pending)
                TimelineTask(id: t.id, title: t.title, due: t.dueAt.toLocal()),
            ],
            // Tonight belongs to today's timeline, even in the morning.
            night: nightPlan(
              plan: wakePlanFrom(settings!),
              night: DateTime(now.year, now.month, now.day),
              sleepTargetMinutes: settings.sleepTargetMinutes,
              windDownLeadMinutes: settings.windDownLeadMinutes,
            ),
            bedDone: log?.bedLoggedAt != null,
            lowEnergy: lowEnergy,
          );
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final doneThisWeek =
        ref.watch(weekRoutineDoneProvider(dateKey(monday))).value ??
        const <int>{};

    // The first build after launch eases the blocks in, once.
    final stagger = !_entered;
    if (stagger) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _entered = true);
    }
    var order = 0;
    Widget enter(Widget child) =>
        FadeSlideIn(index: order++, enabled: stagger, child: child);

    void markSubmitted(Task t) =>
        ref.read(deadlineRemindersProvider).markSubmitted(t.id);

    final focusText = focus == null
        ? null
        : switch (focusStateAt(
            now: now,
            startedAt: focus.startedAt.toLocal(),
            plannedMinutes: focus.durationMinutes,
          )) {
            // Round up: 5:30 left reads "6 min left".
            FocusRunning(:final remaining) =>
              'Focus: ${(remaining.inSeconds + 59) ~/ 60} min left',
            _ => 'Focus: time is up',
          };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          children: [
            // Tuck mirrors the moment: morning, leaving, focus, rest.
            if (!empty) ...[
              Tuck(
                key: const ValueKey('today-tuck'),
                size: 56,
                pose: tuckPoseFor(
                  now: now,
                  status: status,
                  evening: evening,
                  lowEnergy: lowEnergy,
                  focusRunning: focus != null,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    longDate(now),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    greetingFor(now),
                    style: theme.textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (route) => Navigator.of(context).pushNamed(route),
            itemBuilder: (_) => [
              for (final (label, route, icon) in _menu)
                if (features.reminders || route != Routes.notifications)
                  PopupMenuItem(
                    value: route,
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(label),
                      ],
                    ),
                  ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: empty
          ? null
          : FloatingActionButton(
              tooltip: 'Write it down',
              onPressed: () => _go(context, ShellTab.inbox, capture: true),
              child: const Icon(Icons.edit_outlined),
            ),
      body: SafeArea(
        child: ListView(
          padding: PaceSpace.screen,
          children: [
            if (!startup.ok)
              enter(
                Card(
                  key: const ValueKey('startup-problem'),
                  color: scheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Reminders did not start properly'),
                    subtitle: const Text(
                      'Everything else works. Check the reminder setup.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.notifications),
                  ),
                ),
              ),
            if (!empty)
              enter(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WeekStrip(today: now, doneWeekdays: doneThisWeek),
                ),
              ),
            if (empty)
              enter(
                EmptyWelcome(
                  onSetUp: () =>
                      Navigator.of(context).pushNamed(Routes.settings),
                ),
              )
            else ...[
              if (evening)
                enter(
                  _EveningCard(
                    bedtime: LocalTime.of(
                      night.bedtime.hour,
                      night.bedtime.minute,
                    ),
                    onCheckIn: () =>
                        Navigator.of(context).pushNamed(Routes.checkIn),
                    onBed: () => ref
                        .read(routineRemindersProvider)
                        .done(ReminderKind.windDown, night.night.weekday),
                  ),
                ),
              if (status != null)
                enter(
                  _RoutineCard(
                    status: status,
                    onStepDone: (step) => _markStep(ref, step, now),
                    onOutTheDoor: () => _outTheDoor(ref, now),
                  ),
                ),
              if (focusText != null || inboxCount > 0)
                enter(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (focusText != null)
                          _StatusPill(
                            key: const ValueKey('focus-line'),
                            icon: Icons.timer_outlined,
                            text: focusText,
                            onTap: () => _go(context, ShellTab.focus),
                          ),
                        if (inboxCount > 0)
                          _StatusPill(
                            key: const ValueKey('inbox-count'),
                            icon: Icons.inbox_outlined,
                            text: 'Inbox: $inboxCount waiting',
                            onTap: () => _go(context, ShellTab.inbox),
                          ),
                      ],
                    ),
                  ),
                ),
              if (timeline.isNotEmpty)
                enter(
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Text(
                            'Your day',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        DayTimelineView(
                          key: const ValueKey('day-timeline'),
                          entries: timeline,
                          now: now,
                          onTapDeadline: (_) =>
                              _go(context, ShellTab.deadlines),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!lowEnergy)
                enter(
                  PaceSectionCard(
                    title: 'Top 3',
                    icon: Icons.flag_rounded,
                    pastel: PastelKind.leave,
                    action: TextButton(
                      onPressed: () =>
                          _pickTop3(context, ref, now, pending, top3Ids),
                      child: Text(top3.isEmpty ? 'Pick' : 'Change'),
                    ),
                    child: top3.isEmpty
                        ? _Hint(
                            pending.isEmpty
                                ? 'No open deadlines. Add some, or enjoy the room.'
                                : 'Pick up to three things to move today.',
                          )
                        : Column(
                            children: [
                              for (final t in top3)
                                _TaskRow(
                                  key: ValueKey('top3-${t.id}'),
                                  task: t,
                                  now: now,
                                  onSubmitted: () => markSubmitted(t),
                                ),
                            ],
                          ),
                  ),
                ),
              enter(
                PaceSectionCard(
                  title: 'Due soon',
                  icon: Icons.event_note_rounded,
                  pastel: PastelKind.deadline,
                  action: TextButton(
                    onPressed: () => _go(context, ShellTab.deadlines),
                    child: const Text('All'),
                  ),
                  child: soon.isEmpty
                      ? const _Hint('Nothing due in the next two days.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final t in soon.take(maxDeadlinesShown))
                              _TaskRow(
                                key: ValueKey('soon-${t.id}'),
                                task: t,
                                now: now,
                                onSubmitted: () => markSubmitted(t),
                              ),
                            if (soon.length > maxDeadlinesShown)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                                child: Text(
                                  'and ${soon.length - maxDeadlinesShown} more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              if (!lowEnergy && tomorrow != null)
                enter(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_twilight_rounded,
                          size: 18,
                          color: scheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tomorrow,
                            key: const ValueKey('tomorrow-preview'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            enter(
              Card(
                color: lowEnergy ? scheme.secondaryContainer : null,
                child: SwitchListTile(
                  secondary: Icon(
                    lowEnergy ? Icons.spa_rounded : Icons.spa_outlined,
                    color: lowEnergy ? scheme.primary : null,
                  ),
                  title: const Text('Low-energy mode'),
                  subtitle: const Text('Shows only what matters today.'),
                  value: lowEnergy,
                  onChanged: settings == null
                      ? null
                      : (on) => ref.read(setLowEnergyProvider)(on),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Set once the first Today build has eased in, so later rebuilds and
/// scrolling never replay the entrance.
bool _entered = false;

/// First open: Tuck says hello, then one way forward.
class EmptyWelcome extends StatelessWidget {
  const EmptyWelcome({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: Column(
        children: [
          const Tuck(size: 120),
          const SizedBox(height: 20),
          Text(
            'Progress Always Comes Eventually',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'I\'m Tuck. Nothing is scheduled yet. Set up your week '
              'whenever you are ready, and we\'ll take it one step at a time.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          PressScale(
            child: FilledButton.icon(
              onPressed: onSetUp,
              icon: const Icon(Icons.arrow_forward_rounded),
              iconAlignment: IconAlignment.end,
              label: const Text('Set up your week'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EveningCard extends StatelessWidget {
  const _EveningCard({
    required this.bedtime,
    required this.onCheckIn,
    required this.onBed,
  });

  final LocalTime bedtime;
  final VoidCallback onCheckIn;
  final VoidCallback onBed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Evening gets the soft dusk lilac.
    final pastel = PacePastels.of(context).evening;
    final fg = scheme.onSurface;
    return Card(
      key: const ValueKey('evening-card'),
      color: pastel.fill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_rounded, size: 20, color: pastel.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Winding down. Bed around ${bedtime.format24()}.',
                    style: theme.textTheme.titleMedium?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PressScale(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: pastel.ink,
                      foregroundColor: pastel.fill,
                    ),
                    onPressed: onCheckIn,
                    child: const Text('Check in'),
                  ),
                ),
                PressScale(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: pastel.ink.withValues(alpha: .4)),
                    ),
                    onPressed: onBed,
                    child: const Text('Going to bed'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small tappable line about something already under way.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressScale(
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(text, style: theme.textTheme.labelLarge),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The hero: what to do right now, with the morning as a cairn that fills
/// one stone per step.
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
    final scheme = theme.colorScheme;
    // Running late gets the warm dawn tone, never red.
    final late = status is RunningLate;
    // The card takes the soft colour of what is happening now.
    final kind = switch (status) {
      RunningLate() => PastelKind.morning,
      StepsRemaining(:final next) => switch (next.step) {
        RoutineStep.wake || RoutineStep.eat => PastelKind.morning,
        RoutineStep.leave => PastelKind.leave,
        RoutineStep.windDown => PastelKind.evening,
      },
      RoutineAllDone() => PastelKind.leave,
      NoClassToday(:final wake) when wake != null && !wake.done =>
        PastelKind.morning,
      _ => PastelKind.calm,
    };
    final pastel = PacePastels.of(context).forKind(kind);
    final bg = pastel.fill;
    final fg = scheme.onSurface;
    final title = theme.textTheme.headlineSmall?.copyWith(color: fg);
    final body = theme.textTheme.bodyLarge?.copyWith(color: fg);

    final (Widget content, List<bool>? stones) = switch (status) {
      NoClassToday(:final wake) => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No class today. The day is yours.', style: body),
            if (wake != null) ...[
              const SizedBox(height: 12),
              _StepPill(
                stepKey: const ValueKey('step-wake'),
                icon: Icons.wb_sunny_outlined,
                label: wake.done
                    ? 'Up ${wake.at.format24()}'
                    : 'I\'m up · ${wake.at.format24()}',
                done: wake.done,
                onTap: () => onStepDone(RoutineStep.wake),
              ),
            ],
          ],
        ),
        null,
      ),
      MorningDoesNotFit() => (
        Text(
          'Today\'s morning does not fit the times in Settings. '
          'Worth a look.',
          style: body,
        ),
        null,
      ),
      RoutineAllDone() => (
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text('Routine done for today.', style: body)),
          ],
        ),
        const [true, true, true],
      ),
      RunningLate(:final title, :final subtitle, :final steps) => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: body),
            const SizedBox(height: 14),
            PressScale(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: pastel.ink,
                  foregroundColor: bg,
                ),
                onPressed: onOutTheDoor,
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('I\'m out the door'),
              ),
            ),
          ],
        ),
        [for (final s in steps) s.done],
      ),
      StepsRemaining(:final steps, :final next) => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next: ${next.label.toLowerCase()} at ${next.at.format24()}',
              style: title,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, s) in steps.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _StepTile(
                      stepKey: ValueKey('step-${s.step.name}'),
                      label: s.label,
                      time: s.at.format24(),
                      done: s.done,
                      isNext: s == next,
                      onTap: () => onStepDone(s.step),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        [for (final s in steps) s.done],
      ),
    };

    final motion = PaceMotion.of(context);
    return AnimatedContainer(
      key: const ValueKey('routine-card'),
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    late ? 'One thing now' : 'Right now',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fg.withValues(alpha: .72),
                    ),
                  ),
                ),
                if (stones != null)
                  CairnProgress(done: stones, width: 30, color: pastel.ink),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: PaceMotion.standard,
              switchInCurve: PaceMotion.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(0, motion.offset(.08)),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_stateKey(status)),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _stateKey(RoutineStatus s) => switch (s) {
    StepsRemaining(:final next) => 'steps-${next.step.name}',
    _ => s.runtimeType.toString(),
  };
}

/// One routine step. Tap to log it; done steps show a check and stay calm.
class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.stepKey,
    required this.icon,
    required this.label,
    required this.done,
    required this.onTap,
  });

  final Key stepKey;
  final IconData icon;
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = done ? scheme.onPrimary : scheme.onSurface;
    final pill = AnimatedContainer(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
      decoration: ShapeDecoration(
        color: done ? scheme.primary : scheme.surfaceContainerLowest,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: PaceMotion.quick,
            child: Icon(
              done ? Icons.check_rounded : icon,
              key: ValueKey(done),
              size: 18,
              color: done ? fg : scheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg)),
        ],
      ),
    );
    if (done) return Semantics(label: '$label, done', child: pill);
    return PressScale(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: stepKey,
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: pill,
        ),
      ),
    );
  }
}

/// One routine step in the hero strip: label over time. Tap to log it.
/// The next step is lifted; done steps fill with a check.
class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.stepKey,
    required this.label,
    required this.time,
    required this.done,
    required this.isNext,
    required this.onTap,
  });

  final Key stepKey;
  final String label;
  final String time;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = done ? scheme.onPrimary : scheme.onSurface;
    final tile = AnimatedContainer(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: done
            ? scheme.primary
            : isNext
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLowest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(PaceRadius.s),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg.withValues(alpha: .75),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: PaceMotion.quick,
            child: done
                ? Icon(Icons.check_rounded, size: 18, color: fg)
                : const SizedBox(width: 18),
          ),
        ],
      ),
    );
    if (done) return Semantics(label: '$label $time, done', child: tile);
    return PressScale(
      child: Semantics(
        button: true,
        label: 'Mark $label done',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: stepKey,
            borderRadius: BorderRadius.circular(PaceRadius.s),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: tile,
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.task,
    required this.now,
    required this.onSubmitted,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        DoneCheck(onDone: onSubmitted),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: ' · ${describeDue(task.dueAt, now)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            style: theme.textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
