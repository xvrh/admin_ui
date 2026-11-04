import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Column(
      children: [
        child,
        TextButton(onPressed: () {}, child: const Text('After')),
      ],
    ),
  ),
);

void main() {
  testWidgets('empty, the clear slot holds no Tab stop', (tester) async {
    await tester.pumpWidget(_host(const SearchField(width: 240)));
    expect(find.byType(ClearButton), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.focusNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      Focus.of(tester.element(find.text('After'))).hasPrimaryFocus,
      isTrue,
    );
  });

  testWidgets('typing shows a labelled clear without reflowing the field', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _host(SearchField(width: 240, onChanged: changes.add)),
    );
    final input = find.byType(EditableText);
    final before = tester.getRect(input);

    await tester.enterText(find.byType(TextField), 'lamp');
    await tester.pump();
    final clear = find.byType(ClearButton);
    expect(tester.widget<ClearButton>(clear).label, 'Clear search');
    expect(tester.getSize(clear), const Size.square(24));
    expect(tester.getRect(input), before);

    await tester.tap(clear);
    await tester.pump();
    expect(changes.last, '');
    expect(find.byType(ClearButton), findsNothing);
  });

  group('debounce', () {
    const wait = Duration(milliseconds: 300);
    final field = find.byType(TextField);

    testWidgets('six keystrokes report once, when the typing settles', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(SearchField(debounce: wait, onChanged: changes.add)),
      );
      for (final text in ['l', 'la', 'lam', 'lamp', 'lamps', 'lampsh']) {
        await tester.enterText(field, text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(changes, isEmpty);
      await tester.pump(const Duration(milliseconds: 199));
      expect(changes, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(changes, ['lampsh']);
    });

    testWidgets('text taken back within the window never reports', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(SearchField(debounce: wait, onChanged: changes.add)),
      );
      await tester.enterText(field, 'boot');
      await tester.pump(wait);
      expect(changes, ['boot']);

      await tester.enterText(field, 'boots');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'boot');
      await tester.pump(wait * 2);
      expect(changes, ['boot']);
    });

    testWidgets('clearing reports at once and drops what was pending', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(SearchField(debounce: wait, onChanged: changes.add)),
      );
      await tester.enterText(field, 'lamp');
      await tester.pump(wait);
      await tester.enterText(field, 'lampx');
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(ClearButton));
      await tester.pump();
      expect(changes, ['lamp', '']);
      await tester.pump(wait * 2);
      expect(changes, ['lamp', '']);
    });

    testWidgets('submitting reports at once, and only once', (tester) async {
      final changes = <String>[];
      final submitted = <String>[];
      await tester.pumpWidget(
        _host(
          SearchField(
            debounce: wait,
            onChanged: changes.add,
            onSubmitted: submitted.add,
          ),
        ),
      );
      await tester.enterText(field, 'sofa');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(changes, ['sofa']);
      expect(submitted, ['sofa']);
      await tester.pump(wait * 2);
      expect(changes, ['sofa']);
    });

    testWidgets('a value the parent sets wins over pending typing', (
      tester,
    ) async {
      final changes = <String>[];
      var value = '';
      late StateSetter setOuter;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return SearchField(
                value: value,
                debounce: wait,
                onChanged: (text) {
                  changes.add(text);
                  setState(() => value = text);
                },
              );
            },
          ),
        ),
      );
      await tester.enterText(field, 'desk');
      await tester.pump(wait);
      expect(changes, ['desk']);
      expect(value, 'desk');

      await tester.enterText(field, 'desks');
      await tester.pump(const Duration(milliseconds: 100));
      setOuter(() => value = 'chair');
      await tester.pump();
      await tester.pump(wait * 2);
      expect(changes, ['desk']);
      expect(tester.widget<TextField>(field).controller!.text, 'chair');
    });

    testWidgets('an external controller is debounced too', (tester) async {
      final changes = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SearchField(
            controller: controller,
            debounce: wait,
            onChanged: changes.add,
          ),
        ),
      );
      controller.text = 'a';
      await tester.pump(const Duration(milliseconds: 100));
      controller.text = 'ab';
      await tester.pump(wait);
      expect(changes, ['ab']);
    });

    testWidgets('disposed mid-wait, it reports nothing', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(SearchField(debounce: wait, onChanged: changes.add)),
      );
      await tester.enterText(field, 'rug');
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pump(wait * 2);
      expect(changes, isEmpty);
    });

    testWidgets('without a debounce every keystroke reports', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(_host(SearchField(onChanged: changes.add)));
      for (final text in ['r', 'ru', 'rug', 'ru']) {
        await tester.enterText(field, text);
      }
      expect(changes, ['r', 'ru', 'rug', 'ru']);
    });
  });
}
