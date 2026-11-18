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

  testWidgets('hub tiles show live counts and open their screens', (
    tester,
  ) async {
    await db.notesDao.add(title: 'Ideas', body: 'One');
    await db.notesDao.add(title: 'Lists', body: 'Two');
    await db.financeDao.addExpense(
      amountMinor: 12000,
      category: 'Food',
      spentAt: DateTime(2026, 11, 16, 9),
    );
    await pumpApp(tester, Routes.more);
    expect(find.text('2 notes'), findsOneWidget);
    expect(find.textContaining('120.00'), findsOneWidget);
    expect(find.text('Add your timetable'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Ideas'), findsOneWidget);
    await unmount(tester);
  });
}
