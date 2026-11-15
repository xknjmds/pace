import 'reminder_actions.dart';

/// A feature's handler. Returns true when it owned the response.
typedef ReminderResponseHandler = Future<bool> Function(ReminderResponse);

/// Hands each notification response to the first feature that claims it.
class ReminderResponseRouter {
  const ReminderResponseRouter(this.handlers);

  final List<ReminderResponseHandler> handlers;

  Future<void> dispatch(ReminderResponse response) async {
    for (final handler in handlers) {
      if (await handler(response)) return;
    }
  }
}
