import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_gateway.dart';
import 'notification_channels.dart';
import 'notification_permissions.dart';
import 'reminder_actions.dart';

/// [NotificationGateway] backed by flutter_local_notifications on Android.
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    this.backgroundHandler,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Top-level `@pragma('vm:entry-point')` function the plugin runs in a
  /// background isolate for actions that do not open the app.
  final void Function(NotificationResponse)? backgroundHandler;

  final FlutterLocalNotificationsPlugin _plugin;
  final _responses = StreamController<ReminderResponse>.broadcast();

  @override
  Stream<ReminderResponse> get responses => _responses.stream;

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
      onDidReceiveNotificationResponse: (r) => _responses.add(
        ReminderResponse(
          payload: r.payload,
          actionId: r.actionId,
          input: r.input,
        ),
      ),
      onDidReceiveBackgroundNotificationResponse: backgroundHandler,
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.reminders,
        NotificationChannels.remindersName,
        description: NotificationChannels.remindersDescription,
        importance: Importance.high,
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.capture,
        NotificationChannels.captureName,
        description: NotificationChannels.captureDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
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
  Future<ReminderResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final r = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || r == null) return null;
    return ReminderResponse(
      payload: r.payload,
      actionId: r.actionId,
      input: r.input,
    );
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
    List<ReminderAction> actions = const [],
  }) async {
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    final mode = exact ? ScheduleMode.exact : ScheduleMode.inexact;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.reminders,
          NotificationChannels.remindersName,
          channelDescription: NotificationChannels.remindersDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          // Expands to show the whole body (the wake reminder's verse).
          styleInformation: BigTextStyleInformation(body),
          actions: _androidActions(actions),
        ),
      ),
      androidScheduleMode: switch (mode) {
        ScheduleMode.exact => AndroidScheduleMode.exactAllowWhileIdle,
        ScheduleMode.inexact => AndroidScheduleMode.inexactAllowWhileIdle,
      },
    );
    return mode;
  }

  /// Buttons without input open the app, which applies the action. Buttons
  /// with input stay in the shade and run [backgroundHandler].
  List<AndroidNotificationAction> _androidActions(
    List<ReminderAction> actions,
  ) => [
    for (final a in actions)
      AndroidNotificationAction(
        a.id,
        a.label,
        showsUserInterface: !a.takesInput,
        cancelNotification: !a.takesInput,
        inputs: a.takesInput
            ? [AndroidNotificationActionInput(label: a.inputHint)]
            : const [],
      ),
  ];

  @override
  Future<void> showPersistent({
    required int id,
    required String title,
    required String body,
    required String payload,
    List<ReminderAction> actions = const [],
  }) => _plugin.show(
    id: id,
    title: title,
    body: body,
    payload: payload,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.capture,
        NotificationChannels.captureName,
        channelDescription: NotificationChannels.captureDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        silent: true,
        showWhen: false,
        actions: _androidActions(actions),
      ),
    ),
  );

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
