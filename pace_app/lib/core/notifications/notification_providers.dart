import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import '../time/clock.dart';
import 'notification_gateway.dart';
import 'notification_permissions.dart';
import 'reminder_scheduler.dart';

/// The app's notification gateway. `main` overrides this with an initialised
/// [LocalNotificationGateway]; tests override it with a fake. Reading it
/// without an override is a programming error, hence the throw.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (_) => throw UnimplementedError(
    'notificationGatewayProvider must be overridden at the ProviderScope',
  ),
);

/// Current permission state. Invalidate after a request or when the app
/// resumes, since the user may have changed things in system settings.
final notificationPermissionsProvider = FutureProvider<NotificationPermissions>(
  (ref) => ref.watch(notificationGatewayProvider).permissions(),
);

/// Reminders Android still holds for us.
final pendingRemindersProvider = FutureProvider<List<PendingReminder>>(
  (ref) => ref.watch(notificationGatewayProvider).pending(),
);

/// Schedules reminders through the table and the gateway together.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(
    db: ref.watch(appDatabaseProvider),
    gateway: ref.watch(notificationGatewayProvider),
    now: ref.watch(clockProvider),
  ),
);
