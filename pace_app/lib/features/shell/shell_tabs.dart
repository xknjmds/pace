import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routes.dart';

/// The places one tap away. More holds everything else.
enum ShellTab {
  today(Routes.today),
  deadlines(Routes.deadlines),
  inbox(Routes.inbox),
  focus(Routes.focus),
  more(Routes.more);

  const ShellTab(this.route);

  final String route;

  /// The tab a route opens, or null for screens pushed on top.
  static ShellTab? forRoute(String route) => route == Routes.inboxCapture
      ? ShellTab.inbox
      : ShellTab.values.where((t) => t.route == route).firstOrNull;
}

/// A request to show a tab; [capture] also focuses the Inbox field and
/// [taskId] preselects a task on Focus. [serial] makes repeated identical
/// requests still count.
class ShellRequest {
  const ShellRequest(
    this.tab, {
    this.capture = false,
    this.taskId,
    this.serial = 0,
  });

  final ShellTab tab;
  final bool capture;
  final String? taskId;
  final int serial;
}

class ShellRequests extends Notifier<ShellRequest?> {
  int _serial = 0;

  @override
  ShellRequest? build() => null;

  void open(ShellTab tab, {bool capture = false, String? taskId}) => state =
      ShellRequest(tab, capture: capture, taskId: taskId, serial: ++_serial);
}

final shellRequestProvider = NotifierProvider<ShellRequests, ShellRequest?>(
  ShellRequests.new,
);
