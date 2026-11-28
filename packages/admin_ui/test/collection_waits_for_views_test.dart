import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A collection made with `autoLoad: false` waits for its saved views, and is
// read once on open: by the default view, or as the views' load ends.

const _coalesce = Duration(milliseconds: 250);

const _toShip = SavedView(
  id: 'ship',
  name: 'To ship',
  isDefault: true,
  state: ViewState(
    filters: [
      OptionsFilter('status', {'Paid'}),
    ],
  ),
);

const _drafts = SavedView(
  id: 'drafts',
  name: 'Drafts',
  state: ViewState(
    filters: [
      OptionsFilter('status', {'Draft'}),
    ],
  ),
);

/// A store whose `list` can be held, and can fail.
class _Store implements SavedViewsStore {
  _Store(this.views);

  final List<SavedView> views;
  var down = false;

  /// While set, `list` answers only once it completes.
  Completer<void>? hold;

  @override
  Future<List<SavedView>> list(String collectionKey) async {
    await hold?.future;
    if (down) throw StateError('offline');
    return views;
  }

  @override
  Future<SavedView> create(String collectionKey, SavedView view) async =>
      view.copyWith(id: 'new');

  @override
  Future<void> update(String collectionKey, SavedView view) async {}

  @override
  Future<void> delete(String collectionKey, String id) async {}

  @override
  Future<void> setDefault(String collectionKey, String id) async {}

  @override
  Future<void> reorder(String collectionKey, List<String> ids) async {}
}

/// The query of each read of the rows.
final _reads = <CollectionQuery>[];

/// While set, a read of the rows answers only once it completes.
Completer<void>? _holdRows;
var _rowsDown = false;
var _rows = const [1, 2, 3];

CollectionController<int> _collection({bool autoLoad = false}) {
  final controller = CollectionController<int>(
    autoLoad: autoLoad,
    fetcher: (query) async {
      _reads.add(query);
      await _holdRows?.future;
      if (_rowsDown) throw StateError('offline');
      return CollectionPage(items: _rows, total: _rows.length);
    },
  );
  addTearDown(() {
    if (!controller.isDisposed) controller.dispose();
  });
  return controller;
}

SavedViewsController<int> _views(
  CollectionController<int> collection,
  _Store store, {
  bool applyDefaultOnLoad = true,
}) {
  final views = SavedViewsController<int>(
    store: store,
    collectionKey: 'orders',
    collection: collection,
    applyDefaultOnLoad: applyDefaultOnLoad,
  );
  addTearDown(views.dispose);
  return views;
}

void main() {
  setUp(() {
    _reads.clear();
    _holdRows = null;
    _rowsDown = false;
    _rows = const [1, 2, 3];
  });

  group('a collection told not to load', () {
    testWidgets('reads nothing as it is made, and shows as loading', (
      tester,
    ) async {
      final collection = _collection();
      await tester.pump();
      expect(_reads, isEmpty);
      expect(collection.awaitingFirstLoad, isTrue);
      expect(collection.loading, isTrue);
      expect(collection.error, isNull);
      expect(collection.items, isEmpty);
    });

    testWidgets('otherwise reads at once, and waits for nothing', (
      tester,
    ) async {
      final collection = _collection(autoLoad: true);
      expect(collection.awaitingFirstLoad, isFalse);
      expect(_reads, hasLength(1));
      await tester.pump();
      expect(collection.loading, isFalse);
      expect(collection.items, [1, 2, 3]);
    });

    testWidgets('is read by load, which ends the wait', (tester) async {
      final collection = _collection();
      var notified = 0;
      collection.addListener(() => notified++);

      unawaited(collection.load());
      expect(collection.awaitingFirstLoad, isFalse);
      expect(collection.loading, isTrue);
      expect(_reads, hasLength(1));
      await tester.pump();
      expect(collection.loading, isFalse);
      expect(collection.items, [1, 2, 3]);
      expect(notified, greaterThan(0));
    });

    testWidgets('is read by a background refresh, loading until it lands', (
      tester,
    ) async {
      final collection = _collection();
      _holdRows = Completer<void>();

      unawaited(collection.refresh(background: true));
      expect(collection.awaitingFirstLoad, isFalse);
      expect(_reads, hasLength(1));
      await tester.pump();
      expect(collection.loading, isTrue);

      _holdRows!.complete();
      await tester.pump();
      expect(collection.loading, isFalse);
      expect(collection.items, [1, 2, 3]);
    });

    testWidgets('is read by a change of its query, once', (tester) async {
      final collection = _collection();

      collection.sortBy('name', false);
      expect(collection.awaitingFirstLoad, isFalse);
      await tester.pump();
      expect(_reads, hasLength(1));
      expect(_reads.single.sortKey, 'name');
      expect(collection.loading, isFalse);
    });

    testWidgets('that fails its first read says so, and loads no more', (
      tester,
    ) async {
      _rowsDown = true;
      final collection = _collection();

      unawaited(collection.load());
      await tester.pump();
      expect(collection.error, isNotNull);
      expect(collection.loading, isFalse);
      expect(collection.awaitingFirstLoad, isFalse);
    });

    testWidgets('shows its rows as on their way, not as none', (tester) async {
      _rows = const [];
      final collection = _collection();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: Scaffold(
            body: Collection<int>(
              controller: collection,
              columns: [
                TableColumn(id: 'n', label: 'N', cell: (n) => Text('$n')),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EmptyState), findsNothing);

      unawaited(collection.load());
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('its saved views', () {
    testWidgets('read it once, by the default view', (tester) async {
      final store = _Store(const [_toShip, _drafts])..hold = Completer<void>();
      final collection = _collection();
      final views = _views(collection, store);
      await tester.pump();
      // Nothing until the views are read.
      expect(_reads, isEmpty);
      expect(collection.loading, isTrue);

      store.hold!.complete();
      await tester.pump();
      expect(views.activeId, 'ship');
      expect(_reads, hasLength(1));
      expect(_reads.single.filters, _toShip.state.filters);
      expect(collection.items, [1, 2, 3]);
      expect(collection.loading, isFalse);
    });

    testWidgets('read it once when none is the default', (tester) async {
      final store = _Store(const [_drafts])..hold = Completer<void>();
      final collection = _collection();
      final views = _views(collection, store);
      await tester.pump();
      expect(_reads, isEmpty);

      store.hold!.complete();
      await tester.pump();
      expect(views.views, [_drafts]);
      expect(views.activeId, isNull);
      expect(_reads, hasLength(1));
      expect(_reads.single.filters, isEmpty);
      expect(collection.items, [1, 2, 3]);
    });

    testWidgets('read it once when they could not be read', (tester) async {
      final store = _Store(const [_toShip])..down = true;
      final collection = _collection();
      final views = _views(collection, store);
      await tester.pump();
      expect(views.lastError, isNotNull);
      expect(_reads, hasLength(1));
      expect(_reads.single.filters, isEmpty);
      expect(collection.items, [1, 2, 3]);
    });

    testWidgets('read it once when told to apply no default', (tester) async {
      final store = _Store(const [_toShip, _drafts]);
      final collection = _collection();
      final views = _views(collection, store, applyDefaultOnLoad: false);
      await tester.pump();
      expect(views.views, hasLength(2));
      expect(views.activeId, isNull);
      expect(_reads, hasLength(1));
      expect(_reads.single.filters, isEmpty);
    });

    testWidgets('leave the first read to a listener that selects a view as '
        'they land', (tester) async {
      final store = _Store(const [_toShip, _drafts]);
      final collection = _collection();
      final views = _views(collection, store, applyDefaultOnLoad: false);
      // A screen opened on a view of its own choosing.
      void pick() {
        if (views.loading || views.views.isEmpty) return;
        views
          ..removeListener(pick)
          ..select(_drafts);
      }

      views.addListener(pick);
      await tester.pump();
      expect(views.activeId, 'drafts');
      expect(_reads, hasLength(1));
      expect(_reads.single.filters, _drafts.state.filters);
    });

    testWidgets('add no read to one the user asked for meanwhile', (
      tester,
    ) async {
      final store = _Store(const [_drafts])..hold = Completer<void>();
      final collection = _collection();
      _views(collection, store);
      await tester.pump();

      collection.sortBy('name', true);
      await tester.pump();
      expect(_reads, hasLength(1));

      store.hold!.complete();
      await tester.pump();
      expect(_reads, hasLength(1));
      expect(_reads.single.sortKey, 'name');
    });

    testWidgets('disposed before they are read, leave it unread', (
      tester,
    ) async {
      final store = _Store(const [_drafts])..hold = Completer<void>();
      final collection = _collection();
      final views = SavedViewsController<int>(
        store: store,
        collectionKey: 'orders',
        collection: collection,
      );
      await tester.pump();

      views.dispose();
      store.hold!.complete();
      await tester.pump();
      expect(_reads, isEmpty);
      expect(collection.awaitingFirstLoad, isTrue);
    });
  });

  group('a binding', () {
    late StreamController<Object?> changes;
    late StreamController<bool> connected;

    setUp(() {
      changes = StreamController<Object?>.broadcast();
      connected = StreamController<bool>.broadcast();
      addTearDown(changes.close);
      addTearDown(connected.close);
    });

    testWidgets('told the transport is up while the views are on their way '
        'adds no read to the default view\'s', (tester) async {
      final store = _Store(const [_toShip, _drafts])..hold = Completer<void>();
      final collection = _collection();
      final views = _views(collection, store);
      final binding = CollectionRealtime.bind(
        collection,
        onChanged: changes.stream,
        onConnected: connected.stream,
        savedViews: views,
      );
      addTearDown(binding.dispose);
      await tester.pump();

      connected.add(true);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(_reads, isEmpty);

      store.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(views.activeId, 'ship');
      expect(_reads, hasLength(1));
      expect(_reads.single.filters, _toShip.state.filters);
    });

    testWidgets('adds none either when no view is the default', (tester) async {
      final store = _Store(const [_drafts])..hold = Completer<void>();
      final collection = _collection();
      final views = _views(collection, store);
      final binding = CollectionRealtime.bind(
        collection,
        onChanged: changes.stream,
        onConnected: connected.stream,
        savedViews: views,
      );
      addTearDown(binding.dispose);
      await tester.pump();

      connected.add(true);
      await tester.pump(_coalesce);
      await tester.pump();
      store.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(_reads, hasLength(1));
      expect(collection.items, [1, 2, 3]);
    });

    testWidgets('with no views to wait for reads it on the first signal', (
      tester,
    ) async {
      final collection = _collection();
      final binding = CollectionRealtime.bind(
        collection,
        onChanged: changes.stream,
        onConnected: connected.stream,
      );
      addTearDown(binding.dispose);
      await tester.pump();
      expect(_reads, isEmpty);

      connected.add(true);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(_reads, hasLength(1));
      expect(collection.awaitingFirstLoad, isFalse);
      expect(collection.items, [1, 2, 3]);
    });
  });
}
