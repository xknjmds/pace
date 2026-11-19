import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/startup_report.dart';
import '../../../core/time/local_time.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pace_section_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tuck.dart';
import '../../../routes.dart';
import '../../deadlines/application/deadline_providers.dart';
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
import '../../habits/application/habit_providers.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../verse/ui/verse_card.dart';
import 'day_timeline_view.dart';
import 'evening_card.dart';
import '../../deadlines/ui/task_check_in.dart';
import 'now_card.dart';
import 'step_check_in.dart';
import 'today_bits.dart';
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
  /// Shows a tab in the home shell, or pushes the screen when Today runs
  /// on its own.
  static void _go(BuildContext context, ShellTab tab, {bool capture = false}) {
    if (!HomeShell.open(context, tab, capture: capture)) {
      Navigator.of(
        context,
      ).pushNamed(capture ? Routes.inboxCapture : tab.route);
    }
  }

  /// The late card's one button: out the door, routine counted as done.
  /// Up is logged as now, a bit later than planned, which is just true.
  Future<void> _outTheDoor(WidgetRef ref, DateTime now) async {
    final routine = ref.read(routineRemindersProvider);
    await routine.checkIn(ReminderKind.wake, now.weekday, CheckInOutcome.later);
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
    final checkIns =
        ref.watch(checkInsProvider(dateKey(now))).value ??
        const <ReminderKind, CheckIn>{};
    final pending = ref.watch(pendingTasksProvider).value ?? const <Task>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final inboxCount = ref.watch(inboxCountProvider);
    final focus = ref.watch(activeFocusProvider).value;
    final startup = ref.watch(startupReportProvider);
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
            skipped: skippedSteps(checkIns),
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
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    final soon = pending
        .where((t) => t.dueAt.toLocal().isBefore(now.add(deadlineWindow)))
        .toList();
    // Today's deadlines live on the timeline; this list is what follows.
    final comingUp = soon.where((t) => !isToday(t.dueAt.toLocal())).toList();
    final dueToday = soon.length - comingUp.length;

    // Classes and calendar events go on the timeline.
    final classBlocks =
        ref.watch(classBlocksProvider).value ?? const <ClassBlock>[];
    final events =
        ref.watch(eventsOnDayProvider(dateKey(now))).value ??
        const <CalendarEvent>[];
    final day = DateTime(now.year, now.month, now.day);
    final blocks = [
      for (final b in classBlocks)
        if (b.weekday == now.weekday)
          TimelineBlock(
            title: b.subject,
            start: day.add(Duration(minutes: b.startMinutes)),
            end: day.add(Duration(minutes: b.endMinutes)),
            room: b.room,
          ),
      for (final e in events)
        if (!e.allDay)
          TimelineBlock(
            title: e.title,
            start: e.startAt.toLocal(),
            end: e.endAt.toLocal(),
            isEvent: true,
          ),
    ];

    // The movement habit, as one pill.
    final habit = ref.watch(movementHabitProvider).value;
    final showHabit = habit != null && habit.active && !lowEnergy;
    final habitDone =
        showHabit &&
        (ref.watch(habitDoneProvider(dateKey(now))).value ?? false);

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
            blocks: blocks,
            now: now,
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

    Future<bool> markSubmitted(Task t) => checkInTask(context, ref, t);

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
          LowEnergyChip(
            on: lowEnergy,
            onChanged: settings == null
                ? null
                : (on) => ref.read(setLowEnergyProvider)(on),
          ),
          const SizedBox(width: 16),
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
                  EveningCard(
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
                  NowCard(
                    status: status,
                    onStepTap: (step) => checkInStep(
                      context,
                      ref,
                      step: step,
                      item: stepItem(status, step),
                      now: now,
                      graceMinutes: settings!.lateThresholdMinutes,
                      checkIn: checkIns[stepKinds[step]],
                      loggedAt: switch (step) {
                        RoutineStep.wake => log?.wakeLoggedAt,
                        RoutineStep.eat => log?.eatDoneAt,
                        _ => null,
                      },
                    ),
                    onOutTheDoor: () => _outTheDoor(ref, now),
                  ),
                ),
              if (showHabit || focusText != null || inboxCount > 0)
                enter(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (showHabit)
                          StatusPill(
                            key: ValueKey(
                              habitDone ? 'habit-undo' : 'habit-done',
                            ),
                            icon: habitDone
                                ? Icons.check_rounded
                                : Icons.directions_walk_rounded,
                            text: habitDone
                                ? '${habit.name}: done'
                                : '${habit.name}: tap when done',
                            onTap: () => ref
                                .read(habitServiceProvider)
                                .setDoneToday(!habitDone),
                          ),
                        if (focusText != null)
                          StatusPill(
                            key: const ValueKey('focus-line'),
                            icon: Icons.timer_outlined,
                            text: focusText,
                            onTap: () => _go(context, ShellTab.focus),
                          ),
                        if (inboxCount > 0)
                          StatusPill(
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
                        const SectionHeader('Your day'),
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
                        ? TodayHint(
                            pending.isEmpty
                                ? 'No open deadlines. Add some, or enjoy the room.'
                                : 'Pick up to three things to move today.',
                          )
                        : Column(
                            children: [
                              for (final t in top3)
                                TodayTaskRow(
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
                  title: 'Coming up',
                  icon: Icons.event_note_rounded,
                  pastel: PastelKind.deadline,
                  action: TextButton(
                    onPressed: () => _go(context, ShellTab.deadlines),
                    child: const Text('All'),
                  ),
                  child: comingUp.isEmpty
                      ? TodayHint(
                          dueToday > 0
                              ? 'Nothing else due in the next two days.'
                              : 'Nothing due in the next two days.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final t in comingUp.take(maxDeadlinesShown))
                              TodayTaskRow(
                                key: ValueKey('soon-${t.id}'),
                                task: t,
                                now: now,
                                onSubmitted: () => markSubmitted(t),
                              ),
                            if (comingUp.length > maxDeadlinesShown)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                                child: Text(
                                  'and ${comingUp.length - maxDeadlinesShown} more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              if (!lowEnergy) enter(VerseCard(day: now)),
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
          ],
        ),
      ),
    );
  }
}

/// Set once the first Today build has eased in, so later rebuilds and
/// scrolling never replay the entrance.
bool _entered = false;
