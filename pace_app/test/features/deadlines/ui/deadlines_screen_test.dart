import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/deadlines/ui/deadlines_screen.dart';

import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final now = DateTime(2026, 11, 14, 10); // Saturday
  late AppDatabase db;
  late FakeNotificationGateway gateway;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
  });
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
          notificationGatewayProvider.overrideWithValue(gateway),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: PaceTheme.light(),
          home: const DeadlinesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('empty state, then adding a task with the default due time', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('No deadlines yet'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('task-title')), 'Essay');
    await tester.enterText(
      find.byKey(const ValueKey('task-subject')),
      'English',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final task = (await db.tasksDao.getAll()).single;
    expect(task.title, 'Essay');
    expect(task.dueAt.toLocal(), DateTime(2026, 11, 15, 23, 59));
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Due tomorrow 23:59 · English'), findsOneWidget);
    expect(
      gateway.scheduled.values.where((s) => s.payload == 'deadline:${task.id}'),
      isNotEmpty,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('past due sits in its own quiet section; submitting moves it', (
    tester,
  ) async {
    await db.tasksDao.add(title: 'Old', dueAt: DateTime(2026, 11, 12, 23, 59));
    await db.tasksDao.add(title: 'Soon', dueAt: DateTime(2026, 11, 16, 23, 59));
    await pump(tester);
    expect(find.text('Still open'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Was due Thu 23:59'), findsOneWidget);

    // No red anywhere on the past-due card.
    final cards = tester.widgetList<Card>(find.byType(Card));
    for (final c in cards) {
      expect(c.color, isNot(Colors.red));
      expect(
        c.color,
        isNot(
          Theme.of(tester.element(find.byType(Scaffold))).colorScheme.error,
        ),
      );
    }

    await tester.tap(find.byTooltip('Submitted').first);
    await tester.pumpAndSettle();
    expect(find.text('Still open'), findsNothing);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Reopen'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('low-energy mode keeps only the next two days', (tester) async {
    await db.settingsDao.setLowEnergy(true);
    await db.tasksDao.add(title: 'Near', dueAt: DateTime(2026, 11, 15, 9));
    await db.tasksDao.add(title: 'Far', dueAt: DateTime(2026, 11, 20, 9));
    await pump(tester);
    expect(find.text('Near'), findsOneWidget);
    expect(find.text('Far'), findsNothing);
    expect(find.textContaining('Low-energy mode'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('"Not today" from the menu mutes without changing status', (
    tester,
  ) async {
    final task = await db.tasksDao.add(
      title: 'Lab',
      dueAt: DateTime(2026, 11, 14, 20),
    );
    await pump(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();
    expect((await db.tasksDao.getById(task.id))!.status, TaskStatus.pending);
    expect(
      await db.reminderMutesDao.isMuted(ReminderKind.deadline, task.id, now),
      isTrue,
    );
    await unmount(tester);
  });
}
