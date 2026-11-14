import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/widgets/cairn_mark.dart';
import '../../../routes.dart';

/// Answers "what do I do right now?". In M1 it only has the empty state and
/// the low-energy toggle; routine, priorities and deadlines arrive in M4–M6.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _menu = <String, String>{
    'Deadlines': Routes.deadlines,
    'Inbox': Routes.inbox,
    'Focus': Routes.focus,
    'Review': Routes.review,
    'Settings': Routes.settings,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (route) => Navigator.of(context).pushNamed(route),
            itemBuilder: (_) => [
              for (final entry in _menu.entries)
                PopupMenuItem(value: entry.value, child: Text(entry.key)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Center(child: CairnMark(size: 96)),
            const SizedBox(height: 24),
            Text(
              'Progress Always Comes Eventually',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing is scheduled yet. Set up your week whenever you are ready.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: SwitchListTile(
                title: const Text('Low-energy mode'),
                subtitle: const Text('Show only what matters today'),
                value: settings.value?.lowEnergyEnabled ?? false,
                onChanged: settings.hasValue
                    ? (on) => ref
                          .read(appDatabaseProvider)
                          .settingsDao
                          .setLowEnergy(on)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
