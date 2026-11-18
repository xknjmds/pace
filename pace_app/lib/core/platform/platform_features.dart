import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this device can do. PACE runs everywhere Flutter does (Android,
/// web, desktop). Scheduled reminders, notification buttons, home-screen
/// widgets, reading a schedule photo and the app gate exist only on
/// Android; calendar sync works on Android and the web.
class PlatformFeatures {
  const PlatformFeatures({
    required this.reminders,
    required this.homeWidget,
    this.scheduleImport = false,
    this.appBlocking = false,
    this.calendarSync = false,
  });

  /// Features of the device the app is running on right now.
  factory PlatformFeatures.current() {
    if (kIsWeb) return web;
    return defaultTargetPlatform == TargetPlatform.android
        ? android
        : elsewhere;
  }

  static const android = PlatformFeatures(
    reminders: true,
    homeWidget: true,
    scheduleImport: true,
    appBlocking: true,
    calendarSync: true,
  );
  static const web = PlatformFeatures(
    reminders: false,
    homeWidget: false,
    calendarSync: true,
  );
  static const elsewhere = PlatformFeatures(
    reminders: false,
    homeWidget: false,
  );

  /// Scheduled notifications with buttons (wake, leave, deadlines, ...).
  final bool reminders;

  /// Home-screen widgets (quick capture, today's classes).
  final bool homeWidget;

  /// Reading a photo of the class schedule on the device (ML Kit).
  final bool scheduleImport;

  /// The app gate (usage access and an overlay).
  final bool appBlocking;

  /// Read-only Google Calendar.
  final bool calendarSync;
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
