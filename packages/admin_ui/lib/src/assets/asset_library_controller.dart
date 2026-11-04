/// @docImport 'ui/asset_picker.dart';
library;

import 'package:flutter/foundation.dart';

import '../collection/filter.dart';
import 'asset_source.dart';
import 'ui/asset_library.dart';

/// Pages, searches and filters an [AssetSource] for an [AssetLibrary]: the
/// state behind [AssetLibrary.connected], and behind [showAssetPicker]'s
/// library.
///
/// It loads the first page as it is made, and again whenever [query],
/// [filter] or [where] changes, keeping the assets shown until the new page
/// lands. [loadMore] appends the next page, which the grid asks for as it
/// nears its end. An answer to a search the person has since moved past is
/// dropped, and so is every answer after [dispose].
///
/// A first page that fails sets [error], which the library shows with a
/// Retry ([retry]). A next page that fails keeps what is shown and sets
/// [loadMoreError], which [AssetLibrary.connected] reports in a toast; the
/// library's "Load more" tries it again.
///
/// ```dart
/// late final library = AssetLibraryController(source: api.assets);
///
/// AssetLibrary.connected(controller: library, onOpen: showDetails)
/// ```
class AssetLibraryController extends ChangeNotifier {
  AssetLibraryController({
    required this.source,
    this.pageSize = 24,
    AssetType? initialFilter,
  }) : assert(pageSize > 0),
       _filter = initialFilter {
    load();
  }

  final AssetSource source;

  /// How many assets one call to [AssetSource.browse] asks for.
  final int pageSize;

  String _query = '';
  AssetType? _filter;
  List<FilterCondition> _where = const [];
  AssetView _view = AssetView.grid;

  List<Asset> _assets = const [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  Object? _loadMoreError;

  /// Moves on with every first page asked for, so the answer to a search
  /// since replaced, and a next page asked for before it, are dropped.
  int _request = 0;
  bool _disposed = false;

  /// The search, as the library's search field reports it once typing
  /// pauses. Setting a new one reloads.
  String get query => _query;
  set query(String value) {
    if (value == _query) return;
    _query = value;
    load();
  }

  /// The type filter; null shows every type. Setting a new one reloads.
  AssetType? get filter => _filter;
  set filter(AssetType? value) {
    if (value == _filter) return;
    _filter = value;
    load();
  }

  /// The app's own conditions, passed to [AssetSource.browse] as they are:
  /// a filter the app puts in [AssetLibrary.toolbarActions]. Setting new ones
  /// reloads.
  List<FilterCondition> get where => _where;
  set where(List<FilterCondition> value) {
    if (listEquals(value, _where)) return;
    _where = List.unmodifiable(value);
    load();
  }

  /// Grid or list. Setting it shows the same assets the other way.
  AssetView get view => _view;
  set view(AssetView value) {
    if (value == _view) return;
    _view = value;
    _notify();
  }

  /// The assets loaded so far, the pages in order.
  List<Asset> get assets => _assets;

  /// How many assets match [query], [filter] and [where] in all, as the
  /// source last counted them.
  int get total => _total;

  /// More assets match than [assets] holds.
  bool get hasMore => _assets.length < _total;

  /// A first page is on its way: from when the controller is made until the
  /// first page lands, and while a new search loads.
  bool get loading => _loading;

  /// A next page is on its way.
  bool get loadingMore => _loadingMore;

  /// Why the last first page failed, or null.
  Object? get error => _error;

  /// Why the last next page failed, or null; the assets shown stay.
  Object? get loadMoreError => _loadMoreError;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Loads the first page for [query], [filter] and [where]. The assets
  /// shown stay until it lands, and a next page on its way is dropped.
  Future<void> load() async {
    if (_disposed) return;
    final request = ++_request;
    _loading = true;
    _loadingMore = false;
    _error = null;
    _loadMoreError = null;
    _notify();
    try {
      final page = await source.browse(
        size: pageSize,
        query: _query,
        filter: _filter,
        where: _where,
      );
      if (request != _request) return;
      _assets = List.unmodifiable(page.items);
      _total = page.total;
    } catch (error) {
      if (request != _request) return;
      _error = error;
    }
    _loading = false;
    _notify();
  }

  /// Loads the first page again, after [error].
  Future<void> retry() => load();

  /// Appends the page after [assets], unless a page is on its way already or
  /// nothing more matches. A page that fails sets [loadMoreError] and keeps
  /// [assets] as they are.
  Future<void> loadMore() async {
    if (_disposed || _loading || _loadingMore || !hasMore) return;
    final request = _request;
    _loadingMore = true;
    _loadMoreError = null;
    _notify();
    try {
      final page = await source.browse(
        index: _assets.length,
        size: pageSize,
        query: _query,
        filter: _filter,
        where: _where,
      );
      if (request != _request) return;
      _assets = List.unmodifiable([..._assets, ...page.items]);
      // An empty page means the library ended sooner than it counted.
      _total = page.items.isEmpty ? _assets.length : page.total;
    } catch (error) {
      if (request != _request) return;
      _loadMoreError = error;
    }
    _loadingMore = false;
    _notify();
  }

  /// Shows [asset] in place of the loaded asset with its id, with nothing to
  /// reload: say, the asset an alt-text save returned.
  void replace(Asset asset) {
    final i = _assets.indexWhere((a) => a.id == asset.id);
    if (i < 0) return;
    _assets = List.unmodifiable([..._assets]..[i] = asset);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}
