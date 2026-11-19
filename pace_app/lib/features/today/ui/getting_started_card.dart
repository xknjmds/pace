import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_section_card.dart';
import '../../onboarding/application/getting_started_providers.dart';
import '../../onboarding/domain/getting_started.dart';

/// A short list of first things to try, for the first weeks after setup.
/// Each one ticks itself from real data; done rows stay, softly checked.
class GettingStartedCard extends ConsumerWidget {
  const GettingStartedCard({super.key, required this.onOpen});

  /// Opens the place where a step is done.
  final void Function(GettingStartedStepId step) onOpen;

  static const _copy = {
    GettingStartedStepId.classes: (
      Icons.school_rounded,
      'Add your classes',
      'From a photo, or by hand',
    ),
    GettingStartedStepId.deadline: (
      Icons.event_note_rounded,
      'Add your first deadline',
      'Homework, projects, forms',
    ),
    GettingStartedStepId.inbox: (
      Icons.inbox_rounded,
      'Write a thought in Inbox',
      'Anything on your mind',
    ),
    GettingStartedStepId.focus: (
      Icons.timer_rounded,
      'Try a short Focus',
      'Ten minutes on one thing',
    ),
    GettingStartedStepId.reminders: (
      Icons.notifications_none_rounded,
      'Check reminders work',
      'So nudges arrive on time',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = ref.watch(gettingStartedStepsProvider);
    final done = steps.where((s) => s.done).length;

    return PaceSectionCard(
      key: const ValueKey('getting-started'),
      title: 'Getting started',
      icon: Icons.flag_rounded,
      pastel: PastelKind.calm,
      action: TextButton(
        key: const ValueKey('getting-started-hide'),
        onPressed: () => ref
            .read(appDatabaseProvider)
            .settingsDao
            .setGettingStartedClosed(true),
        child: const Text('Hide'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$done of ${steps.length} tried. Take them in any order.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          for (final step in steps)
            _StepRow(
              key: ValueKey('getting-started-${step.id.name}'),
              copy: _copy[step.id]!,
              done: step.done,
              onTap: () => onOpen(step.id),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.copy,
    required this.done,
    required this.onTap,
  });

  final (IconData, String, String) copy;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, subtitle) = copy;
    return MergeSemantics(
      child: ListTile(
        contentPadding: const EdgeInsets.only(right: 4),
        minLeadingWidth: 0,
        leading: Icon(
          done ? Icons.check_circle_rounded : icon,
          color: done ? scheme.secondary : scheme.onSurfaceVariant,
          semanticLabel: done ? 'Done' : null,
        ),
        title: Text(
          title,
          style: done
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyLarge,
        ),
        subtitle: done ? null : Text(subtitle),
        trailing: done ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
