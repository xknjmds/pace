import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/schedule/domain/schedule_parser.dart';

OcrLine line(String text, double left, double top, [double width = 80]) =>
    OcrLine(text, left: left, top: top, right: left + width, bottom: top + 20);

int hm(int h, int m) => h * 60 + m;

void main() {
  group('list layout', () {
    test('clean input under day headings', () {
      final blocks = parseSchedule([
        line('Monday', 0, 0),
        line('8:00 - 9:30 Math Rm 204', 0, 30, 200),
        line('10:00-11:00 English', 0, 60, 200),
        line('Tuesday', 0, 90),
        line('1:00 - 2:30 pm Biology', 0, 120, 200),
      ]);
      expect(blocks, [
        CandidateBlock(
          weekday: 1,
          subject: 'Math',
          start: hm(8, 0),
          end: hm(9, 30),
          room: '204',
        ),
        CandidateBlock(
          weekday: 1,
          subject: 'English',
          start: hm(10, 0),
          end: hm(11, 0),
        ),
        CandidateBlock(
          weekday: 2,
          subject: 'Biology',
          start: hm(13, 0),
          end: hm(14, 30),
        ),
      ]);
      expect(blocks.every((b) => b.complete), isTrue);
    });

    test('day codes like MWF expand to each day', () {
      final blocks = parseSchedule([
        line('MWF 7:30-8:30 AM Physics', 0, 0, 300),
      ]);
      expect(blocks.map((b) => b.weekday), [1, 3, 5]);
      expect(blocks.first.start, hm(7, 30));
      expect(blocks.first.subject, 'Physics');
    });

    test('TTh means Tuesday and Thursday', () {
      final blocks = parseSchedule([line('TTh 11:00-1:00 PM Chem', 0, 0, 300)]);
      expect(blocks.map((b) => b.weekday), [2, 4]);
      expect(blocks.first.start, hm(11, 0));
      expect(blocks.first.end, hm(13, 0));
    });

    test('subject on the line after its time', () {
      final blocks = parseSchedule([
        line('Wednesday', 0, 0),
        line('9:00-10:00', 0, 30),
        line('History', 0, 60),
      ]);
      expect(blocks.single.subject, 'History');
      expect(blocks.single.start, hm(9, 0));
    });

    test('missing times are kept, incomplete, for the owner to fill in', () {
      final blocks = parseSchedule([line('Friday', 0, 0), line('PE', 0, 30)]);
      expect(blocks.single.weekday, 5);
      expect(blocks.single.subject, 'PE');
      expect(blocks.single.start, isNull);
      expect(blocks.single.complete, isFalse);
    });

    test('stray lines without a day or time are dropped', () {
      expect(parseSchedule([line('Class schedule 2026', 0, 0)]), isEmpty);
    });

    test('empty input gives nothing', () {
      expect(parseSchedule(const []), isEmpty);
    });
  });

  group('grid layout', () {
    test('days across the top, times down the side', () {
      final blocks = parseSchedule([
        line('Mon', 100, 0, 40),
        line('Tue', 200, 0, 40),
        line('8:00-9:00', 0, 50),
        line('9:00-10:00', 0, 100),
        line('Math', 100, 50, 40),
        line('Art', 200, 50, 40),
        line('Rm 12', 200, 70, 40),
        line('Science', 100, 100, 60),
      ]);
      expect(
        blocks,
        containsAll([
          CandidateBlock(
            weekday: 1,
            subject: 'Math',
            start: hm(8, 0),
            end: hm(9, 0),
          ),
          CandidateBlock(
            weekday: 2,
            subject: 'Art',
            start: hm(8, 0),
            end: hm(9, 0),
            room: '12',
          ),
          CandidateBlock(
            weekday: 1,
            subject: 'Science',
            start: hm(9, 0),
            end: hm(10, 0),
          ),
        ]),
      );
      expect(blocks, hasLength(3));
    });

    test('several day names on one recognized line still make columns', () {
      final blocks = parseSchedule([
        const OcrLine(
          'Monday Tuesday',
          left: 100,
          top: 0,
          right: 300,
          bottom: 20,
        ),
        line('8:00-9:00', 0, 50),
        line('Math', 120, 50, 40),
        line('Art', 250, 50, 40),
      ]);
      expect(blocks.map((b) => (b.weekday, b.subject)), [
        (1, 'Math'),
        (2, 'Art'),
      ]);
    });
  });

  group('time-block grid rules', () {
    test('single hour labels down the side give each row its hour', () {
      final blocks = parseSchedule([
        line('Mon', 100, 0, 40),
        line('Tue', 200, 0, 40),
        line('7:00', 0, 40, 40),
        line('8:00', 0, 80, 40),
        line('9:00', 0, 120, 40),
        line('Math', 100, 45, 40),
        line('Art', 200, 85, 40),
      ]);
      expect(blocks.map((b) => (b.weekday, b.subject, b.start, b.end)), [
        (1, 'Math', hm(7, 0), hm(8, 0)),
        (2, 'Art', hm(8, 0), hm(9, 0)),
      ]);
    });

    test('a course code opens a class; room and teacher lines join it', () {
      final blocks = parseSchedule([
        line('MONDAY', 100, 0, 60),
        line('TUESDAY', 300, 0, 60),
        line('8:00 - 9:00', 0, 40),
        line('9:00 - 10:00', 0, 80),
        line('CS 101 - INTRO TO', 90, 40, 150),
        line('PROGRAMMING', 100, 55, 100),
        line('LAB 4 - PROF. M. REYES', 90, 70, 150),
        line('MATH 202 - ALGEBRA', 90, 85, 150),
        line('RM 12', 100, 100, 50),
      ]);
      expect(blocks, hasLength(2));
      expect(blocks.first.subject, 'CS 101 - INTRO TO PROGRAMMING');
      expect(blocks.first.room, 'LAB 4');
      expect(blocks.last.subject, 'MATH 202 - ALGEBRA');
      expect(blocks.last.room, '12');
    });

    test('a room code that looks like a course code stays a room', () {
      final blocks = parseSchedule([
        line('MONDAY', 100, 0, 60),
        line('TUESDAY', 300, 0, 60),
        line('8:00 - 9:00', 0, 40),
        line('IT 3119 - DATABASES', 90, 40, 150),
        line('BH101 -PROF. A. CRUZ', 90, 55, 150),
      ]);
      expect(blocks.single.room, 'BH101');
      expect(blocks.single.subject, 'IT 3119 - DATABASES');
    });

    test('lunch is not a class and a table under the grid is ignored', () {
      final blocks = parseSchedule([
        line('MONDAY', 100, 0, 60),
        line('TUESDAY', 300, 0, 60),
        line('12:00 - 1:00', 0, 40),
        line('1:00 - 2:00', 0, 80),
        line('LUNCHBREAK', 150, 40, 80),
        line('IT 3121 - APPS', 90, 80, 150),
        line('Course No.', 0, 200),
        line('IT 3121 - APPS', 90, 220, 150),
      ]);
      expect(blocks.map((b) => (b.subject, b.start)), [
        ('IT 3121 - APPS', hm(13, 0)),
      ]);
    });
  });

  group('overlaps', () {
    test('same day and overlapping times are flagged', () {
      final blocks = [
        CandidateBlock(
          weekday: 1,
          subject: 'A',
          start: hm(8, 0),
          end: hm(9, 0),
        ),
        CandidateBlock(
          weekday: 1,
          subject: 'B',
          start: hm(8, 30),
          end: hm(9, 30),
        ),
        CandidateBlock(
          weekday: 1,
          subject: 'C',
          start: hm(9, 30),
          end: hm(10, 0),
        ),
        CandidateBlock(
          weekday: 2,
          subject: 'D',
          start: hm(8, 0),
          end: hm(9, 0),
        ),
      ];
      expect(overlappingPairs(blocks), [(0, 1)]);
    });

    test('blocks touching end to start do not overlap', () {
      final blocks = [
        CandidateBlock(
          weekday: 3,
          subject: 'A',
          start: hm(8, 0),
          end: hm(9, 0),
        ),
        CandidateBlock(
          weekday: 3,
          subject: 'B',
          start: hm(9, 0),
          end: hm(10, 0),
        ),
      ];
      expect(overlappingPairs(blocks), isEmpty);
    });

    test('overlapping blocks from a photo are both kept for review', () {
      final blocks = parseSchedule([
        line('Monday', 0, 0),
        line('8:00-9:30 Math', 0, 30, 200),
        line('9:00-10:00 Club', 0, 60, 200),
      ]);
      expect(blocks, hasLength(2));
      expect(overlappingPairs(blocks), [(0, 1)]);
    });
  });

  test('earliest start per weekday ignores incomplete blocks', () {
    final earliest = earliestStartByWeekday([
      CandidateBlock(weekday: 1, subject: 'B', start: hm(9, 0), end: hm(10, 0)),
      CandidateBlock(weekday: 1, subject: 'A', start: hm(7, 30), end: hm(8, 0)),
      const CandidateBlock(weekday: 2, subject: 'C'),
    ]);
    expect(earliest, {1: hm(7, 30)});
  });
}
