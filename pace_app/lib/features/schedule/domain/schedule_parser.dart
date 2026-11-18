/// Pure Dart: recognized text from a photo of a class schedule, turned into
/// candidate class blocks for the owner to review. Nothing here is trusted
/// (CLAUDE.md rule 10); the review screen decides what is saved.
library;

/// One line of recognized text and where it sat in the image.
class OcrLine {
  const OcrLine(
    this.text, {
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
  double get height => (bottom - top).abs();
}

/// A class block as far as the photo could tell. Times are minutes since
/// midnight; any of [weekday], [start] and [end] may be missing.
class CandidateBlock {
  const CandidateBlock({
    this.weekday,
    required this.subject,
    this.start,
    this.end,
    this.room,
  });

  /// [DateTime.monday] to [DateTime.sunday].
  final int? weekday;
  final String subject;
  final int? start;
  final int? end;
  final String? room;

  /// Ready to save: a day, a name and a start before the end.
  bool get complete =>
      weekday != null &&
      subject.trim().isNotEmpty &&
      start != null &&
      end != null &&
      start! < end!;

  CandidateBlock copyWith({
    int? weekday,
    String? subject,
    int? start,
    int? end,
    String? room,
  }) => CandidateBlock(
    weekday: weekday ?? this.weekday,
    subject: subject ?? this.subject,
    start: start ?? this.start,
    end: end ?? this.end,
    room: room ?? this.room,
  );

  @override
  bool operator ==(Object other) =>
      other is CandidateBlock &&
      other.weekday == weekday &&
      other.subject == subject &&
      other.start == start &&
      other.end == end &&
      other.room == room;

  @override
  int get hashCode => Object.hash(weekday, subject, start, end, room);

  @override
  String toString() =>
      'CandidateBlock($weekday, $subject, $start-$end, room: $room)';
}

const _dayWords = {
  'monday': 1,
  'mon': 1,
  'tuesday': 2,
  'tues': 2,
  'tue': 2,
  'wednesday': 3,
  'wed': 3,
  'thursday': 4,
  'thurs': 4,
  'thur': 4,
  'thu': 4,
  'friday': 5,
  'fri': 5,
  'saturday': 6,
  'sat': 6,
  'sunday': 7,
  'sun': 7,
};

final _dayPattern = RegExp(
  r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|'
  r'mon|tues|tue|wed|thurs|thur|thu|fri|sat|sun)\b\.?',
  caseSensitive: false,
);

/// Day letter codes as printed on school schedules: MWF, TTh, M/W/F.
final _letterDays = RegExp(
  r'^(?:(?:th|su|sa|m|t|w|f|s)[/,]?){2,7}$',
  caseSensitive: false,
);

final _time = r'(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?|am|pm)?';
final _range = RegExp(
  '$_time\\s*(?:-|–|—|~|to)\\s*$_time',
  caseSensitive: false,
);

final _room = RegExp(
  r'\b(?:rm|room|r)\.?\s*[-#:]?\s*([a-z]?\d+[a-z]?|[a-z]\d*)\b',
  caseSensitive: false,
);

/// Pure: candidate blocks from [lines]. Uses the grid reading when the
/// photo has day names across the top, and a line-by-line reading
/// otherwise.
List<CandidateBlock> parseSchedule(List<OcrLine> lines) {
  final clean = [
    for (final l in lines)
      if (l.text.trim().isNotEmpty) l,
  ];
  final grid = _parseGrid(clean);
  return grid ?? _parseList(clean);
}

/// Pairs of indexes into [blocks] that share a day and overlap in time.
List<(int, int)> overlappingPairs(List<CandidateBlock> blocks) {
  final out = <(int, int)>[];
  for (var i = 0; i < blocks.length; i++) {
    for (var j = i + 1; j < blocks.length; j++) {
      final a = blocks[i];
      final b = blocks[j];
      if (a.weekday == null || a.weekday != b.weekday) continue;
      if (a.start == null ||
          a.end == null ||
          b.start == null ||
          b.end == null) {
        continue;
      }
      if (a.start! < b.end! && b.start! < a.end!) out.add((i, j));
    }
  }
  return out;
}

/// Earliest start per weekday among complete [blocks].
Map<int, int> earliestStartByWeekday(Iterable<CandidateBlock> blocks) {
  final out = <int, int>{};
  for (final b in blocks.where((b) => b.complete)) {
    final current = out[b.weekday!];
    if (current == null || b.start! < current) out[b.weekday!] = b.start!;
  }
  return out;
}

// ---------------------------------------------------------------------------

/// (start, end) minutes for the first time range in [text], and the text
/// with it removed.
({int start, int end, String rest})? _takeRange(String text) {
  final m = _range.firstMatch(text);
  if (m == null) return null;
  final sh = int.parse(m[1]!);
  final sm = int.tryParse(m[2] ?? '') ?? 0;
  final eh = int.parse(m[4]!);
  final em = int.tryParse(m[5] ?? '') ?? 0;
  if (sh > 23 || eh > 23 || sm > 59 || em > 59) return null;
  // A bare "8 - 9" with no minutes and no am/pm is likely not a time.
  if (m[2] == null && m[5] == null && m[3] == null && m[6] == null) {
    return null;
  }
  final sSuffix = _suffix(m[3]);
  final eSuffix = _suffix(m[6]);
  var end = _resolve(eh, em, eSuffix, null);
  var start = _resolve(sh, sm, sSuffix ?? eSuffix, null);
  if (sSuffix == null && start > end && eSuffix != null) {
    // "11:00-1:00 pm": the start is still the morning.
    start = _resolve(sh, sm, 'am', null);
  }
  if (sSuffix == null && eSuffix == null) {
    start = _schoolHour(sh) * 60 + sm;
    end = _schoolHour(eh) * 60 + em;
    if (end <= start && eh < 12) end = (eh + 12) * 60 + em;
  }
  if (end <= start) return null;
  final rest = text.replaceRange(m.start, m.end, ' ');
  return (start: start, end: end, rest: rest);
}

String? _suffix(String? raw) {
  if (raw == null) return null;
  return raw.toLowerCase().startsWith('p') ? 'pm' : 'am';
}

int _resolve(int h, int m, String? suffix, int? fallback) {
  if (suffix == null) return _schoolHour(h) * 60 + m;
  var hour = h % 12;
  if (suffix == 'pm') hour += 12;
  return hour * 60 + m;
}

/// Without am/pm, school hours: 7 to 12 are as written, 1 to 6 are pm.
int _schoolHour(int h) => (h >= 1 && h <= 6) ? h + 12 : h;

/// Every weekday named in [text], in order, and the text without them.
({List<int> days, String rest}) _takeDays(String text) {
  final days = <int>[];
  var rest = text.replaceAllMapped(_dayPattern, (m) {
    final d = _dayWords[m[1]!.toLowerCase()];
    if (d != null && !days.contains(d)) days.add(d);
    return ' ';
  });
  // Letter codes like "MWF" or "TTh", as a word of their own.
  rest = rest.replaceAllMapped(RegExp(r'\S+'), (m) {
    final word = m[0]!;
    if (!_letterDays.hasMatch(word) || word.length < 2) return word;
    final codes = _letterCodes(word);
    if (codes == null) return word;
    for (final d in codes) {
      if (!days.contains(d)) days.add(d);
    }
    return ' ';
  });
  return (days: days, rest: rest);
}

List<int>? _letterCodes(String word) {
  // Only words written in capitals count ("MWF", "TTh"), so ordinary words
  // such as "with" are left alone.
  if (word[0] != word[0].toUpperCase()) return null;
  final w = word.replaceAll(RegExp(r'[/,]'), '').toLowerCase();
  final out = <int>[];
  var i = 0;
  while (i < w.length) {
    final two = i + 1 < w.length ? w.substring(i, i + 2) : '';
    if (two == 'th') {
      out.add(4);
      i += 2;
    } else if (two == 'sa') {
      out.add(6);
      i += 2;
    } else if (two == 'su') {
      out.add(7);
      i += 2;
    } else {
      final d = switch (w[i]) {
        'm' => 1,
        't' => 2,
        'w' => 3,
        'f' => 5,
        's' => 6,
        _ => null,
      };
      if (d == null) return null;
      out.add(d);
      i++;
    }
  }
  return out.length >= 2 ? out : null;
}

({String? room, String rest}) _takeRoom(String text) {
  final m = _room.firstMatch(text);
  if (m == null) return (room: null, rest: text);
  return (
    room: m[1]!.toUpperCase(),
    rest: text.replaceRange(m.start, m.end, ' '),
  );
}

String _tidy(String s) => s
    .replaceAll(RegExp(r'[|•·,;:]+'), ' ')
    .replaceAll(RegExp(r'^\s*[-–—]+|[-–—]+\s*$'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _onlyDays(String text) {
  final d = _takeDays(text);
  return d.days.isNotEmpty && _tidy(d.rest).isEmpty;
}

// -- line by line -----------------------------------------------------------

List<CandidateBlock> _parseList(List<OcrLine> lines) {
  final sorted = [...lines]
    ..sort((a, b) {
      final dy = a.top.compareTo(b.top);
      return dy != 0 ? dy : a.left.compareTo(b.left);
    });
  final out = <CandidateBlock>[];
  var currentDays = <int>[];
  for (var i = 0; i < sorted.length; i++) {
    var text = sorted[i].text;
    final days = _takeDays(text);
    if (days.days.isNotEmpty && _tidy(days.rest).isEmpty) {
      currentDays = days.days; // A heading such as "Monday".
      continue;
    }
    final range = _takeRange(days.rest);
    final room = _takeRoom(range?.rest ?? days.rest);
    var subject = _tidy(room.rest);
    var roomName = room.room;
    // "8:00-9:30" on its own line, with the subject on the next line.
    if (range != null && subject.isEmpty && i + 1 < sorted.length) {
      final next = sorted[i + 1].text;
      if (_takeRange(next) == null && !_onlyDays(next)) {
        final r = _takeRoom(next);
        subject = _tidy(r.rest);
        roomName ??= r.room;
        i++;
      }
    }
    if (subject.isEmpty) continue;
    final forDays = days.days.isNotEmpty ? days.days : currentDays;
    if (range == null && days.days.isEmpty) {
      // A stray line (a title, a teacher): only kept under a day heading.
      if (currentDays.isEmpty) continue;
    }
    for (final d in forDays.isEmpty ? <int?>[null] : forDays) {
      out.add(
        CandidateBlock(
          weekday: d,
          subject: subject,
          start: range?.start,
          end: range?.end,
          room: roomName,
        ),
      );
    }
  }
  return out;
}

// -- grid --------------------------------------------------------------------

class _Column {
  _Column(this.weekday, this.x);
  final int weekday;
  final double x;
}

List<CandidateBlock>? _parseGrid(List<OcrLine> lines) {
  // Day headings, splitting a line that holds several ("Mon Tue Wed").
  final columns = <_Column>[];
  final headerLines = <OcrLine>{};
  // Day headings only make a grid when they share one row across the top.
  final dayLines = lines.where((l) => _onlyDays(l.text)).toList();
  if (dayLines.isEmpty) return null;
  final rowTop = dayLines.map((l) => l.top).reduce((a, b) => a < b ? a : b);
  final tolerance = dayLines
      .map((l) => l.height)
      .reduce((a, b) => a > b ? a : b);
  for (final l in dayLines) {
    if ((l.top - rowTop).abs() > tolerance) continue;
    final matches = _dayPattern.allMatches(l.text).toList();
    if (matches.isEmpty) continue;
    headerLines.add(l);
    final width = l.right - l.left;
    final len = l.text.length;
    for (final m in matches) {
      final mid = (m.start + m.end) / 2 / len;
      columns.add(
        _Column(_dayWords[m[1]!.toLowerCase()]!, l.left + width * mid),
      );
    }
  }
  final distinct = {for (final c in columns) c.weekday};
  if (distinct.length < 2) return null;
  columns.sort((a, b) => a.x.compareTo(b.x));
  final headerBottom = headerLines
      .map((l) => l.bottom)
      .reduce((a, b) => a > b ? a : b);

  // Time labels down the side: a line that is only a time range, left of
  // the first column.
  final firstX = columns.first.x;
  final rows = <({double y, int start, int end})>[];
  final cells = <OcrLine>[];
  for (final l in lines) {
    if (headerLines.contains(l) || l.centerY <= headerBottom) continue;
    final r = _takeRange(l.text);
    if (r != null && _tidy(r.rest).isEmpty && l.centerX < firstX) {
      rows.add((y: l.centerY, start: r.start, end: r.end));
    } else {
      cells.add(l);
    }
  }
  rows.sort((a, b) => a.y.compareTo(b.y));

  // Gather each cell's lines by (column, row).
  final grouped = <(int, int), List<OcrLine>>{};
  for (final l in cells) {
    var col = 0;
    for (var i = 1; i < columns.length; i++) {
      if ((columns[i].x - l.centerX).abs() <
          (columns[col].x - l.centerX).abs()) {
        col = i;
      }
    }
    var row = -1;
    if (rows.isNotEmpty) {
      row = 0;
      for (var i = 1; i < rows.length; i++) {
        if ((rows[i].y - l.centerY).abs() < (rows[row].y - l.centerY).abs()) {
          row = i;
        }
      }
    }
    // Lines with their own time stand alone.
    final ownTime = _takeRange(l.text) != null;
    final key = (col, ownTime ? -1000 - cells.indexOf(l) : row);
    (grouped[key] ??= []).add(l);
  }

  final out = <CandidateBlock>[];
  final keys = grouped.keys.toList()
    ..sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
  for (final key in keys) {
    final group = grouped[key]!..sort((a, b) => a.top.compareTo(b.top));
    int? start;
    int? end;
    String? room;
    final words = <String>[];
    for (final l in group) {
      final r = _takeRange(l.text);
      var rest = r?.rest ?? l.text;
      if (r != null) {
        start = r.start;
        end = r.end;
      }
      final rm = _takeRoom(rest);
      room ??= rm.room;
      rest = _tidy(rm.rest);
      if (rest.isNotEmpty) words.add(rest);
    }
    if (words.isEmpty) continue;
    if (start == null && key.$2 >= 0 && rows.isNotEmpty) {
      start = rows[key.$2].start;
      end = rows[key.$2].end;
    }
    out.add(
      CandidateBlock(
        weekday: columns[key.$1].weekday,
        subject: words.first,
        start: start,
        end: end,
        room: room,
      ),
    );
  }
  return out;
}
