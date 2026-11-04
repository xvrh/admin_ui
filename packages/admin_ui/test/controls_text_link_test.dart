import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = irisTheme.tokens;

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(body: Center(child: child)),
);

TextStyle _style(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  testWidgets('at rest: caption at w600 in the primary text colour', (
    tester,
  ) async {
    await tester.pumpWidget(_host(TextLink('Show', onPressed: () {})));
    final style = _style(tester, 'Show');
    final type = _tokens.typography;
    expect(style.fontSize, type.caption.fontSize);
    expect(style.height, type.caption.height);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _tokens.palette.primaryText);
    expect(style.decoration, isNull);
  });

  testWidgets('the pointer underlines it; a press dims it', (tester) async {
    await tester.pumpWidget(_host(TextLink('Show', onPressed: () {})));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Show')));
    await tester.pump();
    expect(_style(tester, 'Show').decoration, TextDecoration.underline);

    await mouse.down(tester.getCenter(find.text('Show')));
    await tester.pump();
    final pressed = _style(tester, 'Show');
    expect(pressed.decoration, TextDecoration.underline);
    expect(pressed.color!.a, lessThan(_tokens.palette.primaryText.a));
    expect(pressed.decorationColor, _tokens.palette.primaryText);
    await mouse.up();
  });

  testWidgets('underlined, it is underlined at rest; disabled, plain', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(TextLink('Show', onPressed: () {}, underlined: true)),
    );
    expect(_style(tester, 'Show').decoration, TextDecoration.underline);
    await tester.pumpWidget(
      _host(const TextLink('Show', onPressed: null, underlined: true)),
    );
    expect(_style(tester, 'Show').decoration, isNull);
  });

  testWidgets('a Tab stop that Enter runs, named by its semantic label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(
        TextLink(
          'Show',
          semanticLabel: 'Show 3 shared fields',
          expanded: false,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show 3 shared fields')),
      isSemantics(
        label: 'Show 3 shared fields',
        isButton: true,
        isFocusable: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('a leading glyph is xs, in the label colour', (tester) async {
    final color = _tokens.palette.successText;
    await tester.pumpWidget(
      _host(
        TextLink(
          'Approve',
          icon: Icons.check_rounded,
          color: color,
          onPressed: () {},
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
    expect(icon.size, _tokens.iconSizes.xs);
    expect(icon.color, color);
    expect(_style(tester, 'Approve').color, color);
  });

  testWidgets('without onPressed it is subtle and inert', (tester) async {
    await tester.pumpWidget(_host(const TextLink('Show', onPressed: null)));
    expect(_style(tester, 'Show').color, _tokens.palette.foregroundSubtle);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Show')));
    await tester.pump();
    expect(_style(tester, 'Show').decoration, isNull);
  });
}
