import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/time/clock.dart';
import '../../verse/application/verse_providers.dart';
import 'routine_reminders.dart';

final routineRemindersProvider = Provider<RoutineReminders>(
  (ref) => RoutineReminders(
    db: ref.watch(appDatabaseProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    now: ref.watch(clockProvider),
    // Only verses already loaded (startup loads them first): planning
    // never waits on an asset.
    loadVerses: () async => ref.read(versesProvider).value ?? const [],
  ),
);
