/// @docImport 'ui/bulk_action_bar.dart';
/// @docImport 'ui/filter_bar.dart';
library;

import 'package:collection/collection.dart';

import 'collection_controller.dart';
import 'filter.dart';
import 'ui/filter_bar.dart' show FilterOption;

/// The [CollectionFetcher] for rows already in memory — a list loaded whole,
/// or sample data. Answers every channel of a [CollectionQuery] itself:
/// [CollectionQuery.search], each [FilterCondition] variant, the sort and the
/// page.
///
/// [fields] reads a row's value for each [FieldId] — the same ids the columns'
/// sort keys and the [FilterBar]'s fields carry. [searchFields] narrows the
/// global search to some of them; by default it looks in every field.
///
/// Text sorts ignoring case and Latin accents, so "École" sorts among the
/// Es rather than after "z", the same in every locale. It is not a full
/// collator: other scripts keep their code-point order, and no language's
/// own rules apply (Swedish "ä" after "z", say). [compareText] plugs one in,
/// such as an ICU collator's compare; a source that cannot have one sorts on
/// the server.
///
/// ```dart
/// final source = LocalCollectionSource(products, fields: {
///   'name': (p) => p.name,
///   'status': (p) => p.status,
///   'price': (p) => p.price,
/// });
/// final controller = CollectionController(
///   fetcher: source.fetch,
///   rowKey: (p) => p.id,
/// );
/// ```
class LocalCollectionSource<T> {
  final List<T> rows;
  final Map<FieldId, Object? Function(T row)> fields;
  final Set<FieldId>? searchFields;

  /// How two texts sort, for a language's own order; null folds case and
  /// Latin accents away, the same in every locale.
  final int Function(String a, String b)? compareText;

  LocalCollectionSource(
    this.rows, {
    required this.fields,
    this.searchFields,
    this.compareText,
  });

  int _compare(Object a, Object b) => switch ((a, b)) {
    (String a, String b) => (compareText ?? _compareText)(a, b),
    _ => _compareValues(a, b),
  };

  int _compareNullsLast(Object? a, Object? b, bool ascending) {
    if (a == null || b == null) {
      if (a == b) return 0;
      return a == null ? 1 : -1;
    }
    return ascending ? _compare(a, b) : _compare(b, a);
  }

  /// One page of [matching], shaped for [CollectionController.fetcher].
  Future<CollectionPage<T>> fetch(CollectionQuery query) async {
    final all = matching(query);
    return CollectionPage(
      items: all
          .skip(query.pageIndex * query.pageSize)
          .take(query.pageSize)
          .toList(),
      total: all.length,
    );
  }

  /// Every row the query matches, sorted, across all pages — what a "select
  /// all {total}" in a [BulkActionBar] selects.
  List<T> matching(CollectionQuery query) {
    final search = query.search.trim().toLowerCase();
    final searched =
        searchFields?.map(_field).toList() ?? fields.values.toList();
    final filters = [
      for (final c in query.filters)
        if (c.isActive) (read: _field(c.field), condition: c),
    ];
    final result = [
      for (final row in rows)
        if ((search.isEmpty ||
                searched.any((read) => _text(read(row)).contains(search))) &&
            filters.every((f) => _accepts(f.condition, f.read(row))))
          row,
    ];
    if (query.sortKey case final key?) {
      final read = _field(key);
      // Merge sort is stable: rows that tie keep their order in [rows].
      mergeSort(
        result,
        compare: (a, b) => _compareNullsLast(read(a), read(b), query.ascending),
      );
    }
    return result;
  }

  /// The distinct values [field] takes across [rows], sorted, as the options
  /// of an `OptionsFilterField` — with the ids an [OptionsFilter] on it matches.
  List<FilterOption> options(
    FieldId field, {
    String Function(Object value)? label,
  }) {
    final read = _field(field);
    final values = <String, Object>{};
    for (final row in rows) {
      if (read(row) case final value?) {
        values.putIfAbsent(_optionId(value), () => value);
      }
    }
    final sorted = values.values.sorted(_compare);
    return [
      for (final value in sorted)
        FilterOption(_optionId(value), label?.call(value) ?? _optionId(value)),
    ];
  }

  // A condition on a field this source cannot read would otherwise pass every
  // row, and an unfiltered result is the worst answer a filter can give.
  Object? Function(T row) _field(FieldId id) =>
      fields[id] ??
      (throw ArgumentError.value(id, 'field', 'Not one of the source fields'));
}

bool _accepts(FilterCondition condition, Object? value) => switch (condition) {
  TextFilter(value: final text) => _text(
    value,
  ).contains(text.trim().toLowerCase()),
  OptionsFilter(:final selected) =>
    value != null && selected.contains(_optionId(value)),
  NumberRangeFilter(:final min, :final max) =>
    value is num &&
        (min == null || value >= min) &&
        (max == null || value <= max),
  DateRangeFilter(:final from, :final to) =>
    value is DateTime &&
        (from == null || !value.isBefore(from)) &&
        (to == null || value.isBefore(_endOf(to))),
  BoolFilter(value: final wanted) => value == wanted,
};

// The filter bar's date editor picks days, so a bare date as the upper bound
// means that whole day rather than its first instant.
DateTime _endOf(DateTime to) {
  final isDate =
      to.hour == 0 &&
      to.minute == 0 &&
      to.second == 0 &&
      to.millisecond == 0 &&
      to.microsecond == 0;
  if (!isDate) return to.add(const Duration(microseconds: 1));
  return to.isUtc
      ? DateTime.utc(to.year, to.month, to.day + 1)
      : DateTime(to.year, to.month, to.day + 1);
}

String _text(Object? value) => switch (value) {
  null => '',
  Enum() => value.name.toLowerCase(),
  _ => '$value'.toLowerCase(),
};

String _optionId(Object value) => value is Enum ? value.name : '$value';

int _compareValues(Object a, Object b) => switch ((a, b)) {
  (String a, String b) => _compareText(a, b),
  (bool a, bool b) => a == b ? 0 : (a ? 1 : -1),
  (Enum a, Enum b) => a.index.compareTo(b.index),
  (Comparable a, Comparable b) => a.compareTo(b),
  _ => '$a'.compareTo('$b'),
};

/// [a] against [b] with case and Latin accents folded away, then — so that
/// strings differing only in those still have an order — as they are.
int _compareText(String a, String b) {
  final folded = compareAsciiLowerCase(_fold(a), _fold(b));
  return folded != 0 ? folded : a.compareTo(b);
}

/// [text] with the letters of Latin-1 and Latin Extended-A reduced to their
/// ASCII base: "Émilie" → "Emilie", "Łódź" → "Lodz", "Straße" → "Strasse".
String _fold(String text) {
  if (!text.codeUnits.any((u) => u >= 0xC0 && u < 0x180)) return text;
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    out.write(_folds[unit] ?? String.fromCharCode(unit));
  }
  return out.toString();
}

final Map<int, String> _folds = {
  for (var i = 0; i < _accented.length; i++)
    _accented.codeUnitAt(i): _unaccented[i],
  for (final MapEntry(:key, :value) in const {
    'Æ': 'AE',
    'æ': 'ae',
    'Œ': 'OE',
    'œ': 'oe',
    'ß': 'ss',
    'Þ': 'TH',
    'þ': 'th',
    'Ĳ': 'IJ',
    'ĳ': 'ij',
    'ŉ': 'n',
  }.entries)
    key.codeUnitAt(0): value,
};

// Parallel: each letter of [_accented] folds to the one at its index here.
const _accented =
    'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝàáâãäåçèéêëìíîïðñòóôõöøùúûüýÿĀāĂ'
    'ăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀ'
    'ŁłŃńŅņŇňŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſ';
const _unaccented =
    'AAAAAACEEEEIIIIDNOOOOOOUUUUYaaaaaaceeeeiiiidnoooooouuuuyyAaA'
    'aAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiIiJjKkkLlLlLlLl'
    'LlNnNnNnOoOoOoRrRrRrSsSsSsSsTtTtTtUuUuUuUuUuUuWwYyYZzZzZzs';
