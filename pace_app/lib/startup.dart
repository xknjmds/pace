import 'package:flutter/widgets.dart' show AppLifecycleListener;
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
import 'core/platform/platform_features.dart';
import 'features/blocking/application/gate_providers.dart';
import 'features/calendar/application/calendar_providers.dart';
import 'features/deadlines/application/deadline_providers.dart';
import 'features/habits/application/habit_providers.dart';
import 'features/schedule/application/schedule_providers.dart';
import 'features/focus/application/focus_providers.dart';
import 'features/inbox/application/inbox_providers.dart';
import 'features/routine/application/routine_providers.dart';
import 'features/shell/shell_tabs.dart';
import 'features/today/application/reminder_resync.dart';
import 'features/verse/application/verse_providers.dart';
import 'features/wellbeing/application/wellbeing_providers.dart';
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
  // First, so a return after time away plans today as a light day.
  await report.guard(
    'welcome back',
    () => container.read(wellbeingServiceProvider).noteOpened(),
  );
  await report.guard(
    'rebuild reminders',
    () => container.read(reminderSchedulerProvider).rebuildAll(),
  );
  await report.guard('verses', () => container.read(versesProvider.future));
  await report.guard(
    'plan routine',
    () => container.read(routineRemindersProvider).resync(),
  );
  await report.guard(
    'plan deadlines',
    () => container.read(deadlineRemindersProvider).resyncAll(),
  );
  await report.guard(
    'plan habit',
    () => container.read(habitServiceProvider).resync(),
  );
  await report.guard(
    'app gate',
    () => container.read(gateServiceProvider).sync(),
  );
  await report.guard(
    'schedule widget',
    () => container.read(scheduleServiceProvider).publishWidget(),
  );
  // Optional and online: never awaited, so a slow network never holds up
  // the app opening.
  _refreshCalendar(container, report);

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

  // Finishing the morning routine opens the gate at once, wherever it was
  // marked done (Today, a notification button).
  final db = container.read(appDatabaseProvider);
  final bootNow = DateTime.now();
  db.dailyLogsDao
      .watchBetween(
        bootNow.subtract(const Duration(days: 1)),
        bootNow.add(const Duration(days: 7)),
      )
      .map(
        (logs) => [
          for (final l in logs)
            if (l.routineDone) l.date,
        ].join(),
      )
      .distinct()
      .skip(1)
      .listen(
        (_) => report.guard(
          'app gate',
          () => container.read(gateServiceProvider).sync(),
        ),
      );
  // Back in the foreground: lock windows move with the clock, and the
  // calendar may be stale.
  // Registers itself with the binding and lives as long as the app.
  AppLifecycleListener(
    onResume: () {
      report.guard('welcome back', () async {
        final back = await container
            .read(wellbeingServiceProvider)
            .noteOpened();
        if (back) await container.read(reminderResyncProvider)();
      });
      report.guard(
        'app gate',
        () => container.read(gateServiceProvider).sync(),
      );
      _refreshCalendar(container, report);
    },
  );

  final router = ReminderResponseRouter([
    container.read(routineRemindersProvider).handle,
    container.read(deadlineRemindersProvider).handle,
    container.read(habitServiceProvider).handle,
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
    if (route != null) _open(container, route);
  });

  widgetTaps.listen((uri) {
    final route = routeForWidgetUri(uri);
    if (route != null) _open(container, route);
  });
  return launch == null ? null : routeForResponse(launch!);
}

void _refreshCalendar(ProviderContainer container, StartupReport report) {
  if (!container.read(platformFeaturesProvider).calendarSync) return;
  // A failed refresh is quiet: the cache keeps showing the last events.
  container
      .read(calendarServiceProvider)
      .refreshIfStale()
      .catchError((_) => null);
}

void _open(ProviderContainer container, String route) => Routes.open(
  PaceApp.navigatorKey.currentState,
  container.read(shellRequestProvider.notifier),
  route,
);

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
  HomeWidgetKeys.scheduleUri => Routes.schedule,
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
