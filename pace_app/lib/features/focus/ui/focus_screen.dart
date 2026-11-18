import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../application/focus_providers.dart';
import '../domain/focus_timer.dart';

/// "Just start": ten minutes on one thing. Leaving the screen or turning
/// the phone off is fine; a notification says when the time is up.
///
/// Opened with a task id as the route argument to preselect that task.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  /// Low-energy mode offers only tasks due inside this window.
  static const lowEnergyWindow = Duration(hours: 48);

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  String? _taskId;
  bool _argsRead = false;

  /// What the last session came to, shown until the next start.
  String? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsRead) {
      _argsRead = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) _taskId = arg;
    }
  }

  Future<void> _start() async {
    setState(() => _summary = null);
    await ref.read(focusServiceProvider).start(taskId: _taskId);
  }

  Future<void> _stop() async {
    final outcome = await ref.read(focusServiceProvider).stop();
    if (!mounted || outcome == null) return;
    setState(
      () => _summary = focusSummary(
        outcome.minutes,
        completed: outcome.completed,
      ),
    );
  }

  Future<void> _keepGoing() async {
    await ref.read(focusServiceProvider).keepGoing();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(secondTickProvider);
    final now = ref.watch(clockProvider)();
    final activeAsync = ref.watch(activeFocusProvider);
    final active = activeAsync.value;
    final pending = ref.watch(pendingTasksProvider).value ?? const <Task>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final features = ref.watch(platformFeaturesProvider);
    final theme = Theme.of(context);

    final state = focusStateAt(
      now: now,
      startedAt: active?.startedAt.toLocal(),
      plannedMinutes: active?.durationMinutes ?? focusMinutes,
    );
    final activeTask = active?.taskId == null
        ? null
        : pending.where((t) => t.id == active!.taskId).firstOrNull;

    final choices = lowEnergy
        ? pending
              .where(
                (t) => t.dueAt.toLocal().isBefore(
                  now.add(FocusScreen.lowEnergyWindow),
                ),
              )
              .toList()
        : pending;
    // A preselected task stays selectable even if low-energy would hide it.
    final selected = _taskId == null
        ? null
        : pending.where((t) => t.id == _taskId).firstOrNull;
    if (selected != null && !choices.contains(selected)) {
      choices.insert(0, selected);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Just start')),
      body: SafeArea(
        child: activeAsync.isLoading && active == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: switch (state) {
                  FocusIdle() => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ten minutes. Then you decide.',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You only have to start. Stopping early still counts.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String?>(
                        key: const ValueKey('focus-task'),
                        initialValue: selected?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'On what'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Nothing in particular'),
                          ),
                          for (final t in choices)
                            DropdownMenuItem<String?>(
                              value: t.id,
                              child: Text(
                                t.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _taskId = v),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const ValueKey('focus-start'),
                        onPressed: _start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start 10 minutes'),
                      ),
                      if (_summary != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          _summary!,
                          key: const ValueKey('focus-summary'),
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  FocusRunning(:final remaining) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeTask != null)
                        Text(
                          activeTask.title,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        formatRemaining(remaining),
                        key: const ValueKey('focus-remaining'),
                        style: theme.textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        features.reminders
                            ? 'You can turn the screen off. PACE will tell '
                                  'you when the time is up.'
                            : 'Keep PACE open; the time-up alert is on the '
                                  'Android app only.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: _stop,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                  FocusTimeUp() => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${active?.durationMinutes ?? focusMinutes} minutes done.',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (activeTask != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          activeTask.title,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _keepGoing,
                        child: const Text('Keep going, 10 more'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _stop,
                        child: const Text('Stop here'),
                      ),
                    ],
                  ),
                },
              ),
      ),
    );
  }
}
