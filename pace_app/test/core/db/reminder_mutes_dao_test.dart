import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  final day = DateTime(2026, 11, 14);

  test('mute is per kind, owner and day, and idempotent', () async {
    final dao = t.db.reminderMutesDao;
    final m = await dao.mute(ReminderKind.deadline, 'task-1', day);
    final again = await dao.mute(ReminderKind.deadline, 'task-1', day);
    expect(again.id, m.id);
    expect(await dao.isMuted(ReminderKind.deadline, 'task-1', day), isTrue);
    expect(
      await dao.isMuted(
        ReminderKind.deadline,
        'task-1',
        day.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(await dao.isMuted(ReminderKind.wake, 'task-1', day), isFalse);
    expect(await dao.mutesOn(day), hasLength(1));
  });

  test('unmute soft-deletes and a later mute revives the row', () async {
    final dao = t.db.reminderMutesDao;
    final m = await dao.mute(ReminderKind.wake, '1', day);
    await dao.unmute(ReminderKind.wake, '1', day);
    expect(await dao.isMuted(ReminderKind.wake, '1', day), isFalse);
    expect(await dao.mutesOn(day), isEmpty);
    final back = await dao.mute(ReminderKind.wake, '1', day);
    expect(back.id, m.id);
    expect(back.deletedAt, isNull);
    expect(await dao.isMuted(ReminderKind.wake, '1', day), isTrue);
  });
}
