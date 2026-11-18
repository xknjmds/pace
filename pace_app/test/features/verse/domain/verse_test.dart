import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/verse/domain/verse.dart';

void main() {
  final verses = List.generate(
    365,
    (i) => Verse(reference: 'R$i', text: 'T$i'),
  );

  test('day of year counts from 1', () {
    expect(dayOfYear(DateTime(2026, 1, 1)), 1);
    expect(dayOfYear(DateTime(2026, 12, 31)), 365);
    expect(dayOfYear(DateTime(2028, 12, 31)), 366);
  });

  test('a new verse each day', () {
    expect(verseFor(DateTime(2026, 11, 18), verses)!.reference, 'R321');
    expect(verseFor(DateTime(2026, 11, 19), verses)!.reference, 'R322');
  });

  test('leap-year day 366 falls back to a valid verse', () {
    expect(verseFor(DateTime(2028, 12, 31), verses)!.reference, 'R0');
  });

  test('no verses, no verse', () {
    expect(verseFor(DateTime(2026, 1, 1), const []), isNull);
  });

  test('the bundled asset holds 365 verses with text', () {
    final list = parseVerses(File('assets/verses.json').readAsStringSync());
    expect(list, hasLength(365));
    expect(
      list.every((v) => v.text.isNotEmpty && v.reference.isNotEmpty),
      isTrue,
    );
  });
}
