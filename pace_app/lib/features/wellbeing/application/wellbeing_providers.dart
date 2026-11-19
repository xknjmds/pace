import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_key.dart';
import '../../today/application/reminder_resync.dart';
import '../domain/wellbeing_rules.dart';
import 'wellbeing_service.dart';

final wellbeingServiceProvider = Provider<WellbeingService>(
  (ref) => WellbeingService(
    db: ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
    resync: ref.read(reminderResyncProvider),
  ),
);

/// Today greets a returning owner until the card is closed.
final showWelcomeBackProvider = Provider<bool>((ref) {
  final s = ref.watch(settingsProvider).value;
  final today = dateKey(ref.watch(clockProvider)());
  return s?.welcomeBackDate == today;
});

/// Whether the light day in Settings is today (not the Settings switch).
final lightDayTodayProvider = Provider<bool>((ref) {
  final s = ref.watch(settingsProvider).value;
  final today = dateKey(ref.watch(clockProvider)());
  return s?.lightDayDate == today && !(s?.lowEnergyEnabled ?? false);
});

/// Mornings done in the last [steadyLookbackDays] days, for the steady
/// mode offer.
final steadyOfferProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = ref.watch(clockProvider)();
  final s = ref.watch(settingsProvider).value;
  if (s == null) return Stream.value(false);
  return db.dailyLogsDao
      .watchBetween(now.subtract(const Duration(days: steadyLookbackDays)), now)
      .map(
        (logs) => shouldOfferSteady(
          routineDoneDates: [
            for (final l in logs)
              if (l.routineDone) DateTime.parse(l.date),
          ],
          now: now,
          steadyMode: s.steadyMode,
          dismissedAt: s.steadyOfferDismissedAt,
        ),
      );
});
