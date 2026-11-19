import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/rewards/domain/reward_progress.dart';

void main() {
  final created = DateTime(2026, 11, 16, 20);

  RewardProgress progress(Set<String> days, {int needed = 5}) => rewardProgress(
    createdAt: created,
    daysNeeded: needed,
    doneDays: days,
    claimed: false,
  );

  test('days before the reward was set do not count', () {
    final p = progress({'2026-11-10', '2026-11-15'});
    expect(p.daysDone, 0);
    expect(p.remaining, 5);
    expect(p.earned, isFalse);
  });

  test('the day it was set counts', () {
    expect(progress({'2026-11-16'}).daysDone, 1);
  });

  test('earned once enough days are done, gaps allowed', () {
    final p = progress({
      '2026-11-16',
      '2026-11-18',
      '2026-11-25',
      '2026-12-01',
      '2026-12-20',
    });
    expect(p.earned, isTrue);
    expect(p.remaining, 0);
    expect(p.fraction, 1);
  });

  test('fraction stays between 0 and 1', () {
    expect(progress({'2026-11-17', '2026-11-18'}).fraction, closeTo(.4, 1e-9));
    expect(
      progress({'2026-11-17', '2026-11-18', '2026-11-19'}, needed: 2).fraction,
      1,
    );
  });

  test('a reward set in UTC counts from the local day', () {
    final p = rewardProgress(
      createdAt: DateTime(2026, 11, 16, 20).toUtc(),
      daysNeeded: 1,
      doneDays: {'2026-11-16'},
      claimed: false,
    );
    expect(p.earned, isTrue);
  });
}
