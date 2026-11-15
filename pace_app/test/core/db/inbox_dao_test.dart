import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('add, count, process and remove', () async {
    final dao = t.db.inboxDao;
    final a = await dao.add('buy index cards');
    t.tick();
    final b = await dao.add('email prof');
    expect(a.body, 'buy index cards');
    expect(a.processed, isFalse);
    expect(await dao.watchUnprocessedCount().first, 2);
    expect((await dao.getUnprocessed()).map((i) => i.id), [a.id, b.id]);

    await dao.markProcessed(a.id);
    expect((await dao.getUnprocessed()).map((i) => i.id), [b.id]);

    await dao.remove(b.id);
    expect(await dao.getUnprocessed(), isEmpty);
    expect(await dao.watchUnprocessedCount().first, 0);
  });
}
