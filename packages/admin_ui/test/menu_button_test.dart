import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/common/ui/menu.dart';
import 'package:admin_ui/src/common/ui/menu_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('standalone opens the menu and fires an action', (tester) async {
    var edited = 0;
    await tester.pumpWidget(
      _host(
        MenuButton(
          icon: Icons.more_horiz,
          entries: [MenuItem('Edit', onSelect: () => edited++)],
        ),
      ),
    );

    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edited, 1);
  });

  testWidgets('revealed:false hides the trigger until it takes focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: () {}, child: const Text('Before')),
            const MenuButton(
              icon: Icons.more_horiz,
              entries: [MenuItem('Edit')],
              revealed: false,
              maskColor: Colors.white,
            ),
          ],
        ),
      ),
    );
    double opacity() => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(MenuButton),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    // Hidden, the caret is not drawn, but the trigger keeps its Tab stop.
    expect(opacity(), 0);
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(opacity(), 1);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('a parent driving revealed keeps the standalone trigger and '
      'its focus', (tester) async {
    var revealed = true;
    late StateSetter setRevealed;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            setRevealed = setState;
            return MenuButton(
              icon: Icons.more_horiz,
              entries: const [MenuItem('Edit')],
              revealed: revealed,
            );
          },
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final trigger = tester.element(find.byType(IconAction));
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.context, isNotNull);

    for (final value in [false, true, false]) {
      setRevealed(() => revealed = value);
      await tester.pump();
      expect(tester.element(find.byType(IconAction)), same(trigger));
      expect(FocusManager.instance.primaryFocus, same(focused));
      // Focused, it shows either way.
      expect(find.byIcon(Icons.more_horiz).hitTestable(), findsOneWidget);
    }
  });
}
