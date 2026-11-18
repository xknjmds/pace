import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/time/clock.dart';
import 'habit_service.dart';

final habitServiceProvider = Provider<HabitService>(
  (ref) => HabitService(
    db: ref.watch(appDatabaseProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    now: ref.watch(clockProvider),
  ),
);

/// The movement habit (null until first created).
final movementHabitProvider = StreamProvider<Habit?>(
  (ref) => ref.watch(appDatabaseProvider).habitsDao.watchMovement(),
);

/// Whether the habit is done on the day keyed `yyyy-MM-dd`.
final habitDoneProvider = StreamProvider.family<bool, String>((ref, key) {
  final habit = ref.watch(movementHabitProvider).value;
  if (habit == null) return Stream.value(false);
  return ref
      .watch(appDatabaseProvider)
      .habitsDao
      .watchDone(habit.id, DateTime.parse(key));
});
