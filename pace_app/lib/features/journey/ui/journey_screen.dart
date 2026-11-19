import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tuck.dart';
import '../../../routes.dart';
import '../application/journey_providers.dart';
import '../domain/journey.dart';

/// Tuck's journey: one step for every day something got done. Only ever
/// forward. Low-energy mode shows just where Tuck is.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(journeyProvider).value;
    final lowEnergy = ref.watch(lowEnergyProvider);
    return PacePage(
      title: 'Tuck\'s journey',
      subtitle: 'One step for every day something got done.',
      children: [
        if (journey != null) ...[
          _Where(journey: journey),
          if (!lowEnergy) ...[
            const SectionHeader('The way'),
            _Stops(journey: journey),
            const SectionHeader('Firsts'),
            _Firsts(journey: journey),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                key: const ValueKey('open-rewards'),
                leading: const Icon(Icons.redeem_rounded),
                title: const Text('Your rewards'),
                subtitle: const Text('Treats you set for yourself'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pushNamed(Routes.rewards),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _Where extends StatelessWidget {
  const _Where({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastel = PacePastels.of(context).forKind(PastelKind.leave);
    final j = journey;
    final days = j.daysDone;
    return Card(
      key: const ValueKey('journey-where'),
      color: pastel.fill,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tuck(
                  pose: days == 0 ? TuckPose.idle : TuckPose.leaving,
                  size: 72,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        days == 0
                            ? 'Ready to set off'
                            : '$days ${days == 1 ? 'day' : 'days'} along',
                        key: const ValueKey('journey-days'),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        j.reached == null
                            ? 'The first day done is the first step.'
                            : 'At ${j.reached!.name}.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              label:
                  '${j.daysToNext} more ${j.daysToNext == 1 ? 'day' : 'days'} '
                  'to ${j.next.name}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PaceRadius.s),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: j.stretchProgress),
                  duration: PaceMotion.of(context).reduced
                      ? Duration.zero
                      : PaceMotion.emphasized,
                  curve: PaceMotion.easeOut,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    color: pastel.ink,
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: .6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next: ${j.next.name}, '
              '${j.daysToNext} more ${j.daysToNext == 1 ? 'day' : 'days'} '
              'done.',
              key: const ValueKey('journey-next'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stops extends StatelessWidget {
  const _Stops({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = journey.daysDone;
    // The stops reached, the next one, and one more to look forward to.
    final shown = <JourneyStop>[
      for (final s in journeyStops)
        if (s.day <= journey.next.day) s,
    ];
    final after = journeyStops.where((s) => s.day > journey.next.day);
    if (after.isNotEmpty) shown.add(after.first);
    if (journey.next.day > journeyStops.last.day) shown.add(journey.next);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final s in shown)
              ListTile(
                key: ValueKey('stop-${s.day}'),
                dense: true,
                leading: Icon(
                  s.day <= done
                      ? Icons.check_circle_rounded
                      : s == journey.next
                      ? Icons.adjust_rounded
                      : Icons.circle_outlined,
                  color: s.day <= done ? scheme.secondary : scheme.outline,
                ),
                title: Text(
                  s.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: s.day <= done || s == journey.next
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  'day ${s.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Firsts extends StatelessWidget {
  const _Firsts({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = [
      for (final m in Milestone.values)
        if (journey.milestones.contains(m)) m,
    ];
    final ahead = Milestone.values.where(
      (m) => !journey.milestones.contains(m),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reached.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'Your firsts will gather here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in reached)
                Chip(
                  key: ValueKey('first-${m.name}'),
                  avatar: const Icon(Icons.star_rounded, size: 18),
                  label: Text(m.label),
                ),
            ],
          ),
        if (ahead.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Text(
              'Somewhere ahead: ${ahead.first.label.toLowerCase()}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
