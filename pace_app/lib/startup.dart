import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/database_provider.dart';
import 'core/startup_report.dart';
import 'core/home_widget/home_widget_bridge.dart';
import 'core/home_widget/home_widget_providers.dart';
import 'core/notifications/notification_gateway.dart';
import 'core/notifications/notification_providers.dart';
import 'core/db/app_database.dart';
import 'core/notifications/reminder_actions.dart';
import 'core/notifications/reminder_response_router.dart';
import 'features/deadlines/application/deadline_providers.dart';
import 'features/focus/application/focus_providers.dart';
import 'features/inbox/application/inbox_providers.dart';
import 'features/routine/application/routine_providers.dart';
import 'routes.dart';

/// Brings reminders, the capture shortcut and the home-screen widget in
/// line with the data, then applies whatever started the app: a
/// notification button, or a widget tap ([widgetTaps] while running).
///
/// Returns the screen a notification tap asked for on a cold start, if any.
Future<String?> bootstrap(
  NotificationGateway gateway, {
  required ProviderContainer container,
  Stream<Uri?> widgetTaps = const Stream.empty(),
}) async {
  // Each step is guarded on its own: a failing plugin must never stop the
  // app from opening, nor stop the steps that do not depend on it.
  final report = container.read(startupReportProvider);
  await report.guard(
    'rebuild reminders',
    () => container.read(reminderSchedulerProvider).rebuildAll(),
  );
  await report.guard(
    'plan routine',
    () => container.read(routineRemindersProvider).resync(),
  );
  await report.guard(
    'plan deadlines',
    () => container.read(deadlineRemindersProvider).resyncAll(),
  );

  final capture = container.read(inboxCaptureProvider);
  await report.guard('widget count', capture.publishCount);
  await report.guard('capture shortcut', capture.syncShortcut);
  // Keep the widget's count right whatever changes the inbox.
  final widget = container.read(homeWidgetBridgeProvider);
  container
      .read(appDatabaseProvider)
      .inboxDao
      .watchUnprocessedCount()
      .listen(
        (n) => report.guard('widget count', () => widget.publishInboxCount(n)),
      );

  final router = ReminderResponseRouter([
    container.read(routineRemindersProvider).handle,
    container.read(deadlineRemindersProvider).handle,
    capture.handle,
    container.read(focusServiceProvider).handle,
  ]);
  ReminderResponse? launch;
  await report.guard('launch response', () async {
    launch = await gateway.launchResponse();
    if (launch != null) await router.dispatch(launch!);
  });
  // Lives as long as the app; the gateway's stream is app-scoped too.
  gateway.responses.listen((r) async {
    await report.guard('notification response', () => router.dispatch(r));
    final route = routeForResponse(r);
    if (route != null) PaceApp.navigatorKey.currentState?.pushNamed(route);
  });

  widgetTaps.listen((uri) {
    final route = routeForWidgetUri(uri);
    if (route != null) PaceApp.navigatorKey.currentState?.pushNamed(route);
  });
  return launch == null ? null : routeForResponse(launch!);
}

/// Where a plain tap on a notification leads. Button presses are handled
/// in place and stay on whatever screen is open.
String? routeForResponse(ReminderResponse r) {
  if (r.actionId != null) return null;
  return switch (parseReminderPayload(r.payload)?.kind) {
    ReminderKind.windDown => Routes.checkIn,
    ReminderKind.focusEnd => Routes.focus,
    ReminderKind.deadline => Routes.deadlines,
    _ => null,
  };
}

/// Where a widget URI leads. Null means "nothing special".
String? routeForWidgetUri(Uri? uri) => switch (uri?.toString()) {
  HomeWidgetKeys.captureUri => Routes.inboxCapture,
  HomeWidgetKeys.todayUri => Routes.today,
  _ => null,
};

/// The app's container: the real gateway, widget bridge and startup report.
ProviderContainer containerFor(
  NotificationGateway gateway,
  HomeWidgetBridge widget,
  StartupReport report,
) => ProviderContainer(
  overrides: [
    notificationGatewayProvider.overrideWithValue(gateway),
    homeWidgetBridgeProvider.overrideWithValue(widget),
    startupReportProvider.overrideWithValue(report),
  ],
);
