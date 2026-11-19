/// Once mornings run on their own, one gentle idea for what to build next.
/// Sleep first, then study time, then money. Every one can be dismissed.
enum NextRoutine {
  sleep(
    'A steady bedtime',
    'Mornings are steady. Logging "Going to bed" a few nights a week makes '
        'waking up easier.',
    'Try the evening check-in',
  ),
  study(
    'A little study time',
    'Mornings are steady. One short focus session after class adds up '
        'over a week.',
    'Start a focus session',
  ),
  budget(
    'A weekly budget',
    'Mornings are steady. A simple weekly budget shows where allowance goes, '
        'no judging.',
    'Set a budget',
  );

  const NextRoutine(this.title, this.body, this.action);
  final String title;
  final String body;
  final String action;
}

/// Routine days in the last three weeks that count as steady.
const nextRoutineSteadyDays = 12;

/// Pure: the next routine to suggest, or null.
///
/// Only once mornings are steady, and only for something not already
/// happening: fewer than five bedtimes logged in two weeks, fewer than
/// three focus sessions in two weeks, or no budget.
NextRoutine? nextRoutineSuggestion({
  required int routineDaysLast21,
  required int bedtimesLast14,
  required int focusSessionsLast14,
  required bool budgetSet,
  required Set<String> dismissed,
}) {
  if (routineDaysLast21 < nextRoutineSteadyDays) return null;
  final open = {
    NextRoutine.sleep: bedtimesLast14 < 5,
    NextRoutine.study: focusSessionsLast14 < 3,
    NextRoutine.budget: !budgetSet,
  };
  for (final r in NextRoutine.values) {
    if (open[r]! && !dismissed.contains(r.name)) return r;
  }
  return null;
}
