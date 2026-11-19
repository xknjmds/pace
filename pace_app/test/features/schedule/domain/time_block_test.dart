import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/schedule/domain/schedule_parser.dart';

import 'time_block_fixture.dart';

int hm(int h, int m) => h * 60 + m;

/// (weekday, start, end, room, subject starts with) for every class on the
/// owner's real schedule, read off the image and its summary table.
final expected = [
  (1, hm(8, 0), hm(9, 0), 'BH101', 'IT 3119'),
  (1, hm(9, 0), hm(10, 0), 'AVR', 'ITAS3123'),
  (1, hm(10, 0), hm(11, 0), 'BH202', 'IT 3121'),
  (1, hm(11, 0), hm(12, 30), 'LAB 3', 'ITPE3124'),
  (1, hm(13, 0), hm(15, 0), 'ROOM 2', 'IT 3122'),
  (1, hm(15, 30), hm(17, 0), 'AVR', 'LC 3101'),
  (2, hm(8, 0), hm(9, 30), 'LAB 3', 'IT 3120'),
  (2, hm(9, 30), hm(10, 30), 'ROOM 2', 'ITAS3123'),
  (2, hm(11, 0), hm(12, 30), 'LAB 2', 'IT 3121'),
  (2, hm(13, 0), hm(14, 30), 'BH102', 'GEE 2102'),
  (2, hm(14, 30), hm(15, 30), 'BH102', 'IT 3121'),
  (2, hm(16, 0), hm(17, 0), 'BH202', 'IT 3120'),
  (3, hm(8, 0), hm(9, 0), 'BH101', 'IT 3119'),
  (3, hm(9, 30), hm(11, 0), 'LAB 3', 'IT 3119'),
  (3, hm(11, 0), hm(12, 30), 'LAB 3', 'ITPE3124'),
  (3, hm(13, 0), hm(15, 0), 'ROOM 2', 'IT 3122'),
  (3, hm(15, 30), hm(17, 0), 'AVR', 'LC 3101'),
  (4, hm(8, 0), hm(9, 30), 'LAB 3', 'IT 3120'),
  (4, hm(10, 0), hm(11, 0), 'BH202', 'IT 3120'),
  (4, hm(11, 0), hm(12, 30), 'LAB 2', 'IT 3121'),
  (4, hm(14, 0), hm(15, 30), 'LAB 3', 'IT 3119'),
  (4, hm(15, 30), hm(17, 0), 'BH102', 'GEE 2102'),
  (5, hm(8, 0), hm(11, 0), 'ONLINE', 'ITAS3123'),
  (5, hm(15, 0), hm(17, 0), 'ONLINE', 'ITPE3124'),
];

void main() {
  group('time-block schedule with its pixels', () {
    late List<CandidateBlock> blocks;

    testWidgets('every class, with its full time span', (tester) async {
      final image = (await tester.runAsync(timeBlockImage))!;
      blocks = parseSchedule(timeBlockLines(), image: image);
      expect(blocks, hasLength(expected.length));
      for (final (i, e) in expected.indexed) {
        final b = blocks[i];
        expect(
          (b.weekday, b.start, b.end, b.room),
          (e.$1, e.$2, e.$3, e.$4),
          reason: 'class $i: ${b.subject}',
        );
        expect(b.subject, startsWith(e.$5));
        expect(b.complete, isTrue);
      }
    });

    testWidgets('titles are joined; teachers, breaks and the table left out', (
      tester,
    ) async {
      final image = (await tester.runAsync(timeBlockImage))!;
      blocks = parseSchedule(timeBlockLines(), image: image);
      expect(
        blocks.first.subject,
        'IT 3119 - ADVANCE DATABASE MANAGEMENT SYSTEM',
      );
      for (final b in blocks) {
        expect(b.subject, isNot(matches(RegExp(r'PROF|DR\.|INSTR'))));
        expect(b.subject.toUpperCase(), isNot(contains('LUNCH')));
        // Nothing from the summary table under the grid.
        expect(b.subject, isNot(contains('CABUGUASON')));
      }
      expect(overlappingPairs(blocks), isEmpty);
    });

    testWidgets('pixels from another photo are ignored', (tester) async {
      final image = (await tester.runAsync(timeBlockImage))!;
      final small = RgbaImage(100, 100, image.bytes);
      final fromText = parseSchedule(timeBlockLines());
      expect(parseSchedule(timeBlockLines(), image: small), fromText);
    });
  });

  group('time-block schedule from text alone', () {
    final blocks = parseSchedule(timeBlockLines());

    test('one block per class, with day, subject and room', () {
      expect(blocks, hasLength(expected.length));
      for (final (i, e) in expected.indexed) {
        final b = blocks[i];
        expect((b.weekday, b.room), (e.$1, e.$4), reason: b.subject);
        expect(b.subject, startsWith(e.$5));
      }
    });

    test('top-aligned boxes start on time', () {
      expect(blocks.first.start, hm(8, 0));
      expect(blocks.first.end, hm(9, 0));
      expect(blocks[1].start, hm(9, 0));
    });
  });
}
