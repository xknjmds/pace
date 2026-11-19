part of 'schedule_parser.dart';

// -- grid: days across the top, times down the side -------------------------

/// One day column. [left] and [right] bound the cells under its heading.
class _Column {
  _Column(this.weekday, this.x);
  final int weekday;
  final double x;
  double left = 0;
  double right = 0;
}

/// A time row: the label's times and the band of the photo it covers.
class _Band {
  _Band({
    required this.top,
    required this.bottom,
    required this.start,
    required this.end,
  });
  double top;
  double bottom;
  final int start;
  final int end;
}

class _Grid {
  _Grid({
    required this.columns,
    required this.bands,
    required this.headerLines,
    required this.labelLines,
    required this.top,
    required this.bottom,
  });

  final List<_Column> columns;

  /// Time rows, top to bottom. Empty when the side has no times.
  final List<_Band> bands;
  final Set<OcrLine> headerLines;
  final Set<OcrLine> labelLines;

  /// Below the day headings.
  final double top;

  /// Below the last time row. Anything lower (a summary table, a legend)
  /// is not part of the grid.
  final double bottom;

  _Column? columnAt(double x) {
    _Column? best;
    for (final c in columns) {
      if (x < c.left || x > c.right) continue;
      if (best == null || (c.x - x).abs() < (best.x - x).abs()) best = c;
    }
    return best;
  }

  /// The band holding [y], or the closest one.
  _Band? bandAt(double y) {
    if (bands.isEmpty) return null;
    var best = bands.first;
    for (final b in bands) {
      if (y >= b.top && y <= b.bottom) return b;
      final d = y < b.top ? b.top - y : y - b.bottom;
      final bestD = y < best.top ? best.top - y : y - best.bottom;
      if (d < bestD) best = b;
    }
    return best;
  }
}

/// "7:00", "7:00 AM", "1 PM": one time of day and nothing else.
final _singleTime = RegExp(
  r'^\s*(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?|am|pm|nn)?\s*$',
  caseSensitive: false,
);

/// Minutes for a lone time label, or null.
int? _takeSingleTime(String text) {
  final m = _singleTime.firstMatch(text);
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final min = int.tryParse(m[2] ?? '') ?? 0;
  if (h > 23 || min > 59) return null;
  // A bare number with no minutes and no am/pm is not a time label.
  if (m[2] == null && m[3] == null) return null;
  final raw = m[3]?.toLowerCase();
  final suffix = raw == null || raw == 'nn' ? null : _suffix(raw);
  if (raw == 'nn') return 12 * 60 + min;
  return _resolve(h, min, suffix, null);
}

_Grid? _detectGrid(List<OcrLine> lines) {
  // Day headings only make a grid when they share one row across the top.
  final dayLines = lines.where((l) => _onlyDays(l.text)).toList();
  if (dayLines.isEmpty) return null;
  final rowTop = dayLines.map((l) => l.top).reduce((a, b) => a < b ? a : b);
  final tolerance = dayLines
      .map((l) => l.height)
      .reduce((a, b) => a > b ? a : b);
  final columns = <_Column>[];
  final headerLines = <OcrLine>{};
  for (final l in dayLines) {
    if ((l.top - rowTop).abs() > tolerance) continue;
    // Split a line that holds several days ("Mon Tue Wed").
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
  columns.sort((a, b) => a.x.compareTo(b.x));
  final seen = <int>{};
  columns.retainWhere((c) => seen.add(c.weekday));
  if (columns.length < 2) return null;
  final headerBottom = headerLines
      .map((l) => l.bottom)
      .reduce((a, b) => a > b ? a : b);

  // Column bounds halfway to the neighbours.
  final pitch = (columns.last.x - columns.first.x) / (columns.length - 1);
  for (var i = 0; i < columns.length; i++) {
    final c = columns[i];
    c.left = i == 0 ? c.x - pitch / 2 : (columns[i - 1].x + c.x) / 2;
    c.right = i == columns.length - 1
        ? c.x + pitch / 2
        : (c.x + columns[i + 1].x) / 2;
  }

  // Time labels down the side, left of the first column's middle.
  final labels = <({OcrLine line, int start, int? end})>[];
  for (final l in lines) {
    if (headerLines.contains(l) || l.centerY <= headerBottom) continue;
    if (l.centerX >= columns.first.x - pitch / 4) continue;
    final r = _takeRange(l.text);
    if (r != null && _tidy(r.rest).isEmpty) {
      labels.add((line: l, start: r.start, end: r.end));
      continue;
    }
    final t = _takeSingleTime(l.text);
    if (t != null) labels.add((line: l, start: t, end: null));
  }
  labels.sort((a, b) => a.line.centerY.compareTo(b.line.centerY));
  // Labels must run forward in time; drop any that go back.
  final ordered = <({OcrLine line, int start, int? end})>[];
  for (final l in labels) {
    if (ordered.isEmpty || l.start > ordered.last.start) ordered.add(l);
  }

  // The first column starts after the time labels.
  if (ordered.isNotEmpty) {
    final labelRight = ordered
        .map((l) => l.line.right)
        .reduce((a, b) => a > b ? a : b);
    if (labelRight < columns.first.x) columns.first.left = labelRight;
  }

  final bands = <_Band>[];
  final singles = ordered.isNotEmpty && ordered.every((l) => l.end == null);
  for (var i = 0; i < ordered.length; i++) {
    final l = ordered[i];
    final y = l.line.centerY;
    final prevY = i > 0 ? ordered[i - 1].line.centerY : null;
    final nextY = i + 1 < ordered.length ? ordered[i + 1].line.centerY : null;
    final nextStart = i + 1 < ordered.length ? ordered[i + 1].start : null;
    if (singles) {
      // A lone time sits on the line where its hour begins.
      final step = nextY != null ? nextY - y : (prevY != null ? y - prevY : 0);
      bands.add(
        _Band(
          top: y,
          bottom: y + step,
          start: l.start,
          end: nextStart ?? l.start + 60,
        ),
      );
    } else {
      // A range label sits inside its row: the row reaches halfway to the
      // labels around it.
      final up = prevY != null
          ? (y - prevY) / 2
          : (nextY != null ? (nextY - y) / 2 : l.line.height);
      final down = nextY != null ? (nextY - y) / 2 : up;
      bands.add(
        _Band(
          // The first row starts right under the day headings.
          top: i == 0 ? headerBottom : y - up,
          bottom: y + down,
          start: l.start,
          end: l.end ?? nextStart ?? l.start + 30,
        ),
      );
    }
  }

  final double bottom;
  if (bands.isNotEmpty) {
    bottom = bands.last.bottom;
  } else {
    bottom = lines.map((l) => l.bottom).reduce((a, b) => a > b ? a : b);
  }
  return _Grid(
    columns: columns,
    bands: bands,
    headerLines: headerLines,
    labelLines: {for (final l in ordered) l.line},
    top: headerBottom,
    bottom: bottom,
  );
}

/// Course codes that open a class box: "IT 3119", "ITAS3123", "GEE 2102".
final _courseCode = RegExp(r'^\s*[A-Z]{2,6}\s?-?\d{3,4}[A-Z]?\b');

/// A line that starts a class: a course code and a title, not a room
/// ("BH101 - PROF. CRUZ" looks like a code but is a room and a teacher).
bool _opensClass(String text) =>
    _courseCode.hasMatch(text) &&
    !_teacher.hasMatch(text) &&
    _normalRoom(_tidy(text)) == null;

/// Words for a box that is not a class.
final _breakWords = RegExp(
  r'^(lunch\s*break|lunch|break|recess|vacant|free|none)$',
  caseSensitive: false,
);

/// Lines inside the grid, by column, top to bottom.
Map<_Column, List<OcrLine>> _cellLines(List<OcrLine> lines, _Grid grid) {
  final out = <_Column, List<OcrLine>>{};
  for (final l in lines) {
    if (grid.headerLines.contains(l) || grid.labelLines.contains(l)) continue;
    if (l.centerY <= grid.top || l.centerY > grid.bottom) continue;
    final col = grid.columnAt(l.centerX);
    if (col == null) continue;
    (out[col] ??= []).add(l);
  }
  for (final list in out.values) {
    list.sort((a, b) => a.top.compareTo(b.top));
  }
  return out;
}

List<CandidateBlock> _parseGrid(List<OcrLine> lines, _Grid grid) {
  final out = <CandidateBlock>[];
  final byColumn = _cellLines(lines, grid);
  for (final col in grid.columns) {
    final cells = byColumn[col] ?? const <OcrLine>[];
    for (final group in _groupCells(cells, grid)) {
      final cell = _readCell(group);
      if (cell == null) continue;
      var start = cell.start;
      var end = cell.end;
      if (start == null && grid.bands.isNotEmpty) {
        start = grid.bandAt(group.first.centerY)!.start;
        end = grid.bandAt(group.last.centerY)!.end;
        if (end <= start) end = grid.bandAt(group.first.centerY)!.end;
      }
      out.add(
        CandidateBlock(
          weekday: col.weekday,
          subject: cell.subject,
          start: start,
          end: end,
          room: cell.room,
        ),
      );
    }
  }
  return out;
}

/// Splits one column's lines into class boxes.
///
/// When the schedule prints course codes, each code opens a new class and
/// the lines under it (title, room, teacher) belong to it, even across a
/// blank gap. Otherwise each time row is its own cell, and a line with its
/// own time stands alone.
List<List<OcrLine>> _groupCells(List<OcrLine> cells, _Grid grid) {
  if (cells.isEmpty) return const [];
  final coded = cells.any((l) => _opensClass(l.text));
  final groups = <List<OcrLine>>[];
  _Band? lastBand;
  for (final l in cells) {
    final ownTime = _takeRange(l.text) != null;
    final band = grid.bandAt(l.centerY);
    final bool split;
    if (groups.isEmpty) {
      split = true;
    } else if (ownTime || _breakWords.hasMatch(_tidy(l.text))) {
      split = true;
    } else if (_breakWords.hasMatch(_tidy(groups.last.first.text))) {
      split = true;
    } else if (coded) {
      split = _opensClass(l.text);
    } else {
      split = band != lastBand;
    }
    if (split) {
      groups.add([l]);
    } else {
      groups.last.add(l);
    }
    lastBand = band;
  }
  return groups;
}

/// Teacher titles: what follows is a name, not part of the class.
final _teacher = RegExp(
  r"\b(prof|dr|instr|engr|mr|mrs|ms|sir|ma'?am|teacher)\b\.?",
  caseSensitive: false,
);

/// Rooms as schools print them: "BH101", "LAB 3", "ROOM2", "AVR", "ONLINE".
final _roomWord = RegExp(
  r'^(?:(lab|room|rm|bldg|hall)\.?\s*-?\s*(\d{1,4}[a-z]?)|'
  r'([a-z]{1,4}\s?\d{2,4}[a-z]?)|'
  r'(avr|online|gym|field|library|auditorium|court|tba))$',
  caseSensitive: false,
);

String? _normalRoom(String raw) {
  final m = _roomWord.firstMatch(raw.trim());
  if (m == null) return null;
  if (m[1] != null) return '${m[1]!.toUpperCase()} ${m[2]!.toUpperCase()}';
  return (m[3] ?? m[4])!.toUpperCase().replaceAll(RegExp(r'\s+'), '');
}

/// The text of one class box: its subject (title lines joined), its room,
/// and a time if the box prints one. Teacher names are left out. Null for
/// an empty box or a break.
({String subject, String? room, int? start, int? end})? _readCell(
  List<OcrLine> group,
) {
  final subject = <String>[];
  String? room;
  int? start;
  int? end;
  for (final l in group) {
    var text = l.text;
    final r = _takeRange(text);
    if (r != null) {
      start ??= r.start;
      end ??= r.end;
      text = r.rest;
    }
    // "BH101 - PROF. A. CRUZ": a room, then the teacher.
    final t = _teacher.firstMatch(text);
    if (t != null) {
      final before = text
          .substring(0, t.start)
          .replaceAll(RegExp(r'[-–—,/\s]+$'), '');
      room ??= _normalRoom(before);
      if (_normalRoom(before) == null && _tidy(before).isNotEmpty) {
        subject.add(_tidy(before));
      }
      continue;
    }
    // A line that is only a room ("Rm 12", "LAB 3").
    if (subject.isNotEmpty) {
      final rm = _takeRoom(text);
      if (rm.room != null && _tidy(rm.rest).isEmpty) {
        room ??= rm.room;
        continue;
      }
      final onlyRoom = _normalRoom(_tidy(text));
      if (onlyRoom != null) {
        room ??= onlyRoom;
        continue;
      }
    }
    final tidy = _tidy(text);
    if (tidy.isNotEmpty) subject.add(tidy);
  }
  final name = subject.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (name.isEmpty || _breakWords.hasMatch(name)) return null;
  return (subject: name, room: room, start: start, end: end);
}
