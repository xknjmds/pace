import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/deadlines/domain/submission.dart';

void main() {
  final due = DateTime(2026, 11, 20, 23, 59);

  test('at or before the due time is on time', () {
    expect(isLateSubmission(dueAt: due, submittedAt: due), isFalse);
    expect(
      isLateSubmission(dueAt: due, submittedAt: DateTime(2026, 11, 20, 9)),
      isFalse,
    );
  });

  test('after the due time is late', () {
    expect(
      isLateSubmission(dueAt: due, submittedAt: DateTime(2026, 11, 21, 0, 1)),
      isTrue,
    );
  });

  test('UTC and local instants compare as instants', () {
    expect(isLateSubmission(dueAt: due.toUtc(), submittedAt: due), isFalse);
  });

  test('countLateSubmissions counts only late ones', () {
    expect(
      countLateSubmissions([
        (dueAt: due, submittedAt: due),
        (dueAt: due, submittedAt: due.add(const Duration(hours: 1))),
        (dueAt: due, submittedAt: null),
      ]),
      1,
    );
  });
}
