import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import '../db/settings_provider.dart';
import '../theme/pace_pastels.dart';
import '../theme/pace_tokens.dart';
import 'tuck.dart';

/// Ids of the one-time hints, saved in `settings.seen_hints`.
abstract final class HintIds {
  static const today = 'today';
  static const deadlines = 'deadlines';
  static const inbox = 'inbox';
  static const focus = 'focus';
  static const more = 'more';
}

/// A one-time note from Tuck saying what a place is for. "Got it" closes
/// it for good. Low-energy days leave it out without counting it as seen.
class FirstVisitHint extends ConsumerWidget {
  const FirstVisitHint({super.key, required this.id, required this.text});

  final String id;
  final String text;

  /// Turned off for most of the test suite in `test/flutter_test_config.dart`,
  /// so other tests see screens as a returning owner does.
  @visibleForTesting
  static bool debugEnabled = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final hidden =
        !debugEnabled ||
        settings == null ||
        settings.seenHints.contains(id) ||
        ref.watch(lowEnergyProvider);

    return AnimatedSize(
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      alignment: Alignment.topCenter,
      child: hidden
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HintCard(
                key: ValueKey('hint-$id'),
                text: text,
                onDone: () =>
                    ref.read(appDatabaseProvider).settingsDao.markHintSeen(id),
              ),
            ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({super.key, required this.text, required this.onDone});

  final String text;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastel = PacePastels.of(context).forKind(PastelKind.calm);
    return Material(
      color: pastel.fill,
      borderRadius: PaceRadius.cardAll,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Tuck(size: 48, pose: TuckPose.note),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Text(
                      text,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(onPressed: onDone, child: const Text('Got it')),
          ],
        ),
      ),
    );
  }
}
