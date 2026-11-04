import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A library of [count] images with UUID-style ids, paged like a server:
/// every browse is recorded.
class _Library implements AssetSource {
  final int count;
  final calls = <({int index, int size, String? query})>[];

  _Library(this.count);

  late final _assets = [
    for (var i = 0; i < count; i++)
      Asset(
        id: 'a1f3-${i.toString().padLeft(4, '0')}',
        name: i == 0 ? 'sunset.jpg' : 'photo_$i.jpg',
        swatch: const Color(0xFF6D5BD0),
      ),
  ];

  @override
  Future<Asset?> resolve(String id) async =>
      _assets.where((a) => a.id == id).firstOrNull;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async {
    calls.add((index: index, size: size, query: query));
    final q = (query ?? '').toLowerCase();
    final hits = [
      for (final a in _assets)
        if (a.name.contains(q)) a,
    ];
    return AssetBrowseResult(hits.skip(index).take(size).toList(), hits.length);
  }

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

/// A stock provider of [total] results, 20 a page.
class _Stock implements ExternalAssetProvider {
  final int total;
  final pages = <int>[];
  _Stock(this.total);

  @override
  String get id => 'stock';
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
  }) async {
    pages.add(page);
    final from = (page - 1) * 20;
    return ProviderSearchResult(
      items: [
        for (var i = from; i < total && i < from + 20; i++)
          ProviderItem(id: 'sk$i', title: 'stock $i'),
      ],
      total: total,
      page: page,
    );
  }

  @override
  Future<List<ProviderSize>> sizesFor(ProviderItem item) async => const [];

  @override
  Future<String> import(ProviderItem item, {ProviderSize? size}) async =>
      'imported-${item.id}';
}

Future<String? Function()> _open(
  WidgetTester tester,
  AssetSource source, {
  List<ExternalAssetProvider> providers = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  String? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
      builder: (context, navigator) => ToastScope(child: navigator!),
      home: Scaffold(
        body: ModalAnchor(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showAssetPicker(
                context,
                source: source,
                providers: providers,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  testWidgets('typing "sunset" asks the library once', (tester) async {
    final library = _Library(3);
    await _open(tester, library);
    expect(library.calls, hasLength(1));

    final search = find.byType(TextField).first;
    for (var n = 1; n <= 'sunset'.length; n++) {
      await tester.enterText(search, 'sunset'.substring(0, n));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(library.calls.skip(1).map((c) => c.query), ['sunset']);
    expect(find.text('sunset.jpg'), findsOneWidget);
  });

  testWidgets('the next page starts where the first ended', (tester) async {
    final library = _Library(60);
    await _open(tester, library);
    expect(library.calls.single, (index: 0, size: 24, query: ''));

    final more = find.widgetWithText(Button, 'Load more');
    if (more.evaluate().isNotEmpty) await tester.tap(more);
    await tester.pumpAndSettle();

    expect(library.calls[1].index, 24);
    expect(library.calls[1].size, 24);
  });

  testWidgets('confirming a pick returns its string id', (tester) async {
    final library = _Library(3);
    final result = await _open(tester, library);

    await tester.tap(find.text('photo_2.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Button, 'Select'));
    await tester.pumpAndSettle();

    expect(result(), 'a1f3-0002');
  });

  testWidgets('a provider tab pages through its results', (tester) async {
    final stock = _Stock(50);
    final result = await _open(tester, _Library(1), providers: [stock]);
    await tester.tap(find.text('Stockly').first);
    await tester.pumpAndSettle();
    expect(stock.pages.first, 1);

    final more = find.widgetWithText(Button, 'Load more');
    if (more.evaluate().isNotEmpty) await tester.tap(more);
    await tester.pumpAndSettle();
    expect(stock.pages, containsAllInOrder([1, 2]));

    await tester.tap(find.text('stock 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('License & add'));
    await tester.pumpAndSettle();
    expect(result(), 'imported-sk0');
  });
}
