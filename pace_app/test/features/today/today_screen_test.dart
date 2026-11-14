import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/app.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
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

  testWidgets(
    'empty Today shows the tagline without overflowing a small phone',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Progress Always Comes Eventually'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    },
  );

  testWidgets('low-energy switch on Today writes to settings and reads back', (
    tester,
  ) async {
    await pumpApp(tester);
    final toggle = find.byType(Switch);
    expect(toggle, findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect((await db.settingsDao.get()).lowEnergyEnabled, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await unmountApp(tester);
  });

  testWidgets('overflow menu reaches every other screen as a placeholder', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    for (final label in ['Deadlines', 'Inbox', 'Focus', 'Review', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.textContaining('Coming soon'), findsOneWidget);
    await unmountApp(tester);
  });
}
