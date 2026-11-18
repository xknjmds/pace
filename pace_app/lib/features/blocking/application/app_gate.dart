import 'package:flutter/services.dart';

import '../domain/lock_windows.dart';

/// What the gate needs from Android before it can work.
class GatePermissions {
  const GatePermissions({required this.usageAccess, required this.overlay});

  /// "Usage access": lets the gate see which app is in front.
  final bool usageAccess;

  /// "Display over other apps": lets the block screen appear.
  final bool overlay;

  bool get ready => usageAccess && overlay;
}

class InstalledApp {
  const InstalledApp(this.packageName, this.label);

  final String packageName;
  final String label;
}

/// Everything sent to the native gate service. Windows are absolute
/// instants, so the service needs no knowledge of the routine.
class GateConfig {
  const GateConfig({
    required this.enabled,
    this.windows = const [],
    this.packages = const [],
    this.unlockMinutes = 10,
  });

  final bool enabled;
  final List<LockWindow> windows;
  final List<String> packages;
  final int unlockMinutes;

  Map<String, Object?> toMap() => {
    'enabled': enabled,
    'packages': packages,
    'unlockMinutes': unlockMinutes,
    'windows': [
      for (final w in windows)
        {
          'start': w.start.millisecondsSinceEpoch,
          'end': w.end.millisecondsSinceEpoch,
          'reason': w.reason.name,
        },
    ],
  };
}

/// The native app gate (Android only). Behind an interface so tests and
/// other platforms use a stand-in.
abstract interface class AppGate {
  Future<GatePermissions> permissions();
  Future<void> openUsageAccessSettings();
  Future<void> openOverlaySettings();
  Future<List<InstalledApp>> installedApps();
  Future<void> configure(GateConfig config);

  /// When the current emergency unlock ends, if one is running.
  Future<DateTime?> unlockedUntil();

  /// Emergency unlock, always allowed.
  Future<void> unlockFor(int minutes);
}

class ChannelAppGate implements AppGate {
  const ChannelAppGate();

  static const _channel = MethodChannel('com.el.pace/gate');

  /// Calls [method]; without the native side (tests, a broken build) the
  /// gate simply does nothing.
  static Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<GatePermissions> permissions() async {
    final m = await _call<Map<Object?, Object?>>('permissions');
    return GatePermissions(
      usageAccess: m?['usageAccess'] == true,
      overlay: m?['overlay'] == true,
    );
  }

  @override
  Future<void> openUsageAccessSettings() =>
      _call<void>('openUsageAccessSettings');

  @override
  Future<void> openOverlaySettings() => _call<void>('openOverlaySettings');

  @override
  Future<List<InstalledApp>> installedApps() async {
    final list = await _call<List<Object?>>('installedApps');
    return [
      for (final m in (list ?? const []).cast<Map<Object?, Object?>>())
        InstalledApp(m['package']! as String, m['label']! as String),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  @override
  Future<void> configure(GateConfig config) =>
      _call<void>('configure', config.toMap());

  @override
  Future<DateTime?> unlockedUntil() async {
    final ms = await _call<int>('unlockedUntil');
    if (ms == null || ms <= 0) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    return t.isAfter(DateTime.now()) ? t : null;
  }

  @override
  Future<void> unlockFor(int minutes) =>
      _call<void>('unlockFor', {'minutes': minutes});
}

/// Web and desktop: there is nothing to gate.
class NoAppGate implements AppGate {
  const NoAppGate();

  @override
  Future<GatePermissions> permissions() async =>
      const GatePermissions(usageAccess: false, overlay: false);
  @override
  Future<void> openUsageAccessSettings() async {}
  @override
  Future<void> openOverlaySettings() async {}
  @override
  Future<List<InstalledApp>> installedApps() async => const [];
  @override
  Future<void> configure(GateConfig config) async {}
  @override
  Future<DateTime?> unlockedUntil() async => null;
  @override
  Future<void> unlockFor(int minutes) async {}
}
