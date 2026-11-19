import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/widgets/first_visit_hint.dart';
import 'package:pace/core/widgets/tuck.dart';

/// Loads the bundled Figtree before every test file, so layout checks
/// ("fits on a small phone without scrolling") measure the real typeface
/// instead of the square test font.
///
/// Tuck's living loop never ends, which would keep `pumpAndSettle` from
/// settling, so it is off unless a test turns it on. One-time hints are
/// off too, so screens open as a returning owner sees them.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Figtree');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      File(
        'assets/fonts/Figtree-$w.ttf',
      ).readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
    );
  }
  await loader.load();
  Tuck.debugLifeMotion = false;
  FirstVisitHint.debugEnabled = false;
  await testMain();
}
