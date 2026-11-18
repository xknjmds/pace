import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/notifications/notification_channels.dart';
import 'package:pace/core/notifications/notification_permissions.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/features/inbox/application/inbox_capture.dart';

import '../../../core/db/test_db.dart';
import '../../../core/home_widget/fake_home_widget_bridge.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  late TestDb t;
  late FakeNotificationGateway gateway;
  late FakeHomeWidgetBridge widget;
  late InboxCapture capture;

  setUp(() {
    t = TestDb();
    gateway = FakeNotificationGateway(
      state: NotificationPermissions.none.copyWith(notificationsGranted: true),
    );
    widget = FakeHomeWidgetBridge();
    capture = InboxCapture(
      db: t.db,
      gateway: gateway,
      widget: widget,
      now: () => t.now,
    );
  });
  tearDown(() => t.close());

  const shortcut = FixedNotificationIds.captureShortcut;

  test('add trims, ignores empty text and publishes the count', () async {
    expect(await capture.add('   '), isNull);
    final item = await capture.add('  email the prof  ');
    expect(item!.body, 'email the prof');
    await capture.add('buy index cards');
    expect(widget.counts, [1, 2]);
    expect(await t.db.inboxDao.getUnprocessed(), hasLength(2));
  });

  test('processing or removing an item lowers the widget count', () async {
    final a = await capture.add('a');
    final b = await capture.add('b');
    await capture.markProcessed(a!.id);
    await capture.remove(b!.id);
    expect(widget.counts, [1, 2, 1, 0]);
  });

  test('shortcut is shown with a reply field when on and allowed', () async {
    await capture.syncShortcut();
    final n = gateway.persistent[shortcut]!;
    expect(n.payload, InboxCapture.shortcutPayload);
    expect(n.actions.single.id, InboxCapture.replyAction);
    expect(n.actions.single.takesInput, isTrue);
  });

  test('shortcut is removed when turned off or not allowed', () async {
    await capture.syncShortcut();
    await capture.setShortcutEnabled(false);
    expect(gateway.persistent, isEmpty);
    expect(gateway.cancelled, contains(shortcut));
    expect((await t.db.settingsDao.get()).captureShortcutEnabled, isFalse);

    await capture.setShortcutEnabled(true);
    expect(gateway.persistent, contains(shortcut));

    gateway.state = NotificationPermissions.none;
    await capture.syncShortcut();
    expect(gateway.persistent, isEmpty);
  });

  test(
    'a reply from the shade saves the text and re-shows the shortcut',
    () async {
      final handled = await capture.handle(
        const ReminderResponse(
          payload: InboxCapture.shortcutPayload,
          actionId: InboxCapture.replyAction,
          input: 'ask about the lab',
        ),
      );
      expect(handled, isTrue);
      expect(
        (await t.db.inboxDao.getUnprocessed()).single.body,
        'ask about the lab',
      );
      expect(gateway.persistent, contains(shortcut));
      expect(widget.last, 1);
    },
  );

  test('an empty reply saves nothing; other payloads are not ours', () async {
    await capture.handle(
      const ReminderResponse(
        payload: InboxCapture.shortcutPayload,
        actionId: InboxCapture.replyAction,
        input: '  ',
      ),
    );
    expect(await t.db.inboxDao.getUnprocessed(), isEmpty);
    expect(
      await capture.handle(const ReminderResponse(payload: 'wake:1')),
      isFalse,
    );
  });
}
