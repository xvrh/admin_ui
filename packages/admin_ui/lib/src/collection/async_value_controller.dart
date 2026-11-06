/// @docImport 'async_value_builder.dart';
/// @docImport 'collection_controller.dart';
library;

import 'package:flutter/foundation.dart';

import 'latest_load.dart';

/// Loads one value for a page that is not a table (a record's details, a
/// dashboard's figures, a hover card) the way a [CollectionController] loads
/// a table's rows: [loading], an [error] to retry, a [refresh] that keeps
/// the [value] on screen until the new one lands, and the latest request
/// winning. An [AsyncValueBuilder] draws it.
///
/// It calls [fetcher] as it is made, and again on each [refresh]. An answer
/// to a load since replaced is dropped, and so is any answer that lands
/// after [dispose]. A failed load keeps the value from before, which
/// [AsyncValueBuilder] does not show while the [error] stands.
///
/// Where a `FutureBuilder` is handed a future made in `setState`, it listens
/// only at the next frame, and a future that fails before then is reported
/// as uncaught. This controller listens as it calls [fetcher].
///
/// ```dart
/// late final _customer = AsyncValueController(
///   fetcher: () => api.customer(widget.customerId),
/// );
///
/// @override
/// void dispose() {
///   _customer.dispose();
///   super.dispose();
/// }
///
/// @override
/// Widget build(BuildContext context) => AsyncValueBuilder(
///   controller: _customer,
///   builder: (context, customer) => CustomerSummary(customer),
/// );
/// ```
class AsyncValueController<T> extends ChangeNotifier with LatestLoad {
  final Future<T> Function() fetcher;

  T? _value;
  bool _hasValue = false;

  AsyncValueController({required this.fetcher}) {
    refresh();
  }

  /// The value last loaded; null until one lands (see [hasValue]).
  T? get value => _value;

  /// Whether a value has landed: what [value] cannot tell when `T` is
  /// nullable.
  bool get hasValue => _hasValue;

  /// Loads the value again; the one loaded stays until the new one lands.
  ///
  /// A [background] refresh is one the user did not ask for: after an
  /// edit saved elsewhere, on a push, on a timer. Nothing on screen says it
  /// runs, as [loading] stays as it was, and the new value replaces the old
  /// one when it lands. A failure still shows as the [error]: the value on
  /// screen was known to be out of date, or it would not have been
  /// refreshed.
  Future<void> refresh({bool background = false}) => runLoad(fetcher, (value) {
    _value = value;
    _hasValue = true;
  }, background: background);
}
