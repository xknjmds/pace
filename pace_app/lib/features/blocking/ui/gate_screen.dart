import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/section_header.dart';
import '../application/app_gate.dart';
import '../application/gate_providers.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/widgets/pace_choice_sheet.dart';
import '../../../core/widgets/pace_tile.dart';

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
    final picked = await showPaceChoiceSheet<int>(
      context: context,
      title: 'Emergency unlock lasts',
      selected: s.unlockMinutes,
      choices: [
        for (final m in const [5, 10, 15, 30]) PaceChoice(m, '$m min'),
      ],
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
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Pick the apps that pull you away. In the morning they wait '
            'until your routine is marked done; in the evening they wait '
            'from wind-down until you wake. You can always unlock them for '
            'a few minutes, and this switch turns everything off.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
        PaceGroup(
          children: [
            PaceTile.toggle(
              key: const ValueKey('gate-enabled'),
              icon: Icons.do_not_disturb_on_rounded,
              kind: PastelKind.evening,
              title: 'App gate',
              subtitle: settings.gateEnabled
                  ? (perms?.ready ?? false
                        ? 'On'
                        : 'On, waiting for the two permissions below')
                  : 'Off. Nothing is blocked.',
              value: settings.gateEnabled,
              onChanged: service.setEnabled,
            ),
            if (unlockedUntil != null)
              PaceTile(
                icon: Icons.lock_open_rounded,
                kind: PastelKind.evening,
                title:
                    'Unlocked until '
                    '${LocalTime.of(unlockedUntil.hour, unlockedUntil.minute).format24()}',
              ),
          ],
        ),
        const SectionHeader('Permissions'),
        PaceGroup(
          children: [
            PaceTile(
              leading: _Granted(perms?.usageAccess ?? false),
              title: 'Usage access',
              subtitle:
                  'Lets PACE see which app is open. Nothing leaves the phone.',
              trailing: perms?.usageAccess ?? false
                  ? null
                  : TextButton(
                      onPressed: () =>
                          ref.read(appGateProvider).openUsageAccessSettings(),
                      child: const Text('Allow'),
                    ),
            ),
            PaceTile(
              leading: _Granted(perms?.overlay ?? false),
              title: 'Display over other apps',
              subtitle: 'Lets the calm "this can wait" screen appear.',
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
        const SectionHeader('When'),
        PaceGroup(
          children: [
            PaceTile.toggle(
              icon: Icons.wb_sunny_rounded,
              kind: PastelKind.morning,
              title: 'Mornings',
              subtitle: lowEnergy
                  ? 'Low-energy mode: only the first 30 minutes after waking.'
                  : 'From waking until your routine is done (or leaving '
                        'time).',
              value: settings.morningLockEnabled,
              onChanged: (v) => service.updateSettings(
                (s) => s.copyWith(morningLockEnabled: v),
              ),
            ),
            PaceTile.toggle(
              icon: Icons.nights_stay_rounded,
              kind: PastelKind.evening,
              title: 'Evenings',
              subtitle: lowEnergy
                  ? 'Low-energy mode: from bedtime until waking.'
                  : 'From wind-down until waking.',
              value: settings.windDownLockEnabled,
              onChanged: (v) => service.updateSettings(
                (s) => s.copyWith(windDownLockEnabled: v),
              ),
            ),
            PaceTile(
              icon: Icons.lock_open_rounded,
              title: 'Emergency unlock',
              subtitle: 'Always on the block screen.',
              value: '${settings.unlockMinutes} min',
              onTap: () => _unlockMinutes(settings),
            ),
          ],
        ),
        SectionHeader(
          'Apps that wait',
          action: TextButton(
            onPressed: () => _chooseApps(blocked),
            child: const Text('Choose'),
          ),
        ),
        PaceGroup(
          children: [
            if (blocked.isEmpty)
              const PaceTile(
                icon: Icons.apps_rounded,
                title: 'None chosen yet',
                subtitle: 'The gate does nothing until you pick some.',
              )
            else
              for (final a in blocked)
                PaceTile(
                  icon: Icons.hourglass_bottom_rounded,
                  kind: PastelKind.evening,
                  title: a.label.isEmpty ? a.packageName : a.label,
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
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Your apps could not be listed just now.'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(installedAppsProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
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

/// Done or not yet for a permission: icon shape and colour both change.
class _Granted extends StatelessWidget {
  const _Granted(this.granted);

  final bool granted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 32,
      child: Icon(
        granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: granted ? scheme.secondary : scheme.outline,
        semanticLabel: granted ? 'Allowed' : 'Not yet',
      ),
    );
  }
}
