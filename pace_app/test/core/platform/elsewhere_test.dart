import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/app.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/home_widget/noop_home_widget_bridge.dart';
import 'package:pace/core/notifications/noop_notification_gateway.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/platform/platform_features.dart';
import 'package:pace/core/startup_report.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/routes.dart';
import 'package:pace/startup.dart';

/// The web and desktop build: no reminders, no widget, everything else on.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 16, 6); // Monday

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  List<Override> overrides(StartupReport report) => [
    appDatabaseProvider.overrideWithValue(db),
    notificationGatewayProvider.overrideWithValue(
      const NoopNotificationGateway(),
    ),
    homeWidgetBridgeProvider.overrideWithValue(const NoopHomeWidgetBridge()),
    platformFeaturesProvider.overrideWithValue(PlatformFeatures.elsewhere),
    clockProvider.overrideWithValue(() => now),
    startupReportProvider.overrideWithValue(report),
  ];

  Future<void> pumpApp(WidgetTester tester, {String? route}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(StartupReport()),
        child: PaceApp(initialRoute: route ?? Routes.today),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  test(
    'startup with the stand-in gateway completes with no problems',
    () async {
      await db.weekdayScheduleDao.upsert(
        weekday: DateTime.monday,
        firstClassMinutes: 8 * 60 + 30,
        commuteMinutes: 30,
        prepMinutes: 30,
      );
      final report = StartupReport();
      final c = ProviderContainer(overrides: overrides(report));
      addTearDown(c.dispose);
      await bootstrap(const NoopNotificationGateway(), container: c);
      expect(report.problems, isEmpty);
      // The table is still kept, so the plan is the same data everywhere.
      expect(await db.scheduledNotificationsDao.getLive(), isNotEmpty);
    },
  );

  testWidgets('Today works and the menu has no Reminders entry', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Set up your week'), findsOneWidget);
    // Wide window: the tabs sit in a side rail.
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);
    // Android-only screens are left out of the hub.
    expect(find.text('Reminders'), findsNothing);
    expect(find.text('App gate'), findsNothing);
    await unmount(tester);
  });

  testWidgets('Reminders screen explains where reminders live', (tester) async {
    await pumpApp(tester, route: Routes.notifications);
    expect(
      find.textContaining(
        'Reminders and their buttons are part of the Android',
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('Inbox captures but offers no shade shortcut', (tester) async {
    await pumpApp(tester, route: Routes.inbox);
    await tester.enterText(find.byKey(const ValueKey('capture-field')), 'idea');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect((await db.inboxDao.getUnprocessed()).single.body, 'idea');
    expect(find.byType(Switch), findsNothing);
    await unmount(tester);
  });

  testWidgets('Deadlines can be added on a wide screen', (tester) async {
    await pumpApp(tester, route: Routes.deadlines);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('task-title')), 'Essay');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await db.tasksDao.getAll()).single.title, 'Essay');
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
