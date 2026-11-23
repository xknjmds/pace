import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this device can do. PACE runs everywhere Flutter does (Android, iOS,
/// web, desktop). Reminders and schedule photo import run on Android and iOS;
/// home-screen widgets, persistent notification capture and the app gate exist
/// only on Android; calendar sync works on Android, iOS and the web.
class PlatformFeatures {
  const PlatformFeatures({
    required this.reminders,
    required this.homeWidget,
    this.scheduleImport = false,
    this.appBlocking = false,
    this.calendarSync = false,
    this.androidReminderChecks = false,
    this.persistentCapture = false,
  });

  /// Features of the device the app is running on right now. Calendar
  /// sync also needs a Google client id at build time; release builds
  /// without one (the Play launch, until Google verifies the app) hide it.
  factory PlatformFeatures.current() {
    final base = kIsWeb
        ? web
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => android,
            TargetPlatform.iOS => ios,
            _ => elsewhere,
          };
    if (calendarConfigured || !base.calendarSync) return base;
    return PlatformFeatures(
      reminders: base.reminders,
      homeWidget: base.homeWidget,
      scheduleImport: base.scheduleImport,
      appBlocking: base.appBlocking,
      androidReminderChecks: base.androidReminderChecks,
      persistentCapture: base.persistentCapture,
    );
  }

  /// Built with `--dart-define=PACE_GOOGLE_CLIENT_ID=...`.
  static const calendarConfigured =
      String.fromEnvironment('PACE_GOOGLE_CLIENT_ID') != '';

  static const android = PlatformFeatures(
    reminders: true,
    homeWidget: true,
    scheduleImport: true,
    appBlocking: true,
    calendarSync: true,
    androidReminderChecks: true,
    persistentCapture: true,
  );
  static const ios = PlatformFeatures(
    reminders: true,
    homeWidget: false,
    scheduleImport: true,
    appBlocking: false,
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

  /// Scheduled notifications (wake, leave, deadlines, ...).
  final bool reminders;

  /// Home-screen widgets (quick capture, today's classes).
  final bool homeWidget;

  /// Reading a photo of the class schedule on the device (ML Kit).
  final bool scheduleImport;

  /// The app gate (usage access and an overlay).
  final bool appBlocking;

  /// Read-only Google Calendar.
  final bool calendarSync;

  /// Android-only exact alarm, battery optimisation, and OEM auto-start checks.
  final bool androidReminderChecks;

  /// Android-only ongoing notification with inline reply for quick capture.
  final bool persistentCapture;
}

/// Overridable in tests to render either version of a screen.
final platformFeaturesProvider = Provider<PlatformFeatures>(
  (_) => PlatformFeatures.current(),
);

/// Platforms PACE does not build for at all.
bool get isUnsupportedPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.fuchsia;
