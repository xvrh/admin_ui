import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _assets = [
  Asset(id: 'a', name: 'hero.jpg', width: 1200, height: 800, usageCount: 2),
  Asset(id: 'b', name: 'logo.png', width: 512, height: 512, usageCount: 0),
  Asset(
    id: 'c',
    name: 'spec.pdf',
    type: AssetType.document,
    bytes: 200 * 1024,
    usageCount: 1,
  ),
];

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 820, height: 620, child: child)),
  ),
);

void main() {
  testWidgets('grid renders a tile per asset', (tester) async {
    await tester.pumpWidget(_host(const AssetLibrary(assets: _assets)));
    expect(find.text('hero.jpg'), findsOneWidget);
    expect(find.text('logo.png'), findsOneWidget);
    expect(find.text('spec.pdf'), findsOneWidget);
  });

  testWidgets('loading shows the panel, not the grid', (tester) async {
    await tester.pumpWidget(
      _host(const AssetLibrary(assets: [], loading: true)),
    );
    expect(find.text('Loading assets…'), findsOneWidget);
  });

  testWidgets('empty state distinguishes no-assets from no-matches', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const AssetLibrary(assets: [])));
    expect(find.text('No assets yet'), findsOneWidget);

    await tester.pumpWidget(
      _host(const AssetLibrary(assets: [], query: 'zzz')),
    );
    expect(find.text('No matching assets'), findsOneWidget);
  });

  testWidgets('error state offers retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(
        AssetLibrary(assets: const [], error: 'boom', onRetry: () => retried++),
      ),
    );
    expect(find.text('Couldn’t load assets'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('browse-mode tap opens, never toggles', (tester) async {
    Asset? opened;
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          view: AssetView.list,
          onOpen: (a) => opened = a,
        ),
      ),
    );
    await tester.tap(find.text('logo.png'));
    expect(opened?.id, 'b');
  });

  testWidgets('picker-mode tap toggles selection', (tester) async {
    final toggled = <String>[];
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          view: AssetView.list,
          selectionMode: AssetSelectionMode.multiple,
          onToggle: toggled.add,
        ),
      ),
    );
    await tester.tap(find.text('hero.jpg'));
    await tester.tap(find.text('spec.pdf'));
    expect(toggled, ['a', 'c']);
  });

  testWidgets('selection bar reflects count and gates confirm', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          selectionMode: AssetSelectionMode.multiple,
          selected: const {'a', 'b'},
          confirmLabel: 'Insert',
          onConfirm: () => confirmed++,
        ),
      ),
    );
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Insert'));
    expect(confirmed, 1);
  });

  testWidgets('confirm is disabled with an empty selection', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          selectionMode: AssetSelectionMode.multiple,
          selected: const {},
          onConfirm: () => confirmed++,
        ),
      ),
    );
    expect(find.text('Nothing selected'), findsOneWidget);
    await tester.tap(find.text('Select'));
    expect(confirmed, 0);
  });

  testWidgets('upload tab appears when an upload body is supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AssetLibrary(assets: _assets, uploadTab: Text('UPLOAD-PANE')),
      ),
    );
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    expect(find.text('UPLOAD-PANE'), findsOneWidget);
  });

  testWidgets('the search reports once typing pauses', (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets, onQueryChanged: queries.add)),
    );
    final field = find.byType(TextField);
    await tester.enterText(field, 's');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field, 'su');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field, 'sun');
    expect(queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    expect(queries, ['sun']);

    await tester.enterText(field, '');
    expect(queries, ['sun', ''], reason: 'clearing reports at once');
  });

  testWidgets('a zero debounce reports every keystroke', (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          onQueryChanged: queries.add,
          searchDebounce: Duration.zero,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 's');
    await tester.enterText(find.byType(TextField), 'su');
    expect(queries, ['s', 'su']);
  });

  testWidgets('errorText words the error', (tester) async {
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: const [],
          error: StateError('socket closed'),
          errorText: (e) => 'Storage is offline.',
        ),
      ),
    );
    expect(find.text('Storage is offline.'), findsOneWidget);
    expect(find.textContaining('StateError'), findsNothing);
  });

  testWidgets('the type filter picks from a menu', (tester) async {
    final picked = <AssetType?>[];
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets, onFilterChanged: picked.add)),
    );
    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();
    expect(picked, [AssetType.image]);

    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets,
          filter: AssetType.image,
          onFilterChanged: picked.add,
        ),
      ),
    );
    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    expect(picked, [AssetType.image, null]);
  });
}
