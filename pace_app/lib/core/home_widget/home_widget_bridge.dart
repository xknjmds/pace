/// What the home-screen widget needs to know. Behind an interface so the
/// app and the background isolate can publish, and tests can observe.
abstract interface class HomeWidgetBridge {
  Future<void> publishInboxCount(int count);

  /// Today's-classes widget: the week's class blocks and upcoming events
  /// as JSON (built by `scheduleWidgetJson`). The widget works out the
  /// current block itself and wakes at each block boundary.
  Future<void> publishSchedule(String json);
}

/// Values shared with the Kotlin widget provider through home_widget.
abstract final class HomeWidgetKeys {
  static const inboxCount = 'inbox_count';

  /// Kotlin class name of the provider, in `com.el.pace`.
  static const androidProvider = 'PaceWidgetProvider';

  /// The today's-classes widget: its data key and Kotlin provider.
  static const schedule = 'schedule_json';
  static const scheduleProvider = 'PaceScheduleWidgetProvider';

  /// URIs the widget launches the app with.
  static const captureUri = 'pace://capture';
  static const todayUri = 'pace://today';
  static const scheduleUri = 'pace://schedule';
}
