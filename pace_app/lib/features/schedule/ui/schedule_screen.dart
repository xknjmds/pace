import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/time_button.dart';
import '../../../core/widgets/undo_snack.dart';
import '../../routine/ui/routine_settings_screen.dart' show weekdayNames;
import '../application/schedule_providers.dart';
import '../application/schedule_reader.dart';
import '../domain/schedule_parser.dart';
import 'class_block_sheet.dart';
import 'import_review_screen.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_tile.dart';

/// The week's classes. Typed in by hand, or read from a photo of the
/// schedule and reviewed before anything is saved.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _showWeek = false;
  bool _reading = false;

  CandidateBlock _asCandidate(ClassBlock b) => CandidateBlock(
    weekday: b.weekday,
    subject: b.subject,
    start: b.startMinutes,
    end: b.endMinutes,
    room: b.room,
  );

  Future<void> _add() async {
    final b = await showClassBlockSheet(context, title: 'Add a class');
    if (b == null) return;
    await ref
        .read(scheduleServiceProvider)
        .add(
          weekday: b.weekday!,
          subject: b.subject,
          start: b.start!,
          end: b.end!,
          room: b.room,
        );
  }

  Future<void> _edit(ClassBlock block) async {
    final b = await showClassBlockSheet(
      context,
      initial: _asCandidate(block),
      title: 'Edit class',
    );
    if (b == null) return;
    await ref
        .read(scheduleServiceProvider)
        .edit(
          block.copyWith(
            weekday: b.weekday,
            subject: b.subject,
            startMinutes: b.start,
            endMinutes: b.end,
            room: Value(b.room),
          ),
        );
  }

  Future<void> _import({required bool camera}) async {
    setState(() => _reading = true);
    ScheduleScan? scan;
    try {
      scan = await ref.read(scheduleReaderProvider).pickAndRead(camera: camera);
    } catch (e) {
      debugPrint('Schedule import failed: $e');
      if (mounted) _showReadError(e);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
    final read = scan;
    if (read == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImportReviewScreen(
          candidates: parseSchedule(read.lines, image: read.image),
          scanned: read.lines,
        ),
      ),
    );
  }

  /// Says which step failed, calmly, with the technical detail one tap
  /// away so it can be reported.
  void _showReadError(Object error) {
    final step = error is ScheduleReadException ? error.step : 'other';
    final cause = error is ScheduleReadException ? error.cause : error;
    final message = switch (step) {
      'pick' => 'The camera or gallery could not open that photo.',
      'read' => 'The text in that photo could not be read.',
      _ => 'That photo could not be read.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message You can add classes by hand.'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Details',
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('What went wrong'),
              content: SelectableText('Step: $step\n\n$cause'),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: 'Step: $step\n$cause'),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(classBlocksProvider).value ?? const <ClassBlock>[];
    final features = ref.watch(platformFeaturesProvider);
    final lowEnergy = ref.watch(lowEnergyProvider);
    final today = ref.watch(clockProvider)().weekday;
    final theme = Theme.of(context);
    // Low-energy mode lists only today, with the week one tap away.
    final days = lowEnergy && !_showWeek ? [today] : weekdayNames.keys.toList();

    return PacePage(
      title: 'Class schedule',
      subtitle: 'Your week of classes.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add a class'),
      ),
      children: [
        if (features.scheduleImport)
          Card(
            color: PacePastels.of(context).leave.fill,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Read a photo of your schedule',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Read on this phone, nothing is uploaded. You check '
                    'every class before it is saved.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_reading)
                    const LinearProgressIndicator()
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _import(camera: true),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Take a photo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _import(camera: false),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('From gallery'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        if (blocks.isEmpty)
          const EmptyState(
            title: 'No classes yet',
            message:
                'Add your classes to see them on Today and on the '
                'home-screen widget.',
          )
        else ...[
          for (final d in days) ...[
            SectionHeader(
              d == today ? '${weekdayNames[d]} (today)' : weekdayNames[d]!,
            ),
            _DayCard(
              blocks: [
                for (final b in blocks)
                  if (b.weekday == d) b,
              ],
              onTap: _edit,
              onDelete: (b) async {
                final service = ref.read(scheduleServiceProvider);
                await service.remove(b.id);
                if (!context.mounted) return;
                showUndo(
                  context,
                  message: 'Removed ${quoted(b.subject)}.',
                  onUndo: () => service.restore(b.id),
                );
              },
            ),
          ],
          if (lowEnergy)
            TextButton(
              onPressed: () => setState(() => _showWeek = !_showWeek),
              child: Text(_showWeek ? 'Only today' : 'Show the whole week'),
            ),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.blocks,
    required this.onTap,
    required this.onDelete,
  });

  final List<ClassBlock> blocks;
  final ValueChanged<ClassBlock> onTap;
  final ValueChanged<ClassBlock> onDelete;

  @override
  Widget build(BuildContext context) {
    return PaceGroup(
      children: [
        if (blocks.isEmpty)
          const PaceTile(
            icon: Icons.free_breakfast_outlined,
            title: 'No classes',
          )
        else
          for (final b in blocks)
            PaceTile(
              key: ValueKey('block-${b.id}'),
              icon: Icons.school_rounded,
              kind: PastelKind.leave,
              title: b.subject,
              subtitle: [
                formatSpan(b.startMinutes, b.endMinutes),
                if (b.room != null) 'Room ${b.room}',
                if (b.source == BlockSource.image) 'from photo',
              ].join(' · '),
              onTap: () => onTap(b),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => onDelete(b),
              ),
            ),
      ],
    );
  }
}
