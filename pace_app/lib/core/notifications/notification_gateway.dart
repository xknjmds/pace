import 'notification_permissions.dart';
import 'reminder_actions.dart';

/// A pending reminder as Android knows it.
class PendingReminder {
  const PendingReminder({required this.id, this.title, this.body});

  final int id;
  final String? title;
  final String? body;
}

/// Everything PACE asks of the notification system, behind one interface so
/// screens and (later) the scheduler can be tested with a fake.
abstract interface class NotificationGateway {
  /// Sets up time zones and the plugin. Call once before anything else.
  Future<void> initialize();

  Future<NotificationPermissions> permissions();

  /// Shows the system prompt (Android 13+). Returns the new state.
  Future<bool> requestNotificationPermission();

  /// Android 14+: opens the system page for "Alarms & reminders".
  /// Returns whether exact alarms are allowed afterwards.
  Future<bool> requestExactAlarmPermission();

  /// Shows the system "ignore battery optimisations" dialog.
  Future<bool> requestBatteryUnrestricted();

  /// Opens the app's notification settings, for when a prompt was denied
  /// permanently and only the user can undo it.
  Future<void> openNotificationSettings();

  /// Schedules one reminder at [fireAt] (a local instant). Replaces any
  /// pending reminder with the same [id]. Falls back to inexact when exact
  /// alarms are not allowed and reports which mode was used.
  Future<ScheduleMode> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
    List<ReminderAction> actions = const [],
  });

  Future<void> cancel(int id);

  /// Shows (or refreshes) a quiet, persistent notification right now. Used
  /// for the capture shortcut; an action with an input hint gets a reply
  /// field whose text arrives through the background handler.
  Future<void> showPersistent({
    required int id,
    required String title,
    required String body,
    required String payload,
    List<ReminderAction> actions = const [],
  });

  Future<List<PendingReminder>> pending();

  /// Taps and button presses while the app is running or being resumed.
  Stream<ReminderResponse> get responses;

  /// The response that launched the app from a cold start, if any.
  Future<ReminderResponse?> launchResponse();
}
