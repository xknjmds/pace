import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this device can do. PACE runs everywhere Flutter does (Android,
/// web, desktop); scheduled reminders, notification buttons and the
/// home-screen widget exist only on Android.
class PlatformFeatures {
  const PlatformFeatures({required this.reminders, required this.homeWidget});

  /// Features of the device the app is running on right now.
  factory PlatformFeatures.current() {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return PlatformFeatures(reminders: android, homeWidget: android);
  }

  static const android = PlatformFeatures(reminders: true, homeWidget: true);
  static const elsewhere = PlatformFeatures(
    reminders: false,
    homeWidget: false,
  );

  /// Scheduled notifications with buttons (wake, leave, deadlines, ...).
  final bool reminders;
  final bool homeWidget;
}

/// Overridable in tests to render either version of a screen.
final platformFeaturesProvider = Provider<PlatformFeatures>(
  (_) => PlatformFeatures.current(),
);

/// Platforms PACE does not build for at all (no iOS folder exists).
bool get isUnsupportedPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);
