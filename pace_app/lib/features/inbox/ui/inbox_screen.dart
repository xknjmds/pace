import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../deadlines/ui/task_edit_sheet.dart';
import '../application/inbox_providers.dart';

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
    final items = ref.watch(inboxItemsProvider).value ?? const <InboxItem>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final settings = ref.watch(settingsProvider).value;
    final features = ref.watch(platformFeaturesProvider);
    final capture = ref.read(inboxCaptureProvider);
    final theme = Theme.of(context);
    final hideList = lowEnergy && !_showAllInLowEnergy && items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
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
                suffixIcon: IconButton(
                  tooltip: 'Add',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _add,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Inbox is clear.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            else if (hideList)
              Card(
                child: ListTile(
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
            else
              for (final item in items)
                Card(
                  key: ValueKey('inbox-${item.id}'),
                  child: ListTile(
                    title: Text(item.body),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          tooltip: 'Make a deadline',
                          icon: const Icon(Icons.event_outlined),
                          onPressed: () => _toDeadline(item),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.close),
                          onPressed: () => capture.remove(item.id),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            if (settings != null && features.reminders)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Capture from the notification shade'),
                subtitle: const Text(
                  'Keeps a quiet notification with a reply field, so a '
                  'thought can be saved without opening PACE.',
                ),
                value: settings.captureShortcutEnabled,
                onChanged: capture.setShortcutEnabled,
              ),
          ],
        ),
      ),
    );
  }
}
