import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/startup.dart';

import 'core/notifications/fake_notification_gateway.dart';

void main() {
  test(
    'bootstrap plans the routine and applies the launching response',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.weekdayScheduleDao.upsert(
        weekday: DateTime.monday,
        firstClassMinutes: 8 * 60 + 30,
        commuteMinutes: 30,
        prepMinutes: 30,
      );
      final now = DateTime(2026, 11, 16, 6, 31); // Monday, wake just fired
      final gateway = FakeNotificationGateway()
        ..launch = const ReminderResponse(
          payload: 'wake:1',
          actionId: ReminderActionIds.done,
        );

      final container = await bootstrap(
        gateway,
        container: ProviderContainer(
          overrides: [
            notificationGatewayProvider.overrideWithValue(gateway),
            appDatabaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => now),
          ],
        ),
      );
      addTearDown(container.dispose);

      expect(
        gateway.scheduled.values.map((s) => s.payload),
        containsAll(['eat:1', 'leave:1']),
      );
      expect((await db.dailyLogsDao.get(now))?.wakeLoggedAt, now.toUtc());

      // A later button press while running is routed too.
      gateway.responseController.add(
        const ReminderResponse(
          payload: 'eat:1',
          actionId: ReminderActionIds.notToday,
        ),
      );
      await pumpEventQueue(times: 50);
      expect(
        await db.reminderMutesDao.isMuted(ReminderKind.eat, '1', now),
        isTrue,
      );
    },
  );
}
