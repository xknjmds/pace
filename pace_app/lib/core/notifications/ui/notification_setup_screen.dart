import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/pace_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/section_header.dart';

import '../../platform/platform_features.dart';
import '../../time/clock.dart';
import '../../time/local_time.dart';
import '../../db/app_database.dart';
import '../../platform/device_settings.dart';
import '../notification_permissions.dart';
import '../phone_maker_guide.dart';
import '../notification_providers.dart';
import '../../widgets/pace_page.dart';

/// Explains the three Android permissions reminders need, lets the owner
/// grant each one, and sends a test reminder one minute ahead so the whole
/// path (screen off, app swiped away, reboot) can be checked on a real phone.
class NotificationSetupScreen extends ConsumerStatefulWidget {
  const NotificationSetupScreen({super.key});

  /// How far ahead the test reminder is set.
  static const testLead = Duration(minutes: 1);

  @override
  ConsumerState<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState
    extends ConsumerState<NotificationSetupScreen>
    with WidgetsBindingObserver {
  DateTime? _testFireAt;
  ScheduleMode? _testMode;

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

  /// The user comes back from a system settings page: re-read the state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    ref.invalidate(notificationPermissionsProvider);
    ref.invalidate(pendingRemindersProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    await action();
    if (mounted) _refresh();
  }

  /// Owner id for the one test reminder this screen manages.
  static const _owner = 'reminders-screen';

  Future<void> _sendTest() async {
    final fireAt = ref
        .read(clockProvider)()
        .add(NotificationSetupScreen.testLead);
    final exact =
        ref.read(notificationPermissionsProvider).value?.exactAlarmsAllowed ??
        false;
    await ref
        .read(reminderSchedulerProvider)
        .replaceOwner(ReminderKind.test, _owner, [
          (
            fireAt: fireAt,
            title: 'PACE test reminder',
            body: 'It arrived. Reminders work on this phone.',
          ),
        ]);
    if (!mounted) return;
    setState(() {
      _testFireAt = fireAt;
      _testMode = exact ? ScheduleMode.exact : ScheduleMode.inexact;
    });
    _refresh();
  }

  Future<void> _cancelTest() async {
    await ref
        .read(reminderSchedulerProvider)
        .cancelOwner(ReminderKind.test, _owner);
    if (!mounted) return;
    setState(() {
      _testFireAt = null;
      _testMode = null;
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final features = ref.watch(platformFeaturesProvider);
    if (!features.reminders) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminders')),
        body: const Center(
          child: SingleChildScrollView(
            child: EmptyState(
              title: 'Reminders live on your phone',
              message:
                  'Reminders and their buttons are part of the Android app. '
                  'Everything else works here.',
            ),
          ),
        ),
      );
    }
    final gateway = ref.read(notificationGatewayProvider);
    final permissions = ref.watch(notificationPermissionsProvider);
    final pending = ref.watch(pendingRemindersProvider);
    final theme = Theme.of(context);
    final p = permissions.value ?? NotificationPermissions.none;

    return PacePage(
      title: 'Reminders',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text(
            features.androidReminderChecks
                ? 'PACE works by nudging you at the right moment. For that, '
                      'Android needs three things from you. Each one is optional, '
                      'but reminders are less reliable without them.'
                : 'PACE works by nudging you at the right moment. Allow '
                      'notifications so reminders can appear on time.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
        _StepCard(
          step: SetupStep.notifications,
          done: p.notificationsGranted,
          title: 'Show notifications',
          why: 'So reminders can appear at all.',
          action: 'Allow',
          onPressed: () => _run(gateway.requestNotificationPermission),
          secondary: p.notificationsGranted
              ? null
              : TextButton(
                  onPressed: () => _run(gateway.openNotificationSettings),
                  child: const Text('Open settings'),
                ),
        ),
        if (features.androidReminderChecks) ...[
          _StepCard(
            step: SetupStep.exactAlarms,
            done: p.exactAlarmsAllowed,
            title: 'Exact timing',
            why:
                'Without this, Android may hold a reminder back for several '
                'minutes to save battery. A leave-by time needs the minute.',
            action: 'Allow exact timing',
            onPressed: () => _run(gateway.requestExactAlarmPermission),
          ),
          _StepCard(
            step: SetupStep.battery,
            done: p.batteryUnrestricted,
            title: 'Keep running in the background',
            why:
                'Some phones pause apps to save battery, which can silence '
                'reminders. Turning battery optimisation off for PACE keeps '
                'them coming.',
            action: 'Turn off optimisation',
            onPressed: () => _run(gateway.requestBatteryUnrestricted),
          ),
          if (guideFor(ref.watch(manufacturerProvider).value ?? '')
              case final guide?)
            _MakerCard(
              guide: guide,
              onAutoStart: () =>
                  ref.read(deviceSettingsProvider).openAutoStart(),
              onAppInfo: () =>
                  ref.read(deviceSettingsProvider).openAppDetails(),
            ),
        ],
        const SectionHeader('Check it works'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Try it', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Send a test reminder one minute from now, then lock the '
                  'phone and wait. It should arrive on the minute.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (_testFireAt case final fireAt?) ...[
                  Text(
                    'Test reminder set for '
                    '${LocalTime.of(fireAt.hour, fireAt.minute).format24()}'
                    '${_testMode == ScheduleMode.inexact ? ' (approximate, exact timing is off)' : ''}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PressScale(
                      child: FilledButton(
                        onPressed: p.canNotify ? _sendTest : null,
                        child: const Text('Send test reminder'),
                      ),
                    ),
                    if (_testFireAt != null)
                      TextButton(
                        onPressed: _cancelTest,
                        child: const Text('Cancel it'),
                      ),
                  ],
                ),
                if (!p.canNotify)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Allow notifications first.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(switch (pending) {
                  AsyncData(:final value) =>
                    'Reminders waiting: ${value.length}',
                  _ => 'Reminders waiting: …',
                }, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.done,
    required this.title,
    required this.why,
    required this.action,
    required this.onPressed,
    this.secondary,
  });

  final SetupStep step;
  final bool done;
  final String title;
  final String why;
  final String action;
  final VoidCallback onPressed;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedContainer(
      key: ValueKey(step),
      duration: PaceMotion.standard,
      curve: PaceMotion.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: done ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: PaceRadius.cardAll,
        border: Border.all(
          color: done
              ? Colors.transparent
              : scheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: PaceMotion.standard,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(
                      scale: Tween(begin: .8, end: 1.0).animate(a),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    key: ValueKey(done),
                    color: done ? scheme.secondary : scheme.outline,
                    semanticLabel: done ? 'Done' : 'Not yet',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              why,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: done
                    ? scheme.onPrimaryContainer.withValues(alpha: .8)
                    : scheme.onSurfaceVariant,
              ),
            ),
            if (!done) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PressScale(
                    child: FilledButton.tonal(
                      onPressed: onPressed,
                      child: Text(action),
                    ),
                  ),
                  ?secondary,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Brand extras: the steps a phone maker adds on top of Android's own.
class _MakerCard extends StatelessWidget {
  const _MakerCard({
    required this.guide,
    required this.onAutoStart,
    required this.onAppInfo,
  });

  final PhoneMakerGuide guide;
  final VoidCallback onAutoStart;
  final VoidCallback onAppInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('maker-guide'),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: PaceRadius.cardAll,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'On your ${guide.brand} phone',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'This brand can close apps on its own to save battery. These '
              'steps keep reminders arriving. Names differ a little between '
              'versions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final (i, step) in guide.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(step, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (guide.hasAutoStartPage)
                  PressScale(
                    child: FilledButton.tonal(
                      key: const ValueKey('open-autostart'),
                      onPressed: onAutoStart,
                      child: const Text('Open auto-start'),
                    ),
                  ),
                TextButton(
                  key: const ValueKey('open-app-info'),
                  onPressed: onAppInfo,
                  child: const Text('App info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
