import '../../../core/db/app_database.dart';
import '../../../core/home_widget/home_widget_bridge.dart';
import '../../../core/notifications/notification_channels.dart';
import '../../../core/notifications/notification_gateway.dart';
import '../../../core/notifications/reminder_actions.dart';

/// Getting a thought out of the head and into the inbox, from anywhere:
/// the Inbox screen, the home-screen widget, or the notification shade.
/// Also keeps the widget count and the capture shortcut in step.
class InboxCapture {
  InboxCapture({
    required this.db,
    required this.gateway,
    required this.widget,
    required this.now,
  });

  final AppDatabase db;
  final NotificationGateway gateway;
  final HomeWidgetBridge widget;
  final DateTime Function() now;

  /// Payload of the shortcut notification; its reply action id.
  static const shortcutPayload = 'capture';
  static const replyAction = 'capture_text';

  /// Saves [text] (trimmed; empty is ignored) and refreshes the widget.
  Future<InboxItem?> add(String text) async {
    final t = text.trim();
    if (t.isEmpty) return null;
    final item = await db.inboxDao.add(t);
    await publishCount();
    return item;
  }

  Future<void> remove(String id) async {
    await db.inboxDao.remove(id);
    await publishCount();
  }

  /// The item has become a task (or been dealt with) and leaves the inbox.
  Future<void> markProcessed(String id) async {
    await db.inboxDao.markProcessed(id);
    await publishCount();
  }

  Future<void> publishCount() async =>
      widget.publishInboxCount((await db.inboxDao.getUnprocessed()).length);

  /// Shows or removes the shortcut according to the setting and the
  /// notification permission. Re-showing also clears the "sending" state
  /// Android leaves on an inline reply.
  Future<void> syncShortcut() async {
    final settings = await db.settingsDao.get();
    final permissions = await gateway.permissions();
    if (settings.captureShortcutEnabled && permissions.notificationsGranted) {
      await gateway.showPersistent(
        id: FixedNotificationIds.captureShortcut,
        title: 'Got a thought?',
        body: 'Write it here. Sort it out later.',
        payload: shortcutPayload,
        actions: const [
          ReminderAction(
            id: replyAction,
            label: 'Add to inbox',
            inputHint: 'What is on your mind?',
          ),
        ],
      );
    } else {
      await gateway.cancel(FixedNotificationIds.captureShortcut);
    }
  }

  Future<void> setShortcutEnabled(bool enabled) async {
    await db.settingsDao.setCaptureShortcut(enabled);
    await syncShortcut();
  }

  /// Text typed into the shortcut's reply field. Returns false for other
  /// responses. Runs in the background isolate as well as the app.
  Future<bool> handle(ReminderResponse response) async {
    if (response.payload != shortcutPayload) return false;
    if (response.actionId == replyAction) {
      await add(response.input ?? '');
      await syncShortcut();
    }
    return true;
  }
}
