import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_provider.dart';

// Hand-written rather than generated: the generator cannot resolve [Setting]
// because Drift emits that class in a part file during the same build.

/// Live view of the single settings row.
final settingsProvider = StreamProvider<Setting>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(),
);

/// True when the owner asked for a lighter day. Every list screen reads this.
final lowEnergyProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).value?.lowEnergyEnabled ?? false,
);
