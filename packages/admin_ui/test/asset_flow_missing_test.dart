import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A library of [assets]; an id it lacks resolves to null, one in [failing]
/// throws.
class _Source implements AssetSource {
  final Map<String, Asset> assets;
  final Set<String> failing;
  final resolved = <String>[];

  _Source(this.assets, {Set<String>? failing}) : failing = failing ?? {};

  @override
  Future<Asset?> resolve(String id) async {
    resolved.add(id);
    if (failing.contains(id)) throw Exception('SocketException: offline');
    return assets[id];
  }

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult(assets.values.toList(), assets.length);

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

const _hero = Asset(id: 'hero-1', name: 'hero.jpg', swatch: Color(0xFF0F9D8F));
const _other = Asset(
  id: 'other-2',
  name: 'other.jpg',
  swatch: Color(0xFFD24B3E),
);

Widget _host(AssetSource source, Widget child) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
  home: Scaffold(
    body: AssetSourceScope(
      source: source,
      child: ModalAnchor(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    ),
  ),
);

/// The accessible names of the tappable tiles and buttons.
Iterable<String> _labels(WidgetTester tester) => tester
    .widgetList<Tappable>(find.byType(Tappable))
    .map((t) => t.semanticLabel)
    .nonNulls;

void main() {
  late LocalScope scope;
  setUp(() => scope = LocalScope());
  tearDown(() => scope.dispose());

  group('AssetRefField', () {
    testWidgets('an id the source no longer has reads "Asset not found", '
        'never a spinner', (tester) async {
      final cell = scope.assetRef('hero')..assetId.set('deleted-9');
      await tester.pumpWidget(
        _host(_Source({}), AssetRefField(cell, label: 'Hero image')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Asset not found'), findsOneWidget);
      expect(find.text('Loading…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a missing asset is replaced by a tap and cleared by ×', (
      tester,
    ) async {
      final cell = scope.assetRef('hero')..assetId.set('deleted-9');
      cell.crop.set(const CropValue(rect: Rect.fromLTWH(0, 0, 0.5, 0.5)));
      await tester.pumpWidget(
        _host(_Source({'hero-1': _hero}), AssetRefField(cell, label: 'Hero')),
      );
      await tester.pumpAndSettle();

      // Tapping the tile opens the picker to pick its replacement.
      await tester.tap(find.bySemanticsLabel('Asset not found'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('hero.jpg'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Button, 'Select'));
      await tester.pumpAndSettle();
      expect(cell.assetId.value, 'hero-1');
      expect(
        cell.crop.value,
        isNull,
        reason: 'a crop belongs to the old image',
      );
      expect(_labels(tester), contains('hero.jpg'));

      cell.assetId.set('deleted-9');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Remove Asset not found'));
      await tester.pumpAndSettle();
      expect(cell.assetId.value, isNull);
    });

    testWidgets('a resolve that throws offers a retry, which resolves again', (
      tester,
    ) async {
      final source = _Source({'hero-1': _hero}, failing: {'hero-1'});
      final cell = scope.assetRef('hero')..assetId.set('hero-1');
      await tester.pumpWidget(
        _host(source, AssetRefField(cell, label: 'Hero image')),
      );
      await tester.pumpAndSettle();

      expect(_labels(tester), contains('Retry Asset preview'));
      expect(find.text('Loading…'), findsNothing);
      expect(source.resolved, ['hero-1']);

      source.failing.clear();
      await tester.tap(find.bySemanticsLabel('Retry Asset preview'));
      await tester.pumpAndSettle();
      expect(source.resolved, ['hero-1', 'hero-1']);
      expect(_labels(tester), contains('hero.jpg'));
    });

    testWidgets('a collaborator re-pointing the cell resolves the new id', (
      tester,
    ) async {
      final source = _Source({'hero-1': _hero, 'other-2': _other});
      final cell = scope.assetRef('hero')..assetId.set('hero-1');
      await tester.pumpWidget(
        _host(source, AssetRefField(cell, label: 'Hero image')),
      );
      await tester.pumpAndSettle();
      cell.assetId.set('other-2');
      await tester.pumpAndSettle();
      expect(_labels(tester), contains('other.jpg'));
    });
  });

  group('AssetListField', () {
    testWidgets('one missing item among found ones keeps its place', (
      tester,
    ) async {
      final list = scope.recordList<RecordScope>('gallery', build: (r) => r);
      for (final id in ['hero-1', 'gone', 'other-2']) {
        list.add();
        list.elements.last.assetRef('image').assetId.set(id);
      }
      await tester.pumpWidget(
        _host(
          _Source({'hero-1': _hero, 'other-2': _other}),
          AssetListField<RecordScope>(
            list,
            label: 'Gallery',
            image: (r) => r.assetRef('image'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final labels = _labels(tester).toList();
      final found = [
        for (final l in labels)
          if (const {'hero.jpg', 'Asset not found', 'other.jpg'}.contains(l)) l,
      ];
      expect(found, ['hero.jpg', 'Asset not found', 'other.jpg']);
    });
  });

  group('asset editor', () {
    testWidgets('a missing asset says so in the preview, with no crop', (
      tester,
    ) async {
      final cell = scope.assetRef('hero')..assetId.set('deleted-9');
      await tester.pumpWidget(
        _host(
          _Source({}),
          LangScope(
            locales: const [
              LocaleInfo(
                code: 'en',
                native: 'English',
                status: LocaleStatus.source,
              ),
            ],
            visibleLocales: const {'en'},
            sourceLocale: 'en',
            activeLocale: 'en',
            onVisibleLocalesChanged: (_) {},
            child: ModalAnchor(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showAssetEditor(context, cell, label: 'Hero'),
                  child: const Text('edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('edit'));
      await tester.pumpAndSettle();
      expect(find.text('Asset not found'), findsOneWidget);
      final crop = tester.widget<Button>(
        find.widgetWithText(Button, 'Edit crop'),
      );
      expect(crop.onPressed, isNull);
    });
  });
}
