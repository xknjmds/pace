import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/local_notification_gateway.dart';
import 'startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationGateway();
  await notifications.initialize();
  final container = await bootstrap(notifications);
  runApp(
    UncontrolledProviderScope(container: container, child: const PaceApp()),
  );
}
