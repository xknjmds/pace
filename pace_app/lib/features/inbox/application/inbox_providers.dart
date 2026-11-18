import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/home_widget/home_widget_providers.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/time/clock.dart';
import 'inbox_capture.dart';

final inboxCaptureProvider = Provider<InboxCapture>(
  (ref) => InboxCapture(
    db: ref.watch(appDatabaseProvider),
    gateway: ref.watch(notificationGatewayProvider),
    widget: ref.watch(homeWidgetBridgeProvider),
    now: ref.watch(clockProvider),
  ),
);

final inboxItemsProvider = StreamProvider<List<InboxItem>>(
  (ref) => ref.watch(appDatabaseProvider).inboxDao.watchUnprocessed(),
);

final inboxCountProvider = Provider<int>(
  (ref) => ref.watch(inboxItemsProvider).value?.length ?? 0,
);
