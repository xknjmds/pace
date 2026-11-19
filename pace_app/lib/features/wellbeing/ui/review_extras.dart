import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../review/application/review_providers.dart';
import '../application/wellbeing_providers.dart';
import '../domain/wellbeing_rules.dart';

/// Review extras from D2: a neutral line about the evenings and, once
/// mornings are steady, a gentle offer of fewer reminders.
class WellbeingReviewSection extends ConsumerWidget {
  const WellbeingReviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(weekLogsProvider).value ?? const <DailyLog>[];
    // Offers wait for a fuller day; low-energy mode keeps Review short.
    final offer =
        !ref.watch(lowEnergyProvider) &&
        (ref.watch(steadyOfferProvider).value ?? false);
    int count(Mood m) => logs.where((l) => l.mood == m).length;
    final line = moodSummary(
      good: count(Mood.good),
      okay: count(Mood.okay),
      drained: count(Mood.drained),
    );
    if (line == null && !offer) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (line != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              line,
              key: const ValueKey('mood-summary'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (offer)
          Card(
            key: const ValueKey('steady-offer'),
            color: PacePastels.of(context).forKind(PastelKind.leave).fill,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your mornings look steady',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Want fewer reminders? Steady mode keeps only wake and '
                    'leave. You can switch back any time in Settings.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const ValueKey('steady-no'),
                        onPressed: () => ref
                            .read(wellbeingServiceProvider)
                            .dismissSteadyOffer(),
                        child: const Text('Not now'),
                      ),
                      TextButton(
                        key: const ValueKey('steady-yes'),
                        onPressed: () => ref
                            .read(wellbeingServiceProvider)
                            .setSteadyMode(true),
                        child: const Text('Fewer reminders'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
