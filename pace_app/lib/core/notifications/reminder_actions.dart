import '../db/tables.dart';

/// A button on a notification. Tapping opens the app, which handles it.
class ReminderAction {
  const ReminderAction({required this.id, required this.label, this.inputHint});

  final String id;
  final String label;

  /// When set, the button takes free text typed in the notification shade
  /// and the app handles it in the background without opening.
  final String? inputHint;

  bool get takesInput => inputHint != null;
}

/// Action ids, shared by the scheduler and the handlers.
abstract final class ReminderActionIds {
  static const done = 'done';
  static const snooze = 'snooze';
  static const notToday = 'not_today';
}

/// The owner id suffix for a snoozed copy of a routine reminder.
const snoozeOwnerSuffix = ':snooze';

/// Which buttons a reminder gets. Derived, never stored, so a reminder
/// rebuilt from the table gets the same buttons.
List<ReminderAction> actionsFor(ReminderKind kind, String ownerId) {
  switch (kind) {
    case ReminderKind.wake:
    case ReminderKind.eat:
    case ReminderKind.leave:
      final snoozed = ownerId.endsWith(snoozeOwnerSuffix);
      return [
        const ReminderAction(id: ReminderActionIds.done, label: 'Done'),
        if (!snoozed)
          const ReminderAction(
            id: ReminderActionIds.snooze,
            label: '10 more minutes',
          ),
        const ReminderAction(
          id: ReminderActionIds.notToday,
          label: 'Not today',
        ),
      ];
    case ReminderKind.deadline:
      return const [
        ReminderAction(id: ReminderActionIds.done, label: 'Submitted'),
        ReminderAction(id: ReminderActionIds.notToday, label: 'Not today'),
      ];
    case ReminderKind.focusEnd:
      return const [
        ReminderAction(id: ReminderActionIds.done, label: 'Stop here'),
        ReminderAction(id: ReminderActionIds.snooze, label: 'Keep going'),
      ];
    case ReminderKind.windDown:
    case ReminderKind.test:
      return const [];
  }
}

/// What the user did with a notification: tapped it ([actionId] null) or
/// pressed one of its buttons.
class ReminderResponse {
  const ReminderResponse({required this.payload, this.actionId, this.input});

  final String? payload;
  final String? actionId;

  /// Text typed into an action with an input field.
  final String? input;
}

/// Payload format `kind:ownerId`. Returns null for anything else.
({ReminderKind kind, String ownerId})? parseReminderPayload(String? payload) {
  if (payload == null) return null;
  final sep = payload.indexOf(':');
  if (sep <= 0) return null;
  final kindName = payload.substring(0, sep);
  final kind = ReminderKind.values.where((k) => k.name == kindName);
  if (kind.isEmpty) return null;
  return (kind: kind.single, ownerId: payload.substring(sep + 1));
}

String reminderPayload(ReminderKind kind, String ownerId) =>
    '${kind.name}:$ownerId';
