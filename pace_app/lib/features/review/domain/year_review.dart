import '../../../core/time/date_key.dart';

/// A school year so far, in positive totals only.
class YearInReview {
  const YearInReview({
    required this.from,
    required this.daysDone,
    required this.routineDays,
    required this.deadlinesSubmitted,
    required this.focusSessions,
    required this.focusMinutes,
    required this.movementDays,
    required this.nightsLogged,
    required this.rewardsEnjoyed,
  });

  /// First day of the school year.
  final DateTime from;
  final int daysDone;
  final int routineDays;
  final int deadlinesSubmitted;
  final int focusSessions;
  final int focusMinutes;
  final int movementDays;
  final int nightsLogged;
  final int rewardsEnjoyed;

  bool get isEmpty =>
      daysDone == 0 &&
      deadlinesSubmitted == 0 &&
      focusSessions == 0 &&
      nightsLogged == 0 &&
      rewardsEnjoyed == 0;

  /// One line per non-zero total. Never a rate, never a miss.
  List<String> get lines {
    String n(int v, String one, String many) => '$v ${v == 1 ? one : many}';
    final hours = focusMinutes ~/ 60;
    return [
      if (daysDone > 0) '${n(daysDone, 'day', 'days')} with something done',
      if (routineDays > 0)
        '${n(routineDays, 'morning', 'mornings')} out the door with the routine done',
      if (deadlinesSubmitted > 0)
        '${n(deadlinesSubmitted, 'deadline', 'deadlines')} handed in',
      if (focusSessions > 0)
        '${n(focusSessions, 'focus session', 'focus sessions')}'
            '${hours > 0 ? ', about ${n(hours, 'hour', 'hours')}' : ''}',
      if (movementDays > 0) '${n(movementDays, 'day', 'days')} of movement',
      if (nightsLogged > 0) '${n(nightsLogged, 'bedtime', 'bedtimes')} logged',
      if (rewardsEnjoyed > 0)
        '${n(rewardsEnjoyed, 'reward', 'rewards')} enjoyed',
    ];
  }
}

/// Pure: the first day of the school year holding [today], which starts on
/// the 1st of [startMonth].
DateTime schoolYearStart(DateTime today, int startMonth) {
  final d = dateOnly(today);
  final thisYear = DateTime(d.year, startMonth);
  return d.isBefore(thisYear) ? DateTime(d.year - 1, startMonth) : thisYear;
}

/// Pure: totals from [from] up to and including [today]. Day sets are
/// `yyyy-MM-dd` keys; instants are local.
YearInReview yearInReview({
  required DateTime today,
  required int startMonth,
  Set<String> routineDays = const {},
  Set<String> movementDays = const {},
  Set<String> submittedDays = const {},
  int deadlinesSubmitted = 0,
  List<({DateTime startedAt, int minutes})> focus = const [],
  Set<String> bedtimeNights = const {},
  int rewardsEnjoyed = 0,
}) {
  final from = schoolYearStart(today, startMonth);
  final fromKey = dateKey(from);
  final toKey = dateKey(today);
  bool inYear(String key) =>
      key.compareTo(fromKey) >= 0 && key.compareTo(toKey) <= 0;
  Set<String> within(Set<String> s) => s.where(inYear).toSet();
  final sessions = [
    for (final f in focus)
      if (inYear(dateKey(f.startedAt))) f,
  ];
  final routine = within(routineDays);
  final movement = within(movementDays);
  return YearInReview(
    from: from,
    daysDone: {...routine, ...movement, ...within(submittedDays)}.length,
    routineDays: routine.length,
    deadlinesSubmitted: deadlinesSubmitted,
    focusSessions: sessions.length,
    focusMinutes: sessions.fold(0, (sum, f) => sum + f.minutes),
    movementDays: movement.length,
    nightsLogged: within(bedtimeNights).length,
    rewardsEnjoyed: rewardsEnjoyed,
  );
}
