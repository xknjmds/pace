import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';

/// Notes matching a search (empty: all), newest first.
final notesSearchProvider = StreamProvider.family<List<Note>, String>(
  (ref, query) => ref.watch(appDatabaseProvider).notesDao.watchSearch(query),
);
