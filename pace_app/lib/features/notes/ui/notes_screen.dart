import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/notes_providers.dart';
import 'note_editor_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note',
        onPressed: () => _open(null),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: PaceSpace.screen,
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
              title: _query.isEmpty ? 'No notes yet' : 'Nothing matches',
              message: _query.isEmpty
                  ? 'Keep things here that should not get lost.'
                  : null,
            )
          else ...[
            for (final n in shown)
              Card(
                child: ListTile(
                  key: ValueKey('note-${n.id}'),
                  title: Text(
                    n.title.isEmpty ? _firstLine(n.body) : n.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: n.body.isEmpty || n.title.isEmpty
                      ? null
                      : Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => _open(n),
                ),
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
      ),
    );
  }

  static String _firstLine(String body) {
    final line = body.trim().split('\n').first;
    return line.isEmpty ? '(empty note)' : line;
  }
}

/// Turns an inbox item into a note (used by the Inbox).
Future<void> noteFromInbox(WidgetRef ref, String text) =>
    ref.read(appDatabaseProvider).notesDao.add(body: text);
