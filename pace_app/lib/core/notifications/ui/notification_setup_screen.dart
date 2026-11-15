import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../time/clock.dart';
import '../../time/local_time.dart';
import '../../db/app_database.dart';
import '../notification_permissions.dart';
import '../notification_providers.dart';

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
    final gateway = ref.read(notificationGatewayProvider);
    final permissions = ref.watch(notificationPermissionsProvider);
    final pending = ref.watch(pendingRemindersProvider);
    final theme = Theme.of(context);
    final p = permissions.value ?? NotificationPermissions.none;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'PACE works by nudging you at the right moment. For that, '
                'Android needs three things from you. Each one is optional, '
                'but reminders are less reliable without them.',
                style: theme.textTheme.bodyLarge,
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
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        FilledButton(
                          onPressed: p.canNotify ? _sendTest : null,
                          child: const Text('Send test reminder'),
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
        ),
      ),
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
    return Card(
      key: ValueKey(step),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  semanticLabel: done ? 'Done' : 'Not yet',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(why, style: theme.textTheme.bodyMedium),
            if (!done) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.tonal(onPressed: onPressed, child: Text(action)),
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
