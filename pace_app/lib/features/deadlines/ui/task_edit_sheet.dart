import 'package:flutter/material.dart';

import '../../../core/time/local_time.dart';

/// What the sheet hands back.
class TaskEdit {
  const TaskEdit({
    required this.title,
    required this.subject,
    required this.dueAt,
  });

  final String title;
  final String? subject;

  /// Local.
  final DateTime dueAt;
}

/// Bottom sheet to add or edit a task: title, subject, due date and time.
class TaskEditSheet extends StatefulWidget {
  const TaskEditSheet({super.key, required this.now, this.initial});

  final DateTime now;
  final TaskEdit? initial;

  /// New tasks default to tomorrow at 23:59, the usual submission cut-off.
  static DateTime defaultDue(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1, 23, 59);

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _subject = TextEditingController(
    text: widget.initial?.subject ?? '',
  );
  late DateTime _due =
      widget.initial?.dueAt ?? TaskEditSheet.defaultDue(widget.now);

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(widget.now.year - 1),
      lastDate: DateTime(widget.now.year + 2),
    );
    if (picked != null) {
      setState(
        () => _due = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _due.hour,
          _due.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _due.hour, minute: _due.minute),
    );
    if (picked != null) {
      setState(
        () => _due = DateTime(
          _due.year,
          _due.month,
          _due.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Give it a name first.')));
      return;
    }
    final subject = _subject.text.trim();
    Navigator.of(context).pop(
      TaskEdit(
        title: title,
        subject: subject.isEmpty ? null : subject,
        dueAt: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'New deadline' : 'Edit deadline',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('task-title'),
            controller: _title,
            autofocus: widget.initial == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('task-subject'),
            controller: _subject,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Subject (optional)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due'),
                  subtitle: Text('${_due.day}/${_due.month}/${_due.year}'),
                  onTap: _pickDate,
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Time'),
                  subtitle: Text(
                    LocalTime.of(_due.hour, _due.minute).format24(),
                  ),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
