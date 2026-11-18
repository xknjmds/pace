import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/routine/domain/morning_plan.dart';
import 'package:pace/features/routine/domain/wake_schedule.dart';
import 'package:pace/features/today/domain/day_timeline.dart';

void main() {
  final monday = DateTime(2026, 11, 16);
  final classDay = computeLeaveByPlan(
    MorningInputs(
      firstClass: LocalTime.of(8, 30),
      commuteMinutes: 30,
      prepMinutes: 30,
      breakfastMinutes: 15,
      targetWake: LocalTime.of(6, 30),
    ),
  );
  final night = NightPlan(
    night: monday,
    windDownAt: DateTime(2026, 11, 16, 22),
    bedtime: DateTime(2026, 11, 16, 22, 30),
    wakeAt: DateTime(2026, 11, 17, 6, 30),
  );
  final tasks = [
    TimelineTask(id: 'a', title: 'Lab report', due: DateTime(2026, 11, 16, 20)),
    TimelineTask(id: 'b', title: 'Essay', due: DateTime(2026, 11, 17, 23, 59)),
  ];

  List<TimelineEntry> build({bool lowEnergy = false, bool wakeDone = false}) =>
      dayTimeline(
        day: monday,
        morning: classDay,
        wakeDone: wakeDone,
        eatDone: false,
        leaveDone: false,
        tasks: tasks,
        night: night,
        lowEnergy: lowEnergy,
      );

  test('a class day in time order, with only today\'s deadlines', () {
    final e = build();
    expect(e.map((x) => x.kind), [
      TimelineKind.wake,
      TimelineKind.eat,
      TimelineKind.leave,
      TimelineKind.classStart,
      TimelineKind.deadline,
      TimelineKind.windDown,
      TimelineKind.bed,
    ]);
    expect(e.first.at, DateTime(2026, 11, 16, 6, 30));
    expect(e[4].title, 'Lab report');
    expect(e[4].taskId, 'a');
  });

  test('low-energy mode drops breakfast and wind-down', () {
    final kinds = build(lowEnergy: true).map((x) => x.kind);
    expect(kinds, isNot(contains(TimelineKind.eat)));
    expect(kinds, isNot(contains(TimelineKind.windDown)));
    expect(kinds, contains(TimelineKind.bed));
  });

  test('done steps are marked; nothing is ever marked missed', () {
    final e = build(wakeDone: true);
    expect(e.first.done, isTrue);
    expect(e.skip(1).every((x) => !x.done), isTrue);
  });

  test('a free day shows the steady wake time when anchored', () {
    final free = computeLeaveByPlan(
      MorningInputs(
        firstClass: null,
        commuteMinutes: 30,
        prepMinutes: 30,
        breakfastMinutes: 15,
        targetWake: LocalTime.of(7, 30),
      ),
    );
    final e = dayTimeline(
      day: monday,
      morning: free,
      noClassWake: LocalTime.of(7, 30),
      wakeDone: false,
      eatDone: false,
      leaveDone: false,
      lowEnergy: false,
    );
    expect(e.single.kind, TimelineKind.wake);
    expect(e.single.at, DateTime(2026, 11, 16, 7, 30));
  });

  test('now line sits before the first block still ahead', () {
    final e = build();
    expect(nowIndex(e, DateTime(2026, 11, 16, 5)), 0);
    expect(nowIndex(e, DateTime(2026, 11, 16, 7)), 1);
    expect(nowIndex(e, DateTime(2026, 11, 16, 23)), e.length);
  });
}
