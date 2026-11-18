/// A class or event on one day, as Today and the widget show it. Pure.
class DayItem {
  const DayItem({
    required this.title,
    required this.start,
    required this.end,
    this.room,
    this.isEvent = false,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final String? room;

  /// From the calendar rather than the class schedule.
  final bool isEvent;
}

/// Where [now] sits among [items]: the one under way and the next one.
({DayItem? current, DayItem? next}) nowAndNext(
  List<DayItem> items,
  DateTime now,
) {
  final sorted = [...items]..sort((a, b) => a.start.compareTo(b.start));
  DayItem? current;
  DayItem? next;
  for (final i in sorted) {
    if (!now.isBefore(i.start) && now.isBefore(i.end)) {
      current ??= i;
    } else if (i.start.isAfter(now)) {
      next ??= i;
    }
  }
  return (current: current, next: next);
}

/// Merges classes and events for one day, in time order.
List<DayItem> mergeDay(List<DayItem> classes, List<DayItem> events) =>
    [...classes, ...events]..sort((a, b) => a.start.compareTo(b.start));
