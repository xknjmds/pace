import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/home_widget/home_widget_providers.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../today/application/reminder_resync.dart';
import 'schedule_reader.dart';
import 'schedule_service.dart';

final classBlocksProvider = StreamProvider<List<ClassBlock>>(
  (ref) => ref.watch(appDatabaseProvider).classBlocksDao.watchAll(),
);

final scheduleReaderProvider = Provider<ScheduleReader>(
  (ref) => ref.watch(platformFeaturesProvider).scheduleImport
      ? const MlKitScheduleReader()
      : const NoScheduleReader(),
);

final Provider<ScheduleService> scheduleServiceProvider = Provider(
  (ref) => ScheduleService(
    db: ref.watch(appDatabaseProvider),
    widget: ref.watch(homeWidgetBridgeProvider),
    resyncReminders: () => ref.read(reminderResyncProvider)(),
    now: ref.watch(clockProvider),
  ),
);
