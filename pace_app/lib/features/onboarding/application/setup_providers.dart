import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/time/clock.dart';
import '../../routine/application/routine_providers.dart';
import '../../today/application/reminder_resync.dart';
import 'setup_service.dart';

final setupServiceProvider = Provider<SetupService>(
  (ref) => SetupService(
    db: ref.watch(appDatabaseProvider),
    routine: ref.watch(routineRemindersProvider),
    resync: ref.read(reminderResyncProvider),
    now: ref.watch(clockProvider),
  ),
);
