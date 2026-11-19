import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../schedule/application/schedule_providers.dart';
import '../domain/getting_started.dart';

final _anyDeadlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).tasksDao.watchAny(),
);

final _anyInboxProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).inboxDao.watchAny(),
);

final _anyFocusProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).focusSessionsDao.watchAny(),
);

/// The Getting started steps, ticked from what is already in the app.
final gettingStartedStepsProvider = Provider<List<GettingStartedStep>>((ref) {
  final reminders = ref.watch(platformFeaturesProvider).reminders;
  return gettingStartedSteps(
    GettingStartedFacts(
      hasClasses: (ref.watch(classBlocksProvider).value ?? const []).isNotEmpty,
      hasDeadline: ref.watch(_anyDeadlineProvider).value ?? false,
      hasInboxItem: ref.watch(_anyInboxProvider).value ?? false,
      hasFocusSession: ref.watch(_anyFocusProvider).value ?? false,
      remindersAllowed: reminders
          ? ref.watch(notificationPermissionsProvider).value?.canNotify ?? false
          : null,
    ),
  );
});

/// Whether Today shows the Getting started card right now.
final showGettingStartedProvider = Provider<bool>((ref) {
  final s = ref.watch(settingsProvider).value;
  if (s == null) return false;
  return showGettingStarted(
    onboardedAt: s.onboardedAt,
    closedAt: s.gettingStartedClosedAt,
    now: ref.watch(clockProvider)(),
    steps: ref.watch(gettingStartedStepsProvider),
    lowEnergy: ref.watch(lowEnergyProvider),
  );
});
