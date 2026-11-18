import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import 'app_gate.dart';
import 'gate_service.dart';

final appGateProvider = Provider<AppGate>(
  (ref) => ref.watch(platformFeaturesProvider).appBlocking
      ? const ChannelAppGate()
      : const NoAppGate(),
);

final gateServiceProvider = Provider<GateService>(
  (ref) => GateService(
    db: ref.watch(appDatabaseProvider),
    gate: ref.watch(appGateProvider),
    now: ref.watch(clockProvider),
  ),
);

final blockedAppsProvider = StreamProvider<List<BlockedApp>>(
  (ref) => ref.watch(appDatabaseProvider).blockedAppsDao.watchAll(),
);

/// Invalidate after returning from system settings.
final gatePermissionsProvider = FutureProvider<GatePermissions>(
  (ref) => ref.watch(appGateProvider).permissions(),
);

final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.watch(appGateProvider).installedApps(),
);

final unlockedUntilProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(appGateProvider).unlockedUntil(),
);
