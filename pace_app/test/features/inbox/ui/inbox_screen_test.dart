import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/inbox/ui/inbox_screen.dart';

import '../../../core/home_widget/fake_home_widget_bridge.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final now = DateTime(2026, 11, 14, 10);
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late FakeHomeWidgetBridge widget;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    widget = FakeHomeWidgetBridge();
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {bool capturing = false}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          homeWidgetBridgeProvider.overrideWithValue(widget),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          home: InboxScreen(startCapturing: capturing),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('typing and pressing done saves to the inbox', (tester) async {
    await pump(tester);
    expect(find.text('Inbox is clear.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('capture-field')),
      'email prof',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect((await db.inboxDao.getUnprocessed()).single.body, 'email prof');
    expect(find.text('email prof'), findsOneWidget);
    expect(widget.last, 1);
    // Field is cleared and ready for the next thought.
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('capture-field')),
    );
    expect(field.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('opened from the widget, the field has focus', (tester) async {
    await pump(tester, capturing: true);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('capture-field')),
    );
    expect(field.focusNode!.hasFocus, isTrue);
    await unmount(tester);
  });

  testWidgets('an item becomes a deadline and leaves the inbox', (
    tester,
  ) async {
    await db.inboxDao.add('read chapter 4');
    await pump(tester);
    await tester.tap(find.byTooltip('Make a deadline'));
    await tester.pumpAndSettle();
    expect(find.text('read chapter 4'), findsWidgets); // prefilled title
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final task = (await db.tasksDao.getAll()).single;
    expect(task.title, 'read chapter 4');
    expect(task.dueAt.toLocal(), DateTime(2026, 11, 15, 23, 59));
    expect(await db.inboxDao.getUnprocessed(), isEmpty);
    expect(find.text('Inbox is clear.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('delete removes an item', (tester) async {
    await db.inboxDao.add('maybe later');
    await pump(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(await db.inboxDao.getUnprocessed(), isEmpty);
    await unmount(tester);
  });

  testWidgets('low-energy mode folds the list into one gentle line', (
    tester,
  ) async {
    await db.settingsDao.setLowEnergy(true);
    await db.inboxDao.add('a');
    await db.inboxDao.add('b');
    await pump(tester);
    expect(find.text('2 things waiting. They can wait.'), findsOneWidget);
    expect(find.text('a'), findsNothing);
    // Capturing still works.
    expect(find.byKey(const ValueKey('capture-field')), findsOneWidget);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('a'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('shortcut switch writes the setting', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.get()).captureShortcutEnabled, isFalse);
    await unmount(tester);
  });
}
