import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/uuid.dart';

void main() {
  final v4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('uuidV4 returns a lowercase RFC 4122 version 4 string', () {
    final id = uuidV4();
    expect(id, matches(v4));
  });

  test('uuidV4 produces no duplicates in 10 000 draws', () {
    final ids = <String>{for (var i = 0; i < 10000; i++) uuidV4()};
    expect(ids.length, 10000);
  });
}
