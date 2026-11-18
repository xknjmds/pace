import 'package:flutter/widgets.dart';

import 'core/notifications/ui/notification_setup_screen.dart';
import 'core/widgets/coming_soon_screen.dart';
import 'features/deadlines/ui/deadlines_screen.dart';
import 'features/inbox/ui/inbox_screen.dart';
import 'features/routine/ui/routine_settings_screen.dart';
import 'features/today/ui/today_screen.dart';

/// Named routes. Today is home; everything else is reached from it.
abstract final class Routes {
  static const today = '/today';
  static const deadlines = '/deadlines';
  static const inbox = '/inbox';

  /// Inbox with the capture field focused (widget and shortcut entry).
  static const inboxCapture = '/inbox/capture';
  static const focus = '/focus';
  static const review = '/review';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static Map<String, WidgetBuilder> get table => {
    today: (_) => const TodayScreen(),
    deadlines: (_) => const DeadlinesScreen(),
    inbox: (_) => const InboxScreen(),
    inboxCapture: (_) => const InboxScreen(startCapturing: true),
    focus: (_) => const ComingSoonScreen(title: 'Focus'),
    review: (_) => const ComingSoonScreen(title: 'Review'),
    settings: (_) => const RoutineSettingsScreen(),
    notifications: (_) => const NotificationSetupScreen(),
  };
}
