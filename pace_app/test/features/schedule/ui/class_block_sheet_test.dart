import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/schedule/domain/schedule_parser.dart';
import 'package:pace/features/schedule/ui/class_block_sheet.dart';

class _Result {
  CandidateBlock? block;
}

void main() {
  Future<_Result> open(WidgetTester tester, CandidateBlock initial) async {
    final result = _Result();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result.block = await showClassBlockSheet(
                context,
                initial: initial,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> typeRoomAndSave(WidgetTester tester, String room) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Room (optional)'),
      room,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  const block = CandidateBlock(
    weekday: DateTime.monday,
    subject: 'Physics',
    start: 8 * 60,
    end: 9 * 60,
  );

  testWidgets('a room typed last is saved', (tester) async {
    final result = await open(tester, block);
    await typeRoomAndSave(tester, 'B204');
    expect(result.block!.room, 'B204');
  });

  testWidgets('clearing only the room removes it', (tester) async {
    final result = await open(tester, block.copyWith(room: 'B204'));
    await typeRoomAndSave(tester, '');
    expect(result.block!.room, isNull);
  });
}
