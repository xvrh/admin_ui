import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {AdminTokens? tokens}) => MaterialApp(
  theme: buildAppTheme(tokens ?? defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 420, child: child),
    ),
  ),
);

/// Whether keyboard focus is on the one [AddRowButton].
bool _addFocused() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<AddRowButton>() !=
    null;

ReferenceBody<String, String> _reference({
  List<String> value = const [],
  bool enabled = true,
}) => ReferenceBody<String, String>(
  value: value,
  onChanged: (_) {},
  enabled: enabled,
  idOf: (id) => id,
  resolve: (ids) async => [...ids],
  search: (query, {cursor}) async => const ReferencePage(['alpha', 'beta']),
  tile: (context, id) => ReferenceTileCard(title: id),
);

void main() {
  testWidgets('key–value: Tab reaches the add button, Enter adds a row', (
    tester,
  ) async {
    Map<String, String>? emitted;
    await tester.pumpWidget(
      _host(KeyValueBody(value: const {}, onChanged: (v) => emitted = v)),
    );
    expect(find.byType(AddRowButton), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_addFocused(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(emitted, isEmpty);
    expect(find.byType(TextField), findsNWidgets(2));
    // The new row's key takes focus.
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>(),
      isNotNull,
    );
  });

  testWidgets('repeater: Tab reaches the add button, Enter and Space add', (
    tester,
  ) async {
    var added = 0;
    await tester.pumpWidget(
      _host(
        Repeater(
          itemCount: 1,
          itemBuilder: (_, i) => Text('row-$i'),
          onAdd: () => added++,
        ),
      ),
    );
    expect(find.byType(AddRowButton), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_addFocused(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(added, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(added, 2);
  });

  testWidgets('reference: Enter on the add button opens the picker, focused', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(_reference()));
    expect(find.byType(AddRowButton), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AddRowButton)),
      matchesSemantics(
        label: 'Link…',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasExpandedState: true,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_addFocused(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // The picker's search box holds the keyboard.
    final search = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<TextField>();
    expect(search, isNotNull);
    expect(find.text('alpha'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AddRowButton)),
      matchesSemantics(
        label: 'Link…',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasExpandedState: true,
        isExpanded: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('reference: ArrowDown opens the picker, as a field trigger', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_reference()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>(),
      isNotNull,
    );
  });

  testWidgets('a disabled body disables its add button', (tester) async {
    await tester.pumpWidget(_host(_reference(enabled: false)));
    final button = tester.widget<Button>(
      find.descendant(
        of: find.byType(AddRowButton),
        matching: find.byType(Button),
      ),
    );
    expect(button.onPressed, isNull);
  });

  for (final theme in adminThemes) {
    testWidgets('${theme.name}: the add buttons are the small control height', (
      tester,
    ) async {
      final tokens = theme.tokens;
      await tester.pumpWidget(
        _host(
          tokens: tokens,
          Column(
            children: [
              KeyValueBody(value: const {}, onChanged: (_) {}),
              Repeater(
                itemCount: 0,
                itemBuilder: (_, _) => const SizedBox.shrink(),
                onAdd: () {},
              ),
              _reference(),
            ],
          ),
        ),
      );
      final buttons = find.descendant(
        of: find.byType(AddRowButton),
        matching: find.byType(Button),
      );
      expect(buttons, findsNWidgets(3));
      for (final element in buttons.evaluate()) {
        expect(
          tester.getSize(find.byWidget(element.widget)).height,
          tokens.sizes.small,
        );
      }
    });
  }

  for (final rtl in [false, true]) {
    testWidgets(
      'its glyph lines up with the column${rtl ? ', right to left' : ''}',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [AddRowButton(label: 'Add row', onPressed: () {})],
              ),
            ),
          ),
        );
        final column = tester.getRect(find.byType(Column));
        final glyph = tester.getRect(find.byIcon(Icons.add_rounded));
        if (rtl) {
          expect(glyph.right, column.right);
        } else {
          expect(glyph.left, column.left);
        }
        // The hit box follows the glyph.
        var tapped = false;
        await tester.pumpWidget(
          _host(
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddRowButton(
                    label: 'Add row',
                    onPressed: () => tapped = true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tapAt(glyph.center);
        expect(tapped, isTrue);
      },
    );
  }
}
