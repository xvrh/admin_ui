import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host() => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showSideSheet<void>(
            context,
            builder: (context) => SideSheet(
              title: 'Edit details',
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Button.ghost('Cancel', onPressed: () {}),
                  Button.primary('Save', onPressed: () {}),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: TextField(),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('Tab cycles through the controls with no invisible stop', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FocusNode? primary() => FocusManager.instance.primaryFocus;
    final close = Focus.of(
      tester.element(
        find.descendant(
          of: find.byType(IconAction),
          matching: find.byIcon(Icons.close_rounded),
        ),
      ),
    );
    final field = tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode;
    final cancel = Focus.of(tester.element(find.text('Cancel')));
    final save = Focus.of(tester.element(find.text('Save')));

    final seen = <FocusNode?>[];
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      seen.add(primary());
    }
    expect(seen, [close, field, cancel, save, close, field, cancel, save]);
  });

  testWidgets('Escape still closes it, straight after opening', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SideSheet), findsNothing);
  });

  testWidgets('a labelled close button; a dialog named by its title', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    final close = tester.getRect(find.byType(IconAction));
    expect(close.width, greaterThanOrEqualTo(24));
    expect(close.height, greaterThanOrEqualTo(24));
    expect(
      tester.getSemantics(find.byType(SideSheet)),
      isSemantics(
        label: 'Edit details',
        scopesRoute: true,
        namesRoute: true,
        role: SemanticsRole.dialog,
      ),
    );
    expect(
      tester.getSemantics(find.text('Edit details')),
      isSemantics(isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('the header is 48px, with the close centred in it', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byType(SideSheet));
    final body = tester.getRect(find.byType(TextField));
    final close = tester.getRect(find.byType(IconAction));
    // 48px header, a 1px rule, then the body's 16px padding.
    expect(body.top - sheet.top, 48 + 1 + 16);
    expect(close.center.dy - sheet.top, 24);
  });
}
