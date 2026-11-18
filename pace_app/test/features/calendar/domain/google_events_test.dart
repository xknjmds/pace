import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/calendar/domain/google_events.dart';

void main() {
  test('parses timed and all-day events, skips cancelled ones', () {
    final events = parseGoogleEvents('''
{"items": [
  {"id": "a", "summary": "Club", "start": {"dateTime": "2026-11-18T15:00:00+08:00"}, "end": {"dateTime": "2026-11-18T16:00:00+08:00"}},
  {"id": "b", "summary": "Holiday", "start": {"date": "2026-11-20"}, "end": {"date": "2026-11-21"}},
  {"id": "c", "status": "cancelled", "start": {"date": "2026-11-20"}, "end": {"date": "2026-11-21"}},
  {"id": "d", "start": {"dateTime": "2026-11-19T01:00:00Z"}, "end": {"dateTime": "2026-11-19T02:00:00Z"}}
]}''');
    expect(events.map((e) => e.externalId), ['a', 'b', 'd']);
    expect(events[0].startAt, DateTime.utc(2026, 11, 18, 7));
    expect(events[0].allDay, isFalse);
    expect(events[1].allDay, isTrue);
    expect(events[1].startAt, DateTime(2026, 11, 20));
    expect(events[2].title, '(No title)');
  });

  test('an empty reply has no events', () {
    expect(parseGoogleEvents('{}'), isEmpty);
  });

  test('builds a read-only events URL', () {
    final url = eventsUrl(
      DateTime.utc(2026, 11, 18),
      DateTime.utc(2026, 11, 25),
    );
    expect(url.host, 'www.googleapis.com');
    expect(url.queryParameters['singleEvents'], 'true');
    expect(url.queryParameters['timeMin'], '2026-11-18T00:00:00.000Z');
  });
}
