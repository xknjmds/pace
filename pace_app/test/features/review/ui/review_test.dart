import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/notifications/notification_permissions.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/review/ui/check_in_screen.dart';
import 'package:pace/features/review/ui/review_screen.dart';
import 'package:pace/routes.dart';

import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway(
      state: NotificationPermissions.none.copyWith(notificationsGranted: true),
    );
    now = DateTime(2026, 11, 16, 21, 50); // Monday evening
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          home: screen,
          routes: {
            Routes.notifications: (_) => const Scaffold(),
            Routes.settings: (_) => const Scaffold(),
            Routes.checkIn: (_) => const CheckInScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  group('weekly view', () {
    testWidgets('empty week reads calmly', (tester) async {
      await pump(tester, const ReviewScreen());
      expect(find.text('No routine days logged yet'), findsOneWidget);
      expect(find.text('No wake times logged yet'), findsOneWidget);
      expect(find.text('No full nights logged yet'), findsOneWidget);
      expect(find.textContaining('Nothing yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('partial week shows counts, average and the sleep log', (
      tester,
    ) async {
      final logs = db.dailyLogsDao;
      await logs.logBed(DateTime(2026, 11, 14), DateTime(2026, 11, 14, 23, 30));
      await logs.logWake(DateTime(2026, 11, 15), DateTime(2026, 11, 15, 7, 50));
      await logs.logWake(DateTime(2026, 11, 16), DateTime(2026, 11, 16, 6, 30));
      await logs.setRoutineDone(DateTime(2026, 11, 16), true);
      await pump(tester, const ReviewScreen());

      expect(find.text('Routine done on 1 day'), findsOneWidget);
      expect(find.text('Up around 07:10 on average'), findsOneWidget);
      expect(find.text('From 2 mornings'), findsOneWidget);
      expect(find.text('About 8 h 20 min of sleep a night'), findsOneWidget);
      expect(find.text('Sat night'), findsOneWidget);
      expect(find.text('bed 23:30 · up 07:50'), findsOneWidget);
      expect(find.text('Sun night'), findsOneWidget);
      expect(find.text('bed not logged · up 06:30'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('low-energy mode folds the sleep log into a count', (
      tester,
    ) async {
      await db.settingsDao.setLowEnergy(true);
      await db.dailyLogsDao.logWake(
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 16, 6, 30),
      );
      await pump(tester, const ReviewScreen());
      expect(find.text('1 night logged.'), findsOneWidget);
      expect(find.text('Sun night'), findsNothing);
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Sun night'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('check-in', () {
    Future<void> setUpWeek() async {
      await db.weekdayScheduleDao.upsert(
        weekday: DateTime.tuesday,
        firstClassMinutes: 8 * 60 + 30,
        commuteMinutes: 30,
        prepMinutes: 30,
      );
    }

    testWidgets('tomorrow, top 3, alarm, then going to bed', (tester) async {
      await setUpWeek();
      final essay = await db.tasksDao.add(
        title: 'Essay',
        dueAt: DateTime(2026, 11, 17, 23, 59),
      );
      await db.tasksDao.add(title: 'Far off', dueAt: DateTime(2026, 11, 30));
      await pump(tester, const CheckInScreen());

      expect(find.text('Check-in 1 of 5'), findsOneWidget);
      expect(
        find.text('Up at 06:30, leave by 08:00 for class at 08:30.'),
        findsOneWidget,
      );
      expect(find.text('Essay'), findsOneWidget);
      expect(find.text('Far off'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('check-in-next')));
      await tester.pumpAndSettle();
      expect(find.text('Top 3 for tomorrow'), findsOneWidget);
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('pick-${essay.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save (1/3)'));
      await tester.pumpAndSettle();
      expect((await db.dailyLogsDao.get(DateTime(2026, 11, 17)))?.top3TaskIds, [
        essay.id,
      ]);

      await tester.tap(find.byKey(const ValueKey('check-in-next')));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow at 06:30.'), findsOneWidget);
      expect(find.text('Set up reminders'), findsOneWidget); // exact off

      await tester.tap(find.byKey(const ValueKey('check-in-next')));
      await tester.pumpAndSettle();
      expect(find.text('How are you feeling tonight?'), findsOneWidget);
      expect(find.byKey(const ValueKey('light-day-offer')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mood-drained')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('light-day-offer')), findsOneWidget);
      expect(find.byKey(const ValueKey('open-support')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('plan-light-day')));
      await tester.pumpAndSettle();
      expect(
        find.text('Tomorrow is a light day: only the main steps.'),
        findsOneWidget,
      );
      expect(
        (await db.dailyLogsDao.get(DateTime(2026, 11, 16)))?.mood,
        Mood.drained,
      );
      expect((await db.settingsDao.get()).lightDayDate, '2026-11-17');

      await tester.tap(find.byKey(const ValueKey('check-in-next')));
      await tester.pumpAndSettle();
      expect(find.text('Bed around 22:30 gives you 8 hours.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('going-to-bed')));
      await tester.pumpAndSettle();
      expect(find.text('Sleep well.'), findsOneWidget);
      expect(
        (await db.dailyLogsDao.get(DateTime(2026, 11, 16)))?.bedLoggedAt,
        now.toUtc(),
      );
      await unmount(tester);
    });

    testWidgets('low-energy mode skips picking a top 3', (tester) async {
      await setUpWeek();
      await db.settingsDao.setLowEnergy(true);
      await pump(tester, const CheckInScreen());
      expect(find.text('Check-in 1 of 4'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('check-in-next')));
      await tester.pumpAndSettle();
      expect(find.text('Wake reminder'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a night with no class tomorrow says so', (tester) async {
      now = DateTime(2026, 11, 20, 22); // Friday; Saturday has no class
      await pump(tester, const CheckInScreen());
      expect(
        find.text('No class. Up at 07:30 keeps sleep steady.'),
        findsOneWidget,
      );
      await unmount(tester);
    });
  });
}
