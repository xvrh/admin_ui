/// @docImport 'async_value_controller.dart';
/// @docImport 'collection_controller.dart';
library;

import 'package:flutter/foundation.dart';

/// The load state [CollectionController] and [AsyncValueController] share:
/// [loading] and [error], with the latest request winning. An answer to a
/// load since replaced is dropped, and so is any answer that lands after
/// [dispose], which notifies no one.
@internal
mixin LatestLoad on ChangeNotifier {
  bool _loading = false;
  Object? _error;
  int _token = 0;
  bool _disposed = false;

  bool get loading => _loading;
  Object? get error => _error;
  bool get isDisposed => _disposed;

  /// Starts [fetch] at once and hands its answer to [land], unless a later
  /// load or [dispose] came first. A failure, thrown or returned, becomes
  /// [error]; the next load clears it. [land] may start another load.
  ///
  /// The future is listened to as it is made, so one that fails before the
  /// next frame is still the [error], never an uncaught one.
  @protected
  Future<void> runLoad<R>(
    Future<R> Function() fetch,
    void Function(R result) land,
  ) async {
    if (_disposed) return;
    final token = ++_token;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await fetch();
      if (token != _token) return; // superseded, or disposed
      land(result);
    } catch (e) {
      if (token != _token) return;
      _error = e;
    } finally {
      if (token == _token) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _token++;
    super.dispose();
  }
}
