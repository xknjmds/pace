/// What the home-screen widget needs to know. Behind an interface so the
/// app and the background isolate can publish, and tests can observe.
abstract interface class HomeWidgetBridge {
  Future<void> publishInboxCount(int count);
}

/// Values shared with the Kotlin widget provider through home_widget.
abstract final class HomeWidgetKeys {
  static const inboxCount = 'inbox_count';

  /// Kotlin class name of the provider, in `com.el.pace`.
  static const androidProvider = 'PaceWidgetProvider';

  /// URIs the widget launches the app with.
  static const captureUri = 'pace://capture';
  static const todayUri = 'pace://today';
}
