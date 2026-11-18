import 'dart:convert';

class Verse {
  const Verse({required this.reference, required this.text});

  final String reference;
  final String text;
}

/// Parses the bundled `assets/verses.json`.
List<Verse> parseVerses(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  return [
    for (final v in data['verses'] as List<dynamic>)
      Verse(
        reference: (v as Map<String, dynamic>)['reference'] as String,
        text: v['text'] as String,
      ),
  ];
}

/// Day of the year, 1 to 366, of the local calendar day of [day].
int dayOfYear(DateTime day) {
  final d = DateTime.utc(day.year, day.month, day.day);
  return d.difference(DateTime.utc(day.year)).inDays + 1;
}

/// Pure: the verse for [day]. Day 366 of a leap year (and any day past the
/// list) wraps around to a valid verse.
Verse? verseFor(DateTime day, List<Verse> verses) {
  if (verses.isEmpty) return null;
  return verses[(dayOfYear(day) - 1) % verses.length];
}
