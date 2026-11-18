import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../application/habit_providers.dart';
import '../application/habit_service.dart';
import '../domain/habit_planner.dart';

/// Turns the movement habit on or off and sets when its reminder comes.
class HabitSheet extends ConsumerStatefulWidget {
  const HabitSheet({super.key, required this.habit});

  final Habit habit;

  @override
  ConsumerState<HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends ConsumerState<HabitSheet> {
  late bool _active = widget.habit.active;
  late HabitAnchor _anchor = widget.habit.anchor;
  late double _offset = widget.habit.offsetMinutes.toDouble();
  late final _name = TextEditingController(text: widget.habit.name);

  static const _labels = {
    HabitAnchor.wake: 'Waking',
    HabitAnchor.eat: 'Breakfast',
    HabitAnchor.leave: 'Leaving',
    HabitAnchor.windDown: 'Wind-down',
  };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text('Movement', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'One small habit with one reminder. Done days are counted; '
            'missed ones are not.',
            style: theme.textTheme.bodyMedium,
          ),
          SwitchListTile(
            key: const ValueKey('habit-active'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind me'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'What'),
          ),
          const SizedBox(height: 16),
          Text('Tied to', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final a in HabitAnchor.values)
                ChoiceChip(
                  label: Text(_labels[a]!),
                  selected: _anchor == a,
                  onSelected: (_) => setState(() => _anchor = a),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            describeHabitTime(HabitService.pointFor(_anchor), _offset.round()),
            style: theme.textTheme.bodyLarge,
          ),
          Slider(
            min: -60,
            max: 120,
            divisions: 36,
            value: _offset,
            label: '${_offset.round()} min',
            onChanged: (v) => setState(() => _offset = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final name = _name.text.trim();
              await ref
                  .read(habitServiceProvider)
                  .update(
                    widget.habit.copyWith(
                      name: name.isEmpty ? widget.habit.name : name,
                      active: _active,
                      anchor: _anchor,
                      offsetMinutes: _offset.round(),
                    ),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

Future<void> showHabitSheet(BuildContext context, WidgetRef ref) async {
  final habit = await ref.read(appDatabaseProvider).habitsDao.ensureMovement();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => HabitSheet(habit: habit),
  );
}
