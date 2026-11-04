import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'ui/collection_table.dart';

const _eq = DeepCollectionEquality();

/// The presentation layout of a table's columns — their [order], which are
/// [hidden], their [widths] and [pins] — independent of the data query.
/// Persisted as part of a saved view and applied to a `List<TableColumn>` at
/// render time via [apply].
///
/// Forward-compatible by design: a key the layout has never seen (a column added
/// to the code after the layout was saved) appends after the known ones and is
/// visible by default, so new columns never silently disappear from old views.
@immutable
class ColumnLayout {
  /// Column keys in display order. Keys not listed here are unknown to the
  /// layout and sort after the known ones in their declared order.
  final List<String> order;

  /// Keys explicitly hidden. A key absent from both [order] and [hidden] is a
  /// new column — shown by default.
  final Set<String> hidden;

  /// Explicit pixel widths set by resizing, keyed by column key. A key absent
  /// keeps its declared (fixed/flex) sizing. Passed straight to
  /// `CollectionTable.columnWidths`.
  final Map<String, double> widths;

  /// Pinning the user chose, keyed by column key, over each column's
  /// declared [TableColumn.pinned]. A key absent keeps its declaration.
  final Map<String, bool> pins;

  const ColumnLayout({
    this.order = const [],
    this.hidden = const {},
    this.widths = const {},
    this.pins = const {},
  });

  /// The default layout for [columns]: declared order, nothing hidden.
  static ColumnLayout of<T>(List<TableColumn<T>> columns) =>
      ColumnLayout(order: [for (final c in columns) c.key]);

  bool isVisible(String key) => !hidden.contains(key);

  /// Whether the column [key] is pinned: as the user chose, else as
  /// [declared].
  bool isPinned(String key, {bool declared = false}) => pins[key] ?? declared;

  /// [columns] resolved against this layout: pinned per [pins], reordered to
  /// [order] (unknown keys appended in declared order), then filtered to the
  /// visible ones. Pinned columns still lead, in that order, wherever a column
  /// was moved: the table freezes only a leading run.
  List<TableColumn<T>> apply<T>(List<TableColumn<T>> columns) {
    final byKey = {
      for (final c in columns)
        c.key: c.withPinned(isPinned(c.key, declared: c.pinned)),
    };
    final seen = <String>{};
    final result = <TableColumn<T>>[];
    for (final key in order) {
      final col = byKey[key];
      if (col != null && seen.add(key)) result.add(col);
    }
    for (final col in columns) {
      if (seen.add(col.key)) result.add(byKey[col.key]!);
    }
    return [
      for (final c in result)
        if (c.pinned && isVisible(c.key)) c,
      for (final c in result)
        if (!c.pinned && isVisible(c.key)) c,
    ];
  }

  /// The full key list in display order — known keys first, then any new
  /// [columns] not yet in [order]. The canonical order the chooser edits.
  List<String> resolvedOrder<T>(List<TableColumn<T>> columns) {
    final keys = [for (final c in columns) c.key];
    final known = order.where(keys.contains);
    final fresh = keys.where((k) => !order.contains(k));
    return [...known, ...fresh];
  }

  ColumnLayout withVisible(String key, bool visible) => ColumnLayout(
    order: order,
    hidden: visible
        ? (hidden.where((k) => k != key).toSet())
        : {...hidden, key},
    widths: widths,
    pins: pins,
  );

  ColumnLayout withOrder(List<String> next) =>
      ColumnLayout(order: next, hidden: hidden, widths: widths, pins: pins);

  ColumnLayout withWidth(String key, double width) => ColumnLayout(
    order: order,
    hidden: hidden,
    widths: {...widths, key: width},
    pins: pins,
  );

  ColumnLayout withPinned(String key, bool pinned) => ColumnLayout(
    order: order,
    hidden: hidden,
    widths: widths,
    pins: {...pins, key: pinned},
  );

  Map<String, dynamic> toJson() => {
    'order': order,
    if (hidden.isNotEmpty) 'hidden': hidden.toList(),
    if (widths.isNotEmpty) 'widths': widths,
    if (pins.isNotEmpty) 'pins': pins,
  };

  factory ColumnLayout.fromJson(Map<String, dynamic> json) => ColumnLayout(
    order: [for (final k in (json['order'] as List? ?? const [])) k as String],
    hidden: {
      for (final k in (json['hidden'] as List? ?? const [])) k as String,
    },
    widths: {
      for (final e in (json['widths'] as Map? ?? const {}).entries)
        e.key as String: (e.value as num).toDouble(),
    },
    pins: {
      for (final e in (json['pins'] as Map? ?? const {}).entries)
        e.key as String: e.value as bool,
    },
  );

  @override
  bool operator ==(Object other) =>
      other is ColumnLayout &&
      _eq.equals(order, other.order) &&
      _eq.equals(hidden, other.hidden) &&
      _eq.equals(widths, other.widths) &&
      _eq.equals(pins, other.pins);

  @override
  int get hashCode => Object.hash(
    _eq.hash(order),
    _eq.hash(hidden),
    _eq.hash(widths),
    _eq.hash(pins),
  );
}
