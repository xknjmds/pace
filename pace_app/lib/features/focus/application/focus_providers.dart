import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/time/clock.dart';
import 'focus_service.dart';

final focusServiceProvider = Provider<FocusService>(
  (ref) => FocusService(
    db: ref.watch(appDatabaseProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    now: ref.watch(clockProvider),
  ),
);

final activeFocusProvider = StreamProvider<FocusSession?>(
  (ref) => ref.watch(appDatabaseProvider).focusSessionsDao.watchActive(),
);

/// Once a second while a countdown is on screen. Tests override it with an
/// empty stream so the frame settles.
final secondTickProvider = StreamProvider.autoDispose<int>(
  (_) => Stream.periodic(const Duration(seconds: 1), (i) => i),
);
