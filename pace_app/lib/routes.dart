import 'package:flutter/widgets.dart';

import 'core/notifications/ui/notification_setup_screen.dart';
import 'features/deadlines/ui/deadlines_screen.dart';
import 'features/focus/ui/focus_screen.dart';
import 'features/inbox/ui/inbox_screen.dart';
import 'features/review/ui/check_in_screen.dart';
import 'features/review/ui/review_screen.dart';
import 'features/routine/ui/routine_settings_screen.dart';
import 'features/today/ui/today_screen.dart';

/// Named routes. Today is home and the root, so a cold start into any
/// other screen (from a notification or the widget) still has Today
/// underneath it: Flutter builds the stack from the path's segments.
abstract final class Routes {
  static const today = '/';
  static const deadlines = '/deadlines';
  static const inbox = '/inbox';

  /// Inbox with the capture field focused (widget and shortcut entry).
  static const inboxCapture = '/capture';
  static const focus = '/focus';
  static const review = '/review';

  /// The evening check-in (also opened from the wind-down reminder).
  static const checkIn = '/review/check-in';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static Map<String, WidgetBuilder> get table => {
    today: (_) => const TodayScreen(),
    deadlines: (_) => const DeadlinesScreen(),
    inbox: (_) => const InboxScreen(),
    inboxCapture: (_) => const InboxScreen(startCapturing: true),
    focus: (_) => const FocusScreen(),
    review: (_) => const ReviewScreen(),
    checkIn: (_) => const CheckInScreen(),
    settings: (_) => const RoutineSettingsScreen(),
    notifications: (_) => const NotificationSetupScreen(),
  };
}
