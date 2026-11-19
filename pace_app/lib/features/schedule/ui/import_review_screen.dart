import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/local_time.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/time_button.dart';
import '../../routine/ui/routine_settings_screen.dart'
    show weekdayNames, weekdaySchedulesProvider;
import '../application/schedule_providers.dart';
import '../domain/schedule_parser.dart';
import 'class_block_sheet.dart';
import '../../../core/widgets/pace_page.dart';

/// Everything the photo seemed to say, for the owner to fix, remove or add
/// to. Nothing is saved until "Save schedule" (CLAUDE.md rule 10).
class ImportReviewScreen extends ConsumerStatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.candidates,
    this.scanned = const [],
  });

  final List<CandidateBlock> candidates;

  /// The recognized lines behind [candidates]. Debug builds can copy them
  /// as JSON, to turn a real photo into a parser test fixture.
  final List<OcrLine> scanned;

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewState();
}

class _ImportReviewState extends ConsumerState<ImportReviewScreen> {
  late final List<CandidateBlock> _blocks = [...widget.candidates];

  /// Weekdays whose first-class time the owner chose to replace. Null
  /// until first built, then defaults to days with no time set yet.
  Set<int>? _useFirst;
  bool _saving = false;

  Future<void> _edit(int i) async {
    final b = await showClassBlockSheet(
      context,
      initial: _blocks[i],
      title: 'Check this class',
    );
    if (b != null) setState(() => _blocks[i] = b);
  }

  Future<void> _add() async {
    final b = await showClassBlockSheet(context, title: 'Add a class');
    if (b != null) setState(() => _blocks.add(b));
  }

  Future<void> _save(Set<int> useFirst) async {
    setState(() => _saving = true);
    await ref
        .read(scheduleServiceProvider)
        .confirmImport(_blocks, useAsFirstClass: useFirst);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ref.watch(weekdaySchedulesProvider).value ?? const [];
    final current = {for (final r in rows) r.weekday: r.firstClassMinutes};
    final earliest = earliestStartByWeekday(_blocks);
    // Only days where the photo's earliest class differs from what is set.
    final differs = {
      for (final e in earliest.entries)
        if (current[e.key] != e.value) e.key: e.value,
    };
    _useFirst ??= {
      for (final d in differs.keys)
        if (current[d] == null) d,
    };
    final useFirst = _useFirst!..removeWhere((d) => !differs.containsKey(d));
    final overlaps = overlappingPairs(_blocks);
    final overlapping = {
      for (final (a, b) in overlaps) ...[a, b],
    };
    final incomplete = _blocks.where((b) => !b.complete).length;

    return PacePage(
      title: 'Check your schedule',
      actions: [
        if (kDebugMode && widget.scanned.isNotEmpty)
          IconButton(
            tooltip: 'Copy scan data',
            icon: const Icon(Icons.data_object_rounded),
            onPressed: () => Clipboard.setData(
              ClipboardData(
                text: jsonEncode([
                  for (final l in widget.scanned)
                    {
                      'text': l.text,
                      'left': l.left,
                      'top': l.top,
                      'right': l.right,
                      'bottom': l.bottom,
                    },
                ]),
              ),
            ),
          ),
      ],
      children: [
        Text(
          _blocks.isEmpty
              ? 'Nothing could be read from that photo. Add the classes '
                    'here instead, or try a sharper, straight-on photo.'
              : 'This is what the photo seemed to say. Tap a class to fix '
                    'it. Nothing is saved until you press Save.',
          style: theme.textTheme.bodyMedium,
        ),
        if (incomplete > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$incomplete ${incomplete == 1 ? 'class needs' : 'classes need'} '
              'a day or time. Fill them in or remove them.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        if (overlaps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Some classes overlap. That may be right; worth a look.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        const SectionHeader('Classes'),
        Card(
          child: Column(
            children: [
              for (final (i, b) in _blocks.indexed)
                ListTile(
                  key: ValueKey('candidate-$i'),
                  leading: Icon(
                    b.complete
                        ? (overlapping.contains(i)
                              ? Icons.layers_outlined
                              : Icons.check_circle_outline_rounded)
                        : Icons.edit_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(b.subject.isEmpty ? '(no name)' : b.subject),
                  subtitle: Text(
                    [
                      b.weekday == null ? 'day?' : weekdayNames[b.weekday]!,
                      b.start == null || b.end == null
                          ? 'time?'
                          : formatSpan(b.start!, b.end!),
                      if (b.room != null) 'Room ${b.room}',
                    ].join(' · '),
                  ),
                  onTap: () => _edit(i),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _blocks.removeAt(i)),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: const Text('Add a class'),
                onTap: _add,
              ),
            ],
          ),
        ),
        if (differs.isNotEmpty) ...[
          const SectionHeader('First class of the day'),
          Card(
            child: Column(
              children: [
                for (final e in differs.entries)
                  SwitchListTile(
                    key: ValueKey('use-first-${e.key}'),
                    title: Text(
                      '${weekdayNames[e.key]}: use '
                      '${LocalTime(e.value).format24()}',
                    ),
                    subtitle: Text(
                      current[e.key] == null
                          ? 'No first class set yet. Your wake and leave '
                                'reminders follow this.'
                          : 'Now ${LocalTime(current[e.key]!).format24()}. '
                                'Keep that, or use the photo\'s time.',
                    ),
                    value: useFirst.contains(e.key),
                    onChanged: (on) => setState(
                      () => on ? useFirst.add(e.key) : useFirst.remove(e.key),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('save-import'),
          onPressed: _saving || incomplete > 0 || _blocks.isEmpty
              ? null
              : () => _save(useFirst),
          child: const Text('Save schedule'),
        ),
      ],
    );
  }
}
