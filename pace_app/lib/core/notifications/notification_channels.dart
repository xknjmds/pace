/// Android notification channels. Channel settings are owned by the user
/// after creation, so ids are stable and names are calm.
abstract final class NotificationChannels {
  static const String reminders = 'pace_reminders';
  static const String remindersName = 'Reminders';
  static const String remindersDescription =
      'Wake, eat, leave and deadline reminders';

  /// Silent, low importance: the quick-capture shortcut lives here.
  static const String capture = 'pace_capture';
  static const String captureName = 'Quick capture';
  static const String captureDescription =
      'A quiet shortcut for writing a thought down';
}

/// Notification ids below 1000 are reserved for notifications that are
/// shown, not scheduled, and so are not rows in `scheduled_notifications`.
abstract final class FixedNotificationIds {
  static const int captureShortcut = 2;
}
