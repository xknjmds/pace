/// What Android currently lets PACE do with reminders. Pure value type so the
/// setup screen's logic can be unit tested without the plugin.
class NotificationPermissions {
  const NotificationPermissions({
    required this.notificationsGranted,
    required this.exactAlarmsAllowed,
    required this.batteryUnrestricted,
  });

  /// Nothing granted yet: the state of a fresh install on Android 13+.
  static const none = NotificationPermissions(
    notificationsGranted: false,
    exactAlarmsAllowed: false,
    batteryUnrestricted: false,
  );

  static const all = NotificationPermissions(
    notificationsGranted: true,
    exactAlarmsAllowed: true,
    batteryUnrestricted: true,
  );

  /// POST_NOTIFICATIONS (Android 13+) or the app's notifications toggle.
  final bool notificationsGranted;

  /// SCHEDULE_EXACT_ALARM. Granted by default on Android 12 and 13, off by
  /// default on 14+, always true below 12.
  final bool exactAlarmsAllowed;

  /// The app is exempt from battery optimisation (Doze and vendor savers).
  final bool batteryUnrestricted;

  /// A reminder can be shown at all.
  bool get canNotify => notificationsGranted;

  /// A reminder will arrive on the minute with the screen off.
  bool get reliable =>
      notificationsGranted && exactAlarmsAllowed && batteryUnrestricted;

  /// Steps the owner still has to take, in the order the screen shows them.
  List<SetupStep> get missing => [
    if (!notificationsGranted) SetupStep.notifications,
    if (!exactAlarmsAllowed) SetupStep.exactAlarms,
    if (!batteryUnrestricted) SetupStep.battery,
  ];

  NotificationPermissions copyWith({
    bool? notificationsGranted,
    bool? exactAlarmsAllowed,
    bool? batteryUnrestricted,
  }) => NotificationPermissions(
    notificationsGranted: notificationsGranted ?? this.notificationsGranted,
    exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
    batteryUnrestricted: batteryUnrestricted ?? this.batteryUnrestricted,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPermissions &&
      other.notificationsGranted == notificationsGranted &&
      other.exactAlarmsAllowed == exactAlarmsAllowed &&
      other.batteryUnrestricted == batteryUnrestricted;

  @override
  int get hashCode => Object.hash(
    notificationsGranted,
    exactAlarmsAllowed,
    batteryUnrestricted,
  );

  @override
  String toString() =>
      'NotificationPermissions(notify: $notificationsGranted, '
      'exact: $exactAlarmsAllowed, battery: $batteryUnrestricted)';
}

enum SetupStep { notifications, exactAlarms, battery }

/// How a reminder was handed to Android.
enum ScheduleMode {
  /// Exact, fires in Doze. What every reminder should get.
  exact,

  /// Android may delay it by minutes. Used only when exact alarms are denied,
  /// so a reminder still arrives rather than not at all.
  inexact,
}
