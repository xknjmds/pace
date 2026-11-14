import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/local_notification_gateway.dart';
import 'core/notifications/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationGateway();
  await notifications.initialize();
  runApp(
    ProviderScope(
      overrides: [notificationGatewayProvider.overrideWithValue(notifications)],
      child: const PaceApp(),
    ),
  );
}
