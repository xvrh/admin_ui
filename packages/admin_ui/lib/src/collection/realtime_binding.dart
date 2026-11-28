import 'dart:async';

import 'collection_controller.dart';
import 'saved_views_controller.dart';

/// Live-refreshes a [CollectionController]. Refetches the current query on each
/// `onChanged` signal (debounced by [coalesce]) and whenever `onConnected`
/// transitions to `true`; see [CollectionRealtime.bind].
///
/// The reconnect refetch is the correctness rule, not an optimisation: change
/// signals are fire-and-forget, so a refetch on every (re)subscribe closes any
/// gap from a dropped or recycled socket. Stays free of transport/server types
/// — the caller adapts its event + connection streams to these.
///
/// A collection with saved views hands them over as [savedViews]. Views
/// that could not be read while the transport was down are read again on
/// the reconnect, before the rows: reading them applies the default view,
/// which reads the rows itself, and the rows are refetched here only when
/// that did not. Without it the rows came back under a bar still saying its
/// views could not load.
///
/// Once its controller is disposed the binding goes quiet: signals still
/// arriving (the screen popped before the binding was disposed) refetch
/// nothing.
class CollectionRealtime<T> {
  final CollectionController<T> controller;
  final Duration coalesce;

  /// Whether each refetch is a background refresh, which shows nothing
  /// while it runs (see [CollectionController.refresh]).
  final bool background;

  /// The collection's saved views, read again on a reconnect when their
  /// load had failed ([SavedViewsController.retryLoad]).
  final SavedViewsController<T>? savedViews;
  StreamSubscription<Object?>? _changes;
  StreamSubscription<bool>? _connected;
  Timer? _pending;
  var _wasConnected = false;

  /// Whether the refetch waiting on [_pending] answers a reconnect.
  var _reconnected = false;

  /// Whether [savedViews] are being read again, and whether a refetch was
  /// asked for meanwhile.
  var _readingViews = false;
  var _askedMeanwhile = false;
  var _disposed = false;

  CollectionRealtime._(
    this.controller,
    this.coalesce,
    this.background,
    this.savedViews,
  );

  /// Binds [controller] to `onChanged`, a signal that the collection
  /// changed, and `onConnected`, whether the transport is up. With
  /// [background], the rows change in place when a refetch lands, and no
  /// progress shows while it runs. With [savedViews], which must be
  /// [controller]'s, a reconnect reads the views again first when their
  /// load had failed.
  factory CollectionRealtime.bind(
    CollectionController<T> controller, {
    required Stream<Object?> onChanged,
    required Stream<bool> onConnected,
    Duration coalesce = const Duration(milliseconds: 250),
    bool background = false,
    SavedViewsController<T>? savedViews,
  }) {
    assert(
      savedViews == null || identical(savedViews.collection, controller),
      'savedViews must be the views of the controller that is bound',
    );
    final binding = CollectionRealtime<T>._(
      controller,
      coalesce,
      background,
      savedViews,
    );
    binding._changes = onChanged.listen((_) => binding._schedule());
    binding._connected = onConnected.listen((up) {
      if (up && !binding._wasConnected) {
        binding._reconnected = true;
        binding._schedule();
      }
      binding._wasConnected = up;
    });
    return binding;
  }

  void _schedule() {
    _pending?.cancel();
    if (controller.isDisposed) {
      dispose();
      return;
    }
    _pending = Timer(coalesce, _refetch);
  }

  void _refetch() {
    if (_disposed || controller.isDisposed) return;
    final reconnected = _reconnected;
    _reconnected = false;
    if (_readingViews) {
      // The rows are read once the views are: see [_reconnect].
      _askedMeanwhile = true;
      return;
    }
    final views = savedViews;
    if (views == null || !reconnected) {
      controller.refresh(background: background);
      return;
    }
    unawaited(_reconnect(views));
  }

  /// The views first, then the rows unless reading the views read them: a
  /// default view applied is a load of the rows, begun after the
  /// reconnect.
  Future<void> _reconnect(SavedViewsController<T> views) async {
    // A load already out cannot be told from one that begins now, so the
    // rows are then read again in any case. A controller still waiting for
    // its first load shows as loading with none out.
    bool reading() => controller.loading && !controller.awaitingFirstLoad;
    final wasReading = reading();
    var read = false;
    void saw() {
      if (!wasReading && reading()) read = true;
    }

    _readingViews = true;
    _askedMeanwhile = false;
    controller.addListener(saw);
    try {
      await views.retryLoad();
    } finally {
      _readingViews = false;
      controller.removeListener(saw);
    }
    // A controller disposed meanwhile reads nothing when asked.
    if (_disposed) return;
    if (!read || _askedMeanwhile) controller.refresh(background: background);
  }

  void dispose() {
    _disposed = true;
    _pending?.cancel();
    _changes?.cancel();
    _connected?.cancel();
  }
}
