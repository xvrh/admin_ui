// AssetLibrary.connected: the library over an AssetLibraryController. The
// toolbar sets the controller's search, type filter and view; the app's own
// filters sit beside the type filter and wrap on a phone; a failed next page
// keeps the grid and is said once in a toast.

import 'dart:typed_data';

import 'package:admin_ui/src/assets/asset_library_controller.dart';
import 'package:admin_ui/src/assets/asset_source.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/media_tile.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/toast.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Source implements AssetSource {
  final int count;
  bool failFirst = false;
  bool failMore = false;
  final calls = <({int index, String? query, AssetType? filter, int where})>[];

  _Source(this.count);

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async {
    calls.add((
      index: index,
      query: query,
      filter: filter,
      where: where.length,
    ));
    // Every page takes a while, as over a network, so the library shows
    // it loading.
    await Future<void>.delayed(Duration(milliseconds: index == 0 ? 20 : 50));
    if (index == 0 && failFirst) throw StateError('offline');
    if (index > 0 && failMore) throw StateError('timed out');
    final all = [
      for (var i = 0; i < count; i++)
        Asset(id: '$i', name: 'photo_$i.jpg', width: 800, height: 600),
    ];
    return AssetBrowseResult(all.skip(index).take(size).toList(), count);
  }

  @override
  Future<Asset?> resolve(String id) async => null;

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

Widget _usage({String label = 'All assets'}) => FilterMenuButton<int>(
  key: const ValueKey('usage'),
  value: 0,
  tooltip: 'Usage',
  onChanged: (_) {},
  options: [FilterMenuOption(0, label), const FilterMenuOption(1, 'Unused')],
);

Future<void> _pump(
  WidgetTester tester,
  Widget library, {
  Size size = const Size(900, 700),
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      builder: (context, navigator) => ToastScope(child: navigator!),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: library),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the toolbar sets the search, the type and the view', (
    tester,
  ) async {
    final source = _Source(3);
    final library = AssetLibraryController(source: source);
    addTearDown(library.dispose);
    await _pump(tester, AssetLibrary.connected(controller: library));
    expect(find.text('photo_2.jpg'), findsOneWidget);
    expect(find.text('3 assets'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'photo_1');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(library.query, 'photo_1');
    expect(source.calls.last.query, 'photo_1');

    await tester.tap(find.bySemanticsLabel(RegExp('^Filter by type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents').last);
    await tester.pumpAndSettle();
    expect(library.filter, AssetType.document);
    expect(source.calls.last.filter, AssetType.document);

    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();
    expect(library.view, AssetView.list);
    expect(find.byType(MediaListTile), findsNWidgets(3));
  });

  testWidgets('a failed first page offers Retry, which loads it again', (
    tester,
  ) async {
    final source = _Source(2)..failFirst = true;
    final library = AssetLibraryController(source: source);
    addTearDown(library.dispose);
    await _pump(tester, AssetLibrary.connected(controller: library));
    expect(find.text('Couldn’t load assets'), findsOneWidget);

    source.failFirst = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('photo_1.jpg'), findsOneWidget);
    expect(source.calls, hasLength(2));
  });

  testWidgets('a failed next page keeps the grid, is said once, and waits '
      'for Load more', (tester) async {
    final source = _Source(60)..failMore = true;
    final library = AssetLibraryController(source: source);
    addTearDown(library.dispose);
    await _pump(
      tester,
      AssetLibrary.connected(controller: library),
      size: const Size(900, 2000),
    );
    // The grid is short of the window, so it asked for the next page itself,
    // and once only: the failure is not retried behind the person's back.
    expect(source.calls.map((c) => c.index), [0, 24]);
    expect(find.textContaining('Couldn’t load more.'), findsOneWidget);
    expect(find.text('24 of 60 assets'), findsOneWidget);
    expect(find.byType(MediaTile), findsNWidgets(24));

    // A rebuild says nothing new.
    library.view = AssetView.list;
    library.view = AssetView.grid;
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(find.textContaining('Couldn’t load more.'), findsNothing);
    expect(source.calls, hasLength(2));

    // Load more tries again; the grid then pages on by itself.
    source.failMore = false;
    await tester.tap(find.widgetWithText(Button, 'Load more'));
    await tester.pumpAndSettle();
    expect(source.calls.map((c) => c.index), [0, 24, 24, 48]);
    expect(find.text('60 assets'), findsOneWidget);
  });

  testWidgets('a new search pages from its own first page', (tester) async {
    final source = _Source(60);
    final library = AssetLibraryController(source: source);
    addTearDown(library.dispose);
    // Two columns: the first page runs well past the window.
    await _pump(
      tester,
      AssetLibrary.connected(controller: library),
      size: const Size(500, 700),
    );
    final grid = tester.state<ScrollableState>(find.byType(Scrollable).last);
    grid.position.jumpTo(grid.position.maxScrollExtent);
    await tester.pump();
    expect(source.calls.map((c) => c.index), [0, 24]);
    // A search while that page is on its way drops it. Its own first page
    // lands with the grid still at the end, so its next page follows by
    // itself.
    library.query = 'photo';
    await tester.pump();
    await tester.pumpAndSettle();
    expect(source.calls.map((c) => c.index), [0, 24, 0, 24]);
    expect(source.calls.last.query, 'photo');
    expect(library.assets, hasLength(48));
  });

  group('toolbar actions', () {
    testWidgets('sit after the type filter, before the view toggle', (
      tester,
    ) async {
      final library = AssetLibraryController(source: _Source(3));
      addTearDown(library.dispose);
      for (final direction in TextDirection.values) {
        await _pump(
          tester,
          AssetLibrary.connected(
            controller: library,
            toolbarActions: [_usage()],
          ),
          direction: direction,
        );
        final type = tester.getRect(
          find.bySemanticsLabel(RegExp('^Filter by type')),
        );
        final usage = tester.getRect(find.byKey(const ValueKey('usage')));
        final views = tester.getRect(find.byIcon(Icons.grid_view_rounded));
        expect(usage.center.dy, moreOrLessEquals(type.center.dy));
        if (direction == TextDirection.ltr) {
          expect(usage.left - type.right, 12);
          expect(views.left, greaterThan(usage.right));
        } else {
          expect(type.left - usage.right, 12);
          expect(views.right, lessThan(usage.left));
        }
      }
    });

    testWidgets('share a row with the type filter on a phone while they fit', (
      tester,
    ) async {
      final library = AssetLibraryController(source: _Source(3));
      addTearDown(library.dispose);
      await _pump(
        tester,
        AssetLibrary.connected(
          controller: library,
          toolbarActions: [_usage(label: 'Any')],
        ),
        size: const Size(470, 700),
      );
      final type = tester.getRect(
        find.bySemanticsLabel(RegExp('^Filter by type')),
      );
      final usage = tester.getRect(find.byKey(const ValueKey('usage')));
      expect(usage.top, type.top);
      expect(usage.left - type.right, 8);
    });

    testWidgets('wrap under it when they do not', (tester) async {
      final library = AssetLibraryController(source: _Source(3));
      addTearDown(library.dispose);
      await _pump(
        tester,
        AssetLibrary.connected(
          controller: library,
          toolbarActions: [_usage(label: 'Not used by any product')],
        ),
        size: const Size(360, 700),
      );
      expect(tester.takeException(), isNull);
      final type = tester.getRect(
        find.bySemanticsLabel(RegExp('^Filter by type')),
      );
      final usage = tester.getRect(find.byKey(const ValueKey('usage')));
      expect(usage.top - type.bottom, 8);
      expect(usage.left, type.left);
    });
  });

  testWidgets('a new controller is followed', (tester) async {
    final first = AssetLibraryController(source: _Source(1));
    final second = AssetLibraryController(source: _Source(2));
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await _pump(tester, AssetLibrary.connected(controller: first));
    expect(find.text('1 asset'), findsOneWidget);
    await _pump(tester, AssetLibrary.connected(controller: second));
    expect(find.text('2 assets'), findsOneWidget);
    first.view = AssetView.list;
    await tester.pump();
    expect(find.byType(MediaListTile), findsNothing);
  });
}
