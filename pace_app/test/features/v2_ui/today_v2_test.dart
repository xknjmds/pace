import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/startup_report.dart';
import 'package:pace/features/today/ui/today_screen.dart';

import 'harness.dart';

void main() {
  // Monday 16 Nov 2026, 08:15: Math is under way.
  final now = DateTime(2026, 11, 16, 8, 15);

  Future<Harness> setUpDay() async {
    final h = Harness();
    await h.db.weekdayScheduleDao.upsert(
      weekday: 1,
      firstClassMinutes: 8 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await h.db.classBlocksDao.add(
      weekday: 1,
      subject: 'Math',
      startMinutes: 480,
      endMinutes: 540,
    );
    await h.db.classBlocksDao.add(
      weekday: 1,
      subject: 'Art',
      startMinutes: 600,
      endMinutes: 660,
    );
    final habit = await h.db.habitsDao.ensureMovement();
    await h.db.habitsDao.edit(habit.copyWith(active: true));
    return h;
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) => tester
      .scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);

  testWidgets('Today shows the classes, marks the current one, and the habit', (
    tester,
  ) async {
    final h = await setUpDay();
    await h.pump(
      tester,
      const TodayScreen(),
      now: now,
      overrides: [startupReportProvider.overrideWithValue(StartupReport())],
    );
    // The timetable's classes sit on the timeline, with time and length.
    final timeline = find.byKey(const ValueKey('day-timeline'));
    await scrollTo(tester, timeline);
    Finder onTimeline(String text) =>
        find.descendant(of: timeline, matching: find.text(text));
    expect(onTimeline('Math'), findsOneWidget);
    expect(onTimeline('08:00–09:00'), findsOneWidget);
    expect(onTimeline('Art'), findsOneWidget);

    // The habit is one pill in "Also today": tap to mark it done.
    await tester.tap(find.byKey(const ValueKey('habit-done')));
    await tester.pumpAndSettle();
    final id = (await h.db.habitsDao.ensureMovement()).id;
    expect(await h.db.habitsDao.isDone(id, now), isTrue);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('habit-undo')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('habit-undo')), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('low-energy mode keeps now and next, hides verse and habit', (
    tester,
  ) async {
    final h = await setUpDay();
    await h.db.classBlocksDao.add(
      weekday: 1,
      subject: 'History',
      startMinutes: 720,
      endMinutes: 780,
    );
    await h.db.settingsDao.setLowEnergy(true);
    await h.pump(
      tester,
      const TodayScreen(),
      now: now,
      overrides: [startupReportProvider.overrideWithValue(StartupReport())],
    );
    final timeline = find.byKey(const ValueKey('day-timeline'));
    await scrollTo(tester, timeline);
    Finder onTimeline(String text) =>
        find.descendant(of: timeline, matching: find.text(text));
    expect(onTimeline('Math'), findsOneWidget);
    expect(onTimeline('Art'), findsOneWidget);
    expect(onTimeline('History'), findsNothing);
    expect(find.byKey(const ValueKey('habit-done')), findsNothing);
    expect(find.byKey(const ValueKey('verse-card')), findsNothing);
    await h.unmount(tester);
  });
}
