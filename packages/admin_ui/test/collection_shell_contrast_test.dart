import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'shipped_palettes.dart';

/// The catalog's Brand accents: dark mode is where a brand's soft tints are
/// most at risk of washing out.
const _brands = <String, Color?>{
  'Default': null,
  'Teal': Color(0xFF0D9488),
  'Crimson': Color(0xFFE11D48),
};

const _rows = ['Alpha', 'Bravo', 'Cherry', 'Delta'];

const _assets = [
  Asset(id: 'a', name: 'hero.jpg', width: 1200, height: 800),
  Asset(id: 'b', name: 'logo.png', width: 512, height: 512),
];

void main() {
  for (final MapEntry(key: theme, value: dark) in shippedDarkPalettes.entries) {
    for (final MapEntry(key: brand, value: seed) in _brands.entries) {
      final palette = seed == null ? dark : dark.branded(seed);

      group('$theme Dark + $brand', () {
        Future<void> pump(WidgetTester tester, Widget child) =>
            tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(AdminTokens.from(palette: palette)),
                home: Scaffold(
                  body: Center(
                    child: SizedBox(width: 820, height: 480, child: child),
                  ),
                ),
              ),
            );

        testWidgets('table rows read on the selected and striped fills', (
          tester,
        ) async {
          await pump(
            tester,
            CollectionTable<String>(
              rows: _rows,
              rowKey: (r) => r,
              striped: true,
              columns: [const TableColumn(label: 'Name', cell: Text.new)],
              selected: const {'Alpha', 'Bravo'},
              onSelectionChanged: (_) {},
            ),
          );
          final table = tester.widget<TwoDimensionalScrollView>(
            find.byWidgetPredicate((w) => w is TwoDimensionalScrollView),
          );
          final delegate = table.delegate as TableCellBuilderDelegate;
          for (final (i, row) in _rows.indexed) {
            final fill = delegate.buildRow(i + 1)!.backgroundDecoration!.color!;
            _expectContrast(
              _textColor(tester, row),
              _over(fill, palette.surface),
              4.5,
              '$row (row ${i + 1}) text on its fill',
            );
          }
          _expectContrast(
            _textColor(tester, 'Name'),
            palette.surfaceMuted,
            4.5,
            'header label on the header strip',
          );
          final fills = {
            for (var i = 0; i < _rows.length; i++)
              _over(
                delegate.buildRow(i + 1)!.backgroundDecoration!.color!,
                palette.surface,
              ),
          };
          expect(fills, hasLength(3), reason: 'plain, striped and selected');
        });

        testWidgets('sidebar marks the selected item and keeps badges legible', (
          tester,
        ) async {
          await pump(
            tester,
            Row(
              children: [
                Sidebar(
                  entries: [
                    NavItem(
                      'Pages',
                      icon: Icons.description_outlined,
                      badge: '3',
                      selected: true,
                      onTap: () {},
                    ),
                    NavItem(
                      'Media',
                      icon: Icons.photo_library_outlined,
                      badge: '12',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          );

          final tile = _over(_fillBehind(tester, 'Pages'), palette.background);
          _expectContrast(
            _textColor(tester, 'Pages'),
            tile,
            4.5,
            'selected label on its fill',
          );
          final lift = contrastRatio(tile, palette.background);
          expect(
            lift,
            greaterThan(1.1),
            reason:
                'selected fill ${_hex(tile)} vs rail ${_hex(palette.background)} '
                'is ${lift.toStringAsFixed(2)}:1',
          );

          for (final (badge, under) in [
            ('3', tile),
            ('12', palette.background),
          ]) {
            _expectContrast(
              _textColor(tester, badge),
              _over(_fillBehind(tester, badge), under),
              4.5,
              'badge "$badge" on its fill',
            );
          }
        });

        testWidgets('asset picker: check and selected row stay legible', (
          tester,
        ) async {
          await pump(
            tester,
            const AssetLibrary(
              assets: _assets,
              view: AssetView.list,
              selectionMode: AssetSelectionMode.multiple,
              selected: {'a'},
            ),
          );

          final check = tester.widget<Icon>(find.byIcon(Icons.check));
          final disc = _fillBehind(tester, Icons.check);
          // A glyph is a UI graphic: WCAG 1.4.11 asks 3:1.
          _expectContrast(check.color!, disc, 3, 'check on its disc');

          final row = _over(_fillBehind(tester, 'hero.jpg'), palette.surface);
          _expectContrast(
            _textColor(tester, 'hero.jpg'),
            row,
            4.5,
            'selected row name',
          );
          _expectContrast(
            _textColor(tester, find.textContaining('1200')),
            row,
            4.5,
            'selected row metadata',
          );
        });
      });
    }
  }
}

/// The colour the [Text] showing [text] (a string or a [Finder]) paints with,
/// after its inherited style.
Color _textColor(WidgetTester tester, Object text) => tester
    .renderObject<RenderParagraph>(text is Finder ? text : find.text('$text'))
    .text
    .style!
    .color!;

/// The nearest painted fill behind a text or icon: the first ancestor
/// [Container] whose decoration has a colour.
Color _fillBehind(WidgetTester tester, Object target) {
  final finder = target is IconData
      ? find.byIcon(target)
      : find.text('$target');
  final boxes = tester.widgetList<Container>(
    find.ancestor(of: finder, matching: find.byType(Container)),
  );
  for (final box in boxes) {
    final color = switch (box.decoration) {
      BoxDecoration(:final color?) => color,
      _ => box.color,
    };
    if (color != null && color.a > 0) return color;
  }
  throw StateError('no fill behind $target');
}

/// [fill] composited over [page], for a translucent fill.
Color _over(Color fill, Color page) => Color.alphaBlend(fill, page);

void _expectContrast(Color foreground, Color fill, double min, String what) {
  final ratio = contrastRatio(foreground, fill);
  expect(
    ratio,
    greaterThanOrEqualTo(min),
    reason:
        '$what: ${_hex(foreground)} on ${_hex(fill)} is '
        '${ratio.toStringAsFixed(2)}:1',
  );
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
