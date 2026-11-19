import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:pace/features/schedule/domain/schedule_parser.dart';

/// OCR lines for test/fixtures/schedule_time_block.jpg (the owner's real
/// schedule), split one per printed line as ML Kit does.
List<OcrLine> timeBlockLines() {
  final raw =
      jsonDecode(
            File(
              'test/fixtures/schedule_time_block_ocr.json',
            ).readAsStringSync(),
          )
          as List;
  return [
    for (final m in raw.cast<Map<String, dynamic>>())
      OcrLine(
        m['text'] as String,
        left: (m['left'] as num).toDouble(),
        top: (m['top'] as num).toDouble(),
        right: (m['right'] as num).toDouble(),
        bottom: (m['bottom'] as num).toDouble(),
      ),
  ];
}

/// The fixture photo's pixels. Call inside `tester.runAsync`.
Future<RgbaImage> timeBlockImage() async {
  final bytes = File('test/fixtures/schedule_time_block.jpg').readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return RgbaImage(
    frame.image.width,
    frame.image.height,
    data!.buffer.asUint8List(),
  );
}
