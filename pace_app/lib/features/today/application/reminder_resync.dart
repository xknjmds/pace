import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../blocking/application/gate_providers.dart';
import '../../deadlines/application/deadline_providers.dart';
import '../../habits/application/habit_providers.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../routine/application/routine_providers.dart';

/// Re-plans everything that depends on settings and the routine: the
/// routine reminders (wake, eat, leave, wind-down), every deadline's
/// nudges, the movement habit, the app gate's lock windows and the
/// today's-classes widget. Call after any change to wake time, sleep,
/// schedule or low-energy mode.
final reminderResyncProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await ref.read(routineRemindersProvider).resync();
    await ref.read(deadlineRemindersProvider).resyncAll();
    await ref.read(habitServiceProvider).resync();
    await ref.read(gateServiceProvider).sync();
    await ref.read(scheduleServiceProvider).publishWidget();
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
