import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/platform/platform_features.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/focus/application/focus_providers.dart';
import 'package:pace/features/focus/ui/focus_screen.dart';
import 'package:pace/routes.dart';

import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    now = DateTime(2026, 11, 14, 19);
  });
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    String? taskId,
    PlatformFeatures features = PlatformFeatures.android,
  }) async {
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
          secondTickProvider.overrideWith((_) => const Stream.empty()),
          platformFeaturesProvider.overrideWithValue(features),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          onGenerateRoute: (_) => MaterialPageRoute(
            settings: RouteSettings(name: Routes.focus, arguments: taskId),
            builder: (_) => const FocusScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('start, see the countdown, stop early with a kind summary', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Ten minutes. Then you decide.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsOneWidget);

    now = now.add(const Duration(minutes: 3, seconds: 30));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Stopped after 3 minutes. That counts.'), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-start')), findsOneWidget);
    final s = (await db.focusSessionsDao.recent()).single;
    expect(s.durationMinutes, 3);
    expect(s.completed, isFalse);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('coming back after the time is up offers stop or keep going', (
    tester,
  ) async {
    final task = await db.tasksDao.add(
      title: 'Essay',
      dueAt: DateTime(2026, 11, 20),
    );
    await db.focusSessionsDao.start(
      taskId: task.id,
      startedAt: now.subtract(const Duration(minutes: 25)),
      durationMinutes: 10,
    );
    await pump(tester);
    expect(find.text('10 minutes done.'), findsOneWidget);
    expect(find.text('Essay'), findsOneWidget);

    await tester.tap(find.text('Keep going, 10 more'));
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsOneWidget);
    expect((await db.focusSessionsDao.recent()).single.durationMinutes, 10);

    now = now.add(const Duration(minutes: 10));
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester);
    await tester.tap(find.text('Stop here'));
    await tester.pumpAndSettle();
    expect(find.text('10 minutes done. Nice start.'), findsOneWidget);
    expect((await db.focusSessionsDao.recent()).map((s) => s.durationMinutes), [
      10,
      10,
    ]);
    await unmount(tester);
  });

  testWidgets('a task passed in is preselected and recorded', (tester) async {
    final task = await db.tasksDao.add(
      title: 'Lab report',
      dueAt: DateTime(2026, 11, 30),
    );
    await pump(tester, taskId: task.id);
    expect(find.text('Lab report'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pumpAndSettle();
    expect((await db.focusSessionsDao.getActive())!.taskId, task.id);
    await unmount(tester);
  });

  testWidgets('low-energy mode offers only tasks due soon', (tester) async {
    await db.settingsDao.setLowEnergy(true);
    await db.tasksDao.add(title: 'Near', dueAt: DateTime(2026, 11, 15, 9));
    await db.tasksDao.add(title: 'Far', dueAt: DateTime(2026, 11, 30));
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('focus-task')));
    await tester.pumpAndSettle();
    expect(find.text('Near'), findsWidgets);
    expect(find.text('Far'), findsNothing);
    await unmount(tester);
  });

  testWidgets('with reduced motion the states cross-fade without scaling', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    // Flutter already shortens animations under this flag, so sample every
    // millisecond through the swap: nothing may ever be mid-scale (a
    // resting press-scale sits at exactly 1).
    final scaling = find.descendant(
      of: find.byType(AnimatedSwitcher),
      matching: find.byWidgetPredicate(
        (w) => w is ScaleTransition && w.scale.value != 1.0,
      ),
    );
    var sawSwap = false;
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 1));
      if (find.byKey(const ValueKey('focus-remaining')).evaluate().isNotEmpty) {
        sawSwap = true;
      }
      expect(scaling, findsNothing, reason: 'scaled at ${i}ms');
    }
    expect(sawSwap, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('without reminders the countdown says to keep PACE open', (
    tester,
  ) async {
    await pump(tester, features: PlatformFeatures.elsewhere);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Keep PACE open'), findsOneWidget);
    await unmount(tester);
  });
}
