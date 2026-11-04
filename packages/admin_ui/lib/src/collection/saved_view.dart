import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'collection_controller.dart';
import 'column_layout.dart';
import 'filter.dart';

const _eq = DeepCollectionEquality();

/// Schema version of the persisted [ViewState] payload. Stored in
/// [ViewState.toJson] so a future decoder can detect and migrate older blobs.
const savedViewSchemaVersion = 1;

/// Who a saved view belongs to. [personal] is private to the user; [shared] is
/// visible to the whole team.
enum SavedViewScope { personal, shared }

/// The persistable slice of a [CollectionQuery] — what a saved view captures.
/// Deliberately excludes [CollectionQuery.search] and the page index (both
/// transient). [pageSize] is optional: when null it isn't compared for dirtiness
/// (a view that doesn't pin rows-per-page).
@immutable
class ViewState {
  final List<FilterCondition> filters;
  final FieldId? sortKey;
  final bool ascending;
  final int? pageSize;

  /// The table's column layout (order + hidden). Null when the view doesn't pin
  /// columns — presentation, not query, so it's excluded from [matchesQuery].
  final ColumnLayout? columns;

  const ViewState({
    this.filters = const [],
    this.sortKey,
    this.ascending = true,
    this.pageSize,
    this.columns,
  });

  factory ViewState.from(CollectionQuery q, {ColumnLayout? columns}) =>
      ViewState(
        filters: q.filters,
        sortKey: q.sortKey,
        ascending: q.ascending,
        pageSize: q.pageSize,
        columns: columns,
      );

  ViewState withColumns(ColumnLayout? columns) => ViewState(
    filters: filters,
    sortKey: sortKey,
    ascending: ascending,
    pageSize: pageSize,
    columns: columns,
  );

  Map<String, dynamic> toJson() => {
    'version': savedViewSchemaVersion,
    'filters': _filtersJson(filters),
    if (sortKey != null) 'sortKey': sortKey,
    'ascending': ascending,
    if (pageSize != null) 'pageSize': pageSize,
    if (columns != null) 'columns': columns!.toJson(),
  };

  factory ViewState.fromJson(Map<String, dynamic> json) => ViewState(
    filters: [
      for (final f in (json['filters'] as List? ?? const []))
        filterConditionFromJson((f as Map).cast<String, dynamic>()),
    ].whereType<FilterCondition>().toList(),
    sortKey: json['sortKey'] as FieldId?,
    ascending: json['ascending'] as bool? ?? true,
    pageSize: json['pageSize'] as int?,
    columns: json['columns'] == null
        ? null
        : ColumnLayout.fromJson(
            (json['columns'] as Map).cast<String, dynamic>(),
          ),
  );

  /// True when [q] still matches this view — the inverse of "dirty". Compares
  /// sort and filters always; direction only when a sort key is set (it's
  /// meaningless without one); page size only when this view pins one.
  bool matchesQuery(CollectionQuery q) {
    if (sortKey != q.sortKey) return false;
    if (sortKey != null && ascending != q.ascending) return false;
    if (pageSize != null && pageSize != q.pageSize) return false;
    return _eq.equals(_filtersJson(filters), _filtersJson(q.filters));
  }

  /// Canonical (field-sorted, label-free) JSON for a filter list, so comparison
  /// is order-independent and unaffected by a filter's display label — which is
  /// presentation, not query identity, and is re-derived at render time.
  static List<Map<String, dynamic>> _filtersJson(List<FilterCondition> fs) => [
    for (final f in [...fs]..sort((a, b) => a.field.compareTo(b.field)))
      f.toJson()..remove('label'),
  ];
}

/// A named [ViewState] plus presentation metadata. Pure data — stored by a
/// [SavedViewsStore], rendered by a `SavedViewsBar`.
@immutable
class SavedView {
  final String id;
  final String name;
  final SavedViewScope scope;
  final ViewState state;
  final bool isDefault;
  final int position;

  const SavedView({
    required this.id,
    required this.name,
    this.scope = SavedViewScope.personal,
    this.state = const ViewState(),
    this.isDefault = false,
    this.position = 0,
  });

  SavedView copyWith({
    String? id,
    String? name,
    SavedViewScope? scope,
    ViewState? state,
    bool? isDefault,
    int? position,
  }) => SavedView(
    id: id ?? this.id,
    name: name ?? this.name,
    scope: scope ?? this.scope,
    state: state ?? this.state,
    isDefault: isDefault ?? this.isDefault,
    position: position ?? this.position,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'scope': scope.name,
    'state': state.toJson(),
    'isDefault': isDefault,
    'position': position,
  };

  factory SavedView.fromJson(Map<String, dynamic> json) => SavedView(
    id: json['id'] as String,
    name: json['name'] as String,
    scope:
        SavedViewScope.values.asNameMap()[json['scope']] ??
        SavedViewScope.personal,
    state: ViewState.fromJson(
      (json['state'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    isDefault: json['isDefault'] as bool? ?? false,
    position: json['position'] as int? ?? 0,
  );
}

/// Storage for a collection's saved views, keyed by an opaque `collectionKey`
/// (e.g. `'products'`). The package ships [InMemorySavedViewsStore]; projects
/// implement this against prefs (local) or a server table (synced / shared).
///
/// Any call may throw; `SavedViewsController` catches and reports it.
abstract interface class SavedViewsStore {
  /// The views in display order ([SavedView.position]).
  Future<List<SavedView>> list(String collectionKey);
  Future<SavedView> create(String collectionKey, SavedView view);
  Future<void> update(String collectionKey, SavedView view);
  Future<void> delete(String collectionKey, String id);
  Future<void> setDefault(String collectionKey, String id);

  /// Persists a new display order: [ids] lists every view of the collection,
  /// first to last, and each view's [SavedView.position] becomes its index.
  Future<void> reorder(String collectionKey, List<String> ids);
}

/// An in-memory [SavedViewsStore] for demos and tests. Persists each view as
/// JSON (and decodes on read) so it genuinely exercises the codec, and simulates
/// a round-trip [latency].
class InMemorySavedViewsStore implements SavedViewsStore {
  final Duration latency;
  final Map<String, List<Map<String, dynamic>>> _data = {};
  int _seq = 0;

  InMemorySavedViewsStore({
    Map<String, List<SavedView>> seed = const {},
    this.latency = const Duration(milliseconds: 220),
  }) {
    seed.forEach((key, views) {
      _data[key] = [for (final v in views) v.toJson()];
    });
  }

  List<Map<String, dynamic>> _bucket(String key) =>
      _data.putIfAbsent(key, () => []);

  Future<R> _io<R>(R Function() body) async {
    await Future<void>.delayed(latency);
    return body();
  }

  @override
  Future<List<SavedView>> list(String collectionKey) => _io(
    () =>
        [for (final j in _bucket(collectionKey)) SavedView.fromJson(j)]
          ..sort((a, b) => a.position.compareTo(b.position)),
  );

  @override
  Future<SavedView> create(String collectionKey, SavedView view) => _io(() {
    final bucket = _bucket(collectionKey);
    final created = view.copyWith(
      id: 'view-${++_seq}',
      position: bucket.length,
    );
    bucket.add(created.toJson());
    return created;
  });

  @override
  Future<void> update(String collectionKey, SavedView view) => _io(() {
    final bucket = _bucket(collectionKey);
    final i = bucket.indexWhere((j) => j['id'] == view.id);
    if (i >= 0) bucket[i] = view.toJson();
  });

  @override
  Future<void> delete(String collectionKey, String id) =>
      _io(() => _bucket(collectionKey).removeWhere((j) => j['id'] == id));

  @override
  Future<void> setDefault(String collectionKey, String id) => _io(() {
    for (final j in _bucket(collectionKey)) {
      j['isDefault'] = j['id'] == id;
    }
  });

  /// A view missing from [ids] keeps its place after the listed ones.
  @override
  Future<void> reorder(String collectionKey, List<String> ids) => _io(() {
    final bucket = _bucket(collectionKey);
    int rank(Map<String, dynamic> j) {
      final i = ids.indexOf(j['id'] as String);
      return i < 0 ? ids.length + (j['position'] as int? ?? 0) : i;
    }

    final ordered = [...bucket]..sort((a, b) => rank(a).compareTo(rank(b)));
    for (final (i, j) in ordered.indexed) {
      j['position'] = i;
    }
  });
}
