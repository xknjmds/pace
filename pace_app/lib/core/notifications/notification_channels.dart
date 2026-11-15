/// Android notification channels. Channel settings are owned by the user
/// after creation, so ids are stable and names are calm.
abstract final class NotificationChannels {
  static const String reminders = 'pace_reminders';
  static const String remindersName = 'Reminders';
  static const String remindersDescription =
      'Wake, eat, leave and deadline reminders';
}
