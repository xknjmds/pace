import 'dart:async';

import 'notification_gateway.dart';
import 'notification_permissions.dart';
import 'reminder_actions.dart';

/// Used where reminders do not exist (web, desktop). Everything succeeds
/// quietly and nothing is shown, so the rest of the app works unchanged:
/// the `scheduled_notifications` table is still kept, and the Android app
/// would schedule those rows if the data were ever moved over.
class NoopNotificationGateway implements NotificationGateway {
  const NoopNotificationGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissions> permissions() async =>
      NotificationPermissions.none;

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<bool> requestExactAlarmPermission() async => false;

  @override
  Future<bool> requestBatteryUnrestricted() async => false;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<ScheduleMode> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
    List<ReminderAction> actions = const [],
  }) async => ScheduleMode.inexact;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> showPersistent({
    required int id,
    required String title,
    required String body,
    required String payload,
    List<ReminderAction> actions = const [],
  }) async {}

  @override
  Future<List<PendingReminder>> pending() async => const [];

  @override
  Stream<ReminderResponse> get responses => const Stream.empty();

  @override
  Future<ReminderResponse?> launchResponse() async => null;
}
