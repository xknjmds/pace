import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/theme/pace_tokens.dart';
import 'package:pace/core/widgets/splash_intro.dart';

void main() {
  final intro = find.byKey(const ValueKey('splash-intro'));

  Future<void> pumpIntro(
    WidgetTester tester, {
    bool reduced = false,
    bool calm = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: PaceMotionScope(
            calm: calm,
            child: const Stack(
              children: [
                Scaffold(body: Text('the app')),
                Positioned.fill(child: SplashIntro()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('plays over the app, then takes itself away', (tester) async {
    await pumpIntro(tester);
    expect(intro, findsOneWidget);
    // The app is already built underneath.
    expect(find.text('the app', skipOffstage: false), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(intro, findsOneWidget);
    expect(find.byKey(const ValueKey('splash-tagline')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(intro, findsNothing);
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('a tap skips straight to the fade', (tester) async {
    await pumpIntro(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(intro);
    await tester.pump(); // the fade's first frame
    await tester.pump(const Duration(milliseconds: 260));
    expect(intro, findsNothing);
  });

  testWidgets('reduced motion: fades only, done in under half a second', (
    tester,
  ) async {
    await pumpIntro(tester, reduced: true);
    await tester.pump(const Duration(milliseconds: 100));
    // Nothing is scaled on the way.
    final scales = tester
        .widgetList<Transform>(
          find.descendant(of: intro, matching: find.byType(Transform)),
        )
        .where((t) => t.transform != Matrix4.identity());
    expect(scales, isEmpty);
    await tester.pump(const Duration(milliseconds: 360));
    expect(intro, findsNothing);
  });

  testWidgets('low-energy mode skips the show', (tester) async {
    await pumpIntro(tester, calm: true);
    await tester.pump(const Duration(milliseconds: 260));
    expect(intro, findsNothing);
  });
}
