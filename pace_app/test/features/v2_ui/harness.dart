import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/platform/platform_features.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';

import '../../core/home_widget/fake_home_widget_bridge.dart';
import '../../core/notifications/fake_notification_gateway.dart';

/// Pumps one screen with an in-memory database and fakes.
class Harness {
  Harness() : db = AppDatabase(NativeDatabase.memory());

  final AppDatabase db;
  final gateway = FakeNotificationGateway();
  final widget = FakeHomeWidgetBridge();

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    DateTime? now,
    PlatformFeatures features = PlatformFeatures.android,
    List<Override> overrides = const [],
  }) async {
    final t = now ?? DateTime(2026, 11, 16, 9);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          homeWidgetBridgeProvider.overrideWithValue(widget),
          clockProvider.overrideWithValue(() => t),
          platformFeaturesProvider.overrideWithValue(features),
          ...overrides,
        ],
        child: MaterialApp(theme: PaceTheme.light(), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets drift close its streams inside the test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  }
}
