import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/schedule_parser.dart';

/// Picks a photo and reads its text on the device. Behind an interface so
/// tests and other platforms never touch the plugins.
abstract interface class ScheduleReader {
  /// Null when the owner backed out of picking.
  Future<List<OcrLine>?> pickAndRead({required bool camera});
}

/// ML Kit's bundled Latin model: nothing is downloaded, no network.
class MlKitScheduleReader implements ScheduleReader {
  const MlKitScheduleReader();

  @override
  Future<List<OcrLine>?> pickAndRead({required bool camera}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
    );
    if (file == null) return null;
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return [
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
    } finally {
      await recognizer.close();
    }
  }
}

/// Where photo reading is not available (web, desktop).
class NoScheduleReader implements ScheduleReader {
  const NoScheduleReader();

  @override
  Future<List<OcrLine>?> pickAndRead({required bool camera}) async => null;
}
