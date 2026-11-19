import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/review/domain/next_routine.dart';

void main() {
  NextRoutine? suggest({
    int routine = 12,
    int bedtimes = 0,
    int focus = 0,
    bool budget = false,
    Set<String> dismissed = const {},
  }) => nextRoutineSuggestion(
    routineDaysLast21: routine,
    bedtimesLast14: bedtimes,
    focusSessionsLast14: focus,
    budgetSet: budget,
    dismissed: dismissed,
  );

  test('nothing until mornings are steady', () {
    expect(suggest(routine: 11), isNull);
  });

  test('sleep comes first', () {
    expect(suggest(), NextRoutine.sleep);
  });

  test('already logging bedtimes moves on to study', () {
    expect(suggest(bedtimes: 5), NextRoutine.study);
  });

  test('then the budget', () {
    expect(suggest(bedtimes: 5, focus: 3), NextRoutine.budget);
  });

  test('all in place: nothing to suggest', () {
    expect(suggest(bedtimes: 5, focus: 3, budget: true), isNull);
  });

  test('a dismissed idea is skipped for the next one', () {
    expect(suggest(dismissed: {'sleep'}), NextRoutine.study);
    expect(suggest(dismissed: {'sleep', 'study', 'budget'}), isNull);
  });

  test('copy stays gentle', () {
    for (final r in NextRoutine.values) {
      expect(r.body.toLowerCase(), isNot(contains('should')));
      expect(r.body, isNot(contains('!')));
    }
  });
}
