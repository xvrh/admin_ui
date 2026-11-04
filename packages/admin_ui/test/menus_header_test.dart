import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late List<String> chosen;

  Future<void> pumpMenu(WidgetTester tester, {List<MenuEntry>? entries}) {
    chosen = [];
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Menu(
              header: const Text('jane@example.com'),
              entries:
                  entries ??
                  [
                    MenuItem('Profile', onSelect: () => chosen.add('Profile')),
                    MenuItem(
                      'Sign out',
                      onSelect: () => chosen.add('Sign out'),
                    ),
                  ],
              builder: (context, c) =>
                  TextButton(onPressed: c.toggle, child: const Text('Account')),
            ),
          ),
        ),
      ),
    );
  }

  bool hasFocus(WidgetTester tester, String text) =>
      Focus.maybeOf(tester.element(find.text(text)))?.hasPrimaryFocus ?? false;

  testWidgets('the header sits above the entries, parted by a divider', (
    tester,
  ) async {
    await pumpMenu(tester);
    expect(find.text('jane@example.com'), findsNothing);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    final header = tester.getRect(find.text('jane@example.com'));
    final divider = tester.getRect(find.byType(Divider));
    expect(header.bottom, lessThanOrEqualTo(divider.top));
    expect(
      divider.bottom,
      lessThanOrEqualTo(tester.getRect(find.text('Profile')).top),
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(chosen, ['Sign out']);
  });

  testWidgets('the keys start at the first entry, never the header', (
    tester,
  ) async {
    await pumpMenu(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, 'Profile'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, 'Sign out'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, 'Profile'), isTrue);
  });

  testWidgets('the header is outside the screen reader\'s menu', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMenu(tester);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    final menu = tester.getSemantics(find.bySemanticsLabel('Profile'));
    SemanticsNode? node = menu;
    while (node != null && node.role != SemanticsRole.menu) {
      node = node.parent;
    }
    expect(node, isNotNull);
    final labels = <String>[];
    void collect(SemanticsNode n) {
      labels.add(n.label);
      n.visitChildren((child) {
        collect(child);
        return true;
      });
    }

    collect(node!);
    expect(labels, isNot(contains('jane@example.com')));
    expect(find.bySemanticsLabel('jane@example.com'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a menu with only a header shows no divider', (tester) async {
    await pumpMenu(tester, entries: const []);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });
}
