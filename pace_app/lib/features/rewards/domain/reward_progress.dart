import '../../../core/time/date_key.dart';

/// Where a self-set reward stands. Days only add up; nothing expires.
class RewardProgress {
  const RewardProgress({
    required this.daysDone,
    required this.daysNeeded,
    required this.claimed,
  });

  /// Days with something done since the reward was set.
  final int daysDone;
  final int daysNeeded;
  final bool claimed;

  bool get earned => daysDone >= daysNeeded;
  int get remaining => earned ? 0 : daysNeeded - daysDone;

  /// 0 to 1, for a calm progress bar.
  double get fraction =>
      daysNeeded <= 0 ? 1 : (daysDone / daysNeeded).clamp(0, 1).toDouble();
}

/// Pure: progress toward a reward set on [createdAt]. Counts the days in
/// [doneDays] (`yyyy-MM-dd`) from the day it was set, that day included,
/// so a reward set after a good morning already has its first day.
RewardProgress rewardProgress({
  required DateTime createdAt,
  required int daysNeeded,
  required Set<String> doneDays,
  required bool claimed,
}) {
  final from = dateKey(createdAt);
  return RewardProgress(
    daysDone: doneDays.where((d) => d.compareTo(from) >= 0).length,
    daysNeeded: daysNeeded,
    claimed: claimed,
  );
}
