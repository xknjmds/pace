import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/database_provider.dart';
import 'core/home_widget/home_widget_bridge.dart';
import 'core/home_widget/home_widget_providers.dart';
import 'core/notifications/notification_gateway.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/reminder_response_router.dart';
import 'features/deadlines/application/deadline_providers.dart';
import 'features/inbox/application/inbox_providers.dart';
import 'features/routine/application/routine_providers.dart';
import 'routes.dart';

/// Brings reminders, the capture shortcut and the home-screen widget in
/// line with the data, then applies whatever started the app: a
/// notification button, or a widget tap ([widgetTaps] while running).
Future<void> bootstrap(
  NotificationGateway gateway, {
  required ProviderContainer container,
  Stream<Uri?> widgetTaps = const Stream.empty(),
}) async {
  await container.read(reminderSchedulerProvider).rebuildAll();
  await container.read(routineRemindersProvider).resync();
  await container.read(deadlineRemindersProvider).resyncAll();

  final capture = container.read(inboxCaptureProvider);
  await capture.publishCount();
  await capture.syncShortcut();
  // Keep the widget's count right whatever changes the inbox.
  container
      .read(appDatabaseProvider)
      .inboxDao
      .watchUnprocessedCount()
      .listen(container.read(homeWidgetBridgeProvider).publishInboxCount);

  final router = ReminderResponseRouter([
    container.read(routineRemindersProvider).handle,
    container.read(deadlineRemindersProvider).handle,
    capture.handle,
  ]);
  final launch = await gateway.launchResponse();
  if (launch != null) await router.dispatch(launch);
  // Lives as long as the app; the gateway's stream is app-scoped too.
  gateway.responses.listen(router.dispatch);

  widgetTaps.listen((uri) {
    final route = routeForWidgetUri(uri);
    if (route != null) PaceApp.navigatorKey.currentState?.pushNamed(route);
  });
}

/// Where a widget URI leads. Null means "nothing special".
String? routeForWidgetUri(Uri? uri) => switch (uri?.toString()) {
  HomeWidgetKeys.captureUri => Routes.inboxCapture,
  HomeWidgetKeys.todayUri => Routes.today,
  _ => null,
};

/// The app's container: the real gateway and widget bridge.
ProviderContainer containerFor(
  NotificationGateway gateway,
  HomeWidgetBridge widget,
) => ProviderContainer(
  overrides: [
    notificationGatewayProvider.overrideWithValue(gateway),
    homeWidgetBridgeProvider.overrideWithValue(widget),
  ],
);
