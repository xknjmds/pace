import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/time/clock.dart';
import '../../schedule/application/schedule_providers.dart';
import 'calendar_auth.dart';
import 'calendar_service.dart';

final calendarAuthProvider = Provider<CalendarAuth>(
  (ref) => ref.watch(platformFeaturesProvider).calendarSync
      ? GoogleCalendarAuth()
      : const NoCalendarAuth(),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService(
    db: ref.watch(appDatabaseProvider),
    auth: ref.watch(calendarAuthProvider),
    client: ref.watch(httpClientProvider),
    now: ref.watch(clockProvider),
    afterSync: () => ref.read(scheduleServiceProvider).publishWidget(),
  ),
);

/// Cached events on the local day keyed `yyyy-MM-dd`.
final eventsOnDayProvider = StreamProvider.family<List<CalendarEvent>, String>((
  ref,
  key,
) {
  final day = DateTime.parse(key);
  return ref
      .watch(appDatabaseProvider)
      .calendarEventsDao
      .watchBetween(day, DateTime(day.year, day.month, day.day + 1));
});
