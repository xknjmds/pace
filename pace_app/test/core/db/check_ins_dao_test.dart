import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  final day = DateTime(2026, 11, 19);

  test('record stores one row per day and step, and updates it', () async {
    final dao = t.db.checkInsDao;
    await dao.record(day, ReminderKind.wake, CheckInOutcome.onTime);
    t.tick();
    await dao.record(
      day,
      ReminderKind.wake,
      CheckInOutcome.later,
      actualAt: DateTime(2026, 11, 19, 7, 10),
      reason: '  Overslept ',
    );

    final row = (await dao.get(day, ReminderKind.wake))!;
    expect(row.outcome, CheckInOutcome.later);
    expect(row.actualAt, DateTime(2026, 11, 19, 7, 10).toUtc());
    expect(row.reason, 'Overslept');
    expect(row.updatedAt, t.now);
    expect(await dao.between(day, day), hasLength(1));
  });

  test('a blank reason is stored as null', () async {
    final dao = t.db.checkInsDao;
    await dao.record(day, ReminderKind.eat, CheckInOutcome.onTime, reason: ' ');
    expect((await dao.get(day, ReminderKind.eat))!.reason, isNull);
  });

  test('clear is a soft delete, and recording again revives the row', () async {
    final dao = t.db.checkInsDao;
    await dao.record(day, ReminderKind.leave, CheckInOutcome.didntHappen);
    await dao.clear(day, ReminderKind.leave);
    expect(await dao.get(day, ReminderKind.leave), isNull);
    expect(await dao.between(day, day), isEmpty);

    await dao.record(day, ReminderKind.leave, CheckInOutcome.onTime);
    expect(
      (await dao.get(day, ReminderKind.leave))!.outcome,
      CheckInOutcome.onTime,
    );
  });

  test('watchDay maps the day by step', () async {
    final dao = t.db.checkInsDao;
    await dao.record(day, ReminderKind.wake, CheckInOutcome.onTime);
    await dao.record(day, ReminderKind.eat, CheckInOutcome.didntHappen);
    final map = await dao.watchDay(day).first;
    expect(map.keys, {ReminderKind.wake, ReminderKind.eat});
    expect(map[ReminderKind.eat]!.outcome, CheckInOutcome.didntHappen);
  });

  group('tasks', () {
    test('submit at a picked time with a note', () async {
      final dao = t.db.tasksDao;
      final task = await dao.add(title: 'Essay', dueAt: DateTime(2026, 11, 18));
      final at = DateTime(2026, 11, 18, 9);
      await dao.setStatus(task.id, TaskStatus.submitted, at: at, note: 'Wi-Fi');
      final row = (await dao.getById(task.id))!;
      expect(row.submittedAt, at.toUtc());
      expect(row.submitNote, 'Wi-Fi');
    });

    test('let go closes the task and reopening clears the note', () async {
      final dao = t.db.tasksDao;
      final task = await dao.add(title: 'Lab', dueAt: DateTime(2026, 11, 18));
      await dao.setStatus(task.id, TaskStatus.letGo, note: 'Sick');
      expect(await dao.watchPending().first, isEmpty);
      expect((await dao.watchLetGo().first).single.submitNote, 'Sick');
      expect(
        await dao.submittedBetween(DateTime(2026), DateTime(2027)),
        isEmpty,
      );

      await dao.setStatus(task.id, TaskStatus.pending);
      final row = (await dao.getById(task.id))!;
      expect(row.status, TaskStatus.pending);
      expect(row.submittedAt, isNull);
      expect(row.submitNote, isNull);
    });
  });
}
