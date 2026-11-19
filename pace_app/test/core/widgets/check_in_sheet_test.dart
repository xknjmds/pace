import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/check_in/check_in_outcome.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/core/widgets/check_in_sheet.dart';

class _Box {
  CheckInSheetResult? result;
}

void main() {
  final now = DateTime(2026, 11, 19, 7, 30);

  Future<_Box> open(
    WidgetTester tester, {
    CheckInSubject subject = CheckInSubject.routine,
    LocalTime? planned,
    DateTime? dueAt,
    CheckInInitial? initial,
    bool lowEnergy = false,
  }) async {
    final box = _Box();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => box.result = await showCheckInSheet(
                context,
                title: 'Up',
                subject: subject,
                now: now,
                planned: planned,
                dueAt: dueAt,
                initial: initial,
                lowEnergy: lowEnergy,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return box;
  }

  bool isSelected(WidgetTester tester, String name) => tester
      .widget<Semantics>(
        find
            .descendant(
              of: find.byKey(ValueKey('check-in-$name')),
              matching: find.byType(Semantics),
            )
            .first,
      )
      .properties
      .selected!;

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('check-in-save')));
    await tester.tap(find.byKey(const ValueKey('check-in-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('past the plan, "a bit later" is preselected with a time', (
    tester,
  ) async {
    await open(tester, planned: LocalTime.of(6, 30));
    expect(isSelected(tester, 'later'), isTrue);
    expect(find.byKey(const ValueKey('check-in-time')), findsOneWidget);
    expect(find.text('07:30'), findsOneWidget);
  });

  testWidgets('choosing on time and saving returns now', (tester) async {
    final box = await open(tester, planned: LocalTime.of(6, 30));
    await tester.tap(find.byKey(const ValueKey('check-in-onTime')));
    await tester.pumpAndSettle();
    await save(tester);
    final saved = box.result! as CheckInSaved;
    expect(saved.outcome, CheckInOutcome.onTime);
    expect(saved.at, now);
    expect(saved.reason, isNull);
  });

  testWidgets("didn't happen with a quick reason", (tester) async {
    final box = await open(tester, planned: LocalTime.of(7, 20));
    await tester.tap(find.byKey(const ValueKey('check-in-didntHappen')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not feeling well'));
    await tester.pumpAndSettle();
    await save(tester);
    final saved = box.result! as CheckInSaved;
    expect(saved.outcome, CheckInOutcome.didntHappen);
    expect(saved.at, isNull);
    expect(saved.reason, 'Not feeling well');
  });

  testWidgets('low-energy mode keeps the note behind "Add a note"', (
    tester,
  ) async {
    await open(tester, lowEnergy: true);
    expect(find.byKey(const ValueKey('check-in-reason')), findsNothing);
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('check-in-reason')), findsOneWidget);
  });

  testWidgets('editing offers start over', (tester) async {
    final box = await open(
      tester,
      initial: (outcome: CheckInOutcome.onTime, at: now, reason: null),
    );
    expect(isSelected(tester, 'onTime'), isTrue);
    await tester.ensureVisible(find.byKey(const ValueKey('check-in-clear')));
    await tester.tap(find.byKey(const ValueKey('check-in-clear')));
    await tester.pumpAndSettle();
    expect(box.result, isA<CheckInCleared>());
  });

  testWidgets('a deadline past due preselects submitted after due', (
    tester,
  ) async {
    await open(
      tester,
      subject: CheckInSubject.deadline,
      dueAt: DateTime(2026, 11, 18, 23, 59),
    );
    expect(isSelected(tester, 'later'), isTrue);
    expect(find.text('Submitted after the due time'), findsOneWidget);
    expect(find.textContaining('fail'), findsNothing);
  });
}
