import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_features.dart';

/// The phone's maker and the brand settings pages reminders depend on.
/// Android only; elsewhere a quiet stand-in.
abstract interface class DeviceSettings {
  /// `Build.MANUFACTURER`, or empty when unknown.
  Future<String> manufacturer();

  /// Tries the brand's auto-start page. False when none could be opened;
  /// the app's own info page opens instead.
  Future<bool> openAutoStart();

  /// The system "App info" page for PACE.
  Future<void> openAppDetails();

  /// Screen on/unlock (true) and off (false) moments, from usage access.
  /// Empty without the permission. For the D8 sleep check spike.
  Future<List<(DateTime, bool)>> screenEvents(DateTime from, DateTime to);
}

class ChannelDeviceSettings implements DeviceSettings {
  const ChannelDeviceSettings();

  static const _channel = MethodChannel('com.el.pace/device');

  static Future<T?> _call<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String> manufacturer() async =>
      await _call<String>('manufacturer') ?? '';

  @override
  Future<bool> openAutoStart() async =>
      await _call<bool>('openAutoStart') ?? false;

  @override
  Future<void> openAppDetails() => _call<void>('openAppDetails');

  @override
  Future<List<(DateTime, bool)>> screenEvents(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final list = await _channel.invokeMethod<List<Object?>>('screenEvents', {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
      });
      return [
        for (final m in (list ?? const []).cast<Map<Object?, Object?>>())
          (
            DateTime.fromMillisecondsSinceEpoch((m['t']! as num).toInt()),
            m['on'] == true,
          ),
      ];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }
}

class NoDeviceSettings implements DeviceSettings {
  const NoDeviceSettings();

  @override
  Future<String> manufacturer() async => '';
  @override
  Future<bool> openAutoStart() async => false;
  @override
  Future<void> openAppDetails() async {}
  @override
  Future<List<(DateTime, bool)>> screenEvents(
    DateTime from,
    DateTime to,
  ) async => const [];
}

final deviceSettingsProvider = Provider<DeviceSettings>(
  (ref) => ref.watch(platformFeaturesProvider).reminders
      ? const ChannelDeviceSettings()
      : const NoDeviceSettings(),
);

final manufacturerProvider = FutureProvider<String>(
  (ref) => ref.watch(deviceSettingsProvider).manufacturer(),
);
