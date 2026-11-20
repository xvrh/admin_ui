import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Where a top bar runs out of room, its leading widget is given the width
// that is left, so the search icon keeps its place; with room to spare the
// leading widget is as wide as it asks to be.

const _brandKey = Key('brand');
const _nameKey = Key('name');

/// A brand that can shrink: a mark, and a name that ellipsizes.
Widget _brand({String name = 'Northwind Trading'}) => Row(
  key: _brandKey,
  mainAxisSize: MainAxisSize.min,
  children: [
    const SizedBox.square(dimension: 28, child: ColoredBox(color: Colors.teal)),
    const SizedBox(width: 8),
    Flexible(
      child: Text(
        name,
        key: _nameKey,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
);

final _taps = <String>[];

Widget _bar({
  Widget? leading,
  bool search = true,
  String? title,
  bool action = true,
}) => TopBar(
  leading: leading ?? _brand(),
  title: title,
  search: search ? CommandTrigger(onTap: () => _taps.add('field')) : null,
  onSearch: search ? () => _taps.add('search') : null,
  actions: [
    if (action)
      Button.primary(
        'New',
        icon: Icons.add_rounded,
        onPressed: () => _taps.add('new'),
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  required double width,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view
    ..physicalSize = Size(width, 480)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Shell(
        sidebar: Sidebar(
          entries: [NavItem('Pages', icon: Icons.article, onTap: () {})],
        ),
        topBar: bar,
        child: const SizedBox.expand(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _searchIcon = find.widgetWithIcon(IconAction, Icons.search_rounded);
final _new = find.widgetWithText(Button, 'New');

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  setUp(_taps.clear);

  group('on a phone at twice the text size', () {
    testWidgets('nothing overflows, and the search icon keeps its place', (
      tester,
    ) async {
      await _pump(tester, _bar(), width: 360, textScale: 2);
      expect(tester.takeException(), isNull);

      final bar = _rect(tester, find.byType(TopBar));
      final icon = _rect(tester, _searchIcon);
      final action = _rect(tester, _new);
      expect(icon.left, greaterThanOrEqualTo(bar.left));
      expect(icon.right, lessThan(action.left));
      expect(action.right, lessThanOrEqualTo(bar.right));
    });

    testWidgets('the brand gives way: its name is cut, its mark is whole', (
      tester,
    ) async {
      await _pump(tester, _bar(), width: 360, textScale: 2);
      final brand = _rect(tester, find.byKey(_brandKey));
      final icon = _rect(tester, _searchIcon);
      // Narrower than it asks to be, and clear of the search icon.
      await _pump(tester, _bar(), width: 1200, textScale: 2);
      final natural = _rect(tester, find.byKey(_brandKey)).width;
      expect(brand.width, lessThan(natural));
      expect(brand.width, greaterThan(28));
      expect(brand.right, lessThanOrEqualTo(icon.left));
    });

    testWidgets('the icon, the action and the brand still take taps', (
      tester,
    ) async {
      await _pump(
        tester,
        _bar(
          leading: GestureDetector(
            onTap: () => _taps.add('brand'),
            child: _brand(),
          ),
        ),
        width: 360,
        textScale: 2,
      );
      await tester.tap(_searchIcon);
      await tester.tap(_new);
      await tester.tap(find.byKey(_brandKey));
      expect(_taps, ['search', 'new', 'brand']);
    });

    testWidgets('it mirrors right to left', (tester) async {
      await _pump(
        tester,
        _bar(),
        width: 360,
        textScale: 2,
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      final brand = _rect(tester, find.byKey(_brandKey));
      final icon = _rect(tester, _searchIcon);
      final action = _rect(tester, _new);
      expect(action.right, lessThan(icon.left));
      expect(icon.right, lessThanOrEqualTo(brand.left));
    });

    testWidgets('a leading widget that fills its width is cut to the room', (
      tester,
    ) async {
      await _pump(
        tester,
        _bar(
          leading: const SizedBox(
            key: _brandKey,
            width: 400,
            height: 20,
            child: ColoredBox(color: Colors.teal),
          ),
        ),
        width: 360,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final brand = _rect(tester, find.byKey(_brandKey));
      expect(brand.width, lessThan(400));
      expect(brand.right, lessThanOrEqualTo(_rect(tester, _searchIcon).left));
    });
  });

  group('with room to spare', () {
    testWidgets('the leading widget is as wide as it asks to be', (
      tester,
    ) async {
      // A row that would fill any width it was given: the bar gives it
      // none to fill.
      await _pump(
        tester,
        _bar(
          leading: const Row(
            key: _brandKey,
            children: [SizedBox(width: 90, height: 20)],
          ),
          title: 'Catalogue',
        ),
        width: 1200,
      );
      final brand = _rect(tester, find.byKey(_brandKey));
      expect(brand.width, 90);
      // The title starts a gap after it, as in a row.
      expect(
        _rect(tester, find.text('Catalogue')).left,
        brand.right + AdminSpacing.md,
      );
    });

    testWidgets('the parts are in a row: brand, title, search, actions', (
      tester,
    ) async {
      await _pump(tester, _bar(title: 'Catalogue'), width: 1200);
      final bar = _rect(tester, find.byType(TopBar));
      final brand = _rect(tester, find.byKey(_brandKey));
      final title = _rect(tester, find.text('Catalogue'));
      final field = _rect(tester, find.byType(CommandTrigger));
      final action = _rect(tester, _new);

      expect(brand.right, lessThan(title.left));
      expect(title.right, lessThan(field.left));
      // The search field ends a gap before the actions, which end at the
      // page's gutter.
      expect(field.right, action.left - AdminSpacing.md);
      expect(action.right, lessThan(bar.right));
      // Each centred in the bar's height.
      for (final rect in [brand, title, field, action]) {
        expect(rect.center.dy, closeTo(bar.center.dy, 1));
      }
    });

    testWidgets('a bar with no actions gives the middle the rest', (
      tester,
    ) async {
      await _pump(tester, _bar(action: false), width: 1200);
      expect(tester.takeException(), isNull);
      final bar = _rect(tester, find.byType(TopBar));
      final field = _rect(tester, find.byType(CommandTrigger));
      expect(field.right, lessThan(bar.right));
      expect(bar.right - field.right, lessThan(48));
    });
  });

  testWidgets('with no search, the brand has all but the actions', (
    tester,
  ) async {
    await _pump(tester, _bar(search: false), width: 360, textScale: 2);
    expect(tester.takeException(), isNull);
    final brand = _rect(tester, find.byKey(_brandKey));
    final action = _rect(tester, _new);
    expect(brand.right, lessThanOrEqualTo(action.left));
    expect(_searchIcon, findsNothing);
  });
}
