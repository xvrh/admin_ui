import 'package:admin_ui/src/common/ui/accordion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 500, child: child)),
  ),
);

const _sections = [
  AccordionSection(title: 'One', child: Text('body one')),
  AccordionSection(title: 'Two', child: Text('body two')),
  AccordionSection(title: 'Three', child: Text('body three')),
];

void main() {
  testWidgets('starts collapsed by default', (tester) async {
    await tester.pumpWidget(_host(const Accordion(sections: _sections)));
    expect(find.text('body one'), findsNothing);
    expect(find.text('body two'), findsNothing);
  });

  testWidgets('opens the initial section and toggles on tap', (tester) async {
    await tester.pumpWidget(
      _host(const Accordion(initiallyOpen: {0}, sections: _sections)),
    );

    expect(find.text('body one'), findsOneWidget);
    expect(find.text('body two'), findsNothing);

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    // single-open: opening Two closes One.
    expect(find.text('body two'), findsOneWidget);
    expect(find.text('body one'), findsNothing);
  });

  testWidgets('multiple mode keeps sections open together', (tester) async {
    await tester.pumpWidget(
      _host(
        const Accordion(
          multiple: true,
          initiallyOpen: {0},
          sections: _sections,
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(find.text('body one'), findsOneWidget);
    expect(find.text('body two'), findsOneWidget);
  });

  testWidgets('a controlled accordion shows the given set and reports taps', (
    tester,
  ) async {
    final asked = <Set<int>>[];
    Widget build(Set<int> open) => _host(
      Accordion(open: open, onOpenChanged: asked.add, sections: _sections),
    );
    await tester.pumpWidget(build(const {1}));
    expect(find.text('body two'), findsOneWidget);

    await tester.tap(find.text('Three'));
    await tester.pumpAndSettle();
    expect(asked, [
      {2},
    ]);
    // Nothing changes until the host applies it.
    expect(find.text('body two'), findsOneWidget);
    expect(find.text('body three'), findsNothing);

    await tester.pumpWidget(build(const {2}));
    await tester.pumpAndSettle();
    expect(find.text('body three'), findsOneWidget);
    expect(find.text('body two'), findsNothing);
  });
}
