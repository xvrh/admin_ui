/// @docImport 'collection.dart';
/// @docImport 'ui/bulk_action_bar.dart';
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'filter.dart';
import 'latest_load.dart';

/// The query a [CollectionController] issues to its fetcher. Three independent
/// filter channels, all interpreted only by the fetcher (this layer stays free
/// of server types):
/// - [search]: global free-text.
/// - [filters]: structured field/op/value conditions (the filter bar).
/// - [advanced]: an opaque escape hatch for a project's own advanced-search box.
///
/// [sortKey] is a [FieldId] the fetcher reads, like a filter's field.
@immutable
class CollectionQuery {
  final FieldId? sortKey;
  final bool ascending;

  /// Zero-based page index.
  final int pageIndex;
  final int pageSize;
  final String search;
  final List<FilterCondition> filters;
  final Object? advanced;

  const CollectionQuery({
    this.sortKey,
    this.ascending = true,
    this.pageIndex = 0,
    this.pageSize = 25,
    this.search = '',
    this.filters = const [],
    this.advanced,
  });

  CollectionQuery copyWith({
    FieldId? sortKey,
    bool? ascending,
    int? pageIndex,
    int? pageSize,
    String? search,
    List<FilterCondition>? filters,
    Object? advanced,
    bool clearAdvanced = false,
    bool clearSort = false,
  }) => CollectionQuery(
    sortKey: clearSort ? null : (sortKey ?? this.sortKey),
    ascending: ascending ?? this.ascending,
    pageIndex: pageIndex ?? this.pageIndex,
    pageSize: pageSize ?? this.pageSize,
    search: search ?? this.search,
    filters: filters ?? this.filters,
    advanced: clearAdvanced ? null : (advanced ?? this.advanced),
  );
}

/// One page of results. The project's fetcher adapts its `Slice` into this —
/// no server types leak here.
///
/// A source that counts its matches gives [total], which the pager turns into
/// numbered pages and "1–25 of 1,234". One that can't count them cheaply (a
/// cursor API) leaves it null and says whether another page follows with
/// [hasNext]; the pager then offers previous / next and "1–25".
@immutable
class CollectionPage<T> {
  final List<T> items;

  /// Every row the query matches across all pages, or null when unknown.
  final int? total;

  /// Whether a page follows this one. Read only when [total] is null.
  final bool? hasNext;

  const CollectionPage({required this.items, this.total, this.hasNext})
    : assert(
        total != null || hasNext != null,
        'A page needs its total, or hasNext when the total is unknown',
      );
}

typedef CollectionFetcher<T> = Future<CollectionPage<T>> Function(
  CollectionQuery query,
);

/// Owns the query, async state and selection for a [Collection]. Calls the
/// injected [fetcher] whenever the query changes; the latest request wins
/// (stale responses are dropped, and so is any response that lands after
/// [dispose]). Search is debounced.
///
/// **Selection** is kept by [rowKey], so a fetcher that returns fresh objects
/// on every load — paging back, a refresh, a realtime update — keeps its rows
/// selected, and each reload swaps a selected row for its fresh copy. It
/// survives sorting, paging and a page-size change, so a bulk bar counts
/// "N selected" across pages; it is cleared when the search, the filters,
/// the advanced query or a saved view change which rows match, so a bulk
/// action never reaches a row the list no longer shows.
///
/// **Local changes** show a mutation before the server confirms it: a delete
/// or an inline edit takes effect on the loaded rows at once instead of
/// waiting for a refetch. [optimistic] applies one while its commit runs and
/// takes it back if the commit fails; [undoable] also holds the commit until
/// an Undo is no longer offered. [patchLocal] and [removeLocal] change the
/// loaded rows with nothing to commit, as after a save the server confirmed.
class CollectionController<T> extends ChangeNotifier with LatestLoad {
  final CollectionFetcher<T> fetcher;
  final Duration searchDebounce;

  /// A row's stable identity — typically its id — which selection is kept
  /// by. Pass it to any list that selects rows: without it rows are compared
  /// with `==`, and a row reloaded as a new object reads as unselected.
  final Object Function(T row)? rowKey;

  CollectionQuery _query;

  /// The fetcher's last page, with the local changes that settled since.
  CollectionPage<T>? _base;

  /// [_base] under the [_pending] changes: the page on screen.
  CollectionPage<T>? _page;

  /// Local changes whose commit has not settled yet, oldest first. Each is
  /// applied again to a page that lands meanwhile, so a refresh does not
  /// bring back a row that is on its way out.
  final _pending = <_LocalChange<T>>[];

  /// Changes that settled while the load in flight ran: its page may have
  /// been read before they were committed, so they apply to it too.
  final _settledDuringLoad = <_LocalChange<T>>[];

  /// Insertion-ordered, keyed by [rowKey].
  final _selected = <Object?, T>{};
  Set<T>? _selectedRows;

  /// Moves on whenever the selection is dropped or replaced as a whole, so a
  /// failed change puts back the rows it deselected only into the selection
  /// they were taken from.
  int _selectionEpoch = 0;
  Timer? _debounce;

  CollectionController({
    required this.fetcher,
    CollectionQuery initialQuery = const CollectionQuery(),
    this.searchDebounce = const Duration(milliseconds: 350),
    this.rowKey,
  }) : _query = initialQuery {
    load();
  }

  /// The live text of the global search box, owned here so it shares the
  /// controller's lifetime — the box stays in sync with the query across widget
  /// rebuilds and route changes (a remounted list rehydrates from this). Bind it
  /// straight to a `SearchField(controller: …)`; every edit drives [setSearch].
  late final TextEditingController searchController = TextEditingController(
    text: _query.search,
  )..addListener(_onSearchInput);

  void _onSearchInput() {
    if (searchController.text == _query.search) {
      // Typed and taken back within the debounce: nothing left to apply.
      _debounce?.cancel();
      _debounce = null;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, _applySearch);
  }

  /// Applies the box's text as it stands when the debounce fires, not as it
  /// stood when the timer started.
  void _applySearch() {
    _debounce = null;
    if (isDisposed) return;
    final search = searchController.text;
    if (search == _query.search) return;
    _dropSelection();
    _apply(_query.copyWith(search: search));
  }

  CollectionQuery get query => _query;
  List<T> get items => _page?.items ?? const [];

  /// Whether the source reported a [total]. Until the first page lands it is
  /// taken as known (and 0).
  bool get totalKnown => _page == null || _page!.total != null;

  /// Every row the query matches. When the source can't count them
  /// ([totalKnown] false), the rows seen so far: through the end of this
  /// page.
  int get total => _page == null ? 0 : _page!.total ?? to;

  /// The number of pages, or null while the total is unknown.
  int? get pageCount => totalKnown
      ? math.max(1, (total / math.max(1, _query.pageSize)).ceil())
      : null;

  /// The selected rows, each the freshest copy loaded. Read-only: change the
  /// selection with [setSelected], [clearSelection] or [toggleSelected].
  Set<T> get selected => _selectedRows ??= Set.unmodifiable(_selected.values);

  /// The [rowKey]s of the selected rows (the rows themselves without one).
  Set<Object?> get selectedKeys => Set.unmodifiable(_selected.keys);

  bool isSelected(T row) => _selected.containsKey(_keyOf(row));

  Object? _keyOf(T row) => rowKey == null ? row : rowKey!(row);

  /// True when every loaded row on the current page is selected — the cue to
  /// offer "select all {total}" across pages in a [BulkActionBar].
  bool get allOnPageSelected => items.isNotEmpty && items.every(isSelected);

  bool get hasPrev => _query.pageIndex > 0;
  bool get hasNext => totalKnown
      ? (_query.pageIndex + 1) * _query.pageSize < total
      : _page!.hasNext ?? false;
  int get pageSize => _query.pageSize;

  /// The zero-based index of the current page.
  int get pageIndex => _query.pageIndex;

  /// 1-based index of the first row on this page; 0 when it has none.
  int get from => items.isEmpty ? 0 : _query.pageIndex * _query.pageSize + 1;

  /// 1-based index of the last row on this page.
  int get to => _query.pageIndex * _query.pageSize + items.length;

  /// Fetches the current query's page. A [background] load is a
  /// [refresh]'s.
  Future<void> load({bool background = false}) {
    _settledDuringLoad.clear();
    return runLoad(() => fetcher(_query), (result) {
      if (_pastTheEnd(result) case final last?) {
        // The rows of the last page went (a delete, a realtime refresh):
        // show the page that now holds the last rows instead of an empty
        // one.
        _query = _query.copyWith(pageIndex: last);
        if (result.total != 0) {
          unawaited(load(background: background));
          return;
        }
      }
      _base = _settledDuringLoad.fold<CollectionPage<T>>(
        result,
        (page, change) => _applied(page, change.update),
      );
      _settledDuringLoad.clear();
      _rebuildPage();
    }, background: background);
  }

  /// The index of the last page when [page] came back empty past it, else
  /// null. Always lower than the current index, so reloading settles.
  int? _pastTheEnd(CollectionPage<T> page) {
    final index = _query.pageIndex;
    if (page.items.isNotEmpty || index == 0) return null;
    final total = page.total;
    if (total == null) return index - 1;
    final last = math.max(0, (total / math.max(1, _query.pageSize)).ceil() - 1);
    return last < index ? last : null;
  }

  /// Swaps each selected row for its freshly loaded copy.
  void _refreshSelection(List<T> rows) {
    if (_selected.isEmpty) return;
    for (final row in rows) {
      final key = _keyOf(row);
      if (_selected.containsKey(key) && !identical(_selected[key], row)) {
        _selected[key] = row;
        _selectedRows = null;
      }
    }
  }

  /// Fetches the current page again; its rows stay until the new ones land.
  ///
  /// A [background] refresh is one the user did not ask for: after an
  /// edit, on a push, on a timer. Nothing on screen says it runs, as
  /// [loading] stays as it was, and the new rows replace the old ones when
  /// they land. A failure still shows as the [error]. The selection and
  /// the local changes still pending are kept, as on any load.
  Future<void> refresh({bool background = false}) =>
      load(background: background);

  /// Applies [update] to the loaded rows at once and notifies, then awaits
  /// [commit], the server call that makes the change stick. When [commit]
  /// throws, the change is taken back — the rows, the [total] and the rows
  /// it deselected — and the error is rethrown, for the caller to report.
  ///
  /// [update] is handed a copy of the rows on screen and returns the rows to
  /// show: without the deleted ones, with an edited one swapped for its new
  /// copy. A row it drops leaves the selection, and [total] moves by the
  /// number of rows it drops or adds.
  ///
  /// A page that lands while [commit] runs — a refresh, a realtime update,
  /// another page — wins: [update] is applied to it in turn, as it is to a
  /// page whose load began before the commit went through, and a failure
  /// takes the change back out of that newer page instead of restoring the
  /// rows from before. So [update] should be a change that can land twice,
  /// such as dropping or patching the rows it names: a page read after the
  /// server made the change already holds it. Changes can overlap, and each
  /// one's failure takes back only its own.
  ///
  /// ```dart
  /// await controller.optimistic(
  ///   update: (rows) => [
  ///     for (final r in rows) r.id == id ? r.copyWith(done: true) : r,
  ///   ],
  ///   commit: () => api.complete(id),
  /// );
  /// ```
  Future<void> optimistic({
    required List<T> Function(List<T> items) update,
    required Future<void> Function() commit,
  }) async {
    final change = _push(update);
    try {
      await commit();
    } catch (_) {
      _rollback(change);
      rethrow;
    }
    _settle(change);
  }

  /// Like [optimistic], with the commit held until [undone] resolves: the
  /// rows change at once, and [undone] completing with true takes the change
  /// back without committing it; false commits it, taking it back if
  /// [commit] throws (the error is rethrown). Resolves whether it committed.
  ///
  /// [undone] is the offer to undo, typically a toast with an Undo action
  /// that resolves as the toast goes: true when Undo was pressed, false when
  /// it timed out or was closed.
  ///
  /// ```dart
  /// final deleted = await controller.undoable(
  ///   update: (rows) => rows.where((r) => r.id != row.id).toList(),
  ///   commit: () => api.delete(row.id),
  ///   undone: ToastScope.of(context)
  ///       .show(Toast('Deleted', actionLabel: l10n.inputs.undo))
  ///       .dismissed
  ///       .then((reason) => reason == ToastDismissReason.action),
  /// );
  /// ```
  ///
  /// The commit still runs when [undone] resolves after this controller is
  /// disposed — the list left the screen while the Undo was on offer.
  Future<bool> undoable({
    required List<T> Function(List<T> items) update,
    required Future<void> Function() commit,
    required Future<bool> undone,
  }) async {
    final change = _push(update);
    try {
      if (await undone) {
        _rollback(change);
        return false;
      }
      await commit();
    } catch (_) {
      _rollback(change);
      rethrow;
    }
    _settle(change);
    return true;
  }

  /// Swaps each loaded row [where] accepts for [patch]'s copy of it, with
  /// nothing to commit — say, the row a save just returned.
  ///
  /// A page whose load is under way gets the patch too once it lands, as it
  /// may have been read before the save.
  void patchLocal(
    T Function(T row) patch, {
    required bool Function(T row) where,
  }) =>
      _edit((rows) => [for (final row in rows) where(row) ? patch(row) : row]);

  /// Drops the loaded rows [where] accepts, with nothing to commit — say,
  /// rows a realtime event reported deleted. They leave the selection, and
  /// [total] drops by their number.
  ///
  /// A page whose load is under way loses them too once it lands, as it may
  /// have been read before they went.
  void removeLocal(bool Function(T row) where) =>
      _edit((rows) => rows.where((row) => !where(row)).toList());

  void _edit(List<T> Function(List<T> items) update) {
    final before = items;
    if (_base case final base?) _base = _applied(base, update);
    if (loadInFlight) {
      _settledDuringLoad.add(_LocalChange(update, _selectionEpoch));
    }
    _rebuildPage();
    _deselectGone(before, null);
    notifyListeners();
  }

  _LocalChange<T> _push(List<T> Function(List<T> items) update) {
    final change = _LocalChange<T>(update, _selectionEpoch);
    final before = items;
    _pending.add(change);
    _rebuildPage();
    _deselectGone(before, change);
    notifyListeners();
    return change;
  }

  /// Takes [change] back out of the page on screen, and puts back the rows
  /// it deselected, unless the selection has been replaced since.
  void _rollback(_LocalChange<T> change) {
    if (!_pending.remove(change)) return;
    _rebuildPage();
    if (change.selectionEpoch == _selectionEpoch &&
        change.deselected.isNotEmpty) {
      final onPage = {for (final row in items) _keyOf(row): row};
      for (final MapEntry(:key, :value) in change.deselected.entries) {
        _selected.putIfAbsent(key, () => onPage[key] ?? value);
      }
      _selectedRows = null;
    }
    notifyListeners();
  }

  /// Keeps [change] once its commit went through: it moves into the base
  /// page, under the changes still pending.
  void _settle(_LocalChange<T> change) {
    if (!_pending.remove(change)) return;
    if (_base case final base?) _base = _applied(base, change.update);
    if (loadInFlight) _settledDuringLoad.add(change);
    _rebuildPage();
    notifyListeners();
  }

  /// [page] with [update] applied to a copy of its rows; its total moves by
  /// the rows gained or lost.
  CollectionPage<T> _applied(
    CollectionPage<T> page,
    List<T> Function(List<T> items) update,
  ) {
    final rows = update(List.of(page.items));
    final total = page.total;
    return CollectionPage(
      items: rows,
      total: total == null
          ? null
          : math.max(0, total + rows.length - page.items.length),
      hasNext: page.hasNext,
    );
  }

  /// Lays the pending changes over the base page, and swaps each selected
  /// row for the copy now on screen.
  void _rebuildPage() {
    final base = _base;
    if (base == null) return;
    final page = _pending.fold(base, (page, c) => _applied(page, c.update));
    _page = page;
    _refreshSelection(page.items);
  }

  /// Deselects the rows of [before] that are no longer on the page, noting
  /// them on [change] so that a rollback can put them back.
  void _deselectGone(List<T> before, _LocalChange<T>? change) {
    if (_selected.isEmpty) return;
    final kept = {for (final row in items) _keyOf(row)};
    for (final row in before) {
      final key = _keyOf(row);
      if (kept.contains(key) || !_selected.containsKey(key)) continue;
      final removed = _selected.remove(key) as T;
      change?.deselected[key] = removed;
      _selectedRows = null;
    }
  }

  void _apply(CollectionQuery q, {bool resetPage = true}) {
    _query = resetPage ? q.copyWith(pageIndex: 0) : q;
    load();
  }

  void sortBy(FieldId key, bool ascending) =>
      _apply(_query.copyWith(sortKey: key, ascending: ascending));

  /// Back to the source's own order.
  void clearSort() {
    if (_query.sortKey == null) return;
    _apply(_query.copyWith(clearSort: true, ascending: true));
  }

  void setPageSize(int size) => _apply(_query.copyWith(pageSize: size));

  /// Replaces the persistable query slice (filters / sort / page size) at once —
  /// the apply path for a saved view. Leaves [CollectionQuery.search]
  /// untouched (transient), resets to the first page and drops the selection.
  void applyView({
    List<FilterCondition> filters = const [],
    FieldId? sortKey,
    bool ascending = true,
    int? pageSize,
  }) {
    _dropSelection();
    _apply(
      _query.copyWith(
        filters: filters,
        sortKey: sortKey,
        clearSort: sortKey == null,
        ascending: ascending,
        pageSize: pageSize ?? _query.pageSize,
      ),
    );
  }

  /// Sets the search text, applied after [searchDebounce] — the same path as
  /// typing into [searchController], which it updates.
  void setSearch(String search) {
    if (searchController.text == search) {
      _onSearchInput();
    } else {
      searchController.text = search;
    }
  }

  /// Replaces the structured filter set (drops inactive conditions). Resets to
  /// the first page, drops the selection and reloads.
  void setFilters(List<FilterCondition> filters) {
    _dropSelection();
    _apply(_query.copyWith(filters: filters.where((f) => f.isActive).toList()));
  }

  void clearFilters() {
    if (_query.filters.isEmpty) return;
    _dropSelection();
    _apply(_query.copyWith(filters: const []));
  }

  /// Whether a search, a filter or an advanced query narrows the rows — an
  /// empty result then means "no results", not "nothing here yet".
  bool get isFiltered =>
      _query.search.isNotEmpty ||
      _query.filters.isNotEmpty ||
      _query.advanced != null;

  /// Clears the search (at once, past the debounce), the filters and the
  /// advanced query: the "Clear filters" of an empty result.
  void clearSearchAndFilters() {
    _debounce?.cancel();
    _debounce = null;
    final hadQuery = isFiltered;
    _query = _query.copyWith(
      search: '',
      filters: const [],
      clearAdvanced: true,
    );
    // Now equal to the applied search, so the box's listener schedules
    // nothing.
    searchController.clear();
    if (!hadQuery) return;
    _dropSelection();
    _apply(_query);
  }

  /// Sets (or clears, when null) the opaque advanced-search payload. Drops the
  /// selection.
  void setAdvanced(Object? advanced) {
    _dropSelection();
    _apply(
      _query.copyWith(advanced: advanced, clearAdvanced: advanced == null),
    );
  }

  void nextPage() {
    if (hasNext) {
      _apply(
        _query.copyWith(pageIndex: _query.pageIndex + 1),
        resetPage: false,
      );
    }
  }

  void prevPage() {
    if (hasPrev) {
      _apply(
        _query.copyWith(pageIndex: _query.pageIndex - 1),
        resetPage: false,
      );
    }
  }

  /// Jumps to the zero-based [pageIndex], within the known page count.
  void goToPage(int pageIndex) {
    final count = pageCount;
    final index = math.max(
      0,
      count == null ? pageIndex : math.min(pageIndex, count - 1),
    );
    if (index == _query.pageIndex) return;
    _apply(_query.copyWith(pageIndex: index), resetPage: false);
  }

  void setSelected(Set<T> selection) {
    _selectionEpoch++;
    _selected
      ..clear()
      ..addEntries(selection.map((row) => MapEntry(_keyOf(row), row)));
    _selectedRows = null;
    notifyListeners();
  }

  /// Adds [row] to the selection, or removes it when it is already there.
  void toggleSelected(T row) {
    final key = _keyOf(row);
    if (_selected.containsKey(key)) {
      _selected.remove(key);
    } else {
      _selected[key] = row;
    }
    _selectedRows = null;
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _dropSelection();
    notifyListeners();
  }

  void _dropSelection() {
    _selectionEpoch++;
    _selected.clear();
    _selectedRows = null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

/// A local change awaiting its commit: see [CollectionController.optimistic].
class _LocalChange<T> {
  final List<T> Function(List<T> items) update;

  /// The selection's epoch when it was applied.
  final int selectionEpoch;

  /// The rows it took out of the selection, by key.
  final deselected = <Object?, T>{};

  _LocalChange(this.update, this.selectionEpoch);
}
