import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../journey/application/journey_providers.dart';
import '../domain/reward_progress.dart';

typedef RewardView = ({Reward reward, RewardProgress progress});

/// Every reward with its progress, earned and unclaimed first.
final rewardsProvider = Provider.autoDispose<AsyncValue<List<RewardView>>>((
  ref,
) {
  final rewards = ref.watch(_rewardRowsProvider);
  final inputs = ref.watch(journeyInputsProvider);
  if (rewards is! AsyncData<List<Reward>> || inputs is! AsyncData) {
    return const AsyncLoading();
  }
  final done = inputs.requireValue.doneDays;
  final views = [
    for (final r in rewards.value)
      (
        reward: r,
        progress: rewardProgress(
          createdAt: r.createdAt,
          daysNeeded: r.daysNeeded,
          doneDays: done,
          claimed: r.claimedAt != null,
        ),
      ),
  ];
  int rank(RewardView v) => v.progress.claimed
      ? 2
      : v.progress.earned
      ? 0
      : 1;
  views.sort((a, b) => rank(a).compareTo(rank(b)));
  return AsyncData(views);
});

final _rewardRowsProvider = StreamProvider.autoDispose<List<Reward>>(
  (ref) => ref.watch(appDatabaseProvider).rewardsDao.watchAll(),
);
