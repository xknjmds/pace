import 'package:flutter/material.dart';

import '../../../core/time/local_time.dart';

/// What the sheet hands back. Null first class means no class that day.
class WeekdayEdit {
  const WeekdayEdit({
    required this.firstClassMinutes,
    required this.commuteMinutes,
    required this.prepMinutes,
  });

  final int? firstClassMinutes;
  final int commuteMinutes;
  final int prepMinutes;
}

/// Bottom sheet for one weekday: class on or off, its time, commute and
/// getting-ready minutes.
class WeekdayEditSheet extends StatefulWidget {
  const WeekdayEditSheet({super.key, required this.weekdayName, this.initial});

  final String weekdayName;
  final WeekdayEdit? initial;

  /// Used when the owner switches a class on for a day that had none.
  static const defaultFirstClass = 8 * 60;

  @override
  State<WeekdayEditSheet> createState() => _WeekdayEditSheetState();
}

class _WeekdayEditSheetState extends State<WeekdayEditSheet> {
  late bool _hasClass = widget.initial?.firstClassMinutes != null;
  late int _firstClass =
      widget.initial?.firstClassMinutes ?? WeekdayEditSheet.defaultFirstClass;
  late final _commute = TextEditingController(
    text: '${widget.initial?.commuteMinutes ?? 30}',
  );
  late final _prep = TextEditingController(
    text: '${widget.initial?.prepMinutes ?? 30}',
  );

  @override
  void dispose() {
    _commute.dispose();
    _prep.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = LocalTime(_firstClass);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
      helpText: 'First class',
    );
    if (picked != null) {
      setState(() => _firstClass = picked.hour * 60 + picked.minute);
    }
  }

  int? _minutes(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v == null || v < 0 || v > 600) ? null : v;
  }

  void _save() {
    final commute = _minutes(_commute);
    final prep = _minutes(_prep);
    if (commute == null || prep == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minutes need to be a number up to 600.')),
      );
      return;
    }
    Navigator.of(context).pop(
      WeekdayEdit(
        firstClassMinutes: _hasClass ? _firstClass : null,
        commuteMinutes: commute,
        prepMinutes: prep,
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
          Text(widget.weekdayName, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Class this day'),
            value: _hasClass,
            onChanged: (v) => setState(() => _hasClass = v),
          ),
          if (_hasClass)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('First class'),
              trailing: Text(
                LocalTime(_firstClass).format24(),
                style: theme.textTheme.titleMedium,
              ),
              onTap: _pickTime,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('commute-minutes'),
                  controller: _commute,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Commute',
                    suffixText: 'min',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  key: const ValueKey('prep-minutes'),
                  controller: _prep,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Getting ready',
                    suffixText: 'min',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

/// A small dialog for a minutes value. Returns null when dismissed.
Future<int?> showMinutesDialog(
  BuildContext context, {
  required String title,
  required int initial,
}) => showDialog<int>(
  context: context,
  builder: (_) => _MinutesDialog(title: title, initial: initial),
);

class _MinutesDialog extends StatefulWidget {
  const _MinutesDialog({required this.title, required this.initial});

  final String title;
  final int initial;

  @override
  State<_MinutesDialog> createState() => _MinutesDialogState();
}

class _MinutesDialogState extends State<_MinutesDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const ValueKey('minutes-field'),
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(suffixText: 'min'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final v = int.tryParse(_controller.text.trim());
          if (v != null && v >= 0 && v <= 600) Navigator.of(context).pop(v);
        },
        child: const Text('Save'),
      ),
    ],
  );
}
