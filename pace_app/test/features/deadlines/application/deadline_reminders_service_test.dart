import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/core/notifications/reminder_scheduler.dart';
import 'package:pace/features/deadlines/application/deadline_reminders_service.dart';

import '../../../core/db/test_db.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final start = DateTime(2026, 11, 13, 12); // Friday noon
  late TestDb t;
  late FakeNotificationGateway gateway;
  late DeadlineReminders deadlines;

  setUp(() {
    t = TestDb(start.toUtc());
    gateway = FakeNotificationGateway();
    deadlines = DeadlineReminders(
      db: t.db,
      scheduler: ReminderScheduler(
        db: t.db,
        gateway: gateway,
        now: () => t.now,
      ),
      now: () => t.now.toLocal(),
    );
  });
  tearDown(() => t.close());

  Iterable<DateTime> firesFor(String taskId) => gateway.scheduled.values
      .where((s) => s.payload == 'deadline:$taskId')
      .map((s) => s.fireAt.toLocal());

  test('adding a task schedules its four nudges with calm copy', () async {
    final task = await deadlines.add(
      title: 'Essay',
      subject: 'English',
      dueAt: DateTime(2026, 11, 20, 23, 59),
    );
    expect(firesFor(task.id), [
      DateTime(2026, 11, 17, 19),
      DateTime(2026, 11, 19, 19),
      DateTime(2026, 11, 20, 7), // wake 06:30 + 30
      DateTime(2026, 11, 20, 21, 59),
    ]);
    final first = gateway.scheduled.values.first;
    expect(first.title, 'Essay (English)');
    expect(first.body, 'Due Fri 23:59. A good moment to start.');
    expect(first.actions.map((a) => a.id), [
      ReminderActionIds.done,
      ReminderActionIds.notToday,
    ]);
  });

  test(
    'marking submitted removes every pending reminder for the task',
    () async {
      final a = await deadlines.add(
        title: 'A',
        dueAt: DateTime(2026, 11, 20, 23, 59),
      );
      final b = await deadlines.add(
        title: 'B',
        dueAt: DateTime(2026, 11, 21, 23, 59),
      );
      await deadlines.markSubmitted(a.id);
      expect(firesFor(a.id), isEmpty);
      expect(firesFor(b.id), hasLength(4));
      expect(
        await t.db.scheduledNotificationsDao.byOwner(
          ReminderKind.deadline,
          a.id,
        ),
        isEmpty,
      );
      expect((await t.db.tasksDao.getById(a.id))!.status, TaskStatus.submitted);
    },
  );

  test('"Not today" mutes only today\'s nudges for that task', () async {
    final task = await deadlines.add(
      title: 'Lab',
      dueAt: DateTime(2026, 11, 13, 20), // today, 2h-before at 18:00
    );
    expect(firesFor(task.id), [DateTime(2026, 11, 13, 18)]);
    await deadlines.handle(
      ReminderResponse(
        payload: 'deadline:${task.id}',
        actionId: ReminderActionIds.notToday,
      ),
    );
    expect(firesFor(task.id), isEmpty);
    expect((await t.db.tasksDao.getById(task.id))!.status, TaskStatus.pending);
    expect(
      await t.db.reminderMutesDao.isMuted(
        ReminderKind.deadline,
        task.id,
        DateTime(2026, 11, 13),
      ),
      isTrue,
    );
  });

  test('editing the due time re-plans; deleting cancels', () async {
    final task = await deadlines.add(
      title: 'Quiz',
      dueAt: DateTime(2026, 11, 20, 23, 59),
    );
    await deadlines.edit(task.copyWith(dueAt: DateTime(2026, 11, 16, 9)));
    expect(firesFor(task.id), [
      DateTime(2026, 11, 13, 19),
      DateTime(2026, 11, 15, 19),
      DateTime(2026, 11, 16, 7),
    ]);
    await deadlines.remove(task.id);
    expect(firesFor(task.id), isEmpty);
    expect(await t.db.tasksDao.getById(task.id), isNull);
  });

  test('the Submitted button on a notification marks it submitted', () async {
    final task = await deadlines.add(
      title: 'X',
      dueAt: DateTime(2026, 11, 20, 23, 59),
    );
    final handled = await deadlines.handle(
      ReminderResponse(
        payload: 'deadline:${task.id}',
        actionId: ReminderActionIds.done,
      ),
    );
    expect(handled, isTrue);
    expect(
      (await t.db.tasksDao.getById(task.id))!.status,
      TaskStatus.submitted,
    );
    expect(firesFor(task.id), isEmpty);
    expect(
      await deadlines.handle(const ReminderResponse(payload: 'wake:1')),
      isFalse,
    );
  });

  test('resyncAll on launch drops past nudges', () async {
    final task = await deadlines.add(
      title: 'Y',
      dueAt: DateTime(2026, 11, 20, 23, 59),
    );
    t.now = DateTime(2026, 11, 20, 8).toUtc();
    await deadlines.resyncAll();
    expect(firesFor(task.id), [DateTime(2026, 11, 20, 21, 59)]);
  });
}
