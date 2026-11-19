import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tuck.dart';
import '../../../core/widgets/undo_snack.dart';
import '../../../routes.dart';
import '../application/rewards_providers.dart';

/// Rewards the owner sets for themselves. Days only add up, an unclaimed
/// reward waits forever, and claiming is optional.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(rewardsProvider).value ?? const <RewardView>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final open = all.where((v) => !v.progress.claimed).toList();
    final enjoyed = all.where((v) => v.progress.claimed).toList();
    // Low-energy mode keeps only what is ready to enjoy.
    final shown = lowEnergy
        ? open.where((v) => v.progress.earned).toList()
        : open;
    final hidden = open.length - shown.length;
    final theme = Theme.of(context);

    return PacePage(
      title: 'Rewards',
      subtitle: 'Treats you set for yourself.',
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-reward'),
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New reward'),
      ),
      children: [
        if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Pick something small you\'d enjoy, like "5 days done: milk '
              'tea". Every day something gets done counts toward it.',
              key: const ValueKey('rewards-empty'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final v in shown) _RewardCard(view: v),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              '$hidden more on the way.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (enjoyed.isNotEmpty && !lowEnergy) ...[
          const SectionHeader('Enjoyed'),
          for (final v in enjoyed) _RewardCard(view: v),
        ],
      ],
    );
  }
}

class _RewardCard extends ConsumerWidget {
  const _RewardCard({required this.view});

  final RewardView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = view.reward;
    final p = view.progress;
    final dao = ref.read(appDatabaseProvider).rewardsDao;
    final pastel = PacePastels.of(
      context,
    ).forKind(p.earned && !p.claimed ? PastelKind.leave : PastelKind.calm);
    return Card(
      key: ValueKey('reward-${r.id}'),
      color: p.earned && !p.claimed ? pastel.fill : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (p.earned && !p.claimed) ...[
                  const Tuck(pose: TuckPose.proud, size: 44),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(r.title, style: theme.textTheme.titleMedium),
                ),
                PopupMenuButton<String>(
                  key: ValueKey('reward-menu-${r.id}'),
                  onSelected: (choice) async {
                    switch (choice) {
                      case 'edit':
                        await _edit(context, ref, existing: view);
                      case 'remove':
                        await dao.remove(r.id);
                        if (context.mounted) {
                          showUndo(
                            context,
                            message: 'Removed ${quoted(r.title)}',
                            onUndo: () => ref
                                .read(appDatabaseProvider)
                                .rewardsDao
                                .add(title: r.title, daysNeeded: r.daysNeeded),
                          );
                        }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (p.claimed)
              Text('Enjoyed.', style: theme.textTheme.bodyMedium)
            else if (p.earned)
              Text(
                'Earned. Enjoy it whenever you like.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Text(
                '${p.daysDone} of ${p.daysNeeded} days done',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PaceRadius.s),
                  child: LinearProgressIndicator(
                    value: p.fraction,
                    minHeight: 6,
                    color: PacePastels.of(
                      context,
                    ).forKind(PastelKind.leave).ink,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),
            ],
            if (p.earned)
              Wrap(
                spacing: 4,
                children: [
                  if (!p.claimed)
                    TextButton(
                      key: ValueKey('claim-${r.id}'),
                      onPressed: () =>
                          dao.setClaimed(r.id, ref.read(clockProvider)()),
                      child: const Text('I enjoyed it'),
                    )
                  else
                    TextButton(
                      onPressed: () => dao.setClaimed(r.id, null),
                      child: const Text('Not yet'),
                    ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.money),
                    child: const Text('Log the cost'),
                  ),
                ],
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

const _dayChoices = [3, 5, 7, 10, 14, 30];

Future<void> _edit(
  BuildContext context,
  WidgetRef ref, {
  RewardView? existing,
}) async {
  final result = await showModalBottomSheet<(String, int)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RewardSheet(
      title: existing?.reward.title ?? '',
      days: existing?.reward.daysNeeded ?? 5,
    ),
  );
  if (result == null) return;
  final dao = ref.read(appDatabaseProvider).rewardsDao;
  if (existing == null) {
    await dao.add(title: result.$1, daysNeeded: result.$2);
  } else {
    await dao.edit(existing.reward.id, title: result.$1, daysNeeded: result.$2);
  }
}

class _RewardSheet extends StatefulWidget {
  const _RewardSheet({required this.title, required this.days});

  final String title;
  final int days;

  @override
  State<_RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends State<_RewardSheet> {
  late final _title = TextEditingController(text: widget.title);
  late int _days = widget.days;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final t = _title.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop((t, _days));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choices = {..._dayChoices, _days}.toList()..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title.isEmpty ? 'New reward' : 'Edit reward',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('reward-title'),
            controller: _title,
            autofocus: widget.title.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Your reward',
              hintText: 'Milk tea, a movie night, new stickers',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Text('After how many days done?', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in choices)
                ChoiceChip(
                  key: ValueKey('reward-days-$d'),
                  label: Text('$d'),
                  selected: d == _days,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ListenableBuilder(
              listenable: _title,
              builder: (context, _) => FilledButton(
                key: const ValueKey('reward-save'),
                onPressed: _title.text.trim().isEmpty ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
