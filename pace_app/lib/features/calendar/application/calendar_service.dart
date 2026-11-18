import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';
import '../domain/google_events.dart';
import 'calendar_auth.dart';

/// How a refresh went. None of these is an error state for the owner:
/// the cache keeps showing whatever was fetched last.
enum SyncResult { synced, needsReconnect, offline, notConfigured }

/// Read-only Google Calendar sync. The one place in PACE that uses the
/// network (CLAUDE.md rule 3), and entirely optional: with it never set up,
/// nothing else changes.
class CalendarService {
  CalendarService({
    required this.db,
    required this.auth,
    required this.client,
    required this.now,
    required this.afterSync,
  });

  final AppDatabase db;
  final CalendarAuth auth;
  final http.Client client;
  final DateTime Function() now;

  /// Refreshes whatever shows events (the widget).
  final Future<void> Function() afterSync;

  /// Older than this and a launch or resume refreshes quietly.
  static const staleAfter = Duration(hours: 1);
  static const lookBack = Duration(days: 1);
  static const lookAhead = Duration(days: 14);

  Future<bool> get connected async =>
      (await db.settingsDao.get()).calendarSyncedAt != null;

  /// From the "Connect" button: asks the owner, then fetches.
  Future<SyncResult> connect() async {
    if (!auth.configured) return SyncResult.notConfigured;
    final token = await auth.interactiveToken();
    return _fetch(token);
  }

  /// Fetches with a token that needs no prompt.
  Future<SyncResult> refresh() async {
    if (!auth.configured) return SyncResult.notConfigured;
    final String? token;
    try {
      token = await auth.silentToken();
    } catch (_) {
      return SyncResult.needsReconnect;
    }
    if (token == null) return SyncResult.needsReconnect;
    return _fetch(token);
  }

  /// On launch and resume: refresh when connected and the cache is old.
  Future<SyncResult?> refreshIfStale() async {
    final synced = (await db.settingsDao.get()).calendarSyncedAt;
    if (synced == null) return null;
    if (now().toUtc().difference(synced.toUtc()) < staleAfter) return null;
    return refresh();
  }

  Future<SyncResult> _fetch(String token) async {
    final t = now();
    final http.Response res;
    try {
      res = await client.get(
        eventsUrl(t.subtract(lookBack), t.add(lookAhead)),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      return SyncResult.offline;
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      await auth.forgetToken(token);
      return SyncResult.needsReconnect;
    }
    if (res.statusCode != 200) return SyncResult.offline;
    await db.calendarEventsDao.replaceAll(parseGoogleEvents(res.body));
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(calendarSyncedAt: Value(t.toUtc())),
    );
    await afterSync();
    return SyncResult.synced;
  }

  /// Signing out forgets every cached event.
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (_) {
      // Already signed out on Google's side; the local cache still goes.
    }
    await db.calendarEventsDao.clear();
    await db.settingsDao.updateSettings(
      (s) => s.copyWith(calendarSyncedAt: const Value(null)),
    );
    await afterSync();
  }
}
