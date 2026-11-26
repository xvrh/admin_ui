import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Saved views that could not be read while the transport was down are read
// again when it comes back, before the rows.

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

const _drafts = SavedView(id: 'drafts', name: 'Drafts');

/// A store that can be down, and whose `list` can be held.
class _Store implements SavedViewsStore {
  _Store(this.views);

  final List<SavedView> views;
  var down = false;
  var lists = 0;
  var creates = 0;

  /// While set, `list` answers only once it completes.
  Completer<void>? hold;

  void _reach() {
    if (down) throw StateError('offline');
  }

  @override
  Future<List<SavedView>> list(String collectionKey) async {
    lists++;
    await hold?.future;
    _reach();
    return views;
  }

  @override
  Future<SavedView> create(String collectionKey, SavedView view) async {
    creates++;
    _reach();
    return view.copyWith(id: 'new');
  }

  @override
  Future<void> update(String collectionKey, SavedView view) async => _reach();

  @override
  Future<void> delete(String collectionKey, String id) async => _reach();

  @override
  Future<void> setDefault(String collectionKey, String id) async => _reach();

  @override
  Future<void> reorder(String collectionKey, List<String> ids) async =>
      _reach();
}

/// A collection, its views and the binding between them and a transport.
class _Rig {
  _Rig(
    WidgetTester tester, {
    List<SavedView> views = const [_toShip, _drafts],
    bool down = true,
    bool applyDefaultOnLoad = true,
    bool background = false,
    bool bound = true,
  }) : store = _Store(views)..down = down,
       rowsDown = down {
    this.views = SavedViewsController<int>(
      store: store,
      collectionKey: 'orders',
      collection: rows,
      applyDefaultOnLoad: applyDefaultOnLoad,
    );
    if (bound) {
      binding = CollectionRealtime.bind(
        rows,
        onChanged: changes.stream,
        onConnected: connected.stream,
        savedViews: this.views,
        background: background,
      );
    }
    addTearDown(() {
      binding?.dispose();
      if (!viewsDisposed) this.views.dispose();
      if (!rows.isDisposed) rows.dispose();
      changes.close();
      connected.close();
    });
  }

  final _Store store;
  bool rowsDown;
  var viewsDisposed = false;

  /// The query of each read of the rows.
  final reads = <CollectionQuery>[];

  /// While set, a read of the rows answers only once it completes.
  Completer<void>? holdRows;

  late final rows = CollectionController<int>(
    fetcher: (query) async {
      reads.add(query);
      await holdRows?.future;
      if (rowsDown) throw StateError('offline');
      return const CollectionPage(items: [1, 2, 3], total: 3);
    },
  );
  late final SavedViewsController<int> views;
  CollectionRealtime<int>? binding;
  final changes = StreamController<Object?>.broadcast();
  final connected = StreamController<bool>.broadcast();

  /// The transport comes back, and the store and the rows with it.
  void up() {
    store.down = false;
    rowsDown = false;
    connected.add(true);
  }
}

void main() {
  group('a reconnect', () {
    testWidgets('reads again the views that could not be read, and the '
        'default view reads the rows', (tester) async {
      final rig = _Rig(tester);
      await tester.pump();
      expect(rig.views.lastError, isNotNull);
      expect(rig.views.views, isEmpty);
      expect(rig.rows.error, isNotNull);
      expect(rig.store.lists, 1);
      expect(rig.reads, hasLength(1));

      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.views.lastError, isNull);
      expect(rig.views.views, [_toShip, _drafts]);
      expect(rig.views.activeId, 'ship');
      // Once, by the default view: not a second time by the binding.
      expect(rig.reads, hasLength(2));
      expect(rig.reads.last.filters, _toShip.state.filters);
      expect(rig.rows.error, isNull);
      expect(rig.rows.items, [1, 2, 3]);
    });

    testWidgets('with no default view to read the rows, reads them itself', (
      tester,
    ) async {
      final rig = _Rig(tester, views: const [_drafts]);
      await tester.pump();
      expect(rig.reads, hasLength(1));

      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.views.views, [_drafts]);
      expect(rig.views.activeId, isNull);
      expect(rig.reads, hasLength(2));
      expect(rig.rows.error, isNull);
    });

    testWidgets('waits out the coalescing pause before either', (tester) async {
      final rig = _Rig(tester);
      await tester.pump();

      rig.up();
      await tester.pump(_coalesce - const Duration(milliseconds: 1));
      expect(rig.store.lists, 1);
      expect(rig.reads, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.reads, hasLength(2));
    });

    testWidgets('leaves alone the views that are read', (tester) async {
      final rig = _Rig(tester, down: false);
      await tester.pump();
      expect(rig.views.views, hasLength(2));
      expect(rig.store.lists, 1);
      final before = rig.reads.length;

      rig.connected.add(true);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 1);
      expect(rig.reads, hasLength(before + 1));
      expect(rig.views.activeId, 'ship');
    });

    testWidgets('reads the rows when the views fail again', (tester) async {
      final rig = _Rig(tester);
      await tester.pump();

      // The transport is back, the views' store is not.
      rig.rowsDown = false;
      rig.connected.add(true);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.views.lastError, isNotNull);
      expect(rig.reads, hasLength(2));
      expect(rig.rows.error, isNull);

      // A change is no reconnect: the views are not tried on it.
      rig.changes.add(null);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.reads, hasLength(3));

      // The next reconnect tries them once more.
      rig.connected.add(false);
      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 3);
      expect(rig.views.lastError, isNull);
      expect(rig.reads, hasLength(4));
    });

    testWidgets('does not run again a save that failed since', (tester) async {
      final rig = _Rig(tester);
      await tester.pump();
      expect(await rig.views.saveAsNew('Mine'), isNull);
      expect(rig.store.creates, 1);
      expect(rig.views.lastError, isNotNull);

      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.creates, 1);
      expect(rig.store.lists, 2);
      expect(rig.views.views, [_toShip, _drafts]);
      expect(rig.views.lastError, isNull);
    });

    testWidgets('keeps what the failed load was told to apply', (tester) async {
      final rig = _Rig(tester, applyDefaultOnLoad: false);
      await tester.pump();

      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.views.views, [_toShip, _drafts]);
      // The screen opens on a view of its own choosing: the default view
      // is not applied, so the rows are the binding's to read.
      expect(rig.views.activeId, isNull);
      expect(rig.reads, hasLength(2));
      expect(rig.reads.last.filters, isEmpty);
    });

    testWidgets('reads the rows in the background where the binding does', (
      tester,
    ) async {
      final rig = _Rig(tester, views: const [_drafts], background: true);
      await tester.pump();
      final showed = <bool>[];
      rig.rows.addListener(() => showed.add(rig.rows.loading));

      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.reads, hasLength(2));
      expect(showed, isNotEmpty);
      expect(showed, everyElement(isFalse));
    });
  });

  group('a change', () {
    testWidgets('reads the rows and leaves the views unread', (tester) async {
      final rig = _Rig(tester);
      await tester.pump();

      rig
        ..store.down = false
        ..rowsDown = false
        ..changes.add(null);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 1);
      expect(rig.views.lastError, isNotNull);
      expect(rig.reads, hasLength(2));
    });

    testWidgets('that comes while the views are read again waits for them, '
        'and is not lost', (tester) async {
      final rig = _Rig(tester);
      await tester.pump();

      rig.store.hold = Completer<void>();
      rig.up();
      await tester.pump(_coalesce);
      expect(rig.store.lists, 2);
      expect(rig.reads, hasLength(1));

      // A change while the views are on their way: no read of the rows
      // that the default view would only replace.
      rig.changes.add(null);
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.reads, hasLength(1));

      rig.store.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(rig.views.activeId, 'ship');
      // The default view's read, then the one the change asked for.
      expect(rig.reads, hasLength(3));
      expect(rig.reads.last.filters, _toShip.state.filters);
    });

    testWidgets('that came during one reconnect is not counted in the next', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await tester.pump();

      // The transport is back, the views' store is not, and a change comes
      // while the views are on their way.
      rig
        ..rowsDown = false
        ..store.hold = Completer<void>()
        ..connected.add(true);
      await tester.pump(_coalesce);
      rig.changes.add(null);
      await tester.pump(_coalesce);
      rig.store.hold!.complete();
      rig.store.hold = null;
      await tester.pump();
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.views.lastError, isNotNull);
      expect(rig.reads, hasLength(2));

      // The store is back: the default view reads the rows, and nothing
      // reads them a second time.
      rig.connected.add(false);
      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      expect(rig.store.lists, 3);
      expect(rig.views.activeId, 'ship');
      expect(rig.reads, hasLength(3));
    });
  });

  group('the rows', () {
    testWidgets('already loading are not taken for the default view\'s read', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await tester.pump();

      // A read that is still out when the transport comes back.
      rig.holdRows = Completer<void>();
      unawaited(rig.rows.refresh());
      await tester.pump();
      expect(rig.rows.loading, isTrue);
      expect(rig.reads, hasLength(2));

      rig.up();
      await tester.pump(_coalesce);
      await tester.pump();
      // The default view's read, and the binding's own: it cannot tell
      // whose the loading is, so it reads.
      expect(rig.reads, hasLength(4));
      rig.holdRows!.complete();
      await tester.pump();
      expect(rig.rows.error, isNull);
    });

    testWidgets('are not read once the binding is disposed', (tester) async {
      final rig = _Rig(tester, views: const [_drafts]);
      await tester.pump();

      rig.store.hold = Completer<void>();
      rig.up();
      await tester.pump(_coalesce);
      expect(rig.store.lists, 2);

      rig.binding!.dispose();
      rig.store.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(rig.views.views, [_drafts]);
      expect(rig.reads, hasLength(1));
    });

    testWidgets('are not read once their controller is disposed', (
      tester,
    ) async {
      final rig = _Rig(tester, views: const [_drafts]);
      await tester.pump();

      rig.store.hold = Completer<void>();
      rig.up();
      await tester.pump(_coalesce);

      rig.viewsDisposed = true;
      rig.views.dispose();
      rig.rows.dispose();
      rig.store.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(rig.reads, hasLength(1));
    });
  });

  testWidgets('the views bound are the bound collection\'s', (tester) async {
    final rig = _Rig(tester, bound: false);
    final other = CollectionController<int>(
      fetcher: (_) async => const CollectionPage(items: [], total: 0),
    );
    addTearDown(other.dispose);
    expect(
      () => CollectionRealtime.bind(
        other,
        onChanged: rig.changes.stream,
        onConnected: rig.connected.stream,
        savedViews: rig.views,
      ),
      throwsAssertionError,
    );
    await tester.pump();
  });

  group('retryLoad', () {
    testWidgets('reads the views again after a load that failed', (
      tester,
    ) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();
      expect(rig.views.lastError, isNotNull);

      rig
        ..store.down = false
        ..rowsDown = false;
      await rig.views.retryLoad();
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.views.lastError, isNull);
      expect(rig.views.loading, isFalse);
      expect(rig.views.activeId, 'ship');
      expect(rig.reads.last.filters, _toShip.state.filters);
    });

    testWidgets('does nothing when the views are read', (tester) async {
      final rig = _Rig(tester, down: false, bound: false);
      await tester.pump();
      final reads = rig.reads.length;

      await rig.views.retryLoad();
      await tester.pump();
      expect(rig.store.lists, 1);
      expect(rig.reads, hasLength(reads));
    });

    testWidgets('does nothing once a load has succeeded', (tester) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();

      rig
        ..store.down = false
        ..rowsDown = false;
      await rig.views.retry();
      expect(rig.store.lists, 2);
      await rig.views.retryLoad();
      await tester.pump();
      expect(rig.store.lists, 2);
    });

    testWidgets('waits for a load that is running, and starts no other', (
      tester,
    ) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();

      rig
        ..store.down = false
        ..rowsDown = false
        ..store.hold = Completer<void>();
      unawaited(rig.views.retry());
      await tester.pump();
      expect(rig.store.lists, 2);

      var done = false;
      unawaited(rig.views.retryLoad().then((_) => done = true));
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(done, isFalse);

      rig.store.hold!.complete();
      await tester.pump();
      expect(done, isTrue);
      expect(rig.views.views, [_toShip, _drafts]);
      expect(rig.store.lists, 2);
    });

    testWidgets('waits for the load still running when an earlier one is '
        'done', (tester) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();

      rig
        ..store.down = false
        ..rowsDown = false;
      final first = Completer<void>();
      final second = Completer<void>();
      rig.store.hold = first;
      unawaited(rig.views.load());
      rig.store.hold = second;
      unawaited(rig.views.load());
      await tester.pump();
      expect(rig.store.lists, 3);
      first.complete();
      await tester.pump();

      var done = false;
      unawaited(rig.views.retryLoad().then((_) => done = true));
      await tester.pump();
      expect(rig.store.lists, 3);
      expect(done, isFalse);

      second.complete();
      await tester.pump();
      expect(done, isTrue);
      expect(rig.store.lists, 3);
    });

    testWidgets('is still there after the error is dismissed', (tester) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();
      rig.views.clearError();
      expect(rig.views.lastError, isNull);

      rig
        ..store.down = false
        ..rowsDown = false;
      await rig.views.retryLoad();
      await tester.pump();
      expect(rig.store.lists, 2);
      expect(rig.views.views, [_toShip, _drafts]);
    });

    testWidgets('fails again without throwing, and can be asked again', (
      tester,
    ) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();

      await rig.views.retryLoad();
      expect(rig.store.lists, 2);
      expect(rig.views.lastError, isNotNull);

      rig
        ..store.down = false
        ..rowsDown = false;
      await rig.views.retryLoad();
      await tester.pump();
      expect(rig.store.lists, 3);
      expect(rig.views.lastError, isNull);
    });

    testWidgets('asks nothing of a disposed controller', (tester) async {
      final rig = _Rig(tester, bound: false);
      await tester.pump();

      rig.viewsDisposed = true;
      rig.views.dispose();
      rig.store.down = false;
      await rig.views.retryLoad();
      expect(rig.store.lists, 1);
    });
  });
}
