import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/clock.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final lowEnergy = ref.watch(lowEnergyProvider);
    final pending = ref.watch(pendingTasksProvider).value ?? const <Task>[];
    final submitted = ref.watch(submittedTasksProvider).value ?? const <Task>[];
    final service = ref.read(deadlineRemindersProvider);
    final theme = Theme.of(context);

    final shown = lowEnergy
        ? pending
              .where(
                (t) => t.dueAt.toLocal().isBefore(now.add(lowEnergyWindow)),
              )
              .toList()
        : pending;
    final overdue = shown.where((t) => !t.dueAt.toLocal().isAfter(now));
    final upcoming = shown.where((t) => t.dueAt.toLocal().isAfter(now));

    return Scaffold(
      appBar: AppBar(title: const Text('Deadlines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: shown.isEmpty && submitted.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    lowEnergy
                        ? 'Nothing due in the next two days.'
                        : 'No deadlines yet. Add one when you get it.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (lowEnergy)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Low-energy mode: only the next two days.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (overdue.isNotEmpty) ...[
                    _Label('Still open'),
                    for (final t in overdue)
                      _TaskTile(
                        task: t,
                        now: now,
                        pastDue: true,
                        onTap: () => _addOrEdit(context, ref, task: t),
                        onSubmitted: () => service.markSubmitted(t.id),
                        onNotToday: () => service.notToday(t.id, now),
                        onDelete: () => service.remove(t.id),
                      ),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    _Label('Coming up'),
                    for (final t in upcoming)
                      _TaskTile(
                        task: t,
                        now: now,
                        pastDue: false,
                        onTap: () => _addOrEdit(context, ref, task: t),
                        onSubmitted: () => service.markSubmitted(t.id),
                        onNotToday: () => service.notToday(t.id, now),
                        onDelete: () => service.remove(t.id),
                      ),
                  ],
                  if (submitted.isNotEmpty && !lowEnergy) ...[
                    _Label('Submitted'),
                    for (final t in submitted)
                      ListTile(
                        leading: Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          t.title,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
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
  });

  final Task task;
  final DateTime now;
  final bool pastDue;
  final VoidCallback onTap;
  final VoidCallback onSubmitted;
  final VoidCallback onNotToday;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = task.subject;
    return Card(
      key: ValueKey('task-${task.id}'),
      // Past due is quieter, not louder: a tinted surface and an outline.
      color: pastDue ? theme.colorScheme.surfaceContainerHigh : null,
      child: ListTile(
        onTap: onTap,
        leading: IconButton(
          tooltip: 'Submitted',
          icon: const Icon(Icons.radio_button_unchecked),
          onPressed: onSubmitted,
        ),
        title: Text(task.title),
        subtitle: Text(
          [
            describeDue(task.dueAt, now),
            if (subject != null && subject.isNotEmpty) subject,
          ].join(' · '),
          style: pastDue ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (v) => switch (v) {
            'not_today' => onNotToday(),
            'delete' => onDelete(),
            _ => null,
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'not_today', child: Text('Not today')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
