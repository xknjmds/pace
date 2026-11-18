import 'package:flutter/material.dart';

import '../../../core/time/local_time.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/press_scale.dart';

class EveningCard extends StatelessWidget {
  const EveningCard({
    super.key,
    required this.bedtime,
    required this.onCheckIn,
    required this.onBed,
  });

  final LocalTime bedtime;
  final VoidCallback onCheckIn;
  final VoidCallback onBed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Evening gets the soft dusk lilac.
    final pastel = PacePastels.of(context).evening;
    final fg = scheme.onSurface;
    return Card(
      key: const ValueKey('evening-card'),
      color: pastel.fill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_rounded, size: 20, color: pastel.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Winding down. Bed around ${bedtime.format24()}.',
                    style: theme.textTheme.titleMedium?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PressScale(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: pastel.ink,
                      foregroundColor: pastel.fill,
                    ),
                    onPressed: onCheckIn,
                    child: const Text('Check in'),
                  ),
                ),
                PressScale(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: pastel.ink.withValues(alpha: .4)),
                    ),
                    onPressed: onBed,
                    child: const Text('Going to bed'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
