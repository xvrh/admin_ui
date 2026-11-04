import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/provider_browser.dart';
import 'package:admin_ui/src/common/ui/error_text.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _assets = [
  Asset(id: 'a', name: 'hero.jpg', width: 2400, height: 1350),
  Asset(id: 'b', name: 'logo.png', width: 512, height: 512),
  Asset(id: 'c', name: 'spec.pdf', type: AssetType.document, bytes: 200 * 1024),
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

void main() {
  testWidgets('the grid is a named group of selectable buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          selectionMode: AssetSelectionMode.multiple,
          selected: const {'b'},
          onToggle: (_) {},
          onConfirm: () {},
          total: 40,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Assets'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('hero.jpg, 2400 × 1350')),
      isSemantics(
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('spec.pdf, 205 kB')),
      isSemantics(isButton: true, hasSelectedState: true),
    );
    expect(
      tester.getSemantics(find.text('1 selected')),
      isSemantics(isLiveRegion: true),
    );
    expect(
      tester.getSemantics(find.text('3 of 40 assets')),
      isSemantics(isLiveRegion: true),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('a browse-mode tile announces no selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets, onOpen: (_) {})),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('hero.jpg, 2400 × 1350')),
      isSemantics(isButton: true, hasSelectedState: false),
    );
    handle.dispose();
  });

  testWidgets('the type filter names its choice and opens a menu', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    AssetType? picked;
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          onFilterChanged: (t) => picked = t,
          onViewChanged: (_) {},
        ),
      ),
    );
    final trigger = find.bySemanticsLabel('Filter by type: All types');
    expect(
      tester.getSemantics(trigger),
      isSemantics(
        isButton: true,
        isFocusable: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );
    expect(find.bySemanticsLabel('View'), findsOneWidget);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(trigger),
      isSemantics(hasExpandedState: true, isExpanded: true),
    );
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(picked, AssetType.document);
    handle.dispose();
  });

  testWidgets('the provider filters are named for what they filter', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    ProviderFilters? filters;
    await tester.pumpWidget(
      _host(
        ProviderBrowser(
          providerLabel: 'Stock',
          items: const [ProviderItem(id: 'p', title: 'harbour')],
          selectedId: 'p',
          onFiltersChanged: (f) => filters = f,
          onConfirm: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Stock results'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Orientation: Any orientation'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Image type: Any type'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^harbour'))),
      isSemantics(isSelected: true, hasSelectedState: true),
    );

    await tester.tap(find.bySemanticsLabel('Image type: Any type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vectors'));
    await tester.pumpAndSettle();
    expect(filters?.imageType, ProviderImageType.vector);
    handle.dispose();
  });

  testWidgets('a load error reads as words, not an exception', (tester) async {
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: const [],
          error: Exception('SocketException: Failed host lookup'),
        ),
      ),
    );
    expect(find.textContaining('Exception'), findsNothing);
    expect(
      find.text('Can’t reach the server. Check your connection and try again.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: const [],
          error: Exception('boom'),
          errorText: (e) => 'The library is offline.',
        ),
      ),
    );
    expect(find.text('The library is offline.'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        ErrorTextScope(
          describe: (e) => 'Stock search is down.',
          child: ProviderBrowser(
            providerLabel: 'Stock',
            items: const [],
            error: Exception('HTTP 503'),
          ),
        ),
      ),
    );
    expect(find.text('Stock search is down.'), findsOneWidget);
  });
}
