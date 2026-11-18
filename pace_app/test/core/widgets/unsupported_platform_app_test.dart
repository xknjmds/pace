import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/widgets/unsupported_platform_app.dart';

void main() {
  testWidgets('explains where PACE runs instead, without overflow on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const UnsupportedPlatformApp());
    expect(find.text('PACE does not run here yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
