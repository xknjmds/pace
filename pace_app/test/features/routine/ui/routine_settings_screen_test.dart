import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/routine/ui/routine_settings_screen.dart';

import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final now = DateTime(2026, 11, 14, 6); // Saturday
  late AppDatabase db;
  late FakeNotificationGateway gateway;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
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
          home: const RoutineSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('shows wake time, breakfast and seven days without class', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('8 h'), findsOneWidget);
    // Saturday: tomorrow's lie-in wake 07:30 minus 8 h.
    expect(find.text('Bed around 23:30 tonight.'), findsOneWidget);
    for (final name in weekdayNames.values) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('No class · up at 06:30'), findsNWidgets(5));
    expect(find.text('No class · up at 07:30'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('editing Monday saves the row and schedules its reminders', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('weekday-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Class this day'));
    await tester.pumpAndSettle();
    expect(find.text('08:00'), findsOneWidget); // default first class
    await tester.enterText(find.byKey(const ValueKey('commute-minutes')), '40');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final row = await db.weekdayScheduleDao.getFor(DateTime.monday);
    expect(row?.firstClassMinutes, 8 * 60);
    expect(row?.commuteMinutes, 40);
    expect(
      find.text('Class 08:00 · leave by 07:20 · up at 06:30'),
      findsOneWidget,
    );
    expect(
      gateway.scheduled.values.map((s) => s.payload),
      containsAll(['wake:1', 'eat:1', 'leave:1']),
    );
    await unmount(tester);
  });

  testWidgets('breakfast dialog updates settings and re-plans', (tester) async {
    await db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 8 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await pump(tester);
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('minutes-field')), '30');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect((await db.settingsDao.get()).breakfastMinutes, 30);
    expect(find.text('30 min'), findsOneWidget);
    // 30 min breakfast leaves no slack, so breakfast folds into the wake
    // reminder and there is no separate eat reminder.
    expect(
      gateway.scheduled.values.where((s) => s.payload == 'eat:1'),
      isEmpty,
    );
    final wake = gateway.scheduled.values.singleWhere(
      (s) => s.payload == 'wake:1',
    );
    expect(wake.body, contains('Breakfast first.'));
    await unmount(tester);
  });

  testWidgets('starting a gradual shift shows where it is heading', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('start-shift')));
    await tester.pumpAndSettle();
    // Time picker opens at an hour earlier; accept it.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final s = await db.settingsDao.get();
    expect(s.wakeGoalMinutes, 5 * 60 + 30);
    expect(s.wakeShiftFromMinutes, 6 * 60 + 30);
    expect(
      find.text(
        'Moving 15 min earlier every 3 days toward 05:30, there by 26/11.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('stop-shift')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('low-energy switch in Settings pauses other reminders', (
    tester,
  ) async {
    await db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 8 * 60 + 30,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await pump(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('low-energy-setting')),
    );
    await tester.tap(find.byKey(const ValueKey('low-energy-setting')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.get()).lowEnergyEnabled, isTrue);
    final kinds = gateway.scheduled.values
        .map((s) => s.payload!.split(':').first)
        .toSet();
    expect(kinds, {'wake', 'leave'});
    await unmount(tester);
  });
}
