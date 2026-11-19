import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/db/database_provider.dart';
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
  registerFontLicense();
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
  // A fresh install opens on the first-run setup, over Today.
  var needsSetup = false;
  await report.guard('setup check', () async {
    final s = await container.read(appDatabaseProvider).settingsDao.get();
    needsSetup = s.onboardedAt == null;
  });
  Uri? launchedWith;
  if (features.homeWidget) {
    await report.guard('widget launch', () async {
      launchedWith = await HomeWidget.initiallyLaunchedFromHomeWidget();
    });
  }
  final widgetRoute = routeForWidgetUri(launchedWith);
  final initialRoute =
      fromNotification ??
      widgetRoute ??
      (needsSetup ? Routes.setup : Routes.today);
  // Always reached: whatever failed above, the app opens.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PaceApp(
        initialRoute: initialRoute,
        // Only a plain cold start gets the splash hand-off; a tap on a
        // reminder or the widget goes straight where it points.
        showIntro: fromNotification == null && widgetRoute == null,
      ),
    ),
  );
}

/// Figtree ships with the app under the SIL Open Font License.
void registerFontLicense() => LicenseRegistry.addLicense(() async* {
  final text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(const ['Figtree'], text);
});
