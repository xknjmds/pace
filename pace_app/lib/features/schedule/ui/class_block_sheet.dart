import 'package:flutter/material.dart';

import '../../../core/widgets/time_button.dart';
import '../../routine/ui/routine_settings_screen.dart' show weekdayNames;
import '../domain/schedule_parser.dart';

/// Adds or edits one class block. Returns the edited block, or null when
/// dismissed. Works on [CandidateBlock] so imports and saved blocks share it.
class ClassBlockSheet extends StatefulWidget {
  const ClassBlockSheet({super.key, this.initial, this.title = 'Class'});

  final CandidateBlock? initial;
  final String title;

  @override
  State<ClassBlockSheet> createState() => _ClassBlockSheetState();
}

class _ClassBlockSheetState extends State<ClassBlockSheet> {
  late int? _weekday = widget.initial?.weekday ?? DateTime.monday;
  late int? _start = widget.initial?.start;
  late int? _end = widget.initial?.end;
  late final _subject = TextEditingController(text: widget.initial?.subject);
  late final _room = TextEditingController(text: widget.initial?.room);

  @override
  void dispose() {
    _subject.dispose();
    _room.dispose();
    super.dispose();
  }

  CandidateBlock get _block => CandidateBlock(
    weekday: _weekday,
    subject: _subject.text.trim(),
    start: _start,
    end: _end,
    room: _room.text.trim().isEmpty ? null : _room.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = _block;
    final timesWrong = _start != null && _end != null && _end! <= _start!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('block-subject'),
            controller: _subject,
            autofocus: widget.initial == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Subject'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const ValueKey('block-day'),
            initialValue: _weekday,
            decoration: const InputDecoration(labelText: 'Day'),
            items: [
              for (final e in weekdayNames.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (d) => setState(() => _weekday = d),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TimeButton(
                  key: const ValueKey('block-start'),
                  minutes: _start,
                  placeholder: 'Starts',
                  onChanged: (m) => setState(() => _start = m),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to'),
              ),
              Expanded(
                child: TimeButton(
                  key: const ValueKey('block-end'),
                  minutes: _end,
                  placeholder: 'Ends',
                  onChanged: (m) => setState(() => _end = m),
                ),
              ),
            ],
          ),
          if (timesWrong)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'The end needs to be after the start.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _room,
            decoration: const InputDecoration(labelText: 'Room (optional)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: b.complete ? () => Navigator.of(context).pop(b) : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

Future<CandidateBlock?> showClassBlockSheet(
  BuildContext context, {
  CandidateBlock? initial,
  String title = 'Class',
}) => showModalBottomSheet<CandidateBlock>(
  context: context,
  isScrollControlled: true,
  builder: (_) => ClassBlockSheet(initial: initial, title: title),
);
