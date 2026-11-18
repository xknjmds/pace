import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/home_widget/home_widget_bridge.dart';
import 'core/home_widget/home_widget_bridge_impl.dart';
import 'core/home_widget/noop_home_widget_bridge.dart';
import 'core/notifications/local_notification_gateway.dart';
import 'core/notifications/noop_notification_gateway.dart';
import 'core/notifications/notification_gateway.dart';
import 'core/platform/platform_features.dart';
import 'core/startup_report.dart';
import 'core/widgets/unsupported_platform_app.dart';
import 'features/inbox/application/capture_background.dart';
import 'routes.dart';
import 'startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isUnsupportedPlatform) {
    runApp(const UnsupportedPlatformApp());
    return;
  }
  // Android gets real reminders and the home-screen widget; web and
  // desktop get quiet stand-ins and everything else works the same.
  final features = PlatformFeatures.current();
  final report = StartupReport();
  final NotificationGateway notifications = features.reminders
      ? LocalNotificationGateway(
          backgroundHandler: captureFromNotificationBackground,
        )
      : const NoopNotificationGateway();
  final HomeWidgetBridge widget = features.homeWidget
      ? const HomeWidgetBridgeImpl()
      : const NoopHomeWidgetBridge();

  await report.guard('notifications', notifications.initialize);
  final container = containerFor(notifications, widget, report);
  String? fromNotification;
  await report.guard('startup', () async {
    fromNotification = await bootstrap(
      notifications,
      container: container,
      widgetTaps: features.homeWidget
          ? HomeWidget.widgetClicked
          : const Stream.empty(),
    );
  });
  Uri? launchedWith;
  if (features.homeWidget) {
    await report.guard('widget launch', () async {
      launchedWith = await HomeWidget.initiallyLaunchedFromHomeWidget();
    });
  }
  // Always reached: whatever failed above, the app opens.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PaceApp(
        initialRoute:
            fromNotification ?? routeForWidgetUri(launchedWith) ?? Routes.today,
      ),
    ),
  );
}
