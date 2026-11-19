import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/review/ui/next_routine_card.dart';
import 'package:pace/features/review/ui/year_review_screen.dart';

void main() {
  final now = DateTime(2026, 11, 20, 18);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget home) async {
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
        child: MaterialApp(theme: PaceTheme.light(), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> steadyMornings() async {
    for (var i = 0; i < 12; i++) {
      await db.dailyLogsDao.setRoutineDone(
        DateTime(now.year, now.month, now.day - i),
        true,
      );
    }
  }

  testWidgets('an empty school year is welcoming, not empty', (tester) async {
    await pump(tester, const YearReviewScreen());
    expect(find.text('Since 1 June 2026.'), findsOneWidget);
    expect(find.textContaining('just getting started'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the year lists positive totals', (tester) async {
    await steadyMornings();
    await pump(tester, const YearReviewScreen());
    expect(find.text('12 days with something done'), findsOneWidget);
    expect(
      find.text('12 mornings out the door with the routine done'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('steady mornings bring one idea, and not now moves on', (
    tester,
  ) async {
    await pump(tester, const Scaffold(body: NextRoutineCard()));
    expect(find.byKey(const ValueKey('next-routine-sleep')), findsNothing);
    await unmount(tester);

    await steadyMornings();
    await pump(tester, const Scaffold(body: NextRoutineCard()));
    expect(find.byKey(const ValueKey('next-routine-sleep')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-routine-dismiss')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.get()).dismissedSuggestions, ['sleep']);
    expect(find.byKey(const ValueKey('next-routine-study')), findsOneWidget);
    await unmount(tester);
  });
}
