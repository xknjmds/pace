import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/notifications/notification_permissions.dart';

void main() {
  test('nothing granted lists all three steps in screen order', () {
    expect(NotificationPermissions.none.canNotify, isFalse);
    expect(NotificationPermissions.none.reliable, isFalse);
    expect(NotificationPermissions.none.missing, [
      SetupStep.notifications,
      SetupStep.exactAlarms,
      SetupStep.battery,
    ]);
  });

  test('everything granted is reliable with nothing missing', () {
    expect(NotificationPermissions.all.reliable, isTrue);
    expect(NotificationPermissions.all.missing, isEmpty);
  });

  test('notifications alone can notify but is not reliable', () {
    final p = NotificationPermissions.none.copyWith(notificationsGranted: true);
    expect(p.canNotify, isTrue);
    expect(p.reliable, isFalse);
    expect(p.missing, [SetupStep.exactAlarms, SetupStep.battery]);
  });

  test('value equality', () {
    expect(
      NotificationPermissions.none.copyWith(batteryUnrestricted: true),
      const NotificationPermissions(
        notificationsGranted: false,
        exactAlarmsAllowed: false,
        batteryUnrestricted: true,
      ),
    );
    expect(NotificationPermissions.none, isNot(NotificationPermissions.all));
  });
}
