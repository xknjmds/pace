import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/platform/device_settings.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/activity/ui/sleep_check_screen.dart';
import 'package:pace/features/blocking/application/gate_providers.dart';

import '../../blocking/application/gate_service_test.dart' show FakeGate;

class _Device implements DeviceSettings {
  @override
  Future<String> manufacturer() async => 'Xiaomi';
  @override
  Future<bool> openAutoStart() async => true;
  @override
  Future<void> openAppDetails() async {}
  @override
  Future<List<(DateTime, bool)>> screenEvents(
    DateTime from,
    DateTime to,
  ) async => [
    // Every night: off at 23:10, on at 06:40.
    (DateTime(from.year, from.month, from.day, 23, 10), false),
    (DateTime(from.year, from.month, from.day + 1, 6, 40), true),
    (DateTime(from.year, from.month, from.day + 1, 7, 0), false),
  ];
}

void main() {
  final now = DateTime(2026, 11, 20, 9);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('three nights side by side, nothing saved', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await db.dailyLogsDao.logBed(
      DateTime(2026, 11, 19),
      DateTime(2026, 11, 19, 22, 30),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          deviceSettingsProvider.overrideWithValue(_Device()),
          appGateProvider.overrideWithValue(FakeGate()),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          home: const SleepCheckScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thu 19/11 night'), findsOneWidget);
    expect(find.text('Logged: bed 22:30, up not logged'), findsOneWidget);
    expect(find.text('Phone: quiet 23:10 to 06:40'), findsNWidgets(3));
    expect(find.byKey(const ValueKey('sleep-check-access')), findsNothing);
    final logs = await db.dailyLogsDao.between(DateTime(2026, 11, 1), now);
    expect(logs.length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
