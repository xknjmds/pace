import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/section_header.dart';
import '../application/app_gate.dart';
import '../application/gate_providers.dart';
import '../../../core/widgets/pace_page.dart';

/// The app gate: chosen apps wait during the morning (until the routine is
/// done) and the wind-down window. The master switch, and the emergency
/// unlock on this screen and on every block screen, always work
/// (CLAUDE.md rule 11).
class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key});

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from system settings: the permissions may have changed.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(gatePermissionsProvider);
      ref.invalidate(unlockedUntilProvider);
    }
  }

  Future<void> _chooseApps(List<BlockedApp> blocked) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _AppPicker(blocked: {for (final b in blocked) b.packageName}),
    );
  }

  Future<void> _unlockMinutes(Setting s) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Emergency unlock lasts'),
        children: [
          for (final m in const [5, 10, 15, 30])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(m),
              child: Text('$m minutes'),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(gateServiceProvider)
        .updateSettings((x) => x.copyWith(unlockMinutes: picked));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final perms = ref.watch(gatePermissionsProvider).value;
    final blocked =
        ref.watch(blockedAppsProvider).value ?? const <BlockedApp>[];
    final unlockedUntil = ref.watch(unlockedUntilProvider).value;
    final lowEnergy = ref.watch(lowEnergyProvider);
    final service = ref.read(gateServiceProvider);
    final theme = Theme.of(context);
    if (settings == null) return const Scaffold();

    return PacePage(
      title: 'App gate',
      subtitle: 'A short pause before the apps that pull you in.',
      children: [
        Text(
          'Pick the apps that pull you away. In the morning they wait '
          'until your routine is marked done; in the evening they wait '
          'from wind-down until you wake. You can always unlock them for a '
          'few minutes, and this switch turns everything off.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            key: const ValueKey('gate-enabled'),
            secondary: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('App gate'),
            subtitle: Text(
              settings.gateEnabled
                  ? (perms?.ready ?? false
                        ? 'On'
                        : 'On, waiting for the two permissions below')
                  : 'Off. Nothing is blocked.',
            ),
            value: settings.gateEnabled,
            onChanged: service.setEnabled,
          ),
        ),
        if (unlockedUntil != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_open_rounded),
              title: Text(
                'Unlocked until '
                '${LocalTime.of(unlockedUntil.hour, unlockedUntil.minute).format24()}',
              ),
            ),
          ),
        const SectionHeader('Permissions'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  perms?.usageAccess ?? false
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: theme.colorScheme.secondary,
                ),
                title: const Text('Usage access'),
                subtitle: const Text(
                  'Lets PACE see which app is open. Nothing leaves the '
                  'phone.',
                ),
                trailing: perms?.usageAccess ?? false
                    ? null
                    : TextButton(
                        onPressed: () =>
                            ref.read(appGateProvider).openUsageAccessSettings(),
                        child: const Text('Allow'),
                      ),
              ),
              ListTile(
                leading: Icon(
                  perms?.overlay ?? false
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: theme.colorScheme.secondary,
                ),
                title: const Text('Display over other apps'),
                subtitle: const Text(
                  'Lets the calm "this can wait" screen appear.',
                ),
                trailing: perms?.overlay ?? false
                    ? null
                    : TextButton(
                        onPressed: () =>
                            ref.read(appGateProvider).openOverlaySettings(),
                        child: const Text('Allow'),
                      ),
              ),
            ],
          ),
        ),
        const SectionHeader('When'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Mornings'),
                subtitle: Text(
                  lowEnergy
                      ? 'Low-energy mode: only the first 30 minutes after '
                            'waking.'
                      : 'From waking until your routine is done (or '
                            'leaving time).',
                ),
                value: settings.morningLockEnabled,
                onChanged: (v) => service.updateSettings(
                  (s) => s.copyWith(morningLockEnabled: v),
                ),
              ),
              SwitchListTile(
                title: const Text('Evenings'),
                subtitle: Text(
                  lowEnergy
                      ? 'Low-energy mode: from bedtime until waking.'
                      : 'From wind-down until waking.',
                ),
                value: settings.windDownLockEnabled,
                onChanged: (v) => service.updateSettings(
                  (s) => s.copyWith(windDownLockEnabled: v),
                ),
              ),
              ListTile(
                title: const Text('Emergency unlock'),
                subtitle: const Text('Always on the block screen.'),
                trailing: Text('${settings.unlockMinutes} min'),
                onTap: () => _unlockMinutes(settings),
              ),
            ],
          ),
        ),
        SectionHeader(
          'Apps that wait',
          action: TextButton(
            onPressed: () => _chooseApps(blocked),
            child: const Text('Choose'),
          ),
        ),
        Card(
          child: blocked.isEmpty
              ? const ListTile(
                  title: Text('None chosen yet'),
                  subtitle: Text('The gate does nothing until you pick some.'),
                )
              : Column(
                  children: [
                    for (final a in blocked)
                      ListTile(
                        title: Text(a.label.isEmpty ? a.packageName : a.label),
                        trailing: IconButton(
                          tooltip: 'Stop blocking',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => service.setBlocked(
                            InstalledApp(a.packageName, a.label),
                            false,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('gate-unlock-now'),
          icon: const Icon(Icons.lock_open_rounded),
          label: Text('Unlock for ${settings.unlockMinutes} minutes now'),
          onPressed: () async {
            await ref.read(appGateProvider).unlockFor(settings.unlockMinutes);
            ref.invalidate(unlockedUntilProvider);
          },
        ),
      ],
    );
  }
}

class _AppPicker extends ConsumerStatefulWidget {
  const _AppPicker({required this.blocked});

  final Set<String> blocked;

  @override
  ConsumerState<_AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends ConsumerState<_AppPicker> {
  late final Set<String> _blocked = {...widget.blocked};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(installedAppsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Find an app',
              ),
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
          ),
          Expanded(
            child: apps.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Apps could not be listed.')),
              data: (list) {
                final shown = [
                  for (final a in list)
                    if (a.label.toLowerCase().contains(_query)) a,
                ];
                return ListView(
                  controller: scroll,
                  children: [
                    for (final a in shown)
                      CheckboxListTile(
                        title: Text(a.label),
                        value: _blocked.contains(a.packageName),
                        onChanged: (v) async {
                          setState(
                            () => v == true
                                ? _blocked.add(a.packageName)
                                : _blocked.remove(a.packageName),
                          );
                          await ref
                              .read(gateServiceProvider)
                              .setBlocked(a, v == true);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
