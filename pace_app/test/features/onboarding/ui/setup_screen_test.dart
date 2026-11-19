import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/platform/platform_features.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/onboarding/ui/setup_screen.dart';

import '../../../core/home_widget/fake_home_widget_bridge.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final now = DateTime(2026, 11, 16, 20); // Monday evening
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
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
          clockProvider.overrideWithValue(() => now),
          homeWidgetBridgeProvider.overrideWithValue(FakeHomeWidgetBridge()),
          platformFeaturesProvider.overrideWithValue(
            PlatformFeatures.elsewhere,
          ),
        ],
        child: MaterialApp(theme: PaceTheme.light(), home: const SetupScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('setup-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('walking through with defaults saves a working week', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Hi, I\'m Tuck.'), findsOneWidget);
    await next(tester); // classes
    await tester.tap(find.byKey(const ValueKey('day-5'))); // no Friday
    await tester.pumpAndSettle();
    await next(tester); // travel
    await tester.tap(find.byKey(const ValueKey('commute-20')));
    await tester.pumpAndSettle();
    await next(tester); // sleep
    await next(tester); // body clock
    await tester.tap(find.byKey(const ValueKey('chronotype-night')));
    await tester.pumpAndSettle();
    await next(tester); // summary
    expect(find.byKey(const ValueKey('summary-leave')), findsOneWidget);
    expect(find.text('Leave by 07:40 on school days.'), findsOneWidget);
    await next(tester); // Looks good
    await tester.pumpAndSettle();

    final days = await db.weekdayScheduleDao.getAll();
    expect(days, hasLength(7));
    final friday = days.firstWhere((d) => d.weekday == DateTime.friday);
    expect(friday.firstClassMinutes, isNull);
    final monday = days.firstWhere((d) => d.weekday == DateTime.monday);
    expect(monday.commuteMinutes, 20);
    final s = await db.settingsDao.get();
    expect(s.onboardedAt, isNotNull);
    expect(s.weekendLeewayMinutes, 60);
    await unmount(tester);
  });

  testWidgets('skip is there from the first screen and saves nothing else', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('setup-skip')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.get()).onboardedAt, isNotNull);
    expect(await db.weekdayScheduleDao.getAll(), isEmpty);
    await unmount(tester);
  });
}
