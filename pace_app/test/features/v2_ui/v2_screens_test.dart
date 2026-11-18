import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/blocking/application/app_gate.dart';
import 'package:pace/features/blocking/application/gate_providers.dart';
import 'package:pace/features/blocking/ui/gate_screen.dart';
import 'package:pace/features/finance/ui/money_screen.dart';
import 'package:pace/features/notes/ui/notes_screen.dart';
import 'package:pace/features/schedule/domain/schedule_parser.dart';
import 'package:pace/features/schedule/ui/import_review_screen.dart';

import '../blocking/application/gate_service_test.dart' show FakeGate;
import 'harness.dart';

void main() {
  testWidgets('import review: nothing saved until Save, gaps must be filled', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(
      tester,
      const ImportReviewScreen(
        candidates: [
          CandidateBlock(weekday: 1, subject: 'Math', start: 480, end: 540),
          CandidateBlock(weekday: 2, subject: 'PE'),
        ],
      ),
    );
    expect(find.textContaining('needs a day or time'), findsOneWidget);
    final save = find.byKey(const ValueKey('save-import'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(await h.db.classBlocksDao.getAll(), isEmpty);

    // Remove the incomplete one; now it can be saved.
    await tester.tap(find.byTooltip('Remove').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    // Monday had no first class yet, so using 08:00 is offered and on.
    expect(find.text('Monday: use 08:00'), findsOneWidget);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect((await h.db.classBlocksDao.getAll()).single.subject, 'Math');
    expect((await h.db.weekdayScheduleDao.getFor(1))!.firstClassMinutes, 480);
    await h.unmount(tester);
  });

  testWidgets('gate: the emergency unlock and master switch are always there', (
    tester,
  ) async {
    final h = Harness();
    final gate = FakeGate();
    await h.pump(
      tester,
      const GateScreen(),
      overrides: [appGateProvider.overrideWithValue(gate as AppGate)],
    );
    expect(find.byKey(const ValueKey('gate-enabled')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gate-enabled')));
    await tester.pumpAndSettle();
    expect((await h.db.settingsDao.get()).gateEnabled, isTrue);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('gate-unlock-now')),
      200,
    );
    expect(find.text('Unlock for 10 minutes now'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('notes: search titles and bodies; delete asks first', (
    tester,
  ) async {
    final h = Harness();
    await h.db.notesDao.add(title: 'Recipe', body: 'rice');
    await h.db.notesDao.add(title: 'Plans', body: 'trip');
    await h.pump(tester, const NotesScreen());
    expect(find.text('Recipe'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('notes-search')), 'trip');
    await tester.pumpAndSettle();
    expect(find.text('Recipe'), findsNothing);
    expect(find.text('Plans'), findsOneWidget);

    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this note?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(await h.db.notesDao.getAll(), hasLength(2));
    await h.unmount(tester);
  });

  testWidgets(
    'money: logging an expense updates the total, no budget is fine',
    (tester) async {
      final h = Harness();
      await h.pump(tester, const MoneyScreen());
      expect(find.textContaining('No budget set'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-expense')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('expense-amount')),
        '120.50',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-expense')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('spent-total')), findsOneWidget);
      expect(find.text('120.50'), findsWidgets);
      await h.unmount(tester);
    },
  );
}
