import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/db/settings_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/platform/platform_features.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/wellbeing/application/wellbeing_providers.dart';
import 'package:pace/features/wellbeing/ui/support_screen.dart';
import 'package:pace/features/wellbeing/ui/wellbeing_cards.dart';

import '../../../core/home_widget/fake_home_widget_bridge.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final now = DateTime(2026, 11, 20, 7);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          homeWidgetBridgeProvider.overrideWithValue(FakeHomeWidgetBridge()),
          clockProvider.overrideWithValue(() => now),
          platformFeaturesProvider.overrideWithValue(
            PlatformFeatures.elsewhere,
          ),
        ],
        child: MaterialApp(theme: PaceTheme.light(), home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('welcome back shows today and closes for good', (tester) async {
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(
        welcomeBackDate: const Value('2026-11-20'),
        lightDayDate: const Value('2026-11-20'),
      ),
    );
    await pump(
      tester,
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Column(
            children: [
              if (ref.watch(showWelcomeBackProvider)) const WelcomeBackCard(),
              Text('low:${ref.watch(lowEnergyProvider)}'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('low:true'), findsOneWidget);
    // Never mentions the gap.
    expect(find.textContaining('days'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('welcome-back-close')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsNothing);
    await unmount(tester);
  });

  testWidgets('the light day line turns the light day off', (tester) async {
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(lightDayDate: const Value('2026-11-20')),
    );
    await pump(
      tester,
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Column(
            children: [
              if (ref.watch(lightDayTodayProvider)) const LightDayLine(),
              Text('low:${ref.watch(lowEnergyProvider)}'),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('light-day-line')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('light-day-off')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('light-day-line')), findsNothing);
    expect(find.text('low:false'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the support page lists lines and says it is not therapy', (
    tester,
  ) async {
    await pump(tester, const SupportScreen());
    expect(find.text('NCMH Crisis Hotline'), findsOneWidget);
    expect(find.text('1553'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-disclaimer')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('not therapy'), findsOneWidget);
    await unmount(tester);
  });
}
