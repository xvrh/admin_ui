import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/popover_menu.dart' show MenuGroupLabel;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Where a link leads, given out of order: the groups interleave, and the
/// option with no group comes third.
const _targets = [
  ComboboxOption('dashboard', 'Dashboard', group: 'Pages'),
  ComboboxOption('web', 'A web page', group: 'Elsewhere'),
  ComboboxOption('none', 'No link'),
  ComboboxOption('orders', 'Orders', group: 'Pages'),
  ComboboxOption('invoice', 'An invoice', group: 'Documents'),
  ComboboxOption('report', 'A report', group: 'Documents'),
];

/// [_targets] as the list shows them.
const _shown = [
  'No link',
  'Dashboard',
  'Orders',
  'A web page',
  'An invoice',
  'A report',
];

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: 300, child: child),
      ),
    ),
  ),
);

Widget _live({
  String? initial,
  List<ComboboxOption<String>> options = _targets,
  Future<List<ComboboxOption<String>>> Function(String)? onSearch,
  String Function(String)? labelFor,
  ValueChanged<String?>? onPick,
}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) => Combobox<String>(
      value: value,
      options: options,
      onSearch: onSearch,
      labelFor: labelFor,
      onChanged: (v) {
        setState(() => value = v);
        onPick?.call(v);
      },
    ),
  );
}

Finder _heading(String label) => find.byWidgetPredicate(
  (w) => w is MenuGroupLabel && w.label == label,
  description: 'the heading "$label"',
);

/// The headings drawn, top to bottom.
List<String> _headings(WidgetTester tester) {
  final found = find.byType(MenuGroupLabel);
  final headings = [
    for (final e in found.evaluate()) e.widget as MenuGroupLabel,
  ];
  final tops = {
    for (final (i, h) in headings.indexed)
      h.label: tester.getTopLeft(found.at(i)).dy,
  };
  return tops.keys.toList()..sort((a, b) => tops[a]!.compareTo(tops[b]!));
}

/// The options drawn, top to bottom.
List<String> _rows(WidgetTester tester) {
  final rows = find.byType(ListboxOption);
  final options = [
    for (final (i, e) in rows.evaluate().indexed)
      ((e.widget as ListboxOption).label, tester.getTopLeft(rows.at(i)).dy),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final o in options) o.$1];
}

String? _highlighted(WidgetTester tester) {
  final rows = tester.widgetList<ListboxOption>(find.byType(ListboxOption));
  final at = rows.first.controller.highlighted;
  return rows.where((r) => r.index == at).singleOrNull?.label;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

void main() {
  group('headings', () {
    testWidgets('the options with no group first, then each group in the '
        'order it first appears', (tester) async {
      await tester.pumpWidget(_host(_live()));
      await _open(tester);

      expect(_rows(tester), _shown);
      expect(_headings(tester), ['Pages', 'Elsewhere', 'Documents']);
      expect(
        _top(tester, find.text('No link')),
        lessThan(_top(tester, _heading('Pages'))),
        reason: 'no heading over the options with no group',
      );
      for (final (heading, first, next) in [
        ('Pages', 'Dashboard', 'Elsewhere'),
        ('Elsewhere', 'A web page', 'Documents'),
      ]) {
        expect(
          _top(tester, _heading(heading)),
          lessThan(_top(tester, find.text(first))),
        );
        expect(
          _top(tester, find.text(first)),
          lessThan(_top(tester, _heading(next))),
        );
      }
    });

    testWidgets('a heading lines up with its options’ labels', (tester) async {
      await tester.pumpWidget(_host(_live()));
      await _open(tester);
      final text = find.descendant(
        of: _heading('Pages'),
        matching: find.byType(Text),
      );
      expect(
        tester.getTopLeft(text).dx,
        tester.getTopLeft(find.text('Dashboard')).dx,
      );
    });

    testWidgets('options with no group at all draw no heading', (tester) async {
      await tester.pumpWidget(
        _host(
          _live(
            options: const [
              ComboboxOption('a', 'Apple'),
              ComboboxOption('b', 'Banana'),
            ],
          ),
        ),
      );
      await _open(tester);
      expect(find.byType(MenuGroupLabel), findsNothing);
      expect(_rows(tester), ['Apple', 'Banana']);
    });
  });

  group('keyboard', () {
    testWidgets('the arrows pass over the headings', (tester) async {
      await tester.pumpWidget(_host(_live()));
      await _open(tester);
      expect(_highlighted(tester), 'No link');

      final seen = <String?>[];
      for (var i = 0; i < _shown.length; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
        seen.add(_highlighted(tester));
      }
      expect(seen, [..._shown.skip(1), 'No link'], reason: 'wraps at the end');

      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_highlighted(tester), 'A report');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_highlighted(tester), 'No link');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_highlighted(tester), 'A report');
    });

    testWidgets('Enter picks the option under a heading', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(_live(onPick: (v) => picked = v)));
      await _open(tester);
      for (var i = 0; i < 3; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(_highlighted(tester), 'A web page');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, 'web');
    });

    testWidgets('opened on a value, the value is highlighted under its '
        'heading', (tester) async {
      await tester.pumpWidget(_host(_live(initial: 'invoice')));
      await _open(tester);
      expect(_highlighted(tester), 'An invoice');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_highlighted(tester), 'A web page');
    });

    testWidgets('moving up onto a group’s first option brings its heading '
        'into view', (tester) async {
      final options = [
        for (final area in ['North', 'South', 'West'])
          for (var i = 1; i <= 10; i++)
            ComboboxOption('$area $i', '$area $i', group: area),
      ];
      await tester.pumpWidget(_host(_live(options: options)));
      await _open(tester);
      await _key(tester, LogicalKeyboardKey.end);
      for (var i = 0; i < 9; i++) {
        await _key(tester, LogicalKeyboardKey.arrowUp);
      }
      expect(_highlighted(tester), 'West 1');
      final list = tester.getRect(find.byType(Scrollable).last);
      final heading = tester.getRect(_heading('West'));
      expect(heading.top, greaterThanOrEqualTo(list.top));
      expect(heading.bottom, lessThanOrEqualTo(list.bottom));
    });
  });

  group('pointer', () {
    testWidgets('a heading cannot be picked', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(_live(onPick: (v) => picked = v)));
      await _open(tester);
      // The heading itself takes no pointer: the click lands on the list.
      await tester.tapAt(tester.getCenter(_heading('Elsewhere')));
      await tester.pumpAndSettle();
      expect(picked, isNull);
      expect(find.byType(ListboxOption), findsNWidgets(6), reason: 'open');
    });

    testWidgets('a heading takes no highlight from the pointer', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live()));
      await _open(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('Orders')));
      await mouse.moveBy(const Offset(1, 0));
      await tester.pumpAndSettle();
      expect(_highlighted(tester), 'Orders');

      await mouse.moveTo(tester.getCenter(_heading('Elsewhere')));
      await tester.pumpAndSettle();
      expect(_highlighted(tester), 'Orders');
    });
  });

  group('filtering', () {
    testWidgets('a group with no match loses its heading', (tester) async {
      await tester.pumpWidget(_host(_live()));
      await _open(tester);
      await tester.enterText(find.byType(TextField), 'web');
      await tester.pumpAndSettle();
      expect(_rows(tester), ['A web page']);
      expect(_headings(tester), ['Elsewhere']);
    });

    testWidgets('the groups are ordered by their best match, and Enter '
        'picks it', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(_live(onPick: (v) => picked = v)));
      await _open(tester);
      // "A report" matches "re" at a word's start, "Orders" mid-word.
      await tester.enterText(find.byType(TextField), 're');
      await tester.pumpAndSettle();
      expect(_rows(tester), ['A report', 'Orders']);
      expect(_headings(tester), ['Documents', 'Pages']);
      expect(_highlighted(tester), 'A report');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, 'report');
    });

    testWidgets('a match with no group stays first, under no heading', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_live()));
      await _open(tester);
      await tester.enterText(find.byType(TextField), 'n');
      await tester.pumpAndSettle();
      expect(_rows(tester), ['No link', 'An invoice']);
      expect(_headings(tester), ['Documents']);
    });
  });

  testWidgets('a search’s results are grouped, and Enter in flight picks '
      'the first one shown', (tester) async {
    String? picked;
    final pending = Completer<List<ComboboxOption<String>>>();
    await tester.pumpWidget(
      _host(
        _live(
          options: const [],
          onSearch: (q) => q.isEmpty ? Future.value(_targets) : pending.future,
          labelFor: (v) => v,
          onPick: (v) => picked = v,
        ),
      ),
    );
    await _open(tester);
    expect(_rows(tester), _shown);
    expect(_headings(tester), ['Pages', 'Elsewhere', 'Documents']);

    await tester.enterText(find.byType(TextField), 'o');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    pending.complete(const [
      ComboboxOption('orders', 'Orders', group: 'Pages'),
      ComboboxOption('none', 'No link'),
    ]);
    await tester.pumpAndSettle();
    expect(picked, 'none');
  });

  testWidgets('screen readers hear a heading, and each option as before', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_live(initial: 'web')));
    await _open(tester);
    expect(
      tester.getSemantics(_heading('Elsewhere')),
      isSemantics(label: 'Elsewhere', isHeader: true, isButton: false),
    );
    expect(
      tester.getSemantics(find.widgetWithText(ListboxOption, 'A web page')),
      isSemantics(
        label: 'A web page',
        hint: '4 of 6',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isFocused: true,
      ),
    );
    expect(
      tester.getSemantics(find.widgetWithText(ListboxOption, 'Dashboard')),
      isSemantics(label: 'Dashboard', hint: '2 of 6', isFocused: false),
    );
    handle.dispose();
  });

  testWidgets('a Listbox draws a heading where the group changes', (
    tester,
  ) async {
    const rows = [
      ('Alpha', null),
      ('Bravo', 'One'),
      ('Charlie', 'One'),
      ('Delta', 'Two'),
      ('Echo', 'One'),
    ];
    final controller = ListboxController();
    addTearDown(controller.dispose);
    controller.reset(rows.length, labelOf: (i) => rows[i].$1);
    await tester.pumpWidget(
      _host(
        Listbox(
          controller: controller,
          itemCount: rows.length,
          groupOf: (i) => rows[i].$2,
          itemBuilder: (context, i) => ListboxOption(
            controller: controller,
            index: i,
            label: rows[i].$1,
          ),
        ),
      ),
    );
    final labels = [
      for (final h in tester.widgetList<MenuGroupLabel>(
        find.byType(MenuGroupLabel),
      ))
        h.label,
    ];
    expect(labels, ['One', 'Two', 'One'], reason: 'listed as given');
    expect(controller.count, rows.length, reason: 'headings are not options');
  });
}
