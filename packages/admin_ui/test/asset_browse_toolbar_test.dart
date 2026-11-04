import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/media_tile.dart';
import 'package:admin_ui/src/assets/ui/provider_browser.dart';
import 'package:admin_ui/src/common/ui/search_field.dart';
import 'package:admin_ui/src/common/ui/segmented.dart';
import 'package:admin_ui/src/common/ui/tappable.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _assets = [
  Asset(id: 'a', name: 'hero.jpg', width: 1200, height: 800),
  Asset(id: 'b', name: 'logo.png', width: 512, height: 512),
];

const _items = [
  ProviderItem(id: 'p1', title: 'harbour', width: 800, height: 600),
];

Widget _host(AdminTokens tokens, Widget child, {double width = 820}) =>
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: 600, child: child),
        ),
      ),
    );

Finder _is<T>() => find.byWidgetPredicate((w) => w is T);

/// The outline [SearchField] draws at rest.
Color _searchOutline(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find.descendant(
      of: find.byType(SearchField),
      matching: find.byType(TextField),
    ),
  );
  final border = field.decoration!.border!;
  final rest = border is WidgetStateInputBorder
      ? border.resolve(const {})
      : border;
  return rest.borderSide.color;
}

/// The outline each [FilterMenuButton] draws.
List<Color> _filterOutlines(WidgetTester tester) => [
  for (final element in _is<FilterMenuButton>().evaluate())
    tester
        .widgetList<Container>(
          find.descendant(
            of: find.byElementPredicate((e) => e == element),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border)
        .whereType<Border>()
        .first
        .top
        .color,
];

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      final mode = dark ? 'Dark' : 'Light';
      final source = dark ? theme.dark! : theme.tokens;
      final tokens = AdminTokens.from(
        palette: source.palette,
        radii: source.radii,
        focus: source.focus,
        sizes: source.sizes,
      );
      final height = tokens.sizes.medium;

      testWidgets(
        '${theme.name} $mode: the library toolbar is one row, $height tall',
        (tester) async {
          await tester.pumpWidget(
            _host(
              tokens,
              AssetLibrary(
                assets: _assets,
                onFilterChanged: (_) {},
                onViewChanged: (_) {},
              ),
            ),
          );
          final search = tester.getRect(find.byType(SearchField));
          final filter = tester.getRect(_is<FilterMenuButton>());
          final views = tester.getRect(_is<Segmented>());
          for (final rect in [search, filter, views]) {
            expect(rect.height, height);
            expect(rect.top, search.top);
          }
          expect(filter.left, greaterThan(search.right));
          expect(views.left, greaterThan(filter.right));
        },
      );

      testWidgets(
        '${theme.name} $mode: the provider toolbar is one row, $height tall',
        (tester) async {
          await tester.pumpWidget(
            _host(
              tokens,
              ProviderBrowser(
                providerLabel: 'Stock',
                items: _items,
                onFiltersChanged: (_) {},
              ),
            ),
          );
          final search = tester.getRect(find.byType(SearchField));
          final filters = tester
              .widgetList(_is<FilterMenuButton>())
              .map((w) => tester.getRect(find.byWidget(w)))
              .toList();
          expect(filters, hasLength(2));
          for (final rect in [search, ...filters]) {
            expect(rect.height, height);
            expect(rect.top, search.top);
          }
        },
      );

      testWidgets(
        '${theme.name} $mode: the type filter outlines like the search box',
        (tester) async {
          await tester.pumpWidget(
            _host(
              tokens,
              AssetLibrary(
                assets: _assets,
                onFilterChanged: (_) {},
                onViewChanged: (_) {},
              ),
            ),
          );
          final search = _searchOutline(tester);
          expect(search, tokens.palette.controlBorder);
          expect(_filterOutlines(tester), [search]);
        },
      );

      testWidgets(
        '${theme.name} $mode: the provider filters outline like the search '
        'box',
        (tester) async {
          await tester.pumpWidget(
            _host(
              tokens,
              ProviderBrowser(
                providerLabel: 'Stock',
                items: _items,
                onFiltersChanged: (_) {},
              ),
            ),
          );
          final search = _searchOutline(tester);
          expect(_filterOutlines(tester), [search, search]);
        },
      );
    }
  }

  testWidgets('below 480px the search takes a row of its own', (tester) async {
    await tester.pumpWidget(
      _host(
        defaultTokens,
        AssetLibrary(
          assets: _assets,
          onFilterChanged: (_) {},
          onViewChanged: (_) {},
        ),
        width: 400,
      ),
    );
    final library = tester.getRect(find.byType(AssetLibrary));
    final search = tester.getRect(find.byType(SearchField));
    final filter = tester.getRect(_is<FilterMenuButton>());
    final views = tester.getRect(_is<Segmented>());
    // Full width, inside the toolbar's padding on both sides.
    expect(search.left - library.left, library.right - search.right);
    expect(filter.top, greaterThanOrEqualTo(search.bottom + 8));
    expect(views.top, filter.top);
    expect(filter.left, search.left);
    expect(views.right, search.right);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow provider toolbar wraps its filters under the search', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        defaultTokens,
        ProviderBrowser(
          providerLabel: 'Stock',
          items: _items,
          onFiltersChanged: (_) {},
        ),
        width: 400,
      ),
    );
    final search = tester.getRect(find.byType(SearchField));
    for (final filter in tester.widgetList(_is<FilterMenuButton>())) {
      final rect = tester.getRect(find.byWidget(filter));
      expect(rect.top, greaterThanOrEqualTo(search.bottom + 8));
      expect(rect.right, lessThanOrEqualTo(search.right));
    }
    expect(tester.takeException(), isNull);
  });

  group('icon-only segments', () {
    Future<void> expectCentred(WidgetTester tester, IconData icon) async {
      final glyph = tester.getCenter(find.byIcon(icon));
      final segment = tester.getCenter(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(Tappable)),
      );
      expect((glyph.dx - segment.dx).abs(), lessThanOrEqualTo(0.5));
      expect((glyph.dy - segment.dy).abs(), lessThanOrEqualTo(0.5));
    }

    testWidgets('the view toggle centres its glyphs', (tester) async {
      await tester.pumpWidget(
        _host(
          defaultTokens,
          AssetLibrary(assets: _assets, onViewChanged: (_) {}),
        ),
      );
      await expectCentred(tester, Icons.grid_view_rounded);
      await expectCentred(tester, Icons.view_list_rounded);
    });

    testWidgets('an empty label makes a segment icon-only, with no gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          defaultTokens,
          Segmented<int>(
            value: 0,
            onChanged: (_) {},
            segments: const [
              SegmentOption(0, '', icon: Icons.grid_view_rounded),
              SegmentOption(1, 'Rows', icon: Icons.view_list_rounded),
            ],
          ),
        ),
      );
      final segment = find.ancestor(
        of: find.byIcon(Icons.grid_view_rounded),
        matching: find.byType(Tappable),
      );
      expect(
        find.descendant(of: segment, matching: find.byType(Text)),
        findsNothing,
      );
      final size = tester.getSize(segment);
      expect(size.width, size.height, reason: 'square, like showLabel: false');
      await expectCentred(tester, Icons.grid_view_rounded);
    });
  });
}
