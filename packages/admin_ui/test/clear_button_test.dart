import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

SemanticsNode _node(WidgetTester tester) => tester.getSemantics(
  find.descendant(
    of: find.byType(ClearButton),
    matching: find.byType(GestureDetector),
  ),
);

void main() {
  testWidgets('renders the close glyph and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(ClearButton(onPressed: () => taps++)));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(taps, 1);
  });

  testWidgets('a 16px glyph in a 24px hit box', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(ClearButton(onPressed: () => taps++)));
    expect(tester.getSize(find.byType(ClearButton)), const Size.square(24));
    expect(tester.getSize(find.byType(Icon)), const Size.square(16));
    await tester.tapAt(
      tester.getTopLeft(find.byType(ClearButton)) + const Offset(1, 1),
    );
    expect(taps, 1);
  });

  testWidgets('is named "Clear text" by default, or by its tooltip', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(ClearButton(onPressed: () {})));
    expect(_node(tester), isSemantics(label: 'Clear text', isButton: true));
    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Clear text');

    await tester.pumpWidget(
      _host(ClearButton(onPressed: () {}, label: 'Clear date')),
    );
    expect(_node(tester), isSemantics(label: 'Clear date', isButton: true));
    handle.dispose();
  });

  testWidgets('is reached with Tab and cleared with Enter', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(ClearButton(onPressed: () => taps++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });
}
