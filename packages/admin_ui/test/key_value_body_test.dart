import 'package:admin_ui/src/fields/ui/key_value_body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('editing a value emits the updated map', (tester) async {
    Map<String, String>? emitted;
    await tester.pumpWidget(
      _host(
        KeyValueBody(value: const {'a': '1'}, onChanged: (v) => emitted = v),
      ),
    );

    // Two fields: key, value. Value is the second.
    await tester.enterText(find.byType(TextField).at(1), '2');
    expect(emitted, {'a': '2'});
  });

  testWidgets('adding a row then typing a key emits it', (tester) async {
    Map<String, String>? emitted;
    await tester.pumpWidget(
      _host(KeyValueBody(value: const {}, onChanged: (v) => emitted = v)),
    );

    await tester.tap(find.text('Add row'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'color');
    await tester.enterText(find.byType(TextField).at(1), 'red');
    expect(emitted, {'color': 'red'});
  });

  testWidgets('removing a row drops its key', (tester) async {
    Map<String, String>? emitted;
    await tester.pumpWidget(
      _host(
        KeyValueBody(
          value: const {'a': '1', 'b': '2'},
          onChanged: (v) => emitted = v,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    expect(emitted, {'b': '2'});
  });

  testWidgets('a duplicate key lets the lower row win', (tester) async {
    Map<String, String>? emitted;
    await tester.pumpWidget(
      _host(
        KeyValueBody(
          value: const {'a': '1', 'b': '2'},
          onChanged: (v) => emitted = v,
        ),
      ),
    );

    // Retype the second row's key to collide with the first.
    await tester.enterText(find.byType(TextField).at(2), 'a');
    expect(emitted, {'a': '2'});
  });

  testWidgets('an empty key is held but never emitted', (tester) async {
    Map<String, String>? emitted;
    await tester.pumpWidget(
      _host(KeyValueBody(value: const {}, onChanged: (v) => emitted = v)),
    );

    await tester.tap(find.text('Add row'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'orphan value');
    expect(emitted, isEmpty);
  });

  testWidgets('read-only renders no add button or remove icons', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const KeyValueBody(value: {'a': '1'})));

    expect(find.text('Add row'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('read-only and empty shows the empty label', (tester) async {
    await tester.pumpWidget(
      _host(const KeyValueBody(emptyLabel: 'No variables set')),
    );

    expect(find.text('No variables set'), findsOneWidget);
  });
}
