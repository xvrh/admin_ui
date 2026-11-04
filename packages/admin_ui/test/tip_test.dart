import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('wraps the child in a Tooltip carrying the message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Tip(message: 'Settings', child: Icon(Icons.settings)),
        ),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Settings');
  });

  testWidgets('keyboard focus inside the child opens it; leaving closes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tip(
              message: 'Settings',
              child: Button('Open', onPressed: () {}),
            ),
            Tip(
              message: 'Help',
              child: Button('Help me', onPressed: () {}),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Settings'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Help'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Help'), findsNothing);
  });

  testWidgets('focus without the keyboard highlight leaves it closed', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _host(
        Tip(
          message: 'Settings',
          child: Focus(focusNode: node, child: const Icon(Icons.settings)),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.settings));
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('excludeFromSemantics keeps the message out of the tree', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Tip(
          message: 'Settings',
          excludeFromSemantics: true,
          child: Icon(Icons.settings),
        ),
      ),
    );
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).excludeFromSemantics,
      isTrue,
    );
  });

  testWidgets('a long message wraps within 280px', (tester) async {
    const long =
        'A longer explanation that runs onto more than one line to show the '
        'padding, radius and maximum width of the tooltip chip.';
    await tester.pumpWidget(
      _host(
        Tip(
          message: long,
          child: Button('Open', onPressed: () {}),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final text = tester.getSize(find.text(long));
    expect(text.width, lessThanOrEqualTo(280));
    expect(text.height, greaterThan(20), reason: 'wraps onto more lines');
    expect(
      buildAppTheme(defaultTokens).tooltipTheme.constraints?.maxWidth,
      280,
    );
  });
}
