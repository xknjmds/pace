/// Fixed notification ids. M2 only. From M3 on, ids come from the
/// `scheduled_notifications` table (CLAUDE.md rule 2) and this file goes away.
abstract final class NotificationIds {
  /// The one-off "test reminder" the setup screen sends.
  static const int spikeTest = 1;
}

/// Android notification channels. Channel settings are owned by the user
/// after creation, so ids are stable and names are calm.
abstract final class NotificationChannels {
  static const String reminders = 'pace_reminders';
  static const String remindersName = 'Reminders';
  static const String remindersDescription =
      'Wake, eat, leave and deadline reminders';
}
