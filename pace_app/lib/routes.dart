import 'package:flutter/material.dart';

import 'core/notifications/ui/notification_setup_screen.dart';
import 'core/widgets/readable_width.dart';
import 'features/blocking/ui/gate_screen.dart';
import 'features/calendar/ui/calendar_screen.dart';
import 'features/finance/ui/money_screen.dart';
import 'features/notes/ui/notes_screen.dart';
import 'features/onboarding/ui/setup_screen.dart';
import 'features/review/ui/check_in_screen.dart';
import 'features/schedule/ui/schedule_screen.dart';
import 'features/review/ui/review_screen.dart';
import 'features/routine/ui/routine_settings_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/shell/shell_tabs.dart';

/// Named routes. Today, Deadlines, Inbox and Focus are tabs of one home
/// shell, which is always the root; other screens are pushed on top, so a
/// cold start into any of them still has the shell underneath.
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
  static const schedule = '/schedule';
  static const gate = '/gate';
  static const notes = '/notes';
  static const money = '/money';
  static const calendar = '/calendar';

  /// First-run setup, shown until it is finished or skipped.
  static const setup = '/setup';

  /// The hub tab with every other screen.
  static const more = '/more';

  static Map<String, WidgetBuilder> get table => {
    today: (_) => const HomeShell(),
    deadlines: (_) => const HomeShell(initialTab: ShellTab.deadlines),
    inbox: (_) => const HomeShell(initialTab: ShellTab.inbox),
    inboxCapture: (_) =>
        const HomeShell(initialTab: ShellTab.inbox, startCapturing: true),
    focus: (_) => const HomeShell(initialTab: ShellTab.focus),
    more: (_) => const HomeShell(initialTab: ShellTab.more),
    review: (_) => const ReadableWidth(child: ReviewScreen()),
    checkIn: (_) => const ReadableWidth(child: CheckInScreen()),
    settings: (_) => const ReadableWidth(child: RoutineSettingsScreen()),
    notifications: (_) => const ReadableWidth(child: NotificationSetupScreen()),
    schedule: (_) => const ReadableWidth(child: ScheduleScreen()),
    gate: (_) => const ReadableWidth(child: GateScreen()),
    notes: (_) => const ReadableWidth(child: NotesScreen()),
    money: (_) => const ReadableWidth(child: MoneyScreen()),
    calendar: (_) => const ReadableWidth(child: CalendarScreen()),
    setup: (_) => const ReadableWidth(child: SetupScreen()),
  };

  static Route<void> _route(String name) => MaterialPageRoute(
    settings: RouteSettings(name: name),
    builder: table[name]!,
  );

  /// The stack a cold start opens with: a tab route is the shell alone;
  /// any other screen sits on top of the shell at Today.
  static List<Route<dynamic>> initialStack(String name) {
    if (!table.containsKey(name)) return [_route(today)];
    if (ShellTab.forRoute(name) != null) return [_route(name)];
    return [_route(today), _route(name)];
  }

  /// Opens [route] while the app runs (a notification or widget tap): tabs
  /// switch in the shell, other screens are pushed on top of it.
  static void open(NavigatorState? nav, ShellRequests shell, String route) {
    if (nav == null) return;
    final tab = ShellTab.forRoute(route);
    if (tab == null) {
      nav.pushNamed(route);
      return;
    }
    nav.popUntil((r) => r.isFirst);
    shell.open(tab, capture: route == inboxCapture);
  }
}
