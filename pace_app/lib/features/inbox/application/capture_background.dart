import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/db/app_database.dart';
import '../../../core/home_widget/home_widget_bridge_impl.dart';
import '../../../core/notifications/local_notification_gateway.dart';
import '../../../core/notifications/reminder_actions.dart';
import 'inbox_capture.dart';

/// Runs in the plugin's background isolate when the user replies to the
/// capture shortcut from the notification shade. The app is not opened.
/// Plugins are available because the background FlutterEngine registers
/// them; the database is opened fresh and closed again.
@pragma('vm:entry-point')
Future<void> captureFromNotificationBackground(
  NotificationResponse response,
) async {
  final db = AppDatabase.open();
  // Same handler as the app, so initialising here never clears it.
  final gateway = LocalNotificationGateway(
    backgroundHandler: captureFromNotificationBackground,
  );
  try {
    await gateway.initialize();
    await InboxCapture(
      db: db,
      gateway: gateway,
      widget: const HomeWidgetBridgeImpl(),
      now: DateTime.now,
    ).handle(
      ReminderResponse(
        payload: response.payload,
        actionId: response.actionId,
        input: response.input,
      ),
    );
  } catch (e, st) {
    debugPrint('PACE background capture failed: $e\n$st');
  } finally {
    await db.close();
  }
}
