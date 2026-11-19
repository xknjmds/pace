import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/local_time.dart';
import '../../../core/widgets/pace_page.dart';
import '../../blocking/application/gate_providers.dart';
import '../application/sleep_check_providers.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// D8 spike: does phone use match the sleep log? Shows both side by side
/// for the last three nights so the owner can judge, and saves nothing.
class SleepCheckScreen extends ConsumerWidget {
  const SleepCheckScreen({super.key});

  static String _hm(DateTime? t) =>
      t == null ? 'not logged' : LocalTime.of(t.hour, t.minute).format24();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(gatePermissionsProvider).value;
    final nights = ref.watch(sleepCheckProvider).value ?? const [];
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return PacePage(
      title: 'Sleep check (test)',
      subtitle: 'Phone use beside your sleep log. Nothing is saved.',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(sleepCheckProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        if (permissions != null && !permissions.usageAccess)
          Card(
            child: ListTile(
              key: const ValueKey('sleep-check-access'),
              title: const Text('Needs usage access'),
              subtitle: const Text(
                'The same permission the app gate uses. PACE only reads when '
                'the screen turned on and off.',
              ),
              trailing: TextButton(
                onPressed: () async {
                  await ref.read(appGateProvider).openUsageAccessSettings();
                  ref.invalidate(gatePermissionsProvider);
                },
                child: const Text('Allow'),
              ),
            ),
          ),
        for (final n in nights)
          Card(
            key: ValueKey('sleep-night-${n.night.day}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdays[n.night.weekday - 1]} ${n.night.day}/'
                    '${n.night.month} night',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Logged: bed ${_hm(n.bedLogged)}, up ${_hm(n.wakeLogged)}',
                  ),
                  Text(
                    n.estimate == null
                        ? 'Phone: no clear quiet stretch'
                        : 'Phone: quiet ${_hm(n.estimate!.start)} to '
                              '${_hm(n.estimate!.end)}'
                              '${n.estimate!.confident ? '' : ' (short)'}',
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'For the test: write down when you really fell asleep and woke up '
          'for three nights, then compare. Record the result in NOTES.md.',
          style: muted,
        ),
      ],
    );
  }
}
