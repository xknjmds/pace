import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_provider.dart';
import '../domain/verse.dart';

const versesAsset = 'assets/verses.json';

/// Loads the bundled verses once. Works offline: it is an app asset.
Future<List<Verse>> loadBundledVerses() async =>
    parseVerses(await rootBundle.loadString(versesAsset));

final versesProvider = FutureProvider<List<Verse>>((_) => loadBundledVerses());

/// Today's verse, or null when turned off or in low-energy mode.
final verseForDayProvider = Provider.family<Verse?, DateTime>((ref, day) {
  final settings = ref.watch(settingsProvider).value;
  if (settings == null || !settings.verseEnabled) return null;
  if (ref.watch(lowEnergyProvider)) return null;
  final verses = ref.watch(versesProvider).value;
  return verses == null ? null : verseFor(day, verses);
});
