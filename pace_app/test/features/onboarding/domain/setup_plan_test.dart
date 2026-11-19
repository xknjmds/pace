import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/onboarding/domain/setup_plan.dart';

void main() {
  SetupAnswers answers({
    Set<int> classDays = const {1, 2, 3, 4, 5},
    LocalTime? firstClass,
    int commute = 30,
    int prep = 30,
    LocalTime? usualWake,
    int sleep = 480,
    Chronotype chronotype = Chronotype.inBetween,
  }) => SetupAnswers(
    classDays: classDays,
    firstClass: firstClass ?? LocalTime.of(8, 0),
    commuteMinutes: commute,
    prepMinutes: prep,
    usualWake: usualWake ?? LocalTime.of(6, 0),
    sleepTargetMinutes: sleep,
    chronotype: chronotype,
  );

  test('class days get the first class, the rest have none', () {
    final plan = planFromAnswers(answers(classDays: {1, 3}));
    expect(plan.days, hasLength(7));
    expect(plan.days[DateTime.monday]!.firstClassMinutes, 8 * 60);
    expect(plan.days[DateTime.tuesday]!.firstClassMinutes, isNull);
    expect(plan.days[DateTime.wednesday]!.firstClassMinutes, 8 * 60);
    expect(plan.days[DateTime.sunday]!.firstClassMinutes, isNull);
    for (final d in plan.days.values) {
      expect(d.commuteMinutes, 30);
      expect(d.prepMinutes, 30);
    }
  });

  test('a usual wake that fits the morning is kept as is', () {
    final plan = planFromAnswers(answers(usualWake: LocalTime.of(6, 0)));
    expect(plan.wake, isA<WakeNow>());
    expect((plan.wake as WakeNow).minutes, 6 * 60);
  });

  test('a wake a little too late moves straight to a workable time', () {
    // 08:00 class, 30 commute, 30 prep, 15 breakfast: latest wake 06:45,
    // goal leaves 15 minutes of room: 06:30.
    final plan = planFromAnswers(answers(usualWake: LocalTime.of(6, 50)));
    expect(plan.wake, isA<WakeNow>());
    expect((plan.wake as WakeNow).minutes, 6 * 60 + 30);
  });

  test('a much later wake moves there gradually', () {
    final plan = planFromAnswers(answers(usualWake: LocalTime.of(7, 30)));
    final wake = plan.wake as WakeGradually;
    expect(wake.fromMinutes, 7 * 60 + 30);
    expect(wake.goalMinutes, 6 * 60 + 30);
    expect(wake.stepMinutes, 15);
    expect(wake.everyDays, 3);
  });

  test('night people get smaller, slower steps and a longer lie-in', () {
    final plan = planFromAnswers(
      answers(usualWake: LocalTime.of(8, 0), chronotype: Chronotype.night),
    );
    final wake = plan.wake as WakeGradually;
    expect(wake.stepMinutes, 10);
    expect(wake.everyDays, 4);
    expect(plan.weekendLeewayMinutes, 60);
  });

  test('morning people get a shorter lie-in', () {
    final plan = planFromAnswers(answers(chronotype: Chronotype.morning));
    expect(plan.weekendLeewayMinutes, 30);
  });

  test('the earliest class day decides the goal', () {
    final plan = planFromAnswers(
      answers(firstClass: LocalTime.of(7, 0), usualWake: LocalTime.of(6, 0)),
    );
    // 07:00 - 30 - 30 - 15 = 05:45 latest, goal 05:30, gap 30: direct.
    expect((plan.wake as WakeNow).minutes, 5 * 60 + 30);
  });

  test('no class days keeps the usual wake', () {
    final plan = planFromAnswers(
      answers(classDays: {}, usualWake: LocalTime.of(9, 0)),
    );
    expect((plan.wake as WakeNow).minutes, 9 * 60);
    expect(plan.days.values.every((d) => d.firstClassMinutes == null), isTrue);
  });

  test('a morning that cannot fit still gives a plan without a shift', () {
    final plan = planFromAnswers(
      answers(
        firstClass: LocalTime.of(0, 30),
        commute: 30,
        usualWake: LocalTime.of(7, 0),
      ),
    );
    expect((plan.wake as WakeNow).minutes, 7 * 60);
  });

  test('the sleep target is passed through', () {
    expect(planFromAnswers(answers(sleep: 450)).sleepTargetMinutes, 450);
  });

  test('summary leave time matches the first class day', () {
    final plan = planFromAnswers(answers());
    expect(plan.leaveBy, LocalTime.of(7, 30));
  });
}
