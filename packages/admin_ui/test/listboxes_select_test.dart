import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _statuses = [
  SelectOption(value: 'draft', label: 'Draft'),
  SelectOption(value: 'review', label: 'In review'),
  SelectOption(value: 'published', label: 'Published'),
  SelectOption(value: 'archived', label: 'Archived'),
];

final _many = [
  for (var i = 0; i < 500; i++) SelectOption(value: 'v$i', label: 'Item $i'),
];

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

/// A select that keeps its own value, reporting picks to [onPick].
Widget _select({
  String? initial,
  List<SelectOption> options = _statuses,
  bool? searchable,
  ValueChanged<String>? onPick,
}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) => SelectBody(
      options: options,
      value: value,
      searchable: searchable,
      onChanged: (v) {
        setState(() => value = v);
        onPick?.call(v);
      },
    ),
  );
}

/// A multi-select that keeps its own value.
Widget _multi({Set<String> initial = const {}, bool? searchable}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) => MultiSelectBody(
      options: _statuses,
      value: value,
      searchable: searchable,
      onChanged: (v) => setState(() => value = v),
    ),
  );
}

ListboxController _listbox(WidgetTester tester) =>
    tester.widget<ListboxOption>(find.byType(ListboxOption).first).controller;

String? _highlighted(WidgetTester tester) {
  final controller = _listbox(tester);
  final index = controller.highlighted;
  if (index == null) return null;
  return tester
      .widgetList<ListboxOption>(find.byType(ListboxOption))
      .firstWhere((o) => o.index == index)
      .label;
}

bool _focusIn<T extends Widget>() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<T>() !=
    null;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String chars) async {
  for (final c in chars.split('')) {
    await tester.sendKeyEvent(
      LogicalKeyboardKey(c.codeUnitAt(0)),
      character: c,
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('select without a filter', () {
    testWidgets('opens onto the selected option, focus on the list', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_select(initial: 'review')));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(ListboxOption), findsNWidgets(4));
      expect(_highlighted(tester), 'In review');
      expect(_focusIn<Listbox>(), isTrue);
    });

    testWidgets('arrows, Home, End and typeahead move; Enter picks', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _host(_select(initial: 'draft', onPick: (v) => picked = v)),
      );
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();
      expect(_highlighted(tester), 'Draft');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), 'In review');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_highlighted(tester), 'Archived');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), 'Draft', reason: 'wraps');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_highlighted(tester), 'Draft');
      await _type(tester, 'p');
      expect(_highlighted(tester), 'Published');
      // Within a second the letters build one prefix: "pa" matches nothing.
      await _type(tester, 'a');
      expect(_highlighted(tester), 'Published');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'a');
      expect(_highlighted(tester), 'Archived');

      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, 'archived');
      expect(find.byType(ListboxOption), findsNothing);
      expect(_focusIn<SelectBody>(), isTrue, reason: 'back on the trigger');
    });

    testWidgets('a pointer pick hands focus back to the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const TextField(key: Key('before')),
              _select(initial: 'draft'),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('before')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();
      expect(find.byType(ListboxOption), findsNothing);
      expect(_focusIn<FieldTrigger>(), isTrue);
    });

    testWidgets('Space picks too', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(_select(initial: 'draft', onPick: (v) => picked = v)),
      );
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.space);
      expect(picked, 'review');
    });

    testWidgets('Tab closes the menu and moves on from the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              _select(initial: 'draft'),
              const TextField(key: Key('after')),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(ListboxOption), findsWidgets);

      await _key(tester, LogicalKeyboardKey.tab);
      expect(find.byType(ListboxOption), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextField>()
            ?.key,
        const Key('after'),
      );
    });

    testWidgets('the selected one of 500 options is scrolled into view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_select(initial: 'v412', options: _many, searchable: false)),
      );
      await tester.tap(find.text('Item 412'));
      await tester.pumpAndSettle();
      final row = find.widgetWithText(ListboxOption, 'Item 412');
      expect(row, findsOneWidget);
      final list = tester.getRect(find.byType(Listbox));
      final rect = tester.getRect(row);
      expect(list.top <= rect.top && rect.bottom <= list.bottom, isTrue);
      expect(_highlighted(tester), 'Item 412');
    });

    testWidgets('the menu is the trigger’s width', (tester) async {
      await tester.pumpWidget(_host(_select(initial: 'draft')));
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(PopoverMenuSurface)).width,
        tester.getSize(find.byType(FieldTrigger)).width,
      );
    });
  });

  group('select with a filter', () {
    testWidgets('ArrowDown moves from the filter; Enter picks the match', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          _select(initial: 'v0', options: _many, onPick: (v) => picked = v),
        ),
      );
      await tester.tap(find.text('Item 0'));
      await tester.pumpAndSettle();
      expect(_focusIn<EditableText>(), isTrue, reason: 'in the filter');

      await tester.enterText(find.byType(TextField), 'item 4');
      await tester.pumpAndSettle();
      expect(_highlighted(tester), 'Item 4', reason: 'the first match');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), 'Item 40');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, 'v4');
      expect(find.byType(ListboxOption), findsNothing);
    });

    testWidgets('Tab from the filter closes the menu', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              _select(initial: 'draft', searchable: true),
              const TextField(key: Key('after')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();
      expect(_focusIn<ListboxMenu>(), isTrue);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(find.byType(ListboxOption), findsNothing);
      expect(_focusIn<ListboxMenu>(), isFalse);
    });

    testWidgets('the filter box is a small field with a search glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_select(initial: 'draft', searchable: true)),
      );
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();
      final box = find.descendant(
        of: find.byType(ListboxMenu),
        matching: find.byType(TextField),
      );
      expect(tester.getSize(box).height, defaultTokens.sizes.small);
      expect(
        find.descendant(of: box, matching: find.byIcon(Icons.search_rounded)),
        findsOneWidget,
      );
    });
  });

  group('multi-select', () {
    testWidgets('Space and Enter toggle and keep the checklist open', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_multi(initial: {'review'})));
      await tester.tap(find.text('In review'));
      await tester.pumpAndSettle();
      expect(_highlighted(tester), 'In review');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.space);
      final body = tester.widget<MultiSelectBody>(find.byType(MultiSelectBody));
      expect(body.value, {'review', 'published'});
      expect(find.byType(ListboxOption), findsNWidgets(4));
      await _key(tester, LogicalKeyboardKey.enter);
      expect(
        tester.widget<MultiSelectBody>(find.byType(MultiSelectBody)).value,
        {'review'},
      );
      expect(_highlighted(tester), 'Published', reason: 'the highlight stays');
    });

    testWidgets('tokens keep the control height as they come and go', (
      tester,
    ) async {
      double height(Set<String> value) {
        return tester.getSize(find.byType(FieldTrigger)).height;
      }

      await tester.pumpWidget(_host(_multi()));
      final empty = height(const {});
      await tester.pumpWidget(_host(_multi(initial: {'draft'})));
      await tester.pumpAndSettle();
      expect(empty, defaultTokens.sizes.medium);
      expect(height(const {'draft'}), defaultTokens.sizes.medium);
    });

    testWidgets('the rows announce their checked state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_multi(initial: {'draft'})));
      await tester.tap(find.byType(FieldTrigger));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.widgetWithText(ListboxOption, 'Draft')),
        isSemantics(label: 'Draft', hasCheckedState: true, isChecked: true),
      );
      handle.dispose();
    });
  });

  group('state', () {
    testWidgets('an invalid scope reddens the trigger', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FieldStateScope(
                invalid: true,
                child: SelectBody(options: _statuses, onChanged: (_) {}),
              ),
              FieldStateScope(
                invalid: true,
                child: MultiSelectBody(options: _statuses, onChanged: (_) {}),
              ),
            ],
          ),
        ),
      );
      for (final chrome in tester.widgetList<FieldChrome>(
        find.byType(FieldChrome),
      )) {
        expect(chrome.invalid, isTrue);
      }
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FieldChrome).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, defaultTokens.palette.danger);
    });

    testWidgets('read-only keeps contrast and drops the chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              SelectBody(options: _statuses, value: 'review'),
              MultiSelectBody(options: _statuses, value: {'review'}),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      final text = tester.widget<Text>(find.text('In review').first);
      expect(text.style!.color, defaultTokens.palette.foreground);
      expect(
        find.descendant(
          of: find.byType(MultiSelectBody),
          matching: find.byType(IconAction),
        ),
        findsNothing,
        reason: 'no remove buttons',
      );

      // Focusable, but nothing opens.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusIn<SelectBody>(), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(ListboxOption), findsNothing);
    });

    testWidgets('a disabled scope dims the value and keeps the chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FieldStateScope(
            enabled: false,
            child: SelectBody(
              options: _statuses,
              value: 'review',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('In review'));
      expect(text.style!.color, defaultTokens.palette.foregroundSubtle);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      await tester.tap(find.text('In review'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ListboxOption), findsNothing);
    });

    testWidgets('the trigger is the control height in every theme', (
      tester,
    ) async {
      for (final theme in adminThemes) {
        final source = theme.tokens;
        final tokens = AdminTokens.from(
          palette: source.palette,
          radii: source.radii,
          focus: source.focus,
          sizes: source.sizes,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(tokens),
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: SelectBody(
                  options: _statuses,
                  value: 'draft',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(FieldTrigger)).height,
          tokens.sizes.medium,
          reason: theme.name,
        );
      }
    });
  });
}
