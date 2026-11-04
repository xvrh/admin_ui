import 'dart:async';

import 'collection_controller.dart';

/// Live-refreshes a [CollectionController]. Refetches the current query on each
/// `onChanged` signal (debounced by [coalesce]) and whenever `onConnected`
/// transitions to `true`; see [CollectionRealtime.bind].
///
/// The reconnect refetch is the correctness rule, not an optimisation: change
/// signals are fire-and-forget, so a refetch on every (re)subscribe closes any
/// gap from a dropped or recycled socket. Stays free of transport/server types
/// — the caller adapts its event + connection streams to these.
///
/// Once its controller is disposed the binding goes quiet: signals still
/// arriving (the screen popped before the binding was disposed) refetch
/// nothing.
class CollectionRealtime<T> {
  final CollectionController<T> controller;
  final Duration coalesce;
  StreamSubscription<Object?>? _changes;
  StreamSubscription<bool>? _connected;
  Timer? _pending;
  var _wasConnected = false;

  CollectionRealtime._(this.controller, this.coalesce);

  /// Binds [controller] to `onChanged`, a signal that the collection
  /// changed, and `onConnected`, whether the transport is up.
  factory CollectionRealtime.bind(
    CollectionController<T> controller, {
    required Stream<Object?> onChanged,
    required Stream<bool> onConnected,
    Duration coalesce = const Duration(milliseconds: 250),
  }) {
    final binding = CollectionRealtime<T>._(controller, coalesce);
    binding._changes = onChanged.listen((_) => binding._schedule());
    binding._connected = onConnected.listen((up) {
      if (up && !binding._wasConnected) binding._schedule();
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
    _pending = Timer(coalesce, () {
      if (!controller.isDisposed) controller.refresh();
    });
  }

  void dispose() {
    _pending?.cancel();
    _changes?.cancel();
    _connected?.cancel();
  }
}
