import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/local_notification_gateway.dart';
import 'core/notifications/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationGateway();
  await notifications.initialize();
  final container = ProviderContainer(
    overrides: [notificationGatewayProvider.overrideWithValue(notifications)],
  );
  // Android is told exactly what the table says, every launch (rule 2).
  await container.read(reminderSchedulerProvider).rebuildAll();
  runApp(
    UncontrolledProviderScope(container: container, child: const PaceApp()),
  );
}
