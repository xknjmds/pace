import '../../../core/time/local_time.dart';
import '../../routine/domain/morning_plan.dart';
import '../../routine/domain/wake_schedule.dart';

/// What a block on Today's timeline is.
enum TimelineKind {
  wake,
  eat,
  leave,
  classStart,

  /// A class from the timetable, with its end time and room.
  classBlock,

  /// A timed event from the calendar.
  event,
  deadline,
  windDown,
  bed,
}

/// A deadline as the timeline needs it.
class TimelineTask {
  const TimelineTask({
    required this.id,
    required this.title,
    required this.due,
  });

  final String id;
  final String title;

  /// Local time.
  final DateTime due;
}

/// A timed block from the timetable or the calendar, as plain data.
class TimelineBlock {
  const TimelineBlock({
    required this.title,
    required this.start,
    required this.end,
    this.room,
    this.isEvent = false,
  });

  final String title;

  /// Local times.
  final DateTime start;
  final DateTime end;
  final String? room;

  /// From the calendar rather than the timetable.
  final bool isEvent;
}

/// One block of the day.
class TimelineEntry {
  const TimelineEntry({
    required this.kind,
    required this.at,
    required this.title,
    this.done = false,
    this.taskId,
    this.endAt,
    this.detail,
  });

  final TimelineKind kind;

  /// Local time.
  final DateTime at;
  final String title;

  /// Logged as done. A block that is not done is simply still there; it is
  /// never marked as missed.
  final bool done;
  final String? taskId;

  /// For blocks with a length (classes, events).
  final DateTime? endAt;

  /// A short extra line, such as the room.
  final String? detail;
}

/// Pure: today's blocks in time order, from the morning plan, the
/// timetable and calendar [blocks], today's deadlines and tonight's plan.
/// When the timetable has classes today they replace the plan's single
/// "Class" entry, so nothing shows twice.
///
/// In low-energy mode, given [now], only the block under way and the next
/// one stay.
///
/// Low-energy mode keeps only what matters: up, leave, class, what is due
/// and bed (no breakfast block, no wind-down).
List<TimelineEntry> dayTimeline({
  required DateTime day,
  required MorningPlan morning,
  LocalTime? noClassWake,
  required bool wakeDone,
  required bool eatDone,
  required bool leaveDone,
  List<TimelineTask> tasks = const [],
  List<TimelineBlock> blocks = const [],
  DateTime? now,
  NightPlan? night,
  bool bedDone = false,
  required bool lowEnergy,
}) {
  final date = DateTime(day.year, day.month, day.day);
  DateTime at(LocalTime t) =>
      date.add(Duration(minutes: t.minutesSinceMidnight));
  bool sameDay(DateTime d) =>
      d.year == date.year && d.month == date.month && d.day == date.day;

  final todays = blocks.where((b) => sameDay(b.start)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final shownBlocks = lowEnergy && now != null
      ? todays.where((b) => b.end.isAfter(now)).take(2).toList()
      : todays;
  final wakeAt = switch (morning) {
    LeaveByPlan p => p.wake,
    _ => noClassWake,
  };
  final entries = <TimelineEntry>[
    if (wakeAt != null)
      TimelineEntry(
        kind: TimelineKind.wake,
        at: at(wakeAt),
        title: 'Up',
        done: wakeDone,
      ),
    if (morning case LeaveByPlan p) ...[
      if (!lowEnergy)
        TimelineEntry(
          kind: TimelineKind.eat,
          at: at(p.eatStart),
          title: 'Breakfast',
          done: eatDone,
        ),
      TimelineEntry(
        kind: TimelineKind.leave,
        at: at(p.leave),
        title: 'Leave',
        done: leaveDone,
      ),
      if (!todays.any((b) => !b.isEvent))
        TimelineEntry(
          kind: TimelineKind.classStart,
          at: at(p.firstClass),
          title: 'Class',
          done: leaveDone,
        ),
    ],
    for (final b in shownBlocks)
      TimelineEntry(
        kind: b.isEvent ? TimelineKind.event : TimelineKind.classBlock,
        at: b.start,
        endAt: b.end,
        title: b.title,
        detail: b.room,
      ),
    for (final t in tasks)
      if (sameDay(t.due))
        TimelineEntry(
          kind: TimelineKind.deadline,
          at: t.due,
          title: t.title,
          taskId: t.id,
        ),
    if (night != null && sameDay(night.night)) ...[
      if (!lowEnergy)
        TimelineEntry(
          kind: TimelineKind.windDown,
          at: night.windDownAt,
          title: 'Wind down',
          done: bedDone,
        ),
      TimelineEntry(
        kind: TimelineKind.bed,
        at: night.bedtime,
        title: 'Bed',
        done: bedDone,
      ),
    ],
  ];
  entries.sort((a, b) => a.at.compareTo(b.at));
  return entries;
}

/// Pure: where the "now" line sits, as the index of the first block that
/// starts after [now] (the list length when the day is behind us).
int nowIndex(List<TimelineEntry> entries, DateTime now) {
  final i = entries.indexWhere((e) => e.at.isAfter(now));
  return i == -1 ? entries.length : i;
}
