import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A CommandSource told to list on an empty query is what a palette opens
// on: every item, under its group, in the order given. Without, it lists
// none until something is typed, as it always did; and typing matches the
// same either way.

PaletteItem _item(
  String title,
  String group, {
  List<String> keywords = const [],
  VoidCallback? onSelect,
}) => PaletteItem(
  id: '$group/$title',
  title: title,
  icon: Icons.circle_outlined,
  group: group,
  keywords: keywords,
  onSelect: onSelect ?? () {},
);

List<PaletteItem> _items() => [
  _item('Dashboard', 'Pages'),
  _item('New product', 'Commands'),
  _item('Orders', 'Pages'),
  _item('Sign out', 'Commands', keywords: ['log out']),
  _item('Customers', 'Pages'),
];

/// Each section as `title: item, item`.
List<String> _read(List<PaletteSection> sections) => [
  for (final s in sections)
    '${s.title}: ${[for (final e in s.entries) e.item.title].join(', ')}',
];

/// What a match marks and how it ranks, to compare two by.
String _mark(ScoredItem entry) => '${entry.matched} ${entry.score}';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Center(child: SizedBox(width: 600, height: 480, child: child)),
      ),
    ),
  );
  await tester.pump(); // settle autofocus
}

void main() {
  // A controller's registry defers a notify mid-frame through the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommandSource', () {
    test('lists nothing on an empty query, as it did', () {
      expect(const CommandSource(_items).search(''), isEmpty);
      expect(const CommandSource(_items).listOnEmptyQuery, isFalse);
    });

    test('told to, lists every item under its group, in the order given', () {
      final sections = const CommandSource(
        _items,
        listOnEmptyQuery: true,
      ).search('');
      expect(_read(sections), [
        'Pages: Dashboard, Orders, Customers',
        'Commands: New product, Sign out',
      ]);
    });

    test('an item listed is not a match: no letter marked, no rank', () {
      final sections = const CommandSource(
        _items,
        listOnEmptyQuery: true,
      ).search('');
      for (final entry in sections.expand((s) => s.entries)) {
        expect(entry.matched, isEmpty, reason: entry.item.title);
        expect(entry.score, 0, reason: entry.item.title);
      }
    });

    test('a query of spaces is an empty one', () {
      final source = const CommandSource(_items, listOnEmptyQuery: true);
      expect(_read(source.search('   ')), _read(source.search('')));
      expect(source.search('   '), isNotEmpty);
      expect(const CommandSource(_items).search('   '), isEmpty);
    });

    test('a typed query matches as it does without', () {
      final listing = const CommandSource(_items, listOnEmptyQuery: true);
      final plain = const CommandSource(_items);
      for (final query in ['or', 'sign', 'log out', 'cust', 'zzzz', ' da ']) {
        final a = listing.search(query);
        final b = plain.search(query);
        expect(_read(a), _read(b), reason: query);
        expect(
          [for (final e in a.expand((s) => s.entries)) _mark(e)],
          [for (final e in b.expand((s) => s.entries)) _mark(e)],
          reason: query,
        );
      }
      // And a typed query narrows: it is not the whole list.
      expect(_read(listing.search('cust')), ['Pages: Customers']);
      expect(listing.search('zzzz'), isEmpty);
    });

    test('with no item it lists no section', () {
      expect(
        CommandSource(() => const [], listOnEmptyQuery: true).search(''),
        isEmpty,
      );
    });

    test('it reads its items each time, so a registry\'s changes show', () {
      final items = [_item('Dashboard', 'Pages')];
      final source = CommandSource(() => items, listOnEmptyQuery: true);
      expect(_read(source.search('')), ['Pages: Dashboard']);
      items.add(_item('Export', 'Commands'));
      expect(_read(source.search('')), [
        'Pages: Dashboard',
        'Commands: Export',
      ]);
    });
  });

  group('a palette over it', () {
    test('opens on the list, its first item selected', () {
      final c = CommandPaletteController(
        sources: [const CommandSource(_items, listOnEmptyQuery: true)],
      );
      addTearDown(c.dispose);
      expect(_read(c.sections), [
        'Pages: Dashboard, Orders, Customers',
        'Commands: New product, Sign out',
      ]);
      expect(c.selected, 0);
      expect(c.selectedItem!.title, 'Dashboard');
      expect(c.loading, isFalse);
    });

    test('files the groups in the palette\'s order, recents among them', () {
      final c = CommandPaletteController(
        groupOrder: const ['Recent', 'Commands', 'Pages'],
        sources: [
          const CommandSource(_items, listOnEmptyQuery: true),
          RecentsSource(() => [_item('Order 1042', 'Recent')]),
        ],
      );
      addTearDown(c.dispose);
      expect(_read(c.sections), [
        'Recent: Order 1042',
        'Commands: New product, Sign out',
        'Pages: Dashboard, Orders, Customers',
      ]);
    });

    test('typing narrows the list and clearing brings it back', () {
      final c = CommandPaletteController(
        sources: [const CommandSource(_items, listOnEmptyQuery: true)],
      );
      addTearDown(c.dispose);
      final opened = _read(c.sections);

      c.setQuery('cust');
      expect(_read(c.sections), ['Pages: Customers']);

      c.setQuery('');
      expect(_read(c.sections), opened);
      expect(c.selected, 0);
    });

    test('without, the palette opens on nothing', () {
      final c = CommandPaletteController(
        sources: [const CommandSource(_items)],
      );
      addTearDown(c.dispose);
      expect(c.sections, isEmpty);
      expect(c.selectedItem, isNull);
    });

    testWidgets('draws the list where "Type to search" was', (tester) async {
      final listing = CommandPaletteController(
        sources: [const CommandSource(_items, listOnEmptyQuery: true)],
      );
      addTearDown(listing.dispose);
      await _pump(tester, CommandPalette.controller(listing, onDismiss: () {}));
      expect(find.text('Type to search'), findsNothing);
      expect(find.text('PAGES'), findsOneWidget);
      expect(find.text('COMMANDS'), findsOneWidget);
      for (final item in _items()) {
        expect(find.text(item.title), findsOneWidget, reason: item.title);
      }
    });

    testWidgets('without, it still says "Type to search"', (tester) async {
      final plain = CommandPaletteController(
        sources: [const CommandSource(_items)],
      );
      addTearDown(plain.dispose);
      await _pump(tester, CommandPalette.controller(plain, onDismiss: () {}));
      expect(find.text('Type to search'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('Enter on opening runs the first item listed', (tester) async {
      final ran = <String>[];
      final c = CommandPaletteController(
        sources: [
          CommandSource(
            () => [
              _item('Dashboard', 'Pages', onSelect: () => ran.add('Dashboard')),
              _item('Orders', 'Pages', onSelect: () => ran.add('Orders')),
            ],
            listOnEmptyQuery: true,
          ),
        ],
      );
      addTearDown(c.dispose);
      await _pump(tester, CommandPalette.controller(c, onDismiss: () {}));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(ran, ['Dashboard']);
    });

    testWidgets('the arrow keys walk the list from the first item', (
      tester,
    ) async {
      final c = CommandPaletteController(
        sources: [const CommandSource(_items, listOnEmptyQuery: true)],
      );
      addTearDown(c.dispose);
      await _pump(tester, CommandPalette.controller(c, onDismiss: () {}));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(c.selectedItem!.title, 'Orders');
      // Past the first group's end, into the second.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(c.selectedItem!.title, 'New product');
    });
  });
}
