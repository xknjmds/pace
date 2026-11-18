import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../deadlines/domain/deadline_reminders.dart';

/// Pick up to three pending tasks to focus on today.
class Top3PickerSheet extends StatefulWidget {
  const Top3PickerSheet({
    super.key,
    required this.tasks,
    required this.selected,
    required this.now,
  });

  final List<Task> tasks;
  final List<String> selected;
  final DateTime now;

  @override
  State<Top3PickerSheet> createState() => _Top3PickerSheetState();
}

class _Top3PickerSheetState extends State<Top3PickerSheet> {
  late final List<String> _picked = [...widget.selected];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Top 3 for today',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No open deadlines to choose from.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in widget.tasks)
                      CheckboxListTile(
                        key: ValueKey('pick-${t.id}'),
                        value: _picked.contains(t.id),
                        title: Text(t.title),
                        subtitle: Text(describeDue(t.dueAt, widget.now)),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            if (_picked.length < 3) _picked.add(t.id);
                          } else {
                            _picked.remove(t.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_picked),
                child: Text(
                  _picked.length == 3 ? 'Save' : 'Save (${_picked.length}/3)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
