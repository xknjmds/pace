import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pastel_icon_chip.dart';
import '../application/verse_providers.dart';

/// Today's verse, quietly. Absent when turned off or in low-energy mode.
class VerseCard extends ConsumerWidget {
  const VerseCard({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(
      verseForDayProvider(DateTime(day.year, day.month, day.day)),
    );
    if (verse == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final pastels = PacePastels.of(context);
    // The verse keeps the evening lilac, the family for quiet moments.
    final pastel = pastels.evening;
    return Card(
      key: const ValueKey('verse-card'),
      color: pastel.fill,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PastelIconChip(
              icon: Icons.menu_book_rounded,
              kind: PastelKind.evening,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verse.text,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.reference,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: pastel.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
