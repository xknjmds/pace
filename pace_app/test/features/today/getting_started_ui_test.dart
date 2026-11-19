import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/app.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/startup_report.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/core/widgets/first_visit_hint.dart';

import '../../core/home_widget/fake_home_widget_bridge.dart';
import '../../core/notifications/fake_notification_gateway.dart';

/// D11: what a new user sees in the first days after setup.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 16, 10); // a Monday, after school starts

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    FirstVisitHint.debugEnabled = true;
    await db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 8 * 60 + 30,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(
        onboardedAt: Value(now.subtract(const Duration(hours: 2))),
      ),
    );
  });
  tearDown(() async {
    FirstVisitHint.debugEnabled = false;
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          homeWidgetBridgeProvider.overrideWithValue(FakeHomeWidgetBridge()),
          startupReportProvider.overrideWithValue(StartupReport()),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const PaceApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  final card = find.byKey(const ValueKey('getting-started'));

  testWidgets('a new user sees Getting started, and a deadline ticks it', (
    tester,
  ) async {
    await pumpApp(tester);
    await scrollTo(tester, card);
    expect(find.textContaining('0 of'), findsOneWidget);
    expect(find.text('Add your first deadline'), findsOneWidget);

    await db.tasksDao.add(title: 'Essay', dueAt: DateTime(2026, 11, 20));
    await tester.pumpAndSettle();
    await scrollTo(tester, card);
    expect(find.textContaining('1 of'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('getting-started-deadline')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('Hide puts the card away for good', (tester) async {
    await pumpApp(tester);
    await scrollTo(tester, card);
    await tester.tap(find.byKey(const ValueKey('getting-started-hide')));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect((await db.settingsDao.get()).gettingStartedClosedAt, isNotNull);

    await unmountApp(tester);
    await pumpApp(tester);
    expect(card, findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a step opens its place', (tester) async {
    await pumpApp(tester);
    await scrollTo(tester, find.text('Write a thought in Inbox'));
    await tester.tap(find.text('Write a thought in Inbox'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-field')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('low-energy mode leaves the card and hints out', (tester) async {
    await db.settingsDao.setLowEnergy(true);
    await pumpApp(tester);
    expect(card, findsNothing);
    expect(find.byKey(const ValueKey('hint-today')), findsNothing);
    // Not counted as seen: it comes back on a normal day.
    expect((await db.settingsDao.get()).seenHints, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('each tab hint shows once; Got it closes it for good', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const ValueKey('hint-today')), findsOneWidget);

    for (final (tab, id) in [
      ('Deadlines', 'deadlines'),
      ('Inbox', 'inbox'),
      ('Focus', 'focus'),
      ('More', 'more'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      final hint = find.byKey(ValueKey('hint-$id'));
      expect(hint, findsOneWidget, reason: tab);
      await tester.tap(
        find.descendant(of: hint, matching: find.text('Got it')),
      );
      await tester.pumpAndSettle();
      expect(hint, findsNothing, reason: tab);
    }
    expect(
      (await db.settingsDao.get()).seenHints,
      containsAll(['deadlines', 'inbox', 'focus', 'more']),
    );
    await unmountApp(tester);
  });

  testWidgets('a hidden card can be brought back from More', (tester) async {
    await db.settingsDao.setGettingStartedClosed(true);
    await db.settingsDao.markHintSeen(HintIds.more);
    await pumpApp(tester);
    expect(card, findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('More'),
      ),
    );
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('more-getting-started'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect((await db.settingsDao.get()).gettingStartedClosedAt, isNull);
    await scrollTo(tester, card);
    expect(card, findsOneWidget);
    await unmountApp(tester);
  });
}
