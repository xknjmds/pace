import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/app.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/home_widget/noop_home_widget_bridge.dart';
import 'package:pace/core/notifications/noop_notification_gateway.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/startup_report.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/shell/shell_tabs.dart';
import 'package:pace/routes.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationGatewayProvider.overrideWithValue(
          const NoopNotificationGateway(),
        ),
        homeWidgetBridgeProvider.overrideWithValue(
          const NoopHomeWidgetBridge(),
        ),
        startupReportProvider.overrideWithValue(StartupReport()),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 16, 10)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: PaceApp(initialRoute: route),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  bool captureFocused(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const ValueKey('capture-field')))
      .focusNode!
      .hasFocus;

  test('tab routes open the shell alone; others sit on top of it', () {
    expect(Routes.initialStack(Routes.deadlines), hasLength(1));
    expect(Routes.initialStack(Routes.inboxCapture), hasLength(1));
    expect(Routes.initialStack(Routes.settings), hasLength(2));
    expect(Routes.initialStack('/nowhere'), hasLength(1));
    expect(ShellTab.forRoute(Routes.inboxCapture), ShellTab.inbox);
    expect(ShellTab.forRoute(Routes.review), isNull);
  });

  testWidgets('the widget entry opens Inbox with the field focused', (
    tester,
  ) async {
    await pumpApp(tester, Routes.inboxCapture);
    expect(captureFocused(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('a deep link while running switches tab, not stacks', (
    tester,
  ) async {
    await pumpApp(tester, Routes.settings);
    expect(find.byType(NavigationBar), findsNothing); // Settings on top
    Routes.open(
      PaceApp.navigatorKey.currentState,
      container.read(shellRequestProvider.notifier),
      Routes.inboxCapture,
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(captureFocused(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('Today\'s write-it-down button opens capture', (tester) async {
    await db.inboxDao.add('something'); // so Today is not the welcome
    await pumpApp(tester, Routes.today);
    await tester.tap(find.byTooltip('Write it down'));
    await tester.pumpAndSettle();
    expect(captureFocused(tester), isTrue);
    await unmount(tester);
  });
}
