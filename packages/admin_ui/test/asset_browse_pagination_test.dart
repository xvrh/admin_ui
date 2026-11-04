import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/provider_browser.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

List<Asset> _assets(int count) => [
  for (var i = 0; i < count; i++)
    Asset(id: 'a$i', name: 'asset_$i.jpg', width: 800, height: 600),
];

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 820, height: 600, child: child),
    ),
  ),
);

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).last).position;

void main() {
  testWidgets('scrolling near the end loads the next page, once', (
    tester,
  ) async {
    var loads = 0;
    Widget library({bool loadingMore = false, int count = 60}) => _host(
      AssetLibrary(
        assets: _assets(count),
        hasMore: true,
        loadingMore: loadingMore,
        onLoadMore: () => loads++,
      ),
    );
    await tester.pumpWidget(library());
    await tester.pump();
    expect(loads, 0, reason: 'the end is far off');

    final position = _position(tester);
    position.jumpTo(position.maxScrollExtent - 100);
    await tester.pump();
    expect(loads, 1);
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(loads, 1, reason: 'one call until the page lands');

    await tester.pumpWidget(library(loadingMore: true));
    position.jumpTo(position.maxScrollExtent - 1);
    await tester.pump();
    expect(loads, 1, reason: 'not while the page is loading');

    await tester.pumpWidget(library(count: 80));
    await tester.pump();
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(loads, 2, reason: 'the new end asks again');
  });

  testWidgets('a page too short to scroll asks for more by itself', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets(3),
          hasMore: true,
          onLoadMore: () => loads++,
        ),
      ),
    );
    await tester.pump();
    expect(loads, 1);
  });

  testWidgets('nothing more: no call, no button', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets(3), onLoadMore: () => loads++)),
    );
    await tester.pump();
    expect(loads, 0);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('the bar counts what is shown against the total', (tester) async {
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets(24), total: 120)),
    );
    expect(find.text('24 of 120 assets'), findsOneWidget);

    await tester.pumpWidget(_host(AssetLibrary(assets: _assets(1), total: 1)));
    expect(find.text('1 asset'), findsOneWidget);
  });

  testWidgets('Load more fetches; a spinner stands in while it lands', (
    tester,
  ) async {
    var loads = 0;
    Widget library({required bool loadingMore}) => _host(
      AssetLibrary(
        // Tall enough that scrolling alone would not ask yet.
        assets: _assets(60),
        total: 120,
        hasMore: true,
        loadingMore: loadingMore,
        onLoadMore: () => loads++,
      ),
    );
    await tester.pumpWidget(library(loadingMore: false));
    await tester.tap(find.text('Load more'));
    expect(loads, 1);

    await tester.pumpWidget(library(loadingMore: true));
    expect(find.text('Load more'), findsNothing);
    expect(find.text('Loading more…'), findsOneWidget);
  });

  testWidgets('the grid is lazy: far tiles are not built', (tester) async {
    await tester.pumpWidget(_host(AssetLibrary(assets: _assets(400))));
    expect(find.text('asset_0.jpg'), findsOneWidget);
    expect(find.text('asset_399.jpg'), findsNothing);
  });

  testWidgets('the provider browser pages the same way', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(
        ProviderBrowser(
          providerLabel: 'Stock',
          items: [
            for (var i = 0; i < 4; i++)
              ProviderItem(id: 'p$i', title: 'shot $i'),
          ],
          total: 900,
          hasMore: true,
          onLoadMore: () => loads++,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('4 of 900 results'), findsOneWidget);
    expect(loads, 1);
  });

  testWidgets('a new search keeps the grid under a progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets(3), loading: true)),
    );
    expect(find.text('asset_0.jpg'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Loading assets…'), findsNothing);
  });
}
