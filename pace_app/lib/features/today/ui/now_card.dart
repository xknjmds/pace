import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/cairn_progress.dart';
import '../../../core/widgets/press_scale.dart';
import '../../routine/domain/routine_reminder_planner.dart';
import '../domain/today_model.dart';

/// The hero: what to do right now, with the morning as a cairn that fills
/// one stone per step.
class NowCard extends StatelessWidget {
  const NowCard({
    super.key,
    required this.status,
    required this.onStepDone,
    required this.onOutTheDoor,
  });

  final RoutineStatus status;
  final void Function(RoutineStep step) onStepDone;
  final VoidCallback onOutTheDoor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Running late gets the warm dawn tone, never red.
    final late = status is RunningLate;
    // The card takes the soft colour of what is happening now.
    final kind = switch (status) {
      RunningLate() => PastelKind.morning,
      StepsRemaining(:final next) => switch (next.step) {
        RoutineStep.wake || RoutineStep.eat => PastelKind.morning,
        RoutineStep.leave => PastelKind.leave,
        RoutineStep.windDown => PastelKind.evening,
      },
      RoutineAllDone() => PastelKind.leave,
      NoClassToday(:final wake) when wake != null && !wake.done =>
        PastelKind.morning,
      _ => PastelKind.calm,
    };
    final pastel = PacePastels.of(context).forKind(kind);
    final bg = pastel.fill;
    final fg = scheme.onSurface;
    final title = theme.textTheme.headlineSmall?.copyWith(color: fg);
    final body = theme.textTheme.bodyLarge?.copyWith(color: fg);

    final (Widget content, List<bool>? stones) = switch (status) {
      NoClassToday(:final wake) => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No class today. The day is yours.', style: body),
            if (wake != null) ...[
              const SizedBox(height: 12),
              _StepPill(
                stepKey: const ValueKey('step-wake'),
                icon: Icons.wb_sunny_outlined,
                label: wake.done
                    ? 'Up ${wake.at.format24()}'
                    : 'I\'m up · ${wake.at.format24()}',
                done: wake.done,
                onTap: () => onStepDone(RoutineStep.wake),
              ),
            ],
          ],
        ),
        null,
      ),
      MorningDoesNotFit() => (
        Text(
          'Today\'s morning does not fit the times in Settings. '
          'Worth a look.',
          style: body,
        ),
        null,
      ),
      RoutineAllDone() => (
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: scheme.secondary),
            const SizedBox(width: 12),
            Expanded(child: Text('Routine done for today.', style: body)),
          ],
        ),
        const [true, true, true],
      ),
      RunningLate(:final title, :final subtitle, :final steps) => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: body),
            const SizedBox(height: 14),
            PressScale(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: pastel.ink,
                  foregroundColor: bg,
                ),
                onPressed: onOutTheDoor,
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('I\'m out the door'),
              ),
            ),
          ],
        ),
        [for (final s in steps) s.done],
      ),
      StepsRemaining(:final steps, :final next) => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next: ${next.label.toLowerCase()} at ${next.at.format24()}',
              style: title,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, s) in steps.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _StepTile(
                      stepKey: ValueKey('step-${s.step.name}'),
                      label: s.label,
                      time: s.at.format24(),
                      done: s.done,
                      isNext: s == next,
                      onTap: () => onStepDone(s.step),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        [for (final s in steps) s.done],
      ),
    };

    final motion = PaceMotion.of(context);
    return AnimatedContainer(
      key: const ValueKey('routine-card'),
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    late ? 'One thing now' : 'Right now',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fg.withValues(alpha: .72),
                    ),
                  ),
                ),
                if (stones != null)
                  CairnProgress(done: stones, width: 30, color: pastel.ink),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: PaceMotion.standard,
              switchInCurve: PaceMotion.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(0, motion.offset(.08)),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_stateKey(status)),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _stateKey(RoutineStatus s) => switch (s) {
    StepsRemaining(:final next) => 'steps-${next.step.name}',
    _ => s.runtimeType.toString(),
  };
}

/// One routine step. Tap to log it; done steps show a check and stay calm.
class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.stepKey,
    required this.icon,
    required this.label,
    required this.done,
    required this.onTap,
  });

  final Key stepKey;
  final IconData icon;
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = done ? scheme.onSecondary : scheme.onSurface;
    final pill = AnimatedContainer(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
      decoration: ShapeDecoration(
        color: done ? scheme.secondary : scheme.surfaceContainerLowest,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: PaceMotion.quick,
            child: Icon(
              done ? Icons.check_rounded : icon,
              key: ValueKey(done),
              size: 18,
              color: done ? fg : scheme.secondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg)),
        ],
      ),
    );
    if (done) return Semantics(label: '$label, done', child: pill);
    return PressScale(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: stepKey,
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: pill,
        ),
      ),
    );
  }
}

/// One routine step in the hero strip: label over time. Tap to log it.
/// The next step is lifted; done steps fill with a check.
class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.stepKey,
    required this.label,
    required this.time,
    required this.done,
    required this.isNext,
    required this.onTap,
  });

  final Key stepKey;
  final String label;
  final String time;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = done ? scheme.onSecondary : scheme.onSurface;
    final tile = AnimatedContainer(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: done
            ? scheme.secondary
            : isNext
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLowest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(PaceRadius.s),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg.withValues(alpha: .75),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: PaceMotion.quick,
            child: done
                ? Icon(Icons.check_rounded, size: 18, color: fg)
                : const SizedBox(width: 18),
          ),
        ],
      ),
    );
    if (done) return Semantics(label: '$label $time, done', child: tile);
    return PressScale(
      child: Semantics(
        button: true,
        label: 'Mark $label done',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: stepKey,
            borderRadius: BorderRadius.circular(PaceRadius.s),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: tile,
          ),
        ),
      ),
    );
  }
}
