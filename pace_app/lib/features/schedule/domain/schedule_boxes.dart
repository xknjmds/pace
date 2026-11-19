part of 'schedule_parser.dart';

// -- grid from pixels: the coloured boxes of a time-block schedule ----------

/// Decoded photo pixels, four bytes per pixel (RGBA), row by row.
class RgbaImage {
  const RgbaImage(this.width, this.height, this.bytes);

  final int width;
  final int height;
  final Uint8List bytes;

  int _at(int x, int y) => (y * width + x) * 4;
}

/// A vertical stretch of one colour, or a border.
class _Run {
  _Run(this.top, this.bottom, this.color);
  int top;
  int bottom;
  final int color;
  int get height => bottom - top + 1;
}

int _r(int c) => (c >> 16) & 0xff;
int _g(int c) => (c >> 8) & 0xff;
int _b(int c) => c & 0xff;
int _lum(int c) => (_r(c) * 299 + _g(c) * 587 + _b(c) * 114) ~/ 1000;
int _dist(int a, int b) =>
    (_r(a) - _r(b)).abs() + (_g(a) - _g(b)).abs() + (_b(a) - _b(b)).abs();

/// The fill colour of row [y] between [x0] and [x1]: the median of each
/// channel over evenly spaced samples, skipping anything inside a text
/// box. Null when text covers the whole row.
int? _rowColor(RgbaImage img, int y, int x0, int x1, List<OcrLine> text) {
  final covering = [
    for (final l in text)
      if (y >= l.top - 2 && y <= l.bottom + 2) l,
  ];
  final rs = <int>[];
  final gs = <int>[];
  final bs = <int>[];
  final step = ((x1 - x0) / 64).clamp(1, 1 << 20).toInt();
  for (var x = x0; x <= x1; x += step) {
    if (covering.any((l) => x >= l.left - 2 && x <= l.right + 2)) continue;
    final i = img._at(x, y);
    rs.add(img.bytes[i]);
    gs.add(img.bytes[i + 1]);
    bs.add(img.bytes[i + 2]);
  }
  if (rs.length < 3) return null;
  int median(List<int> v) => (v..sort())[v.length ~/ 2];
  return median(rs) << 16 | median(gs) << 8 | median(bs);
}

/// Splits [y0]..[y1] of a vertical strip into runs of one colour. Thin or
/// dark runs (cell borders) are dropped, so they only separate boxes. Rows
/// fully covered by [text] continue the run they are in.
List<_Run> _runs(
  RgbaImage img,
  int x0,
  int x1,
  int y0,
  int y1, [
  List<OcrLine> text = const [],
]) {
  final runs = <_Run>[];
  int? prev;
  for (var y = y0; y <= y1; y++) {
    final c = _rowColor(img, y, x0, x1, text);
    if (c == null) {
      if (runs.isNotEmpty) runs.last.bottom = y;
      continue;
    }
    // Compare with the row above, not the run's start, so slow lighting
    // changes across a photo stay one run.
    if (prev == null || _dist(c, prev) > 48) {
      runs.add(_Run(y, y, c));
    } else {
      runs.last.bottom = y;
    }
    prev = c;
  }
  return [
    for (final r in runs)
      if (r.height > 3 && _lum(r.color) > 70) r,
  ];
}

/// Class boxes from the photo's colours, timed by the rows they cover.
/// Null when the boxes cannot be trusted (no time rows, a tilted photo, far
/// fewer boxes than the text found), so the caller falls back to the text.
List<CandidateBlock>? _parseBoxes(
  List<OcrLine> lines,
  _Grid grid,
  RgbaImage img,
  int textCount,
) {
  if (grid.bands.isEmpty || grid.columns.isEmpty) return null;
  // The pixels must be the same photo the text came from.
  for (final l in lines) {
    if (l.right > img.width + 4 || l.bottom > img.height + 4) return null;
  }
  final bands = _pixelBands(grid, img) ?? grid.bands;
  final top = bands.first.top.round().clamp(0, img.height - 1);
  final bottom = bands.last.bottom.round().clamp(0, img.height - 1);
  if (bottom - top < 20) return null;

  _Band bandAt(double y) {
    var best = bands.first;
    for (final b in bands) {
      if (y >= b.top && y <= b.bottom) return b;
      final d = y < b.top ? b.top - y : y - b.bottom;
      final bestD = y < best.top ? best.top - y : y - best.bottom;
      if (d < bestD) best = b;
    }
    return best;
  }

  final byColumn = _cellLines(lines, grid);
  final out = <CandidateBlock>[];
  for (final col in grid.columns) {
    final width = col.right - col.left;
    final x0 = (col.left + width * .15).round().clamp(0, img.width - 1);
    final x1 = (col.right - width * .15).round().clamp(0, img.width - 1);
    if (x1 <= x0) return null;
    final cells = byColumn[col] ?? const <OcrLine>[];
    for (final run in _runs(img, x0, x1, top, bottom, cells)) {
      final inside = [
        for (final l in cells)
          if (l.centerY >= run.top && l.centerY <= run.bottom) l,
      ];
      if (inside.isEmpty) continue; // An empty cell.
      // Two classes in one run (same colour, no border): split them.
      for (final group in _groupCells(inside, grid)) {
        final cell = _readCell(group);
        if (cell == null) continue;
        final many = inside.length != group.length;
        final y0 = many && group.first != inside.first
            ? (group.first.top + _previousBottom(inside, group)) / 2
            : run.top.toDouble();
        final y1 = many && group.last != inside.last
            ? (group.last.bottom + _nextTop(inside, group)) / 2
            : run.bottom.toDouble();
        var start = cell.start ?? bandAt(y0 + 2).start;
        var end = cell.end ?? bandAt(y1 - 2).end;
        if (end <= start) end = bandAt(y0 + 2).end;
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
  }
  if (out.length < textCount / 2) return null;
  return out;
}

double _previousBottom(List<OcrLine> inside, List<OcrLine> group) {
  final i = inside.indexOf(group.first);
  return i > 0 ? inside[i - 1].bottom : group.first.top;
}

double _nextTop(List<OcrLine> inside, List<OcrLine> group) {
  final i = inside.indexOf(group.last);
  return i + 1 < inside.length ? inside[i + 1].top : group.last.bottom;
}

/// The time rows as the photo draws them: the time column split at its
/// border lines, each row carrying the label inside it. Null when the
/// borders do not match the labels one to one.
List<_Band>? _pixelBands(_Grid grid, RgbaImage img) {
  final labels = grid.labelLines.toList()
    ..sort((a, b) => a.centerY.compareTo(b.centerY));
  if (labels.length < 2 || labels.length != grid.bands.length) return null;
  final x0 = labels.map((l) => l.left).reduce((a, b) => a < b ? a : b);
  final x1 = labels.map((l) => l.right).reduce((a, b) => a > b ? a : b);
  final y0 = grid.top.round().clamp(0, img.height - 1);
  final pitch =
      (grid.bands.last.bottom - grid.bands.first.top) / grid.bands.length;
  final y1 = (labels.last.bottom + pitch).round().clamp(0, img.height - 1);
  final runs = _runs(
    img,
    x0.round().clamp(0, img.width - 1),
    x1.round().clamp(0, img.width - 1),
    y0,
    y1,
    labels,
  );
  final out = <_Band>[];
  _Run? last;
  for (var i = 0; i < labels.length; i++) {
    final y = labels[i].centerY;
    final run = runs.where((r) => y >= r.top && y <= r.bottom).firstOrNull;
    // Each label needs a row of its own.
    if (run == null || identical(run, last)) return null;
    last = run;
    out.add(
      _Band(
        top: run.top.toDouble(),
        bottom: run.bottom.toDouble(),
        start: grid.bands[i].start,
        end: grid.bands[i].end,
      ),
    );
  }
  // Borders sit between rows: split each gap between the rows around it.
  for (var i = 1; i < out.length; i++) {
    final mid = (out[i - 1].bottom + out[i].top) / 2;
    out[i - 1].bottom = mid;
    out[i].top = mid;
  }
  return out;
}
