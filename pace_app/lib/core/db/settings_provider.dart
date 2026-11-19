import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../energy/low_energy.dart';
import '../time/clock.dart';
import 'app_database.dart';
import 'database_provider.dart';

// Hand-written rather than generated: the generator cannot resolve [Setting]
// because Drift emits that class in a part file during the same build.

/// Live view of the single settings row.
final settingsProvider = StreamProvider<Setting>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(),
);

/// True when the owner asked for a lighter day: the switch, or a one-day
/// light day. Every list screen reads this.
final lowEnergyProvider = Provider<bool>((ref) {
  final s = ref.watch(settingsProvider).value;
  if (s == null) return false;
  return s.lowEnergyAt(ref.watch(clockProvider)());
});
