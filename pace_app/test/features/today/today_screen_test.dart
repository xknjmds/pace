import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/app.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/time/clock.dart';

import '../../core/home_widget/fake_home_widget_bridge.dart';
import '../../core/notifications/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
  });
  tearDown(() => db.close());

  /// A typical small phone.
  const phone = Size(360, 640);

  Future<void> pumpApp(WidgetTester tester, DateTime now) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          homeWidgetBridgeProvider.overrideWithValue(FakeHomeWidgetBridge()),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const PaceApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Drift closes query streams on a zero-length timer when their last
  /// listener goes away. Unmount inside the test so that timer fires before
  /// flutter_test checks for pending timers.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> mondayClass() => db.weekdayScheduleDao.upsert(
    weekday: DateTime.monday,
    firstClassMinutes: 8 * 60 + 30,
    commuteMinutes: 30,
    prepMinutes: 30,
  );

  /// Fully inside the visible viewport, no scrolling needed.
  void expectOnScreen(WidgetTester tester, Finder finder) {
    final rect = tester.getRect(finder);
    expect(rect.bottom, lessThanOrEqualTo(phone.height));
    expect(rect.top, greaterThanOrEqualTo(0));
  }

  testWidgets('with no data: tagline, set-up button, nothing overflows', (
    tester,
  ) async {
    await pumpApp(tester, DateTime(2026, 11, 14, 10));
    expect(find.text('Progress Always Comes Eventually'), findsOneWidget);
    expect(find.text('Set up your week'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('a class morning answers "what now" without scrolling', (
    tester,
  ) async {
    await mondayClass();
    await db.weekdayScheduleDao.upsert(
      weekday: DateTime.tuesday,
      firstClassMinutes: 9 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await db.tasksDao.add(
      title: 'Essay',
      dueAt: DateTime(2026, 11, 17, 23, 59),
    );
    await db.tasksDao.add(
      title: 'Quiz prep',
      dueAt: DateTime(2026, 11, 16, 20),
    );
    await db.tasksDao.add(title: 'Far away', dueAt: DateTime(2026, 11, 30));
    await pumpApp(tester, DateTime(2026, 11, 16, 6, 0)); // Monday 06:00

    expect(find.text('Next: up at 06:30'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);
    expect(find.textContaining('Quiz prep'), findsOneWidget);
    expect(find.textContaining('Essay'), findsOneWidget);
    expect(find.textContaining('Far away'), findsNothing);
    final tomorrow = find.byKey(const ValueKey('tomorrow-preview'));
    expect(find.text('Tomorrow: class 09:00, leave by 08:30'), findsOneWidget);
    expectOnScreen(tester, tomorrow);
    expectOnScreen(tester, find.byKey(const ValueKey('routine-card')));
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('tapping a step chip logs it and moves to the next step', (
    tester,
  ) async {
    await mondayClass();
    final now = DateTime(2026, 11, 16, 6, 35);
    await pumpApp(tester, now);
    await tester.tap(find.byKey(const ValueKey('step-wake')));
    await tester.pumpAndSettle();
    expect(find.text('Next: eat at 07:15'), findsOneWidget);
    expect((await db.dailyLogsDao.get(now))?.wakeLoggedAt, now.toUtc());
    await unmountApp(tester);
  });

  testWidgets('late morning shows one calm card with an arrival time', (
    tester,
  ) async {
    await mondayClass();
    final now = DateTime(2026, 11, 16, 8, 10);
    await pumpApp(tester, now);
    expect(find.text('Leave now'), findsOneWidget);
    expect(find.text('You arrive about 08:40.'), findsOneWidget);
    expect(find.textContaining('late'), findsNothing);
    expect(find.textContaining('Late'), findsNothing);
    expect(find.byKey(const ValueKey('step-wake')), findsNothing);

    await tester.tap(find.text('I\'m out the door'));
    await tester.pumpAndSettle();
    expect(find.text('Routine done for today.'), findsNothing); // eat open
    expect(find.text('Next: eat at 07:15'), findsOneWidget);
    final log = await db.dailyLogsDao.get(now);
    expect(log?.wakeLoggedAt, isNotNull);
    expect(log?.routineDone, isTrue);
    await unmountApp(tester);
  });

  testWidgets('tomorrow preview is hidden when tomorrow has no class', (
    tester,
  ) async {
    await mondayClass();
    await pumpApp(tester, DateTime(2026, 11, 16, 6)); // Tuesday has no row
    expect(find.byKey(const ValueKey('tomorrow-preview')), findsNothing);
    expect(find.text('Nothing due in the next two days.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('no class today says so, no late card ever', (tester) async {
    await mondayClass();
    await pumpApp(tester, DateTime(2026, 11, 15, 11)); // Sunday
    expect(find.text('No class today. The day is yours.'), findsOneWidget);
    expect(find.text('Tomorrow: class 08:30, leave by 08:00'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('top 3 picker saves to the daily log', (tester) async {
    await mondayClass();
    final a = await db.tasksDao.add(
      title: 'Alpha',
      dueAt: DateTime(2026, 11, 20),
    );
    await db.tasksDao.add(title: 'Beta', dueAt: DateTime(2026, 11, 21));
    final now = DateTime(2026, 11, 16, 6);
    await pumpApp(tester, now);
    expect(find.text('Pick up to three things to move today.'), findsOneWidget);

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('pick-${a.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save (1/3)'));
    await tester.pumpAndSettle();

    expect((await db.dailyLogsDao.get(now))?.top3TaskIds, [a.id]);
    expect(find.textContaining('Alpha · Due Fri'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('low-energy mode: only up, leave and due soon', (tester) async {
    await mondayClass();
    await db.settingsDao.setLowEnergy(true);
    await pumpApp(tester, DateTime(2026, 11, 16, 6));
    expect(find.text('Top 3'), findsNothing);
    expect(find.byKey(const ValueKey('step-eat')), findsNothing);
    expect(find.byKey(const ValueKey('step-wake')), findsOneWidget);
    expect(find.byKey(const ValueKey('step-leave')), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);
    expect(find.byKey(const ValueKey('tomorrow-preview')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('low-energy switch on Today writes to settings', (tester) async {
    await pumpApp(tester, DateTime(2026, 11, 14, 10));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.get()).lowEnergyEnabled, isTrue);
    await unmountApp(tester);
  });

  testWidgets('overflow menu reaches every other screen', (tester) async {
    await pumpApp(tester, DateTime(2026, 11, 14, 10));
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    for (final label in [
      'Deadlines',
      'Inbox',
      'Focus',
      'Review',
      'Settings',
      'Reminders',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-field')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('inbox count shows on Today and opens the Inbox', (tester) async {
    await db.inboxDao.add('one');
    await db.inboxDao.add('two');
    await pumpApp(tester, DateTime(2026, 11, 14, 10));
    expect(find.text('Inbox: 2 waiting'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('inbox-count')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-field')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a running focus session shows on Today', (tester) async {
    final now = DateTime(2026, 11, 14, 19, 4);
    await db.focusSessionsDao.start(
      startedAt: DateTime(2026, 11, 14, 19),
      durationMinutes: 10,
    );
    await pumpApp(tester, now);
    expect(find.text('Focus: 6 min left'), findsOneWidget);
    await unmountApp(tester);
  });
}
