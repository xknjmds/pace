import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/theme/pace_tokens.dart';
import 'package:pace/core/widgets/cairn_progress.dart';
import 'package:pace/core/widgets/done_check.dart';
import 'package:pace/core/widgets/fade_slide_in.dart';

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

void main() {
  testWidgets('cairn progress says how many steps are done', (tester) async {
    await tester.pumpWidget(_app(const CairnProgress(done: [true, false])));
    expect(find.bySemanticsLabel('1 of 2 steps done'), findsOneWidget);
  });

  testWidgets('done check fills, then reports, under the Submitted tooltip', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(_app(DoneCheck(onDone: () => done++)));
    await tester.tap(find.byTooltip('Submitted'));
    await tester.pump();
    expect(done, 0, reason: 'the fill plays first');
    await tester.pumpAndSettle();
    expect(done, 1);
    // A second tap while finished does nothing.
    await tester.tap(find.byTooltip('Submitted'));
    await tester.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('motion: reduced removes movement, calm removes decoration', (
    tester,
  ) async {
    late PaceMotion motion;
    Widget probe() => Builder(
      builder: (context) {
        motion = PaceMotion.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(_app(probe()));
    expect(motion.offset(8), 8);
    expect(motion.decorative, isTrue);

    await tester.pumpWidget(_app(probe(), reduced: true));
    expect(motion.offset(8), 0);
    expect(motion.decorative, isFalse);

    await tester.pumpWidget(_app(probe(), calm: true));
    expect(motion.offset(8), 8);
    expect(motion.decorative, isFalse);
  });

  testWidgets('done check: with reduced motion the check fades, never grows', (
    tester,
  ) async {
    await tester.pumpWidget(_app(DoneCheck(onDone: () {}), reduced: true));
    await tester.tap(find.byTooltip('Submitted'));
    await tester.pump(const Duration(milliseconds: 80)); // mid-fill
    // The check's box keeps the circle's full 24 px the whole time; the
    // old grow-in drew it at 60–100 % of that.
    final check = tester.getRect(find.byIcon(Icons.check_rounded));
    expect(check.width, closeTo(24, .01));
    await tester.pumpAndSettle();
  });

  testWidgets('entrance is skipped in low-energy mode', (tester) async {
    await tester.pumpWidget(
      _app(const FadeSlideIn(child: Text('hi')), calm: true),
    );
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('hi'), findsOneWidget);
  });
}
