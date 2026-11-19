import '../../../core/time/date_key.dart';

/// Tuck's slow walk to the sea. Every day something got done moves Tuck one
/// step further. Nothing is ever taken away: a missed day just means no
/// step that day.
class JourneyStop {
  const JourneyStop(this.day, this.name);

  /// Days done needed to reach this stop.
  final int day;
  final String name;
}

const journeyStops = [
  JourneyStop(1, 'The first step'),
  JourneyStop(3, 'Clover patch'),
  JourneyStop(7, 'Little bridge'),
  JourneyStop(14, 'Quiet pond'),
  JourneyStop(21, 'Old oak'),
  JourneyStop(30, 'Sandy path'),
  JourneyStop(45, 'Dunes'),
  JourneyStop(60, 'Lighthouse'),
  JourneyStop(90, 'The shore'),
  JourneyStop(120, 'Tide pools'),
  JourneyStop(180, 'Coral garden'),
  JourneyStop(250, 'Warm current'),
  JourneyStop(365, 'Island cove'),
];

/// Past the last stop, a new stretch of open sea every this many days.
const openSeaEvery = 100;

/// A personal first. Never a ranking, never compared with anyone.
enum Milestone {
  firstDay('First day done'),
  steadyWeek('First week with three mornings done'),
  tenFocus('Ten focus sessions'),
  fiveMovement('Five days of movement'),
  tenSubmitted('Ten deadlines handed in'),
  thirtyDays('Thirty days done');

  const Milestone(this.label);
  final String label;
}

/// What the journey is made from. Plain values gathered from the logs.
class JourneyInputs {
  const JourneyInputs({
    this.routineDays = const {},
    this.movementDays = const {},
    this.submittedDays = const {},
    this.focusSessions = 0,
    this.deadlinesSubmitted = 0,
  });

  /// `yyyy-MM-dd` keys of days with the morning routine done.
  final Set<String> routineDays;
  final Set<String> movementDays;

  /// Days on which at least one deadline was handed in.
  final Set<String> submittedDays;
  final int focusSessions;
  final int deadlinesSubmitted;
}

class Journey {
  const Journey({
    required this.daysDone,
    required this.reached,
    required this.next,
    required this.milestones,
  });

  /// Distinct days with something done. Only ever grows.
  final int daysDone;

  /// The last stop reached, or null before the first day.
  final JourneyStop? reached;

  /// The stop ahead.
  final JourneyStop next;

  final Set<Milestone> milestones;

  int get daysToNext => next.day - daysDone;

  /// 0 to 1 along the stretch from [reached] to [next].
  double get stretchProgress {
    final from = reached?.day ?? 0;
    final span = next.day - from;
    return span <= 0 ? 1 : ((daysDone - from) / span).clamp(0, 1).toDouble();
  }
}

/// Pure: where Tuck is. More history can only move Tuck forward.
Journey journeyFrom(JourneyInputs i) {
  final days = {...i.routineDays, ...i.movementDays, ...i.submittedDays};
  final done = days.length;

  JourneyStop? reached;
  JourneyStop? next;
  for (final stop in journeyStops) {
    if (stop.day <= done) {
      reached = stop;
    } else {
      next = stop;
      break;
    }
  }
  if (next == null) {
    final last = journeyStops.last.day;
    final stretch = (done - last) ~/ openSeaEvery;
    if (stretch > 0) {
      reached = JourneyStop(last + stretch * openSeaEvery, 'Open sea $stretch');
    }
    next = JourneyStop(
      last + (stretch + 1) * openSeaEvery,
      'Open sea ${stretch + 1}',
    );
  }

  return Journey(
    daysDone: done,
    reached: reached,
    next: next,
    milestones: {
      if (done >= 1) Milestone.firstDay,
      if (_hasSteadyWeek(i.routineDays)) Milestone.steadyWeek,
      if (i.focusSessions >= 10) Milestone.tenFocus,
      if (i.movementDays.length >= 5) Milestone.fiveMovement,
      if (i.deadlinesSubmitted >= 10) Milestone.tenSubmitted,
      if (done >= 30) Milestone.thirtyDays,
    },
  );
}

/// Any Monday-to-Sunday week with three or more routine days.
bool _hasSteadyWeek(Set<String> routineDays) {
  final perWeek = <String, int>{};
  for (final key in routineDays) {
    final d = DateTime.parse(key);
    final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    final k = dateKey(monday);
    perWeek[k] = (perWeek[k] ?? 0) + 1;
  }
  return perWeek.values.any((n) => n >= 3);
}
