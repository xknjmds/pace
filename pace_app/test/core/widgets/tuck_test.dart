import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/theme/pace_tokens.dart';
import 'package:pace/core/widgets/tuck.dart';

Widget _app(Widget child, {bool reduced = false, bool calm = false}) =>
    MaterialApp(
      theme: PaceTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: PaceMotionScope(
          calm: calm,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

String _shownAsset(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image).last);
  return (image.image as AssetImage).assetName;
}

void main() {
  tearDown(() => Tuck.debugLifeMotion = false);

  testWidgets('every pose has its image and Tuck is labelled', (tester) async {
    for (final pose in TuckPose.values) {
      await tester.pumpWidget(_app(Tuck(pose: pose)));
      expect(_shownAsset(tester), 'assets/mascot/tuck_${pose.file}.png');
    }
    expect(find.bySemanticsLabel('Tuck the turtle'), findsOneWidget);
  });

  testWidgets('with reduced motion Tuck is a still image', (tester) async {
    Tuck.debugLifeMotion = true;
    await tester.pumpWidget(_app(const Tuck(), reduced: true));
    // Nothing is ticking, so this settles at once.
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(Tuck), matching: find.byType(Transform)),
      findsNothing,
    );
  });

  testWidgets('alive: breathes and blinks, then opens its eyes again', (
    tester,
  ) async {
    Tuck.debugLifeMotion = true;
    await tester.pumpWidget(_app(Tuck(random: Random(1))));
    expect(_shownAsset(tester), Tuck.asset(TuckPose.idle));

    // The first blink lands within 2–5 s; sample finely until it shows.
    var sawBlink = false;
    for (var i = 0; i < 400 && !sawBlink; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      sawBlink = _shownAsset(tester) == Tuck.blinkAsset;
    }
    expect(sawBlink, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_shownAsset(tester), Tuck.asset(TuckPose.idle));

    // Breathing moves Tuck (a transform is applied while alive).
    expect(
      find.descendant(of: find.byType(Tuck), matching: find.byType(Transform)),
      findsWidgets,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('low-energy mode keeps only the breath: no z or sparkles', (
    tester,
  ) async {
    Tuck.debugLifeMotion = true;
    await tester.pumpWidget(
      _app(const Tuck(pose: TuckPose.resting), calm: true),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('z'), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resting Tuck lets a z drift up now and then', (tester) async {
    Tuck.debugLifeMotion = true;
    await tester.pumpWidget(_app(const Tuck(pose: TuckPose.resting)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('z'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tapping Tuck does nothing harmful', (tester) async {
    Tuck.debugLifeMotion = true;
    await tester.pumpWidget(_app(Tuck(random: Random(2))));
    await tester.tap(find.byType(Tuck));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Tuck), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
