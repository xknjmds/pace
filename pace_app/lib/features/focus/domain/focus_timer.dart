// Pure timer logic for "just start". Wall-clock based: nothing ticks in
// the background, so the answer is right whenever the app looks.

/// The default and only length offered: small enough to start.
const focusMinutes = 10;

sealed class FocusState {
  const FocusState();
}

class FocusIdle extends FocusState {
  const FocusIdle();
}

class FocusRunning extends FocusState {
  const FocusRunning({required this.endsAt, required this.remaining});

  final DateTime endsAt;
  final Duration remaining;
}

/// The planned time has passed; waiting for stop or keep going.
class FocusTimeUp extends FocusState {
  const FocusTimeUp({required this.endsAt});

  final DateTime endsAt;
}

DateTime focusEndsAt(DateTime startedAt, int plannedMinutes) =>
    startedAt.add(Duration(minutes: plannedMinutes));

/// [startedAt] null means no live session.
FocusState focusStateAt({
  required DateTime now,
  required DateTime? startedAt,
  required int plannedMinutes,
}) {
  if (startedAt == null) return const FocusIdle();
  final endsAt = focusEndsAt(startedAt, plannedMinutes);
  if (!now.isBefore(endsAt)) return FocusTimeUp(endsAt: endsAt);
  return FocusRunning(endsAt: endsAt, remaining: endsAt.difference(now));
}

/// What a session is worth when it ends at [now]: whole minutes actually
/// spent, never more than planned (time after the alarm is not focus).
({int minutes, bool completed}) focusOutcome({
  required DateTime now,
  required DateTime startedAt,
  required int plannedMinutes,
}) {
  final elapsed = now.difference(startedAt).inMinutes;
  if (elapsed >= plannedMinutes) {
    return (minutes: plannedMinutes, completed: true);
  }
  return (minutes: elapsed < 0 ? 0 : elapsed, completed: false);
}

/// "9:59", "0:05". Rounds up so the display never shows 0:00 while running.
String formatRemaining(Duration remaining) {
  final total = (remaining.inMilliseconds / 1000).ceil();
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Calm words for a finished session. Starting counts, whatever the length.
String focusSummary(int minutes, {required bool completed}) {
  if (completed) return '$minutes minutes done. Nice start.';
  if (minutes < 1) return 'Stopped. Starting is the hard part.';
  if (minutes == 1) return 'Stopped after 1 minute. That counts.';
  return 'Stopped after $minutes minutes. That counts.';
}
