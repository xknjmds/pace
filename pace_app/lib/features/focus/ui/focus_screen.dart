import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/tuck.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../shell/shell_tabs.dart';
import '../application/focus_providers.dart';
import '../domain/focus_timer.dart';
import 'focus_ring.dart';

/// "Just start": ten minutes on one thing. Leaving the screen or turning
/// the phone off is fine; a notification says when the time is up.
///
/// Opened with a task id (route argument, or a shell request from
/// Deadlines' "Just start") to preselect that task.
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
      final request = ref.read(shellRequestProvider);
      if (arg is String) {
        _taskId = arg;
      } else if (request?.tab == ShellTab.focus && request?.taskId != null) {
        _taskId = request!.taskId;
      }
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

    // "Just start" on a deadline while this tab is already built.
    ref.listen(shellRequestProvider, (_, next) {
      if (next?.tab == ShellTab.focus && next?.taskId != null) {
        setState(() => _taskId = next!.taskId);
      }
    });
    final planned = active?.durationMinutes ?? focusMinutes;
    final scheme = theme.colorScheme;
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );

    final Widget body = switch (state) {
      FocusIdle() => Column(
        key: const ValueKey('idle'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: FocusRing(
              progress: 0,
              size: 168,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$focusMinutes',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: scheme.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    'minutes',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Ten minutes. Then you decide.',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You only have to start. Stopping early still counts.',
            style: hint,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          KeyedSubtree(
            // Rebuilt when a task is handed over from Deadlines.
            key: ValueKey('choice-${selected?.id}'),
            child: DropdownButtonFormField<String?>(
              key: const ValueKey('focus-task'),
              initialValue: selected?.id,
              isExpanded: true,
              borderRadius: BorderRadius.circular(PaceRadius.m),
              decoration: const InputDecoration(
                labelText: 'On what',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Nothing in particular'),
                ),
                for (final t in choices)
                  DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _taskId = v),
            ),
          ),
          const SizedBox(height: 16),
          PressScale(
            child: FilledButton.icon(
              key: const ValueKey('focus-start'),
              onPressed: _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start 10 minutes'),
            ),
          ),
          if (_summary != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(PaceRadius.m),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _summary!,
                      key: const ValueKey('focus-summary'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      FocusRunning(:final remaining) => Column(
        key: const ValueKey('running'),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeTask != null) ...[
            Text(
              activeTask.title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
          Center(
            child: FocusRing(
              progress: 1 - remaining.inSeconds / (planned * 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatRemaining(remaining),
                    key: const ValueKey('focus-remaining'),
                    style: theme.textTheme.displayLarge,
                  ),
                  Text(
                    'left',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Tuck(pose: TuckPose.focus, size: 80)),
          const SizedBox(height: 12),
          Text(
            features.reminders
                ? 'You can turn the screen off. PACE will tell '
                      'you when the time is up.'
                : 'Keep PACE open; the time-up alert is on the '
                      'Android app only.',
            style: hint,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          PressScale(
            child: OutlinedButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
            ),
          ),
        ],
      ),
      FocusTimeUp() => Column(
        key: const ValueKey('up'),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: FocusRing(
              progress: 1,
              size: 168,
              child: const Tuck(pose: TuckPose.proud, size: 112),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '$planned minutes done.',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (activeTask != null) ...[
            const SizedBox(height: 4),
            Text(activeTask.title, style: hint, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 28),
          PressScale(
            child: FilledButton(
              onPressed: _keepGoing,
              child: const Text('Keep going, 10 more'),
            ),
          ),
          const SizedBox(height: 10),
          PressScale(
            child: OutlinedButton(
              onPressed: _stop,
              child: const Text('Stop here'),
            ),
          ),
        ],
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Just start')),
      body: SafeArea(
        child: activeAsync.isLoading && active == null
            ? const SizedBox.shrink()
            : LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (box.maxHeight - 32).clamp(0, double.infinity),
                    ),
                    child: AnimatedSwitcher(
                      duration: PaceMotion.emphasized,
                      switchInCurve: PaceMotion.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(
                          scale: Tween(begin: .97, end: 1.0).animate(a),
                          child: child,
                        ),
                      ),
                      child: body,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
