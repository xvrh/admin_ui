import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.2 SC 2.5.8: a pointer target of at least 24 by 24 CSS pixels.
const _targetSize = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);

const _guidelines = [
  (labeledTapTargetGuideline, 'labelled targets'),
  (_targetSize, '24px targets'),
  (textContrastGuideline, 'text contrast'),
];

class _Product {
  final int id;
  final String name;
  _Product(this.id, this.name);
}

final _products = [for (var i = 0; i < 4; i++) _Product(i, 'Product $i')];

final _exhibits = <String, Widget Function()>{
  'Pager': () => Pager(
    from: 41,
    to: 60,
    total: 1234,
    hasPrev: true,
    hasNext: true,
    page: 3,
    onPage: (_) {},
    pageSize: 20,
    pageSizes: const [20, 50],
    onPageSize: (_) {},
  ),
  'Cards, one selected': () => SizedBox(
    height: 420,
    child: CollectionCards<_Product>(
      rows: _products,
      rowKey: (p) => p.id,
      cardBuilder: (_, p) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        child: Text(p.name),
      ),
      onCardTap: (_) {},
      selected: {_products[1]},
      onSelectionChanged: (_) {},
    ),
  ),
  'Cards, no results': () => SizedBox(
    height: 320,
    child: CollectionCards<_Product>(
      rows: const [],
      cardBuilder: (_, p) => Text(p.name),
      filtered: true,
      onClearFilters: () {},
    ),
  ),
};

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      if (dark && !theme.hasDark) continue;
      final tokens = dark ? theme.dark! : theme.tokens;
      final data = buildAppTheme(
        AdminTokens.from(
          palette: tokens.palette,
          radii: tokens.radii,
          focus: tokens.focus,
          sizes: tokens.sizes,
          table: tokens.table,
        ),
      );
      group('${theme.name} ${dark ? 'Dark' : 'Light'}', () {
        for (final MapEntry(key: name, value: build) in _exhibits.entries) {
          for (final (guideline, label) in _guidelines) {
            testWidgets('$name: $label', (tester) async {
              final handle = tester.ensureSemantics();
              tester.view.physicalSize = const Size(1000, 700);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                MaterialApp(
                  theme: data,
                  home: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: build(),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              await expectLater(tester, meetsGuideline(guideline));
              handle.dispose();
            });
          }
        }
      });
    }
  }
}
