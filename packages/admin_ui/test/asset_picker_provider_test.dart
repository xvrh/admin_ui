import 'package:admin_ui/src/assets/asset_source.dart';
import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/asset_picker.dart';
import 'package:admin_ui/src/assets/ui/provider_browser.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/common/ui/modal_anchor.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeSource implements AssetSource {
  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => const AssetBrowseResult([
    Asset(id: '1', name: 'local.jpg', width: 800, height: 600),
  ], 1);

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

class _FakeProvider implements ExternalAssetProvider {
  @override
  String get id => 'fake';
  @override
  String get label => 'Stockly';
  @override
  IconData get icon => Icons.collections_outlined;
  @override
  bool get choosesSize => false;

  @override
  Future<ProviderSearchResult> search({
    String? query,
    int page = 1,
    ProviderFilters filters = const ProviderFilters(),
  }) async => const ProviderSearchResult(
    items: [ProviderItem(id: 'sk1', title: 'from stockly')],
    total: 1,
  );

  @override
  Future<List<ProviderSize>> sizesFor(ProviderItem item) async => const [];

  @override
  Future<String> import(ProviderItem item, {ProviderSize? size}) async =>
      'stock-777';
}

/// Opens the picker from a button; [onResult] gets what it closes with.
Widget _opener({
  required void Function(String? result) onResult,
  List<ExternalAssetProvider> providers = const [],
}) => MaterialApp(
  home: Scaffold(
    body: ModalAnchor(
      child: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async => onResult(
              await showAssetPicker(
                context,
                source: _FakeSource(),
                providers: providers,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('picker shows a tab per provider and imports through it', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalAnchor(
            child: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showAssetPicker(
                      context,
                      source: _FakeSource(),
                      providers: [_FakeProvider()],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // One flat strip: Library | Upload | provider.
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Stockly'), findsWidgets);
    expect(find.text('local.jpg'), findsOneWidget);

    // Switch to the provider tab; its search runs.
    await tester.tap(find.text('Stockly').first);
    await tester.pumpAndSettle();
    expect(find.text('from stockly'), findsOneWidget);

    // Select → license → import → dialog pops the new local id.
    await tester.tap(find.text('from stockly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('License & add'));
    await tester.pumpAndSettle();

    expect(result, 'stock-777');
  });

  testWidgets('no providers ⇒ just Library and Upload tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalAnchor(
            child: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showAssetPicker(context, source: _FakeSource()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('local.jpg'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Stockly'), findsNothing);
  });

  testWidgets('Enter on a provider tile already picked confirms the pick', (
    tester,
  ) async {
    var closed = false;
    String? result;
    await tester.pumpWidget(
      _opener(
        providers: [_FakeProvider()],
        onResult: (r) {
          closed = true;
          result = r;
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stockly').first);
    await tester.pumpAndSettle();

    // Click picks the tile; the keyboard then lands on it and confirms.
    await tester.tap(find.text('from stockly'));
    await tester.pump();
    FocusManager.instance.rootScope.descendants
        .firstWhere(
          (n) =>
              n.debugLabel == 'Media item 0' &&
              n.context?.findAncestorWidgetOfExactType<ProviderBrowser>() !=
                  null,
        )
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // The license sheet opens for that item, rather than the pick clearing.
    expect(find.text('License & add'), findsOneWidget);
    await tester.tap(find.text('License & add'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, 'stock-777');
  });

  testWidgets('the picker is a dialog named by its title', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_opener(onResult: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose media'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Choose media')),
      isSemantics(isHeader: true),
    );
    // The surface's own node: a dialog, a route of its own, named by the
    // title. Read off the widget and its render object: the anchor's
    // barrier keeps the whole overlay out of the test's semantics tree.
    final route = find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.namesRoute ?? false),
    );
    expect(route, findsOne);
    final properties = tester.widget<Semantics>(route).properties;
    expect(properties.label, 'Choose media');
    expect(properties.scopesRoute, isTrue);
    expect(properties.role, SemanticsRole.dialog);
    expect(
      tester.getSemantics(route),
      isSemantics(label: 'Choose media', scopesRoute: true, namesRoute: true),
    );
    semantics.dispose();
  });

  for (final tab in ['Library', 'Upload', 'Stockly']) {
    testWidgets('its close button, reached on the $tab tab, closes it with '
        'nothing picked', (tester) async {
      var closed = false;
      String? result = 'unset';
      await tester.pumpWidget(
        _opener(
          providers: [_FakeProvider()],
          onResult: (r) {
            closed = true;
            result = r;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result, isNull);
      expect(find.text('Choose media'), findsNothing);
    });
  }

  testWidgets('Escape still closes it once a tab switch hid the focused '
      'pane', (tester) async {
    var closed = false;
    await tester.pumpWidget(_opener(onResult: (_) => closed = true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
}
