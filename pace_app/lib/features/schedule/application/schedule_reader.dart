import 'dart:io';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/schedule_parser.dart';

/// What a photo gave: its text lines and, when they could be decoded, its
/// pixels in the same coordinates (for reading coloured time blocks).
typedef ScheduleScan = ({List<OcrLine> lines, RgbaImage? image});

/// Which step of reading a photo failed, and why. Shown to the owner so a
/// failure can be reported instead of guessed at.
class ScheduleReadException implements Exception {
  const ScheduleReadException(this.step, this.cause);

  /// "pick" (opening the camera or gallery) or "read" (text recognition).
  final String step;
  final Object cause;

  @override
  String toString() => 'ScheduleReadException($step): $cause';
}

/// Picks a photo and reads its text on the device. Behind an interface so
/// tests and other platforms never touch the plugins.
abstract interface class ScheduleReader {
  /// Null when the owner backed out of picking.
  Future<ScheduleScan?> pickAndRead({required bool camera});
}

/// ML Kit's bundled Latin model: nothing is downloaded, no network.
class MlKitScheduleReader implements ScheduleReader {
  const MlKitScheduleReader();

  @override
  Future<ScheduleScan?> pickAndRead({required bool camera}) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2400,
      );
    } catch (e) {
      throw ScheduleReadException('pick', e);
    }
    if (file == null) return null;
    final recognizer = TextRecognizer();
    try {
      final RecognizedText result;
      try {
        result = await recognizer.processImage(
          InputImage.fromFilePath(file.path),
        );
      } catch (e) {
        throw ScheduleReadException('read', e);
      }
      final lines = [
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine(
              line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              right: line.boundingBox.right,
              bottom: line.boundingBox.bottom,
            ),
      ];
      return (lines: lines, image: await _decode(file.path));
    } finally {
      try {
        await recognizer.close();
      } catch (_) {}
    }
  }

  /// The photo's pixels, or null if they cannot be decoded. The parser
  /// checks that the size matches the text before using them.
  static Future<RgbaImage?> _decode(String path) async {
    try {
      final codec = await ui.instantiateImageCodec(
        await File(path).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final out = data == null
          ? null
          : RgbaImage(image.width, image.height, data.buffer.asUint8List());
      image.dispose();
      codec.dispose();
      return out;
    } catch (_) {
      return null;
    }
  }
}

/// Where photo reading is not available (web, desktop).
class NoScheduleReader implements ScheduleReader {
  const NoScheduleReader();

  @override
  Future<ScheduleScan?> pickAndRead({required bool camera}) async => null;
}
