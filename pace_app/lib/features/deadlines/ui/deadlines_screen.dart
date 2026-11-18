import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/done_check.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/tuck.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/undo_snack.dart';
import '../../../routes.dart';
import '../../shell/home_shell.dart';
import '../../shell/shell_tabs.dart';
import '../application/deadline_providers.dart';
import '../domain/deadline_reminders.dart';
import 'task_edit_sheet.dart';

/// Pending deadlines, past-due ones first, then what has been submitted.
/// Nothing here is red: a past-due task is simply still open.
class DeadlinesScreen extends ConsumerWidget {
  const DeadlinesScreen({super.key});

  /// Low-energy mode shows only what is due within this window.
  static const lowEnergyWindow = Duration(hours: 48);

  Future<void> _addOrEdit(
    BuildContext context,
    WidgetRef ref, {
    Task? task,
  }) async {
    final now = ref.read(clockProvider)();
    final result = await showModalBottomSheet<TaskEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskEditSheet(
        now: now,
        initial: task == null
            ? null
            : TaskEdit(
                title: task.title,
                subject: task.subject,
                dueAt: task.dueAt.toLocal(),
              ),
      ),
    );
    if (result == null) return;
    final service = ref.read(deadlineRemindersProvider);
    if (task == null) {
      await service.add(
        title: result.title,
        subject: result.subject,
        dueAt: result.dueAt,
      );
    } else {
      await service.edit(
        task.copyWith(
          title: result.title,
          subject: Value(result.subject),
          dueAt: result.dueAt,
        ),
      );
    }
  }

  static void _justStart(BuildContext context, Task t) {
    if (!HomeShell.open(context, ShellTab.focus, taskId: t.id)) {
      Navigator.of(context).pushNamed(Routes.focus, arguments: t.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final lowEnergy = ref.watch(lowEnergyProvider);
    final pending = ref.watch(pendingTasksProvider).value ?? const <Task>[];
    final submitted = ref.watch(submittedTasksProvider).value ?? const <Task>[];
    final service = ref.read(deadlineRemindersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final shown = lowEnergy
        ? pending
              .where(
                (t) => t.dueAt.toLocal().isBefore(now.add(lowEnergyWindow)),
              )
              .toList()
        : pending;
    final overdue = shown.where((t) => !t.dueAt.toLocal().isAfter(now));
    final upcoming = shown.where((t) => t.dueAt.toLocal().isAfter(now));

    var i = 0;
    Widget tile(Task t, {required bool pastDue}) => FadeSlideIn(
      key: ValueKey('enter-${t.id}'),
      index: i++,
      child: _TaskTile(
        task: t,
        now: now,
        pastDue: pastDue,
        onTap: () => _addOrEdit(context, ref, task: t),
        onSubmitted: () => service.markSubmitted(t.id),
        onNotToday: () => service.notToday(t.id, now),
        onDelete: () async {
          await service.remove(t.id);
          if (!context.mounted) return;
          showUndo(
            context,
            message: 'Deleted ${quoted(t.title)}.',
            onUndo: () => service.restore(t.id),
          );
        },
        onJustStart: () => _justStart(context, t),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Deadlines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: shown.isEmpty && submitted.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  child: lowEnergy
                      ? const EmptyState(
                          pose: TuckPose.resting,
                          title: 'Nothing due in the next two days.',
                          message: 'Low-energy mode shows only what is close.',
                        )
                      : const EmptyState(
                          title: 'No deadlines yet',
                          message:
                              'Add one when you get it. PACE will nudge you '
                              'gently as it gets close.',
                        ),
                ),
              )
            : ListView(
                padding: PaceSpace.screen,
                children: [
                  if (lowEnergy)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Low-energy mode: only the next two days.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (overdue.isNotEmpty) ...[
                    const SectionHeader('Still open'),
                    for (final t in overdue) tile(t, pastDue: true),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    const SectionHeader('Coming up'),
                    for (final t in upcoming) tile(t, pastDue: false),
                  ],
                  if (submitted.isNotEmpty && !lowEnergy) ...[
                    const SectionHeader('Submitted'),
                    Card(
                      child: Column(
                        children: [
                          for (final (n, t) in submitted.indexed) ...[
                            if (n > 0) const Divider(indent: 56),
                            ListTile(
                              key: ValueKey('done-${t.id}'),
                              leading: Icon(
                                Icons.check_circle_rounded,
                                color: scheme.primary,
                              ),
                              title: Text(
                                t.title,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(describeDue(t.dueAt, now)),
                              trailing: TextButton(
                                onPressed: () => service.markPending(t.id),
                                child: const Text('Reopen'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.now,
    required this.pastDue,
    required this.onTap,
    required this.onSubmitted,
    required this.onNotToday,
    required this.onDelete,
    required this.onJustStart,
  });

  final Task task;
  final DateTime now;
  final bool pastDue;
  final VoidCallback onTap;
  final VoidCallback onSubmitted;
  final VoidCallback onNotToday;
  final VoidCallback onDelete;
  final VoidCallback onJustStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subject = task.subject;
    final due = task.dueAt.toLocal();
    // Due within a day gets a small warm marker; nothing is ever red.
    final soon = !pastDue && due.difference(now) < const Duration(hours: 24);
    final pastels = PacePastels.of(context);
    return Card(
      key: ValueKey('task-${task.id}'),
      // Past due is quieter, not louder: a tinted surface.
      // Due within a day: the warm deadline pastel. Past due: quiet sage.
      color: pastDue
          ? pastels.calm.fill
          : soon
          ? pastels.deadline.fill
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 0, 8),
          child: Row(
            children: [
              DoneCheck(onDone: onSubmitted),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (soon) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: pastels.deadline.ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            [
                              describeDue(task.dueAt, now),
                              if (subject != null && subject.isNotEmpty)
                                subject,
                            ].join(' · '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: soon
                                  ? pastels.deadline.ink
                                  : scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                onSelected: (v) => switch (v) {
                  'just_start' => onJustStart(),
                  'not_today' => onNotToday(),
                  'delete' => onDelete(),
                  _ => null,
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'just_start',
                    child: _MenuRow(Icons.play_arrow_rounded, 'Just start'),
                  ),
                  PopupMenuItem(
                    value: 'not_today',
                    child: _MenuRow(Icons.snooze_rounded, 'Not today'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: _MenuRow(Icons.delete_outline_rounded, 'Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 12),
      Text(label),
    ],
  );
}
