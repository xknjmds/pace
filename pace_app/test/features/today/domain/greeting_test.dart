import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/today/domain/today_model.dart';

void main() {
  test('greeting follows the time of day', () {
    expect(greetingFor(DateTime(2026, 11, 16, 5)), 'Good morning');
    expect(greetingFor(DateTime(2026, 11, 16, 11, 59)), 'Good morning');
    expect(greetingFor(DateTime(2026, 11, 16, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 11, 16, 18)), 'Good evening');
    expect(greetingFor(DateTime(2026, 11, 16, 2)), 'Good evening');
  });

  test('long date reads weekday, day and month', () {
    expect(longDate(DateTime(2026, 11, 16)), 'Monday, 16 November');
    expect(longDate(DateTime(2026, 1, 4)), 'Sunday, 4 January');
  });
}
