import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/core/notifications/reminder_scheduler.dart';
import 'package:pace/features/habits/application/habit_service.dart';

import '../../../core/db/test_db.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final start = DateTime(2026, 11, 16, 5); // Monday 05:00 local
  late TestDb t;
  late FakeNotificationGateway gateway;
  late HabitService habits;

  setUp(() async {
    t = TestDb(start.toUtc());
    gateway = FakeNotificationGateway();
    habits = HabitService(
      db: t.db,
      scheduler: ReminderScheduler(
        db: t.db,
        gateway: gateway,
        now: () => t.now,
      ),
      now: () => t.now.toLocal(),
    );
    await t.db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 8 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
  });
  tearDown(() => t.close());

  Future<void> turnOn() async {
    final h = await t.db.habitsDao.ensureMovement();
    await habits.update(h.copyWith(active: true, offsetMinutes: 30));
  }

  Iterable<DateTime> fires() => gateway.scheduled.values
      .where((s) => s.payload?.startsWith('habit:') ?? false)
      .map((s) => s.fireAt.toLocal());

  test('off by default: no reminders', () async {
    await habits.resync();
    expect(fires(), isEmpty);
  });

  test('on: one reminder a day, 30 min after waking', () async {
    await turnOn();
    expect(fires(), hasLength(7));
    expect(fires().first, DateTime(2026, 11, 16, 7)); // wake 06:30 + 30
  });

  test('done today cancels the rest of today only', () async {
    await turnOn();
    await habits.setDoneToday(true);
    expect(fires().any((d) => d.day == 16), isFalse);
    expect(fires(), hasLength(6));
  });

  test('the notification "Done" and "Not today" buttons are handled', () async {
    await turnOn();
    final id = (await t.db.habitsDao.ensureMovement()).id;
    final handled = await habits.handle(
      ReminderResponse(
        payload: reminderPayload(ReminderKind.habit, id),
        actionId: ReminderActionIds.notToday,
      ),
    );
    expect(handled, isTrue);
    expect(fires().any((d) => d.day == 16), isFalse);
    // Not today is not "done": the weekly count stays honest.
    expect(await t.db.habitsDao.isDone(id, start), isFalse);
  });

  test('low-energy mode pauses the habit reminder', () async {
    await turnOn();
    await t.db.settingsDao.setLowEnergy(true);
    await habits.resync();
    expect(fires(), isEmpty);
  });

  test('responses for other kinds are left alone', () async {
    expect(
      await habits.handle(
        const ReminderResponse(payload: 'wake:1', actionId: 'done'),
      ),
      isFalse,
    );
  });
}
