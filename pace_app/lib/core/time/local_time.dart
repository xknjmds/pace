/// A time of day with minute precision, stored as minutes since midnight.
///
/// Pure value type: no timezone, no date. Combine with a date via [onDate].
class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.minutesSinceMidnight)
    : assert(
        minutesSinceMidnight >= 0 && minutesSinceMidnight < minutesPerDay,
        'minutesSinceMidnight must be within one day',
      );

  LocalTime.of(int hour, int minute) : this(hour * 60 + minute);

  static const int minutesPerDay = 24 * 60;

  final int minutesSinceMidnight;

  int get hour => minutesSinceMidnight ~/ 60;
  int get minute => minutesSinceMidnight % 60;

  /// Adds [minutes] (negative allowed), wrapping around midnight.
  LocalTime plusMinutes(int minutes) =>
      LocalTime((minutesSinceMidnight + minutes) % minutesPerDay);

  /// This time of day on the calendar day of [date], in [date]'s zone.
  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.minutesSinceMidnight == minutesSinceMidnight;

  @override
  int get hashCode => minutesSinceMidnight.hashCode;

  @override
  String toString() => 'LocalTime(${format24()})';
}
