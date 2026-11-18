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

  test('timetable classes replace the plan\'s single Class entry', () {
    final e = dayTimeline(
      day: monday,
      morning: classDay,
      wakeDone: false,
      eatDone: false,
      leaveDone: false,
      lowEnergy: false,
      blocks: [
        TimelineBlock(
          title: 'Math',
          start: DateTime(2026, 11, 16, 8, 30),
          end: DateTime(2026, 11, 16, 9, 30),
          room: 'B12',
        ),
        TimelineBlock(
          title: 'Club meeting',
          start: DateTime(2026, 11, 16, 15),
          end: DateTime(2026, 11, 16, 16),
          isEvent: true,
        ),
        // Another day's class stays out.
        TimelineBlock(
          title: 'Art',
          start: DateTime(2026, 11, 17, 8),
          end: DateTime(2026, 11, 17, 9),
        ),
      ],
    );
    final kinds = e.map((x) => x.kind).toList();
    expect(kinds, isNot(contains(TimelineKind.classStart)));
    final math = e.firstWhere((x) => x.kind == TimelineKind.classBlock);
    expect(
      (math.title, math.detail, math.endAt),
      ('Math', 'B12', DateTime(2026, 11, 16, 9, 30)),
    );
    expect(e.where((x) => x.title == 'Art'), isEmpty);
    expect(kinds, contains(TimelineKind.event));
  });

  test('a calendar event alone keeps the plan\'s Class entry', () {
    final e = dayTimeline(
      day: monday,
      morning: classDay,
      wakeDone: false,
      eatDone: false,
      leaveDone: false,
      lowEnergy: false,
      blocks: [
        TimelineBlock(
          title: 'Dentist',
          start: DateTime(2026, 11, 16, 16),
          end: DateTime(2026, 11, 16, 17),
          isEvent: true,
        ),
      ],
    );
    expect(e.map((x) => x.kind), contains(TimelineKind.classStart));
  });

  test('low-energy mode keeps only the block under way and the next', () {
    TimelineBlock cls(String t, int h) => TimelineBlock(
      title: t,
      start: DateTime(2026, 11, 16, h),
      end: DateTime(2026, 11, 16, h + 1),
    );
    final e = dayTimeline(
      day: monday,
      morning: classDay,
      wakeDone: false,
      eatDone: false,
      leaveDone: false,
      lowEnergy: true,
      now: DateTime(2026, 11, 16, 8, 15),
      blocks: [cls('Math', 8), cls('Art', 10), cls('History', 12)],
    );
    expect(
      e.where((x) => x.kind == TimelineKind.classBlock).map((x) => x.title),
      ['Math', 'Art'],
    );
  });

  test('now line sits before the first block still ahead', () {
    final e = build();
    expect(nowIndex(e, DateTime(2026, 11, 16, 5)), 0);
    expect(nowIndex(e, DateTime(2026, 11, 16, 7)), 1);
    expect(nowIndex(e, DateTime(2026, 11, 16, 23)), e.length);
  });
}
