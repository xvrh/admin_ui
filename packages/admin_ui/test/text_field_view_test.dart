import 'package:admin_ui/src/fields/ui/field_shell.dart';
import 'package:admin_ui/src/fields/ui/text_body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('typing updates the controller', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      _host(
        FieldShell(
          label: 'Title',
          child: TextBody(controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    expect(controller.text, 'hello');
  });

  testWidgets('tapping the label focuses the field', (tester) async {
    final focusNode = FocusNode();
    await tester.pumpWidget(
      _host(
        FieldShell(
          label: 'Title',
          child: TextBody(focusNode: focusNode),
        ),
      ),
    );
    expect(focusNode.hasFocus, isFalse);

    await tester.tap(find.text('TITLE'));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });
}
