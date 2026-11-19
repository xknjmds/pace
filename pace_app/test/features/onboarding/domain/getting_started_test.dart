import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/onboarding/domain/getting_started.dart';

void main() {
  const none = GettingStartedFacts(
    hasClasses: false,
    hasDeadline: false,
    hasInboxItem: false,
    hasFocusSession: false,
    remindersAllowed: false,
  );

  group('gettingStartedSteps', () {
    test('lists every step in order, none done on a fresh install', () {
      final steps = gettingStartedSteps(none);
      expect(steps.map((s) => s.id), GettingStartedStepId.values);
      expect(steps.any((s) => s.done), isFalse);
    });

    test('each fact ticks its own step', () {
      final steps = gettingStartedSteps(
        const GettingStartedFacts(
          hasClasses: true,
          hasDeadline: false,
          hasInboxItem: true,
          hasFocusSession: false,
          remindersAllowed: true,
        ),
      );
      expect(
        {for (final s in steps) s.id: s.done},
        {
          GettingStartedStepId.classes: true,
          GettingStartedStepId.deadline: false,
          GettingStartedStepId.inbox: true,
          GettingStartedStepId.focus: false,
          GettingStartedStepId.reminders: true,
        },
      );
    });

    test('leaves reminders out where the device has none', () {
      final steps = gettingStartedSteps(
        const GettingStartedFacts(
          hasClasses: false,
          hasDeadline: false,
          hasInboxItem: false,
          hasFocusSession: false,
        ),
      );
      expect(
        steps.map((s) => s.id),
        isNot(contains(GettingStartedStepId.reminders)),
      );
      expect(steps, hasLength(4));
    });
  });

  group('showGettingStarted', () {
    final setup = DateTime(2026, 11, 19, 7);
    final steps = gettingStartedSteps(none);

    bool show({
      DateTime? onboardedAt,
      DateTime? closedAt,
      DateTime? now,
      List<GettingStartedStep>? withSteps,
      bool lowEnergy = false,
    }) => showGettingStarted(
      onboardedAt: onboardedAt,
      closedAt: closedAt,
      now: now ?? setup.add(const Duration(days: 1)),
      steps: withSteps ?? steps,
      lowEnergy: lowEnergy,
    );

    test('shows in the first days after setup', () {
      expect(show(onboardedAt: setup), isTrue);
    });

    test('not before setup is done or skipped', () {
      expect(show(), isFalse);
    });

    test('not once closed', () {
      expect(show(onboardedAt: setup, closedAt: setup), isFalse);
    });

    test('not in low-energy mode', () {
      expect(show(onboardedAt: setup, lowEnergy: true), isFalse);
    });

    test('not once every step is done', () {
      final allDone = [
        for (final s in steps) GettingStartedStep(s.id, done: true),
      ];
      expect(show(onboardedAt: setup, withSteps: allDone), isFalse);
    });

    test('steps aside after two weeks', () {
      expect(
        show(onboardedAt: setup, now: setup.add(const Duration(days: 13))),
        isTrue,
      );
      expect(
        show(onboardedAt: setup, now: setup.add(const Duration(days: 14))),
        isFalse,
      );
    });
  });
}
