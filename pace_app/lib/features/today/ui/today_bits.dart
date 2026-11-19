import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/done_check.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/tuck.dart';
import '../../deadlines/domain/deadline_reminders.dart';

/// First open: Tuck says hello, then one way forward.
class EmptyWelcome extends StatelessWidget {
  const EmptyWelcome({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: Column(
        children: [
          const Tuck(size: 120),
          const SizedBox(height: 20),
          Text(
            'Progress Always Comes Eventually',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'I\'m Tuck. Nothing is scheduled yet. Set up your week '
              'whenever you are ready, and we\'ll take it one step at a time.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          PressScale(
            child: FilledButton.icon(
              onPressed: onSetUp,
              icon: const Icon(Icons.arrow_forward_rounded),
              iconAlignment: IconAlignment.end,
              label: const Text('Set up your week'),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayHint extends StatelessWidget {
  const TodayHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A small tappable line about something already under way.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressScale(
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: scheme.secondary),
                const SizedBox(width: 8),
                Text(text, style: theme.textTheme.labelLarge),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodayTaskRow extends StatelessWidget {
  const TodayTaskRow({
    super.key,
    required this.task,
    required this.now,
    required this.onSubmitted,
  });

  final Task task;
  final DateTime now;

  /// Opens the check-in; false when nothing changed.
  final Future<bool> Function() onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        DoneCheck(onDone: onSubmitted),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: ' · ${describeDue(task.dueAt, now)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            style: theme.textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Low-energy mode as a one-tap chip in Today's header. The icon and the
/// filled shape change with the state, so it is never colour alone.
class LowEnergyChip extends StatelessWidget {
  const LowEnergyChip({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = on ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    // On narrow phones the label would crowd out the greeting: icon only,
    // with the same name for screen readers and a tooltip.
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Semantics(
      toggled: on,
      button: true,
      label: 'Low-energy mode',
      excludeSemantics: true,
      child: Tooltip(
        message: on ? 'Low-energy mode is on' : 'Low-energy mode',
        child: PressScale(
          enabled: onChanged != null,
          child: Material(
            key: const ValueKey('low-energy-chip'),
            color: on ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onChanged == null ? null : () => onChanged!(!on),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        on ? Icons.spa_rounded : Icons.spa_outlined,
                        size: 18,
                        color: on ? scheme.secondary : fg,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Low energy',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: fg,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
