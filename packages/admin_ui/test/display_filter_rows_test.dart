import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _status = OptionsFilterField('status', 'Status', [
  FilterOption('published', 'Published'),
  FilterOption('draft', 'Draft'),
  FilterOption('archived', 'Archived'),
]);

const _featured = BoolFilterField('featured', 'Featured');

class _Harness extends StatefulWidget {
  final AdminTokens tokens;
  final List<FilterCondition> initial;
  const _Harness({required this.tokens, this.initial = const []});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late var active = widget.initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildAppTheme(widget.tokens),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: FilterBar(
          fields: const [_status, _featured],
          active: active,
          onChanged: (next) => setState(() => active = next),
        ),
      ),
    ),
  );
}

/// The fill of the option row labelled [label].
Color? _fill(WidgetTester tester, String label) {
  final box = find.descendant(
    of: find.byWidgetPredicate((w) => w is ListboxOption && w.label == label),
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration,
    ),
  );
  return (tester.widget<Container>(box.first).decoration! as BoxDecoration)
      .color;
}

Set<String> _selected(WidgetTester tester) {
  final active = tester.state<_HarnessState>(find.byType(_Harness)).active;
  return {
    for (final c in active)
      if (c is OptionsFilter) ...c.selected,
  };
}

void main() {
  for (final (name, palette) in [
    ('Iris Light', irisPalette),
    ('Iris Dark', irisDarkPalette),
  ]) {
    final tokens = AdminTokens.from(palette: palette);

    testWidgets('$name: the options editor lists ListboxOptions, the one '
        'under the pointer on listHighlight', (tester) async {
      await tester.pumpWidget(_Harness(tokens: tokens));
      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();

      final options = find.byType(ListboxOption);
      expect(options, findsNWidgets(3));
      for (final option in tester.widgetList<ListboxOption>(options)) {
        expect(option.checkbox, isTrue);
      }

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Draft')));
      await tester.pump();
      expect(_fill(tester, 'Draft'), palette.listHighlight);
      expect(_fill(tester, 'Published'), isNull);

      // A row as tall as a medium control, its text at the field inset.
      final row = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ListboxOption && w.label == 'Draft',
        ),
        matching: find.byType(Container),
      );
      expect(
        tester.getSize(row.first).height,
        greaterThanOrEqualTo(tokens.sizes.medium),
      );
    });
  }

  testWidgets('arrow keys move the highlight and Space checks it, the list '
      'staying open', (tester) async {
    final tokens = AdminTokens.from(palette: irisPalette);
    await tester.pumpWidget(_Harness(tokens: tokens));
    await tester.tap(find.text('Status'));
    await tester.pumpAndSettle();

    final highlight = tokens.palette.listHighlight;
    expect(_fill(tester, 'Published'), highlight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_fill(tester, 'Published'), isNull);
    expect(_fill(tester, 'Draft'), highlight);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_selected(tester), {'draft'});
    expect(find.byType(ListboxOption), findsNWidgets(3));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_selected(tester), {'draft', 'archived'});

    // Up from the first wraps to the last.
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_fill(tester, 'Archived'), highlight);
  });

  testWidgets('the yes/no editor is a single choice: the current one checked, '
      'Enter on the other picks it and closes', (tester) async {
    final tokens = AdminTokens.from(palette: irisPalette);
    await tester.pumpWidget(
      _Harness(
        tokens: tokens,
        initial: const [BoolFilter('featured', true, label: 'Featured')],
      ),
    );
    await tester.tap(find.textContaining('Featured'));
    await tester.pumpAndSettle();

    final yes = tester.widget<ListboxOption>(
      find.byWidgetPredicate((w) => w is ListboxOption && w.label == 'Yes'),
    );
    expect(yes.selected, isTrue);
    expect(yes.checkbox, isFalse);
    expect(_fill(tester, 'Yes'), tokens.palette.listHighlight);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ListboxOption), findsNothing);
    final active = tester.state<_HarnessState>(find.byType(_Harness)).active;
    expect(active.single, isA<BoolFilter>());
    expect((active.single as BoolFilter).value, isFalse);
  });

  testWidgets('a tap on a yes/no row picks it and closes', (tester) async {
    await tester.pumpWidget(
      _Harness(tokens: AdminTokens.from(palette: irisPalette)),
    );
    await tester.tap(find.text('Featured'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.byType(ListboxOption), findsNothing);
    final active = tester.state<_HarnessState>(find.byType(_Harness)).active;
    expect((active.single as BoolFilter).value, isFalse);
  });
}
