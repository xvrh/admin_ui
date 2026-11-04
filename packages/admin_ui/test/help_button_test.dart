import 'package:admin_ui/src/fields/ui/field_shell.dart';
import 'package:admin_ui/src/fields/ui/help_button.dart';
import 'package:admin_ui/src/fields/ui/text_body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('help opens from the field label row and keeps the field focus', (
    tester,
  ) async {
    final focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FieldShell(
              label: 'Title',
              help: const HelpButton(text: 'Help body text.'),
              child: TextBody(focusNode: focusNode),
            ),
          ),
        ),
      ),
    );

    // Focus the field, then open help.
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(find.text('Help body text.'), findsNothing);

    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();
    expect(find.text('Help body text.'), findsOneWidget);
    // Read-only tip must not steal the editor's cursor.
    expect(focusNode.hasFocus, isTrue);

    // Re-tap closes.
    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();
    expect(find.text('Help body text.'), findsNothing);
  });
}
