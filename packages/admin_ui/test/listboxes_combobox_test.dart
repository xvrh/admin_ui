import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fruit = [
  ComboboxOption('a', 'Apple'),
  ComboboxOption('b', 'Banana'),
  ComboboxOption('c', 'Cherry'),
];

final _many = [for (var i = 0; i < 30; i++) ComboboxOption('$i', 'Option $i')];

Widget _host(Widget child, {double width = 300}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

/// A combobox that keeps its own value, reporting picks to [onPick].
Widget _live({
  String? initial,
  List<ComboboxOption<String>> options = _fruit,
  Future<List<ComboboxOption<String>>> Function(String)? onSearch,
  String Function(String)? labelFor,
  ValueChanged<String?>? onPick,
  FocusNode? focusNode,
}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) => Combobox<String>(
      value: value,
      options: options,
      onSearch: onSearch,
      labelFor: labelFor,
      focusNode: focusNode,
      onChanged: (v) {
        setState(() => value = v);
        onPick?.call(v);
      },
    ),
  );
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

ListboxController _listbox(WidgetTester tester) =>
    tester.widget<ListboxOption>(find.byType(ListboxOption).first).controller;

bool _focusInCombobox() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<Combobox<String>>() !=
    null;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  group('async mode', () {
    testWidgets('keeps the picked label with no options to find it in', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          _live(
            options: const [],
            onSearch: (q) async => _fruit
                .where((o) => o.label.toLowerCase().contains(q.toLowerCase()))
                .toList(),
            onPick: (v) => picked = v,
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();
      expect(picked, 'b');
      expect(_fieldText(tester), 'Banana');

      // Closing and reopening, then leaving with Escape, keeps it too.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_fieldText(tester), 'Banana');
    });

    testWidgets('labelFor names a value no search has returned', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _live(
            initial: 'c',
            options: const [],
            onSearch: (q) async => const [],
            labelFor: (v) => 'Label of $v',
          ),
        ),
      );
      expect(_fieldText(tester), 'Label of c');
    });

    testWidgets('a failed search shows the error and retries', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          _live(
            options: const [],
            onSearch: (q) async {
              calls++;
              if (calls == 1) throw StateError('offline');
              return _fruit;
            },
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Couldn’t load results'), findsOneWidget);
      expect(find.text('Searching…'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load results'), findsNothing);
      expect(find.text('Cherry'), findsOneWidget);
      expect(_focusInCombobox(), isTrue);
    });

    testWidgets('Enter in flight waits for the results and picks the first', (
      tester,
    ) async {
      final pending = <String, Completer<List<ComboboxOption<String>>>>{};
      String? picked;
      await tester.pumpWidget(
        _host(
          _live(
            options: const [],
            onSearch: (q) => (pending[q] = Completer()).future,
            onPick: (v) => picked = v,
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      pending['']!.complete(_fruit);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);

      // The full list is still showing while "ch" is in flight.
      await tester.enterText(find.byType(TextField), 'ch');
      await tester.pump();
      expect(find.text('Apple'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, isNull, reason: 'no stale row is picked');

      pending['ch']!.complete(const [ComboboxOption('c', 'Cherry')]);
      await tester.pumpAndSettle();
      expect(picked, 'c');
      expect(_fieldText(tester), 'Cherry');
    });

    testWidgets('shows a spinner in the field while a search runs', (
      tester,
    ) async {
      final pending = <String, Completer<List<ComboboxOption<String>>>>{};
      await tester.pumpWidget(
        _host(
          _live(
            options: const [],
            onSearch: (q) => (pending[q] = Completer()).future,
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      pending['']!.complete(_fruit);
      await tester.pumpAndSettle();
      final inField = find.descendant(
        of: find.byType(TextField),
        matching: find.byType(Spinner),
      );
      expect(inField, findsNothing);

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      expect(inField, findsOneWidget, reason: 'results already showing');
      pending['a']!.complete(_fruit);
      await tester.pumpAndSettle();
      expect(inField, findsNothing);
    });
  });

  group('opening', () {
    testWidgets('with a value it lists every option, the value highlighted', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live(initial: 'b')));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(ListboxOption), findsNWidgets(3));
      expect(_listbox(tester).highlighted, 1);

      // Typing filters, onto the first match.
      await tester.enterText(find.byType(TextField), 'ch');
      await tester.pumpAndSettle();
      expect(find.byType(ListboxOption), findsOneWidget);
      expect(_listbox(tester).highlighted, 0);
    });

    testWidgets('Tab focus does not open; ArrowDown and Alt+ArrowDown do', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live()));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusInCombobox(), isTrue);
      expect(find.byType(ListboxOption), findsNothing);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(find.byType(ListboxOption), findsNWidgets(3));
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ListboxOption), findsNothing);
      expect(_focusInCombobox(), isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(ListboxOption), findsNWidgets(3));
    });

    testWidgets('a selected option far down is scrolled into view', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live(initial: '27', options: _many)));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final row = find.widgetWithText(ListboxOption, 'Option 27');
      expect(row, findsOneWidget);
      final list = tester.getRect(find.byType(Listbox));
      final rect = tester.getRect(row);
      expect(list.top <= rect.top && rect.bottom <= list.bottom, isTrue);
    });
  });

  group('keyboard', () {
    testWidgets('arrows and Enter pick; focus stays in the field', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              _live(initial: 'a', onPick: (v) => picked = v),
              const TextField(key: Key('next')),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, 'b');
      expect(find.byType(ListboxOption), findsNothing);
      expect(_focusInCombobox(), isTrue);
    });

    testWidgets('Home, End, PageDown and PageUp move the highlight', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live(options: _many)));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(_listbox(tester).highlighted, 0);
      await _key(tester, LogicalKeyboardKey.end);
      expect(_listbox(tester).highlighted, 29);
      expect(find.widgetWithText(ListboxOption, 'Option 29'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.home);
      expect(_listbox(tester).highlighted, 0);
      await _key(tester, LogicalKeyboardKey.pageDown);
      expect(_listbox(tester).highlighted, 10);
      await _key(tester, LogicalKeyboardKey.pageUp);
      expect(_listbox(tester).highlighted, 0);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_listbox(tester).highlighted, 29, reason: 'arrows wrap');
    });

    testWidgets('Tab away closes the list and restores the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              _live(initial: 'a'),
              const TextField(key: Key('next')),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'ba');
      await tester.pumpAndSettle();
      expect(find.byType(ListboxOption), findsWidgets);

      // Onto the clear button, a stop of its own beside the field.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(find.byType(ListboxOption), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ClearButton>(),
        isNotNull,
      );
      expect(_fieldText(tester), 'Apple');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusInCombobox(), isFalse);
    });

    testWidgets('the arrows left and right still move the caret', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live(initial: 'b')));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      controller.selection = const TextSelection.collapsed(offset: 3);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(controller.selection.baseOffset, 2);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(controller.selection.baseOffset, 3);
      expect(
        find.byType(ListboxOption),
        findsNWidgets(3),
        reason: 'still open',
      );
    });
  });

  group('placement', () {
    testWidgets('the dropdown is the field’s width, at least 200', (
      tester,
    ) async {
      for (final (width, expected) in [(360.0, 360.0), (160.0, 200.0)]) {
        await tester.pumpWidget(_host(_live(), width: width));
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(PopoverMenuSurface)).width, expected);
        await _key(tester, LogicalKeyboardKey.escape);
      }
    });

    testWidgets('right to left, a wider dropdown lines up with the start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Directionality(textDirection: TextDirection.rtl, child: _live()),
          width: 160,
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(TextField));
      final menu = tester.getRect(find.byType(PopoverMenuSurface));
      expect(menu.width, 200);
      expect(menu.right, field.right);
    });

    testWidgets('near the bottom it opens above the field', (tester) async {
      tester.view.physicalSize = const Size(600, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(width: 300, child: _live(options: _many)),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(TextField));
      final menu = tester.getRect(find.byType(PopoverMenuSurface));
      expect(menu.bottom, lessThanOrEqualTo(field.top));
      expect(menu.top, greaterThanOrEqualTo(0));
    });
  });

  group('semantics', () {
    testWidgets('the field reports expanded; rows their selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_live(initial: 'b')));
      final field = find.byType(TextField);
      expect(
        tester.getSemantics(field),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(field),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      expect(
        tester.getSemantics(find.widgetWithText(ListboxOption, 'Banana')),
        isSemantics(
          label: 'Banana',
          hint: '2 of 3',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isFocused: true,
        ),
      );
      expect(
        tester.getSemantics(find.widgetWithText(ListboxOption, 'Apple')),
        isSemantics(isSelected: false, isFocused: false),
      );
      handle.dispose();
    });
  });

  group('state', () {
    testWidgets('with a value, the clear sits just before the chevron', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live(initial: 'a')));
      final clear = tester.getRect(find.byType(ClearButton));
      final chevron = tester.getRect(find.byType(FieldChevron));
      final field = tester.getRect(find.byType(TextField));
      expect(clear.right, chevron.left, reason: 'adjacent 24px slots');
      expect(clear.center.dy, chevron.center.dy);
      // The chevron's glyph ends fieldPaddingX in, as a FieldTrigger's does.
      final glyph = tester.getRect(
        find.descendant(
          of: find.byType(FieldChevron),
          matching: find.byType(Icon),
        ),
      );
      expect(field.right - glyph.right, defaultTokens.sizes.fieldPaddingX);

      await tester.pumpWidget(_host(_live(initial: null)));
      expect(find.byType(ClearButton), findsNothing);
      expect(find.byType(FieldChevron), findsOneWidget);
    });

    testWidgets('read-only stays focusable and never opens', (tester) async {
      await tester.pumpWidget(
        _host(
          const Combobox<String>(value: 'b', onChanged: null, options: _fruit),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(field.decoration!.enabled, isTrue);
      expect(find.byType(ClearButton), findsNothing);
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
        ),
        findsNothing,
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(_focusInCombobox(), isTrue);
      expect(find.byType(ListboxOption), findsNothing);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(find.byType(ListboxOption), findsNothing);
    });

    testWidgets('enabled: false and a disabled scope disable it', (
      tester,
    ) async {
      for (final child in [
        Combobox<String>(
          value: 'b',
          onChanged: (_) {},
          options: _fruit,
          enabled: false,
        ),
        FieldStateScope(
          enabled: false,
          child: Combobox<String>(
            value: 'b',
            onChanged: (_) {},
            options: _fruit,
          ),
        ),
      ]) {
        await tester.pumpWidget(_host(child));
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration!.enabled, isFalse);
        await tester.tap(find.byType(TextField), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byType(ListboxOption), findsNothing);
      }
    });

    testWidgets('an invalid scope draws the error outline', (tester) async {
      await tester.pumpWidget(
        _host(
          FieldStateScope(
            invalid: true,
            child: Combobox<String>(
              value: 'b',
              onChanged: (_) {},
              options: _fruit,
            ),
          ),
        ),
      );
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      final border = decoration.border! as FieldBorder;
      expect(
        border.chromeOf(const {}).outline.color,
        defaultTokens.palette.danger,
      );
    });
  });
}
