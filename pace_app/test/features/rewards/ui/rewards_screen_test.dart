import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/rewards/ui/rewards_screen.dart';

void main() {
  final now = DateTime(2026, 11, 20, 18);
  late AppDatabase db;

  setUp(
    () => db = AppDatabase(NativeDatabase.memory(), now: () => now.toUtc()),
  );
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1200);
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
          home: const RewardsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('add a reward from the sheet', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('rewards-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-reward')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reward-title')),
      'Milk tea',
    );
    await tester.tap(find.byKey(const ValueKey('reward-days-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reward-save')));
    await tester.pumpAndSettle();
    final r = (await db.rewardsDao.getAll()).single;
    expect(r.title, 'Milk tea');
    expect(r.daysNeeded, 3);
    expect(find.text('0 of 3 days done'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('days done after it was set earn it, and it can be enjoyed', (
    tester,
  ) async {
    final r = await db.rewardsDao.add(title: 'Movie night', daysNeeded: 2);
    await db.dailyLogsDao.setRoutineDone(DateTime(2026, 11, 20), true);
    await db.habitsDao.ensureMovement().then(
      (h) => db.habitsDao.setDone(h.id, DateTime(2026, 11, 21), true),
    );
    await pump(tester);
    expect(find.text('Earned. Enjoy it whenever you like.'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('claim-${r.id}')));
    await tester.pumpAndSettle();
    expect((await db.rewardsDao.getAll()).single.claimedAt, isNotNull);
    expect(find.text('Enjoyed'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('low-energy mode shows only rewards ready to enjoy', (
    tester,
  ) async {
    await db.settingsDao.setLowEnergy(true);
    await db.rewardsDao.add(title: 'Far off', daysNeeded: 30);
    await pump(tester);
    expect(find.text('Far off'), findsNothing);
    expect(find.text('1 more on the way.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('remove then undo brings the same reward back', (tester) async {
    final r = await db.rewardsDao.add(title: 'Stickers', daysNeeded: 5);
    await pump(tester);
    await tester.tap(find.byKey(ValueKey('reward-menu-${r.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(await db.rewardsDao.getAll(), isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    final back = (await db.rewardsDao.getAll()).single;
    expect(back.id, r.id);
    expect(back.createdAt, r.createdAt);
    await unmount(tester);
  });
}
