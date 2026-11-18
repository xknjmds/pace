import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../routine/application/routine_providers.dart';

/// Re-plans every reminder that depends on settings: the routine (wake,
/// eat, leave, wind-down) and every deadline's nudges. Call after any
/// change to wake time, sleep, schedule or low-energy mode.
final reminderResyncProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await ref.read(routineRemindersProvider).resync();
    await ref.read(deadlineRemindersProvider).resyncAll();
  },
);

/// Turns low-energy mode on or off and makes reminders match at once, so
/// Today and the notification shade never disagree.
final setLowEnergyProvider = Provider<Future<void> Function(bool)>(
  (ref) => (on) async {
    await ref.read(appDatabaseProvider).settingsDao.setLowEnergy(on);
    await ref.read(reminderResyncProvider)();
  },
);
