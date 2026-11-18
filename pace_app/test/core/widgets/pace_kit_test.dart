import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/core/widgets/pace_choice_sheet.dart';
import 'package:pace/core/widgets/pace_page.dart';
import 'package:pace/core/widgets/pace_tile.dart';

Widget _app(Widget home) => MaterialApp(theme: PaceTheme.light(), home: home);

void main() {
  testWidgets('a tile reads as one control and taps through', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: PaceGroup(
            children: [
              PaceTile(
                icon: Icons.restaurant_outlined,
                title: 'Breakfast',
                subtitle: 'Time set aside to eat.',
                value: '15 min',
                chevron: true,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(PaceTile)),
      isSemantics(
        label: 'Breakfast\nTime set aside to eat.\n15 min',
        hasTapAction: true,
      ),
    );
    expect(tester.getSize(find.byType(PaceTile)).height, greaterThan(55));
    await tester.tap(find.text('Breakfast'));
    expect(taps, 1);
  });

  testWidgets('a toggle row flips from anywhere on the row', (tester) async {
    var on = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: PaceTile.toggle(
              title: 'Low-energy mode',
              value: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Low-energy mode'));
    await tester.pumpAndSettle();
    expect(on, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('the page title appears in the bar only once scrolled away', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PacePage(
          title: 'Money',
          subtitle: 'This week at a glance.',
          children: [for (var i = 0; i < 40; i++) Text('row $i')],
        ),
      ),
    );
    final barTitle = find.byKey(const ValueKey('bar-title'));
    expect(barTitle, findsNothing);
    expect(find.text('Money'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(barTitle, findsOneWidget);
  });

  testWidgets('choice sheet returns the tapped value and marks the current', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showPaceChoiceSheet<int>(
                context: context,
                title: 'Breakfast',
                selected: 15,
                choices: const [
                  PaceChoice(10, '10 min'),
                  PaceChoice(15, '15 min'),
                  PaceChoice(20, '20 min'),
                ],
                custom: () async => 42,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // The current choice carries a check, not just a colour.
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('15 min'), matching: find.byType(Row)),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('20 min'));
    await tester.pumpAndSettle();
    expect(result, 20);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom…'));
    await tester.pumpAndSettle();
    expect(result, 42);
  });
}
