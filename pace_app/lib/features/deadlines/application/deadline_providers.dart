import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/time/clock.dart';
import 'deadline_reminders_service.dart';

final deadlineRemindersProvider = Provider<DeadlineReminders>(
  (ref) => DeadlineReminders(
    db: ref.watch(appDatabaseProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    now: ref.watch(clockProvider),
  ),
);

final pendingTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(appDatabaseProvider).tasksDao.watchPending(),
);

final submittedTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(appDatabaseProvider).tasksDao.watchSubmitted(),
);
