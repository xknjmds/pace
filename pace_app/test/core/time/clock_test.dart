import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/clock.dart';

void main() {
  test('clockProvider returns the current time by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final before = DateTime.now();
    final now = container.read(clockProvider)();
    expect(now.isBefore(before), isFalse);
    expect(now.difference(before).inSeconds, lessThan(5));
  });

  test('clockProvider can be overridden with a frozen time in tests', () {
    final frozen = DateTime(2026, 11, 14, 6, 30);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => frozen)],
    );
    addTearDown(container.dispose);
    expect(container.read(clockProvider)(), frozen);
  });
}
