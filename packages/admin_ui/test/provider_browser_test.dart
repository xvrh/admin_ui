import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/provider_browser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _items = [
  ProviderItem(id: 'a', title: 'mountain', width: 4000, height: 2667),
  ProviderItem(id: 'b', title: 'skyline'),
  ProviderItem(id: 'c', title: 'desk'),
];

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 820, height: 620, child: child)),
  ),
);

void main() {
  testWidgets('renders a tile per item', (tester) async {
    await tester.pumpWidget(
      _host(const ProviderBrowser(providerLabel: 'Stockly', items: _items)),
    );
    expect(find.text('mountain'), findsOneWidget);
    expect(find.text('skyline'), findsOneWidget);
    expect(find.text('desk'), findsOneWidget);
  });

  testWidgets('loading shows the searching panel', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProviderBrowser(
          providerLabel: 'Stockly',
          items: [],
          loading: true,
        ),
      ),
    );
    expect(find.text('Searching…'), findsOneWidget);
  });

  testWidgets('empty distinguishes pre-search from no-matches', (tester) async {
    await tester.pumpWidget(
      _host(const ProviderBrowser(providerLabel: 'Stockly', items: [])),
    );
    expect(find.text('Find stock images'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const ProviderBrowser(
          providerLabel: 'Stockly',
          items: [],
          query: 'zzz',
        ),
      ),
    );
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('error offers retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(
        ProviderBrowser(
          providerLabel: 'Stockly',
          items: const [],
          error: 'boom',
          onRetry: () => retried++,
        ),
      ),
    );
    expect(find.text('Search failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('confirm is gated on a selection', (tester) async {
    var confirmed = 0;
    Widget build(String? selectedId) => _host(
      ProviderBrowser(
        providerLabel: 'Stockly',
        items: _items,
        selectedId: selectedId,
        onConfirm: () => confirmed++,
      ),
    );

    await tester.pumpWidget(build(null));
    await tester.tap(find.text('Use image'));
    expect(confirmed, 0); // disabled with nothing selected

    await tester.pumpWidget(build('a'));
    await tester.tap(find.text('Use image'));
    expect(confirmed, 1);
  });

  testWidgets('tapping a tile reports the selection', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        ProviderBrowser(
          providerLabel: 'Stockly',
          items: _items,
          onSelect: (it) => picked = it.id,
        ),
      ),
    );
    await tester.tap(find.text('mountain'));
    expect(picked, 'a');
  });

  testWidgets('the facet menus change the filters', (tester) async {
    final changes = <ProviderFilters>[];
    await tester.pumpWidget(
      _host(
        ProviderBrowser(
          providerLabel: 'Stockly',
          items: _items,
          onFiltersChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.text('Any orientation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Square'));
    await tester.pumpAndSettle();
    expect(changes.single.orientation, ProviderOrientation.square);
    expect(changes.single.imageType, isNull);
  });

  testWidgets('the footer says what licensing a pick does', (tester) async {
    await tester.pumpWidget(
      _host(const ProviderBrowser(providerLabel: 'Stockly', items: _items)),
    );
    expect(find.text('Select an image to license'), findsOneWidget);
    await tester.pumpWidget(
      _host(
        const ProviderBrowser(
          providerLabel: 'Stockly',
          items: _items,
          selectedId: 'b',
        ),
      ),
    );
    expect(
      find.text('Licensing adds it to your library and uses 1 download'),
      findsOneWidget,
    );
  });
}
