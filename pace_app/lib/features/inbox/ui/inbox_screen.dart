import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/tuck.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/undo_snack.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../deadlines/ui/task_edit_sheet.dart';
import '../../shell/shell_tabs.dart';
import '../application/inbox_providers.dart';
import '../../notes/ui/notes_screen.dart' show noteFromInbox;

/// Quick capture and a short queue to sort later: each item becomes a
/// deadline or goes away. Nothing here nags.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.startCapturing = false});

  /// Focus the field right away (opened from the widget or a shortcut).
  final bool startCapturing;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _showAllInLowEnergy = false;

  @override
  void initState() {
    super.initState();
    if (widget.startCapturing) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    await ref.read(inboxCaptureProvider).add(text);
    _focus.requestFocus();
  }

  Future<void> _toDeadline(InboxItem item) async {
    final now = ref.read(clockProvider)();
    final result = await showModalBottomSheet<TaskEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskEditSheet(
        now: now,
        initial: TaskEdit(
          title: item.body,
          subject: null,
          dueAt: TaskEditSheet.defaultDue(now),
        ),
      ),
    );
    if (result == null) return;
    await ref
        .read(deadlineRemindersProvider)
        .add(title: result.title, subject: result.subject, dueAt: result.dueAt);
    await ref.read(inboxCaptureProvider).markProcessed(item.id);
  }

  @override
  Widget build(BuildContext context) {
    // "Write it down" from elsewhere while this tab is already built.
    ref.listen(shellRequestProvider, (_, next) {
      if (next?.capture ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      }
    });
    final items = ref.watch(inboxItemsProvider).value ?? const <InboxItem>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final settings = ref.watch(settingsProvider).value;
    final features = ref.watch(platformFeaturesProvider);
    final capture = ref.read(inboxCaptureProvider);
    final theme = Theme.of(context);
    final hideList = lowEnergy && !_showAllInLowEnergy && items.isNotEmpty;

    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: SafeArea(
        child: ListView(
          padding: PaceSpace.screen,
          children: [
            Card(
              color: PacePastels.of(context).leave.fill,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write it down, sort it later.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('capture-field'),
                      controller: _text,
                      focusNode: _focus,
                      autofocus: widget.startCapturing,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      decoration: InputDecoration(
                        hintText: 'What is on your mind?',
                        fillColor: scheme.surfaceContainerLowest,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6),
                          child: IconButton.filled(
                            tooltip: 'Add',
                            icon: Icon(
                              Icons.arrow_upward_rounded,
                              color: scheme.onPrimary,
                            ),
                            onPressed: _add,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const EmptyState(
                title: 'Inbox is clear.',
                message:
                    'Anything you write above waits here until you '
                    'decide what it is.',
                pose: TuckPose.note,
                mascotSize: 96,
              )
            else if (hideList)
              Card(
                color: scheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.spa_outlined),
                  title: Text(
                    '${items.length} ${items.length == 1 ? 'thing' : 'things'} '
                    'waiting. They can wait.',
                  ),
                  trailing: TextButton(
                    onPressed: () => setState(() => _showAllInLowEnergy = true),
                    child: const Text('Show'),
                  ),
                ),
              )
            else ...[
              SectionHeader(
                '${items.length} waiting',
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
              ),
              for (final (i, item) in items.indexed)
                FadeSlideIn(
                  key: ValueKey('inbox-${item.id}'),
                  index: i,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.body,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Make a deadline',
                            icon: Icon(
                              Icons.event_available_outlined,
                              color: scheme.primary,
                            ),
                            onPressed: () => _toDeadline(item),
                          ),
                          IconButton(
                            tooltip: 'Make a note',
                            icon: Icon(
                              Icons.sticky_note_2_outlined,
                              color: scheme.primary,
                            ),
                            onPressed: () async {
                              await noteFromInbox(ref, item.body);
                              await capture.markProcessed(item.id);
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(
                              Icons.close_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () async {
                              await capture.remove(item.id);
                              if (!context.mounted) return;
                              showUndo(
                                context,
                                message: 'Deleted ${quoted(item.body)}.',
                                onUndo: () => capture.restore(item.id),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            if (settings != null && features.reminders) ...[
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Capture from the notification shade'),
                  subtitle: const Text(
                    'Keeps a quiet notification with a reply field, so a '
                    'thought can be saved without opening PACE.',
                  ),
                  value: settings.captureShortcutEnabled,
                  onChanged: capture.setShortcutEnabled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
