import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_gateway.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/reminder_response_router.dart';
import 'features/deadlines/application/deadline_providers.dart';
import 'features/routine/application/routine_providers.dart';

/// Builds the app's provider container and brings reminders in line with
/// the data: Android gets exactly the table's rows, the routine is planned
/// for the coming week, and a notification tap or button that started or
/// resumed the app is applied.
///
/// [container] lets tests supply a container with their own overrides; the
/// gateway override is added in `main` through [containerFor].
Future<ProviderContainer> bootstrap(
  NotificationGateway gateway, {
  ProviderContainer? container,
}) async {
  container ??= containerFor(gateway);
  await container.read(reminderSchedulerProvider).rebuildAll();
  await container.read(routineRemindersProvider).resync();
  await container.read(deadlineRemindersProvider).resyncAll();

  final router = ReminderResponseRouter([
    container.read(routineRemindersProvider).handle,
    container.read(deadlineRemindersProvider).handle,
  ]);
  final launch = await gateway.launchResponse();
  if (launch != null) await router.dispatch(launch);
  // Lives as long as the app; the gateway's stream is app-scoped too.
  gateway.responses.listen(router.dispatch);
  return container;
}

/// The app's container: the real gateway plus any extra overrides.
ProviderContainer containerFor(NotificationGateway gateway) =>
    ProviderContainer(
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
