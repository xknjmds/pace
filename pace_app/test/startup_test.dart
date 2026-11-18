import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/db/database_provider.dart';
import 'package:pace/core/home_widget/home_widget_providers.dart';
import 'package:pace/core/notifications/notification_channels.dart';
import 'package:pace/core/notifications/notification_permissions.dart';
import 'package:pace/core/notifications/notification_providers.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/core/time/clock.dart';
import 'package:pace/features/inbox/application/inbox_capture.dart';
import 'package:pace/routes.dart';
import 'package:pace/startup.dart';

import 'core/home_widget/fake_home_widget_bridge.dart';
import 'core/notifications/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late FakeHomeWidgetBridge widget;
  final now = DateTime(2026, 11, 16, 6, 31); // Monday, wake just fired

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway(
      state: NotificationPermissions.none.copyWith(notificationsGranted: true),
    );
    widget = FakeHomeWidgetBridge();
  });
  tearDown(() => db.close());

  ProviderContainer container() => ProviderContainer(
    overrides: [
      notificationGatewayProvider.overrideWithValue(gateway),
      homeWidgetBridgeProvider.overrideWithValue(widget),
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => now),
    ],
  );

  test(
    'bootstrap plans the routine and applies the launching response',
    () async {
      await db.weekdayScheduleDao.upsert(
        weekday: DateTime.monday,
        firstClassMinutes: 8 * 60 + 30,
        commuteMinutes: 30,
        prepMinutes: 30,
      );
      gateway.launch = const ReminderResponse(
        payload: 'wake:1',
        actionId: ReminderActionIds.done,
      );
      final c = container();
      addTearDown(c.dispose);
      await bootstrap(gateway, container: c);

      expect(
        gateway.scheduled.values.map((s) => s.payload),
        containsAll(['eat:1', 'leave:1']),
      );
      expect((await db.dailyLogsDao.get(now))?.wakeLoggedAt, now.toUtc());

      // A later button press while running is routed too.
      gateway.responseController.add(
        const ReminderResponse(
          payload: 'eat:1',
          actionId: ReminderActionIds.notToday,
        ),
      );
      await pumpEventQueue(times: 50);
      expect(
        await db.reminderMutesDao.isMuted(ReminderKind.eat, '1', now),
        isTrue,
      );
    },
  );

  test(
    'bootstrap shows the capture shortcut and keeps the widget count',
    () async {
      await db.inboxDao.add('already there');
      final c = container();
      addTearDown(c.dispose);
      await bootstrap(gateway, container: c);

      expect(
        gateway.persistent,
        contains(FixedNotificationIds.captureShortcut),
      );
      expect(widget.last, 1);

      // A reply arriving while the app is open goes to the inbox.
      gateway.responseController.add(
        const ReminderResponse(
          payload: InboxCapture.shortcutPayload,
          actionId: InboxCapture.replyAction,
          input: 'from the shade',
        ),
      );
      await pumpEventQueue(times: 50);
      expect(await db.inboxDao.getUnprocessed(), hasLength(2));
      expect(widget.last, 2);
    },
  );

  test('widget URIs map to screens', () {
    expect(routeForWidgetUri(Uri.parse('pace://capture')), Routes.inboxCapture);
    expect(routeForWidgetUri(Uri.parse('pace://today')), Routes.today);
    expect(routeForWidgetUri(Uri.parse('pace://other')), isNull);
    expect(routeForWidgetUri(null), isNull);
  });

  test('plain notification taps open the matching screen', () {
    expect(
      routeForResponse(const ReminderResponse(payload: 'windDown:1')),
      Routes.checkIn,
    );
    expect(
      routeForResponse(const ReminderResponse(payload: 'focusEnd:abc')),
      Routes.focus,
    );
    expect(
      routeForResponse(const ReminderResponse(payload: 'deadline:abc')),
      Routes.deadlines,
    );
    expect(routeForResponse(const ReminderResponse(payload: 'wake:1')), isNull);
    expect(
      routeForResponse(
        const ReminderResponse(
          payload: 'windDown:1',
          actionId: ReminderActionIds.done,
        ),
      ),
      isNull,
    );
  });

  test(
    'a cold start from the wind-down reminder returns the check-in',
    () async {
      gateway.launch = const ReminderResponse(payload: 'windDown:1');
      final c = container();
      addTearDown(c.dispose);
      expect(await bootstrap(gateway, container: c), Routes.checkIn);
    },
  );
}
