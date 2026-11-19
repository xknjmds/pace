import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/notifications/notification_permissions.dart';
import 'package:pace/core/platform/device_settings.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/notifications/ui/notification_setup_screen.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';

import 'fake_notification_gateway.dart';

void main() {
  final frozen = DateTime(2026, 11, 14, 6, 30);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<FakeNotificationGateway> pump(
    WidgetTester tester, {
    NotificationPermissions state = NotificationPermissions.none,
    bool grantOnRequest = true,
    Size size = const Size(360, 1600),
    DeviceSettings device = const _FakeDevice(''),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeNotificationGateway(
      state: state,
      grantOnRequest: grantOnRequest,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          clockProvider.overrideWithValue(() => frozen),
          deviceSettingsProvider.overrideWithValue(device),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          home: const NotificationSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return gateway;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  IconData stepIcon(WidgetTester tester, SetupStep step) => tester
      .widget<Icon>(
        find.descendant(
          of: find.byKey(ValueKey(step)),
          matching: find.byType(Icon),
        ),
      )
      .icon!;

  testWidgets('lays out on a small phone without overflow', (tester) async {
    await pump(tester, size: const Size(360, 640));
    expect(find.text('Reminders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fresh install shows three open steps and a disabled test', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Reminders'), findsOneWidget);
    for (final step in SetupStep.values) {
      expect(stepIcon(tester, step), Icons.radio_button_unchecked);
    }
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Allow exact timing'), findsOneWidget);
    expect(find.text('Turn off optimisation'), findsOneWidget);

    final send = find.widgetWithText(FilledButton, 'Send test reminder');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    expect(find.text('Allow notifications first.'), findsOneWidget);
    expect(find.text('Reminders waiting: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('granting each step marks it done and hides its button', (
    tester,
  ) async {
    final gateway = await pump(tester);

    await tapText(tester, 'Allow');
    expect(stepIcon(tester, SetupStep.notifications), Icons.check_circle);
    expect(find.text('Allow'), findsNothing);

    await tapText(tester, 'Allow exact timing');
    expect(stepIcon(tester, SetupStep.exactAlarms), Icons.check_circle);

    await tapText(tester, 'Turn off optimisation');
    expect(stepIcon(tester, SetupStep.battery), Icons.check_circle);
    expect(gateway.state, NotificationPermissions.all);
  });

  testWidgets('a denied notification prompt keeps a way into settings', (
    tester,
  ) async {
    final gateway = await pump(tester, grantOnRequest: false);
    await tapText(tester, 'Allow');
    expect(
      stepIcon(tester, SetupStep.notifications),
      Icons.radio_button_unchecked,
    );
    await tapText(tester, 'Open settings');
    expect(gateway.openSettingsCalls, 1);
  });

  testWidgets('test reminder is scheduled one minute ahead through the table', (
    tester,
  ) async {
    final gateway = await pump(tester, state: NotificationPermissions.all);
    await tapText(tester, 'Send test reminder');

    final r = gateway.scheduled.values.single;
    // Stored as UTC; compare the instant, not the DateTime flavour.
    expect(
      r.fireAt.isAtSameMomentAs(frozen.add(NotificationSetupScreen.testLead)),
      isTrue,
    );
    final row = (await db.scheduledNotificationsDao.getLive()).single;
    expect(row.kind, ReminderKind.test);
    expect(gateway.scheduled.keys.single, row.notificationId);
    expect(find.text('Test reminder set for 06:31.'), findsOneWidget);
    expect(find.text('Reminders waiting: 1'), findsOneWidget);

    await tapText(tester, 'Cancel it');
    expect(gateway.cancelled, [row.notificationId]);
    expect(await db.scheduledNotificationsDao.getLive(), isEmpty);
    expect(find.text('Reminders waiting: 0'), findsOneWidget);
    expect(find.textContaining('Test reminder set for'), findsNothing);
  });

  testWidgets(
    'without exact alarms the test is sent and labelled approximate',
    (tester) async {
      await pump(
        tester,
        state: NotificationPermissions.none.copyWith(
          notificationsGranted: true,
        ),
      );
      await tapText(tester, 'Send test reminder');
      expect(
        find.text(
          'Test reminder set for 06:31 (approximate, exact timing is off).',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a Xiaomi phone gets its own steps and auto-start button', (
    tester,
  ) async {
    final device = _FakeDevice.recording('Xiaomi');
    await pump(tester, device: device);
    expect(find.byKey(const ValueKey('maker-guide')), findsOneWidget);
    expect(find.text('On your Xiaomi, Redmi or POCO phone'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-autostart')));
    await tester.pumpAndSettle();
    expect(device.opened, ['autostart']);
  });

  testWidgets('stock Android shows no brand card', (tester) async {
    await pump(tester, device: _FakeDevice('Google'));
    expect(find.byKey(const ValueKey('maker-guide')), findsNothing);
  });
}

class _FakeDevice implements DeviceSettings {
  const _FakeDevice(this.maker) : opened = const [];

  _FakeDevice.recording(this.maker) : opened = [];

  final String maker;
  final List<String> opened;

  @override
  Future<String> manufacturer() async => maker;
  @override
  Future<bool> openAutoStart() async {
    opened.add('autostart');
    return true;
  }

  @override
  Future<void> openAppDetails() async => opened.add('details');

  @override
  Future<List<(DateTime, bool)>> screenEvents(
    DateTime from,
    DateTime to,
  ) async => const [];
}
