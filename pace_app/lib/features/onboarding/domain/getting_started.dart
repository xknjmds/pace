/// The first few things worth trying, in the order Today lists them.
enum GettingStartedStepId { classes, deadline, inbox, focus, reminders }

class GettingStartedStep {
  const GettingStartedStep(this.id, {required this.done});

  final GettingStartedStepId id;
  final bool done;
}

/// What the app already knows, as plain values.
class GettingStartedFacts {
  const GettingStartedFacts({
    required this.hasClasses,
    required this.hasDeadline,
    required this.hasInboxItem,
    required this.hasFocusSession,
    this.remindersAllowed,
  });

  final bool hasClasses;
  final bool hasDeadline;
  final bool hasInboxItem;
  final bool hasFocusSession;

  /// Null where this device has no reminders: the step is left out.
  final bool? remindersAllowed;
}

/// How long after setup the card offers itself.
const gettingStartedDays = 14;

/// Pure: the steps, each ticked from real data rather than by hand.
List<GettingStartedStep> gettingStartedSteps(GettingStartedFacts f) => [
  GettingStartedStep(GettingStartedStepId.classes, done: f.hasClasses),
  GettingStartedStep(GettingStartedStepId.deadline, done: f.hasDeadline),
  GettingStartedStep(GettingStartedStepId.inbox, done: f.hasInboxItem),
  GettingStartedStep(GettingStartedStepId.focus, done: f.hasFocusSession),
  if (f.remindersAllowed != null)
    GettingStartedStep(
      GettingStartedStepId.reminders,
      done: f.remindersAllowed!,
    ),
];

/// Pure: whether Today shows the card. It steps aside once setup is a
/// fortnight old, once everything is tried, when closed, and on
/// low-energy days (CLAUDE.md rule 6).
bool showGettingStarted({
  required DateTime? onboardedAt,
  required DateTime? closedAt,
  required DateTime now,
  required List<GettingStartedStep> steps,
  required bool lowEnergy,
}) {
  if (onboardedAt == null || closedAt != null || lowEnergy) return false;
  if (steps.every((s) => s.done)) return false;
  return now.difference(onboardedAt) < const Duration(days: gettingStartedDays);
}
