import 'package:flutter/material.dart';

import '../../../core/theme/pace_tokens.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/press_scale.dart';

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

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'New deadline' : 'Edit deadline',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('task-title'),
            controller: _title,
            autofocus: widget.initial == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('task-subject'),
            controller: _subject,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Subject (optional)',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PickerField(
                  icon: Icons.calendar_today_rounded,
                  label: 'Due',
                  value:
                      '${_weekdays[_due.weekday - 1]} ${_due.day} '
                      '${_months[_due.month - 1]}',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerField(
                  icon: Icons.schedule_rounded,
                  label: 'Time',
                  value: LocalTime.of(_due.hour, _due.minute).format24(),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PressScale(
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

/// A filled field that opens a picker: small label over the value.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(PaceRadius.m),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
