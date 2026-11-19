/// A moment the screen turned on or off, from Android's usage events.
class ScreenEvent {
  const ScreenEvent(this.at, {required this.on});

  final DateTime at;

  /// True for screen on or unlock, false for screen off.
  final bool on;
}

/// What the phone suggests about a night. A suggestion only: the owner
/// confirms before anything is saved.
class SleepEstimate {
  const SleepEstimate({required this.start, required this.end});

  /// Phone went quiet.
  final DateTime start;

  /// First real use after the quiet stretch.
  final DateTime end;

  Duration get length => end.difference(start);

  /// Four hours or more of quiet reads as a real night.
  bool get confident => length >= const Duration(hours: 4);
}

/// Screen-on stretches shorter than this (checking the time at 3am) do not
/// break the night.
const brief = Duration(minutes: 3);

/// A quiet stretch must be at least this long to count as sleep.
const minimumSleep = Duration(hours: 2);

/// Pure: the night's sleep as the phone saw it, or null.
///
/// Looks between [from] and [to] (for example 20:00 to noon) for the
/// longest stretch with the screen off, treating brief pickups as part of
/// the night. [events] may be in any order and may start with the screen
/// already on or off.
SleepEstimate? estimateSleep({
  required List<ScreenEvent> events,
  required DateTime from,
  required DateTime to,
}) {
  final sorted = [
    for (final e in events)
      if (!e.at.isBefore(from) && !e.at.isAfter(to)) e,
  ]..sort((a, b) => a.at.compareTo(b.at));
  if (sorted.isEmpty) return null;

  // Screen-on periods as [start, end) pairs.
  final on = <(DateTime, DateTime)>[];
  DateTime? openedAt = sorted.first.on ? null : from;
  for (final e in sorted) {
    if (e.on) {
      openedAt ??= e.at;
    } else if (openedAt != null) {
      on.add((openedAt, e.at));
      openedAt = null;
    }
  }
  if (openedAt != null) on.add((openedAt, to));

  // Drop brief pickups so they do not split the night.
  final real = [
    for (final p in on)
      if (p.$2.difference(p.$1) >= brief) p,
  ];

  // Quiet stretches between real use, including the edges of the window.
  final quiet = <(DateTime, DateTime)>[];
  var cursor = from;
  for (final p in real) {
    if (p.$1.isAfter(cursor)) quiet.add((cursor, p.$1));
    if (p.$2.isAfter(cursor)) cursor = p.$2;
  }
  if (to.isAfter(cursor)) quiet.add((cursor, to));

  (DateTime, DateTime)? best;
  for (final q in quiet) {
    // A stretch that runs to the window's end has no wake-up in it.
    if (!q.$2.isBefore(to)) continue;
    if (best == null || q.$2.difference(q.$1) > best.$2.difference(best.$1)) {
      best = q;
    }
  }
  if (best == null || best.$2.difference(best.$1) < minimumSleep) return null;
  return SleepEstimate(start: best.$1, end: best.$2);
}
