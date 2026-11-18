import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pace/features/calendar/application/calendar_auth.dart';
import 'package:pace/features/calendar/application/calendar_service.dart';

import '../../../core/db/test_db.dart';

class FakeAuth implements CalendarAuth {
  FakeAuth({this.token = 'tok', this.configured = true});

  String? token;
  final forgotten = <String>[];
  var signedOut = false;

  @override
  final bool configured;
  @override
  Future<String?> silentToken() async => token;
  @override
  Future<String> interactiveToken() async => 'fresh';
  @override
  Future<void> forgetToken(String t) async => forgotten.add(t);
  @override
  Future<void> signOut() async => signedOut = true;
}

const reply = '''
{"items": [{"id": "e1", "summary": "Club", "start": {"dateTime": "2026-11-14T09:00:00Z"}, "end": {"dateTime": "2026-11-14T10:00:00Z"}}]}
''';

void main() {
  late TestDb t;
  var synced = 0;

  setUp(() {
    t = TestDb();
    synced = 0;
  });
  tearDown(() => t.close());

  CalendarService service(FakeAuth auth, http.Client client) => CalendarService(
    db: t.db,
    auth: auth,
    client: client,
    now: () => t.now,
    afterSync: () async => synced++,
  );

  Future<int> cached() async => (await t.db.calendarEventsDao.between(
    t.now.subtract(const Duration(days: 2)),
    t.now.add(const Duration(days: 2)),
  )).length;

  test('connect fetches read-only and caches the events', () async {
    late http.Request seen;
    final s = service(
      FakeAuth(),
      MockClient((r) async {
        seen = r;
        return http.Response(reply, 200);
      }),
    );
    expect(await s.connect(), SyncResult.synced);
    expect(seen.headers['Authorization'], 'Bearer fresh');
    expect(seen.method, 'GET');
    expect(await cached(), 1);
    expect(await s.connected, isTrue);
    expect(synced, 1);
  });

  test('offline keeps the cache and says so calmly', () async {
    final ok = service(
      FakeAuth(),
      MockClient((_) async => http.Response(reply, 200)),
    );
    await ok.refresh();
    final offline = service(
      FakeAuth(),
      MockClient((_) async => throw http.ClientException('no network')),
    );
    expect(await offline.refresh(), SyncResult.offline);
    expect(await cached(), 1);
  });

  test('a rejected token is dropped and asks to reconnect', () async {
    final auth = FakeAuth();
    final s = service(auth, MockClient((_) async => http.Response('', 401)));
    expect(await s.refresh(), SyncResult.needsReconnect);
    expect(auth.forgotten, ['tok']);
  });

  test('no silent token means reconnect, without a network call', () async {
    var calls = 0;
    final s = service(
      FakeAuth()..token = null,
      MockClient((_) async {
        calls++;
        return http.Response(reply, 200);
      }),
    );
    expect(await s.refresh(), SyncResult.needsReconnect);
    expect(calls, 0);
  });

  test('signing out clears cached events', () async {
    final auth = FakeAuth();
    final s = service(auth, MockClient((_) async => http.Response(reply, 200)));
    await s.connect();
    await s.signOut();
    expect(auth.signedOut, isTrue);
    expect(await cached(), 0);
    expect(await s.connected, isFalse);
  });

  test('never set up: nothing happens and nothing is fetched', () async {
    var calls = 0;
    final s = service(
      FakeAuth(configured: false),
      MockClient((_) async {
        calls++;
        return http.Response(reply, 200);
      }),
    );
    expect(await s.refresh(), SyncResult.notConfigured);
    expect(await s.refreshIfStale(), isNull);
    expect(calls, 0);
  });
}
