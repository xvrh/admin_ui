import 'package:admin_ui/src/fields/ui/tags_body.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('typing and submitting adds a tag', (tester) async {
    List<String>? emitted;
    await tester.pumpWidget(
      _host(TagsBody(value: const ['a'], onChanged: (v) => emitted = v)),
    );

    await tester.enterText(find.byType(TextField), 'b');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(emitted, ['a', 'b']);
  });

  testWidgets('a duplicate is rejected', (tester) async {
    List<String>? emitted;
    await tester.pumpWidget(
      _host(TagsBody(value: const ['a'], onChanged: (v) => emitted = v)),
    );

    await tester.enterText(find.byType(TextField), 'a');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(emitted, isNull); // never fired
  });

  testWidgets('blank input is ignored', (tester) async {
    List<String>? emitted;
    await tester.pumpWidget(
      _host(TagsBody(value: const ['a'], onChanged: (v) => emitted = v)),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(emitted, isNull);
  });

  testWidgets('the × removes a tag', (tester) async {
    List<String>? emitted;
    await tester.pumpWidget(
      _host(TagsBody(value: const ['a', 'b'], onChanged: (v) => emitted = v)),
    );

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    expect(emitted, ['b']);
  });

  testWidgets('backspace on the empty input removes the last tag', (
    tester,
  ) async {
    List<String>? emitted;
    await tester.pumpWidget(
      _host(TagsBody(value: const ['a', 'b'], onChanged: (v) => emitted = v)),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(emitted, ['a']);
  });

  testWidgets('read-only renders chips without remove or input', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TagsBody(value: ['a', 'b'])));

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
