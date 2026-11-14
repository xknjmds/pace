import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_gateway.dart';
import 'notification_ids.dart';
import 'notification_permissions.dart';

/// [NotificationGateway] backed by flutter_local_notifications on Android.
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() async {
    await _setLocalTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_pace'),
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.reminders,
        NotificationChannels.remindersName,
        description: NotificationChannels.remindersDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _setLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Unknown zone name: tz.local stays UTC. Scheduling still uses the
      // right instant because we convert from an absolute DateTime.
      debugPrint('PACE: could not resolve local time zone: $e');
    }
  }

  @override
  Future<NotificationPermissions> permissions() async {
    final android = _android;
    return NotificationPermissions(
      notificationsGranted: await android?.areNotificationsEnabled() ?? false,
      exactAlarmsAllowed:
          await android?.canScheduleExactNotifications() ?? false,
      batteryUnrestricted:
          await Permission.ignoreBatteryOptimizations.isGranted,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> requestExactAlarmPermission() async =>
      await _android?.requestExactAlarmsPermission() ?? false;

  @override
  Future<bool> requestBatteryUnrestricted() async =>
      (await Permission.ignoreBatteryOptimizations.request()).isGranted;

  @override
  Future<void> openNotificationSettings() async {
    await _android?.openAppNotificationSettings();
  }

  @override
  Future<ScheduleMode> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
  }) async {
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    final mode = exact ? ScheduleMode.exact : ScheduleMode.inexact;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.reminders,
          NotificationChannels.remindersName,
          channelDescription: NotificationChannels.remindersDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: switch (mode) {
        ScheduleMode.exact => AndroidScheduleMode.exactAllowWhileIdle,
        ScheduleMode.inexact => AndroidScheduleMode.inexactAllowWhileIdle,
      },
    );
    return mode;
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<List<PendingReminder>> pending() async {
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final r in requests)
        PendingReminder(id: r.id, title: r.title, body: r.body),
    ];
  }
}
