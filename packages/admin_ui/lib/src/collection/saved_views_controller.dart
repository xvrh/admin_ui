import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../l10n/admin_ui_localizations.dart';
import 'collection_controller.dart';
import 'column_layout.dart';
import 'saved_view.dart';

/// Bridges a [SavedViewsStore] to a [CollectionController]: owns the view list,
/// the active view and the dirty flag, and drives the collection's query when a
/// view is applied. Notifies on every collection change too, so a bar bound to
/// it re-renders the dirty state live.
///
/// The Screen creates one per collection and feeds its state into a
/// `SavedViewsBar`, which asks for names itself (`showSaveViewDialog`); this
/// controller takes no UI dependency.
///
/// With no view active ([activeId] null) the collection shows every row, at
/// the query it had when this controller was made. [load] applies only a
/// view marked [SavedView.isDefault], never simply the first, and
/// [clearView] returns to no view: a bar's "All" tab.
///
/// Store calls never throw out of this controller: a failed call leaves the
/// views as they were (an optimistic [reorder] is rolled back), resets
/// [loading], and is kept as [lastError] with a [retry] until the next call
/// succeeds or [clearError] drops it. Feed [lastError] to the bar's `error`.
class SavedViewsController<T> extends ChangeNotifier {
  final SavedViewsStore store;
  final String collectionKey;
  final CollectionController<T> collection;

  /// Optional bridge to the Screen-owned column layout, so a saved view also
  /// captures and restores column order/visibility. Both must be set to enable
  /// column persistence; left null, views ignore columns.
  final ColumnLayout Function()? readColumns;
  final void Function(ColumnLayout?)? writeColumns;

  /// The name [duplicate] gives a copy of the view named `name` when it is
  /// not handed one: by default "`name` copy" in intl's current language,
  /// as this controller has no context. `SavedViewsBar` hands one in the
  /// app's language.
  final String Function(String name) nameForCopy;

  /// The collection's query as this controller found it: what [clearView]
  /// returns to.
  final ViewState _initial;

  List<SavedView> _views = [];
  String? _activeId;
  bool _loading = false;
  bool _disposed = false;
  Object? _lastError;
  Future<void> Function()? _retry;

  /// Guards against a store round-trip resolving after the screen was popped —
  /// notifying a disposed [ChangeNotifier] throws.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Starts to [load] the views at once. With [applyDefaultOnLoad] false the
  /// load leaves the collection's query alone even when a view is marked
  /// default, for a screen that opens on a view of its own choosing.
  SavedViewsController({
    required this.store,
    required this.collectionKey,
    required this.collection,
    this.readColumns,
    this.writeColumns,
    String Function(String name)? nameForCopy,
    bool applyDefaultOnLoad = true,
  }) : nameForCopy = nameForCopy ?? _copyName,
       _initial = ViewState.from(collection.query) {
    collection.addListener(notifyListeners);
    load(applyDefault: applyDefaultOnLoad);
  }

  static String _copyName(String name) => AdminLocalizations.lookup(
    Locale(Intl.shortLocale(Intl.getCurrentLocale())),
  ).collection.copyOf(name);

  List<SavedView> get views => _views;
  String? get activeId => _activeId;
  bool get loading => _loading;
  SavedView? get active => _views.firstWhereOrNull((v) => v.id == _activeId);

  /// The raw error of the last store call, while it is the latest outcome.
  /// Describe it for people with `ErrorTextScope.describe`.
  Object? get lastError => _lastError;

  /// Re-runs the call behind [lastError]; nothing while there is none.
  Future<void> retry() async {
    final again = _retry;
    if (again != null) await again();
  }

  /// Dismisses [lastError] without retrying.
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    _retry = null;
    _notify();
  }

  /// True when the live query — or, if columns are bridged, the column layout —
  /// has drifted from the active view; with no view active, when the query
  /// has drifted from the one the collection started with, which
  /// [discardChanges] returns to.
  bool get dirty {
    if (_activeId == null) return !_initial.matchesQuery(collection.query);
    final a = active;
    if (a == null) return false;
    if (!a.state.matchesQuery(collection.query)) return true;
    return _columnsDirty(a);
  }

  bool _columnsDirty(SavedView view) {
    if (readColumns == null) return false;
    final saved = view.state.columns;
    if (saved == null) return false;
    return readColumns!() != saved;
  }

  /// Runs one store round-trip and whatever it applies. A throw is recorded as
  /// [lastError] with [again] as its retry, and reported as false; success
  /// clears the last error.
  Future<bool> _guard(
    Future<void> Function() call, {
    required Future<void> Function() again,
  }) async {
    try {
      await call();
    } catch (error) {
      if (_disposed) return false;
      _lastError = error;
      _retry = again;
      _notify();
      return false;
    }
    if (_disposed) return false;
    if (_lastError != null) {
      _lastError = null;
      _retry = null;
    }
    return true;
  }

  /// Reads the views from the [store]. With [applyDefault], makes the view
  /// marked [SavedView.isDefault] active, or, when none is, leaves any
  /// active view for every row ([clearView]).
  Future<void> load({bool applyDefault = true}) async {
    _loading = true;
    _notify();
    await _guard(() async {
      final views = await store.list(collectionKey);
      if (_disposed) return;
      _views = views;
      if (!applyDefault) return;
      final preferred = _views.firstWhereOrNull((v) => v.isDefault);
      if (preferred != null) {
        _activeId = preferred.id;
        _apply(preferred);
      } else if (_activeId != null) {
        _clear();
      }
    }, again: () => load(applyDefault: applyDefault));
    _loading = false;
    _notify();
  }

  void select(SavedView view) {
    _activeId = view.id;
    _apply(view);
    _notify();
  }

  /// Leaves the active view for every row: the collection's filters, sort
  /// and page size as they were when this controller was made, and the
  /// columns' own layout (`writeColumns(null)`). What a `SavedViewsBar`'s
  /// "All" tab selects.
  void clearView() {
    _clear();
    _notify();
  }

  void _clear() {
    _activeId = null;
    collection.applyView(
      filters: _initial.filters,
      sortKey: _initial.sortKey,
      ascending: _initial.ascending,
      pageSize: _initial.pageSize,
    );
    writeColumns?.call(null);
  }

  /// Reverts the live query to the active view, dropping unsaved edits;
  /// with no view active, to the query the collection started with.
  void discardChanges() {
    if (_activeId == null) {
      _clear();
      return;
    }
    final a = active;
    if (a != null) _apply(a);
  }

  Future<void> saveChanges() async {
    final a = active;
    if (a == null) return;
    final updated = a.copyWith(
      state: ViewState.from(collection.query, columns: readColumns?.call()),
    );
    final ok = await _guard(
      () => store.update(collectionKey, updated),
      again: saveChanges,
    );
    if (!ok) return;
    _replace(updated);
    _notify();
  }

  /// Saves the live query as a new view and makes it active. Null when the
  /// store failed; see [lastError].
  Future<SavedView?> saveAsNew(
    String name, {
    SavedViewScope scope = SavedViewScope.personal,
  }) async {
    SavedView? created;
    final ok = await _guard(
      () async => created = await store.create(
        collectionKey,
        SavedView(
          id: '',
          name: name,
          scope: scope,
          state: ViewState.from(collection.query, columns: readColumns?.call()),
        ),
      ),
      again: () => saveAsNew(name, scope: scope),
    );
    if (!ok) return null;
    _views = [..._views, created!];
    _activeId = created!.id;
    _notify();
    return created;
  }

  /// Renames [view] to [name].
  Future<void> rename(SavedView view, String name) async {
    final updated = view.copyWith(name: name);
    final ok = await _guard(
      () => store.update(collectionKey, updated),
      again: () => rename(view, name),
    );
    if (!ok) return;
    _replace(updated);
    _notify();
  }

  /// Saves a copy of [view] named [name], or by [nameForCopy], after the
  /// others.
  Future<void> duplicate(SavedView view, [String? name]) async {
    late SavedView copy;
    final ok = await _guard(
      () async => copy = await store.create(
        collectionKey,
        SavedView(
          id: '',
          name: name ?? nameForCopy(view.name),
          scope: view.scope,
          state: view.state,
        ),
      ),
      again: () => duplicate(view, name),
    );
    if (!ok) return;
    _views = [..._views, copy];
    _notify();
  }

  /// Deletes [view]. When it was active, the default view takes its place,
  /// or no view ([clearView]) when there is none.
  Future<void> delete(SavedView view) async {
    final ok = await _guard(
      () => store.delete(collectionKey, view.id),
      again: () => delete(view),
    );
    if (!ok) return;
    _views = _views.where((v) => v.id != view.id).toList();
    if (_activeId == view.id) {
      final next = _views.firstWhereOrNull((v) => v.isDefault);
      if (next == null) {
        _clear();
      } else {
        _activeId = next.id;
        _apply(next);
      }
    }
    _notify();
  }

  Future<void> setDefault(SavedView view) async {
    final ok = await _guard(
      () => store.setDefault(collectionKey, view.id),
      again: () => setDefault(view),
    );
    if (!ok) return;
    _views = [for (final v in _views) v.copyWith(isDefault: v.id == view.id)];
    _notify();
  }

  /// Puts the views in the order of [ids] at once, then persists it; a view
  /// missing from [ids] keeps its place after the listed ones. Rolled back if
  /// the store fails.
  Future<void> reorder(List<String> ids) async {
    final before = _views;
    int rank(SavedView v) {
      final i = ids.indexOf(v.id);
      return i < 0 ? ids.length + before.indexOf(v) : i;
    }

    final ordered = [...before]..sort((a, b) => rank(a).compareTo(rank(b)));
    _views = [for (final (i, v) in ordered.indexed) v.copyWith(position: i)];
    _notify();
    final ok = await _guard(
      () => store.reorder(collectionKey, [for (final v in _views) v.id]),
      again: () => reorder(ids),
    );
    if (ok || _disposed) return;
    _views = before;
    _notify();
  }

  /// Moves [view] [delta] places along the list (negative is earlier),
  /// clamped to its ends.
  Future<void> move(SavedView view, int delta) {
    final ids = [for (final v in _views) v.id];
    final from = ids.indexOf(view.id);
    if (from < 0) return Future.value();
    final to = (from + delta).clamp(0, ids.length - 1);
    if (to == from) return Future.value();
    ids
      ..removeAt(from)
      ..insert(to, view.id);
    return reorder(ids);
  }

  void _apply(SavedView view) {
    collection.applyView(
      filters: view.state.filters,
      sortKey: view.state.sortKey,
      ascending: view.state.ascending,
      pageSize: view.state.pageSize,
    );
    writeColumns?.call(view.state.columns);
  }

  void _replace(SavedView view) =>
      _views = [for (final v in _views) v.id == view.id ? view : v];

  @override
  void dispose() {
    _disposed = true;
    collection.removeListener(notifyListeners);
    super.dispose();
  }
}
