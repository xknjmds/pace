import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/notes_providers.dart';
import 'note_editor_screen.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/tuck.dart';

/// Notes: things worth keeping, separate from the quick-capture inbox.
/// Search covers titles and bodies.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  /// Low-energy mode shows only this many, with the rest one tap away.
  static const lowEnergyCount = 5;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  bool _showAll = false;

  void _open(Note? note) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => NoteEditorScreen(note: note)));

  @override
  Widget build(BuildContext context) {
    final notes =
        ref.watch(notesSearchProvider(_query)).value ?? const <Note>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final limited = lowEnergy && !_showAll && _query.isEmpty;
    final shown = limited ? notes.take(NotesScreen.lowEnergyCount) : notes;
    final theme = Theme.of(context);
    return PacePage(
      title: 'Notes',
      subtitle: 'Things that should not get lost.',
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note',
        onPressed: () => _open(null),
        child: const Icon(Icons.add_rounded),
      ),
      children: [
        TextField(
          key: const ValueKey('notes-search'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search notes',
          ),
          onChanged: (q) => setState(() => _query = q),
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          EmptyState(
            pose: TuckPose.note,
            title: _query.isEmpty ? 'No notes yet' : 'Nothing matches',
            message: _query.isEmpty
                ? 'Keep things here that should not get lost.'
                : null,
          )
        else ...[
          for (final n in shown)
            _NoteCard(
              key: ValueKey('note-${n.id}'),
              title: n.title.isEmpty ? _firstLine(n.body) : n.title,
              preview: n.body.isEmpty || n.title.isEmpty ? null : n.body,
              onTap: () => _open(n),
            ),
          if (limited && notes.length > NotesScreen.lowEnergyCount)
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(
                'Show all ${notes.length}',
                style: theme.textTheme.labelLarge,
              ),
            ),
        ],
      ],
    );
  }

  static String _firstLine(String body) {
    final line = body.trim().split('\n').first;
    return line.isEmpty ? '(empty note)' : line;
  }
}

/// One note as a soft sand card: its title and the start of its text.
/// The whole note is one tap away, so the preview may stop short.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    super.key,
    required this.title,
    required this.preview,
    required this.onTap,
  });

  final String title;
  final String? preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastel = PacePastels.of(context).deadline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: PressScale(
        child: Material(
          color: pastel.fill,
          borderRadius: PaceRadius.cardAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Turns an inbox item into a note (used by the Inbox).
Future<void> noteFromInbox(WidgetRef ref, String text) =>
    ref.read(appDatabaseProvider).notesDao.add(body: text);
