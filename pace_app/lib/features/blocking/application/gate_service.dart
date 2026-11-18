import '../../../core/db/app_database.dart';
import '../../routine/application/day_times.dart';
import '../domain/lock_windows.dart';
import 'app_gate.dart';

/// Turns settings, the routine and the blocked-app list into the native
/// gate's configuration. The master switch off always sends "disabled",
/// so turning the gate off removes all blocking (CLAUDE.md rule 11).
class GateService {
  GateService({required this.db, required this.gate, required this.now});

  final AppDatabase db;
  final AppGate gate;
  final DateTime Function() now;

  /// The configuration for right now. Pure apart from reading the data.
  Future<GateConfig> currentConfig() async {
    final s = await db.settingsDao.get();
    if (!s.gateEnabled) return const GateConfig(enabled: false);
    final apps = await db.blockedAppsDao.getAll();
    if (apps.isEmpty) return const GateConfig(enabled: false);
    final t = now();
    final logs = await db.dailyLogsDao.between(
      t.subtract(const Duration(days: 1)),
      t.add(const Duration(days: 7)),
    );
    final windows = lockWindows(
      now: t,
      timesFor: await loadRoutineTimes(db),
      morningLock: s.morningLockEnabled,
      windDownLock: s.windDownLockEnabled,
      routineDoneDays: {
        for (final l in logs)
          if (l.routineDone) l.date,
      },
      lowEnergy: s.lowEnergyEnabled,
    );
    return GateConfig(
      enabled: true,
      windows: windows,
      packages: [for (final a in apps) a.packageName],
      unlockMinutes: s.unlockMinutes,
    );
  }

  Future<void> sync() async => gate.configure(await currentConfig());

  Future<void> setEnabled(bool on) async {
    await db.settingsDao.updateSettings((s) => s.copyWith(gateEnabled: on));
    await sync();
  }

  Future<void> updateSettings(Setting Function(Setting) change) async {
    await db.settingsDao.updateSettings(change);
    await sync();
  }

  Future<void> setBlocked(InstalledApp app, bool blocked) async {
    if (blocked) {
      await db.blockedAppsDao.add(app.packageName, app.label);
    } else {
      await db.blockedAppsDao.remove(app.packageName);
    }
    await sync();
  }
}
