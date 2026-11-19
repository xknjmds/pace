import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/journey/ui/journey_screen.dart';

void main() {
  final now = DateTime(2026, 11, 20, 18);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          home: const JourneyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('with no data Tuck is ready to set off', (tester) async {
    await pump(tester);
    expect(find.text('Ready to set off'), findsOneWidget);
    expect(find.text('Your firsts will gather here.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('three routine days in a week reach the clover patch', (
    tester,
  ) async {
    for (final d in [16, 17, 18]) {
      await db.dailyLogsDao.setRoutineDone(DateTime(2026, 11, d), true);
    }
    await pump(tester);
    expect(find.text('3 days along'), findsOneWidget);
    expect(find.text('At Clover patch.'), findsOneWidget);
    expect(find.byKey(const ValueKey('first-steadyWeek')), findsOneWidget);
    expect(find.text('Next: Little bridge, 4 more days done.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('low-energy mode shows only where Tuck is', (tester) async {
    await db.settingsDao.setLowEnergy(true);
    await db.dailyLogsDao.setRoutineDone(DateTime(2026, 11, 16), true);
    await pump(tester);
    expect(find.byKey(const ValueKey('journey-where')), findsOneWidget);
    expect(find.text('The way'), findsNothing);
    await unmount(tester);
  });
}
