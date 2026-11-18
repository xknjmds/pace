import 'dart:convert';

import '../../../core/db/daos/calendar_events_dao.dart' show FetchedEvent;

/// Pure: events from a Google Calendar `events.list` reply. Cancelled
/// events are skipped; all-day events span their dates in local time.
List<FetchedEvent> parseGoogleEvents(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final items = (data['items'] as List<dynamic>? ?? const []);
  final out = <FetchedEvent>[];
  for (final raw in items) {
    final e = raw as Map<String, dynamic>;
    if (e['status'] == 'cancelled') continue;
    final id = e['id'] as String?;
    final start = e['start'] as Map<String, dynamic>?;
    final end = e['end'] as Map<String, dynamic>?;
    if (id == null || start == null || end == null) continue;
    final allDay = start['dateTime'] == null;
    final s = _when(start);
    final f = _when(end);
    if (s == null || f == null) continue;
    out.add((
      externalId: id,
      title: (e['summary'] as String?)?.trim().isNotEmpty == true
          ? (e['summary'] as String).trim()
          : '(No title)',
      startAt: s,
      endAt: f,
      allDay: allDay,
    ));
  }
  return out;
}

DateTime? _when(Map<String, dynamic> m) {
  final dt = m['dateTime'] as String?;
  if (dt != null) return DateTime.tryParse(dt);
  final d = m['date'] as String?;
  if (d == null) return null;
  final parsed = DateTime.tryParse(d);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// The `events.list` URL for [from] to [to].
Uri eventsUrl(DateTime from, DateTime to) =>
    Uri.https('www.googleapis.com', '/calendar/v3/calendars/primary/events', {
      'timeMin': from.toUtc().toIso8601String(),
      'timeMax': to.toUtc().toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '250',
    });
