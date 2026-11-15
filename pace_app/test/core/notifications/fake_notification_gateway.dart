import 'package:pace/core/notifications/notification_gateway.dart';
import 'dart:async';

import 'package:pace/core/notifications/notification_permissions.dart';
import 'package:pace/core/notifications/reminder_actions.dart';

/// In-memory gateway. Requests flip the matching flag so tests can drive
/// the setup flow without Android.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({
    this.state = NotificationPermissions.none,
    this.grantOnRequest = true,
  });

  NotificationPermissions state;
  bool grantOnRequest;
  int initializeCalls = 0;
  int openSettingsCalls = 0;
  final scheduled =
      <
        int,
        ({
          String title,
          String body,
          DateTime fireAt,
          String? payload,
          List<ReminderAction> actions,
        })
      >{};
  final responseController = StreamController<ReminderResponse>.broadcast();
  ReminderResponse? launch;
  final cancelled = <int>[];

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Future<NotificationPermissions> permissions() async => state;

  @override
  Future<bool> requestNotificationPermission() async {
    if (grantOnRequest) state = state.copyWith(notificationsGranted: true);
    return state.notificationsGranted;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    if (grantOnRequest) state = state.copyWith(exactAlarmsAllowed: true);
    return state.exactAlarmsAllowed;
  }

  @override
  Future<bool> requestBatteryUnrestricted() async {
    if (grantOnRequest) state = state.copyWith(batteryUnrestricted: true);
    return state.batteryUnrestricted;
  }

  @override
  Future<void> openNotificationSettings() async => openSettingsCalls++;

  @override
  Future<ScheduleMode> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
    List<ReminderAction> actions = const [],
  }) async {
    scheduled[id] = (
      title: title,
      body: body,
      fireAt: fireAt,
      payload: payload,
      actions: actions,
    );
    return state.exactAlarmsAllowed ? ScheduleMode.exact : ScheduleMode.inexact;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<List<PendingReminder>> pending() async => [
    for (final e in scheduled.entries)
      PendingReminder(id: e.key, title: e.value.title, body: e.value.body),
  ];

  @override
  Stream<ReminderResponse> get responses => responseController.stream;

  @override
  Future<ReminderResponse?> launchResponse() async => launch;
}
