import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/home_widget/home_widget_bridge_impl.dart';
import 'core/startup_report.dart';
import 'core/widgets/unsupported_platform_app.dart';
import 'core/notifications/local_notification_gateway.dart';
import 'features/inbox/application/capture_background.dart';
import 'routes.dart';
import 'startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android only (CLAUDE.md). Anywhere else, say so instead of crashing on
  // the first database or plugin call.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    runApp(const UnsupportedPlatformApp());
    return;
  }
  final report = StartupReport();
  final notifications = LocalNotificationGateway(
    backgroundHandler: captureFromNotificationBackground,
  );
  await report.guard('notifications', notifications.initialize);
  final container = containerFor(
    notifications,
    const HomeWidgetBridgeImpl(),
    report,
  );
  String? fromNotification;
  await report.guard('startup', () async {
    fromNotification = await bootstrap(
      notifications,
      container: container,
      widgetTaps: HomeWidget.widgetClicked,
    );
  });
  Uri? launchedWith;
  await report.guard('widget launch', () async {
    launchedWith = await HomeWidget.initiallyLaunchedFromHomeWidget();
  });
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
