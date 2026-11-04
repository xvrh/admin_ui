import 'package:flutter/widgets.dart';

/// Lifecycle state of a point in an entity's version timeline.
enum VersionStatus { draft, current, published, restored, archived }

/// How one element changed between the base (left) and compare (right) sides of
/// a diff. Also tags runs inside an inline text diff, where only [unchanged],
/// [added] and [removed] occur.
enum DiffOp { unchanged, added, removed, changed, moved }

/// One point in an entity's version timeline — presentational; a Screen maps the
/// host's version archive onto it. Two of these are the endpoints of a
/// [VersionDiff].
@immutable
class VersionRef {
  final String id;

  /// Human label for the entry — "Reworded hero", "Published v4".
  final String label;
  final String author;
  final String initials;

  /// Avatar swatch; null derives a stable hue from [initials].
  final Color? color;

  /// Pre-formatted relative or absolute time — "2 hours ago", "Mar 4, 14:22".
  final String timestamp;
  final VersionStatus status;

  /// Monotonic version number, when the entry is an archived publish.
  final int? number;

  const VersionRef({
    required this.id,
    required this.label,
    required this.author,
    required this.initials,
    required this.timestamp,
    required this.status,
    this.color,
    this.number,
  });
}

/// A run of text within an inline diff, tagged with how it changed. [op] is one
/// of [DiffOp.unchanged], [DiffOp.added] or [DiffOp.removed].
@immutable
class DiffSegment {
  final String text;
  final DiffOp op;

  const DiffSegment(this.text, this.op);
}

/// Which renderer a [FieldDiff] picks: inline word diff for [text], a block
/// diff for [richText], a nested record diff for [recordList], a before→after
/// swap for the rest.
enum DiffFieldKind {
  text,
  richText,
  scalar,
  choice,
  media,
  reference,
  recordList,
}

/// One block's change inside a rich-body diff. Keyed by the stable block [id] so
/// a reorder is reported as a [DiffOp.moved], not a remove + add.
@immutable
class BlockChange {
  final String id;

  /// Block type — 'paragraph', 'heading_2', 'image', 'quote', …
  final String type;
  final DiffOp op;

  /// Plain-text content before; null when the block was [DiffOp.added].
  final String? before;

  /// Plain-text content after; null when the block was [DiffOp.removed].
  final String? after;

  /// Position before / after, when the block was [DiffOp.moved] (or changed
  /// and shifted).
  final int? fromIndex;
  final int? toIndex;

  /// Human one-liner for a block that carries no plain text (image filename,
  /// embed host, "Divider"…). Rendered in place of an empty [before]/[after].
  /// Null for ordinary text blocks, which diff via [before]/[after].
  final String? summary;

  const BlockChange({
    required this.id,
    required this.type,
    required this.op,
    this.before,
    this.after,
    this.fromIndex,
    this.toIndex,
    this.summary,
  });

  /// True when this block also shifted position (moved, or changed-and-shifted).
  bool get shifted =>
      fromIndex != null && toIndex != null && fromIndex != toIndex;
}

/// One field's change for one locale. For a non-translatable field there is a
/// single entry whose [locale] is empty. Text fields carry [before]/[after]
/// (the view word-diffs them); rich fields carry [blocks].
@immutable
class LocaleDiff {
  final String locale;
  final DiffOp op;

  /// Whole-value before/after, for text-like fields.
  final String? before;
  final String? after;

  /// Per-block changes, for rich-body fields.
  final List<BlockChange> blocks;

  const LocaleDiff({
    required this.locale,
    required this.op,
    this.before,
    this.after,
    this.blocks = const [],
  });

  bool get changed => op != DiffOp.unchanged;

  /// Counts of block ops, for a one-line summary ("2 added · 1 moved").
  Map<DiffOp, int> get blockCounts {
    final counts = <DiffOp, int>{};
    for (final b in blocks) {
      if (b.op == DiffOp.unchanged) continue;
      counts[b.op] = (counts[b.op] ?? 0) + 1;
    }
    return counts;
  }
}

/// A single field's change across one or more locales.
///
/// Built from its lanes, or from the field's two values by a factory that
/// works out each lane's op: [FieldDiff.text] for plain text, which the view
/// diffs word by word ([InlineDiff.words]), [FieldDiff.translated] for text
/// in several languages, and [FieldDiff.scalar] for any other value, compared
/// as the text it is shown as. A value that is null or empty is absent, so a
/// lane is [DiffOp.added] when only the compare side has one, [DiffOp.removed]
/// when only the base side does, and otherwise [DiffOp.changed] or
/// [DiffOp.unchanged] as the two differ or not.
@immutable
class FieldDiff {
  final String label;
  final String fieldKey;
  final DiffFieldKind kind;
  final bool translatable;

  /// Per-locale changes. A non-translatable field has one entry, locale ''.
  /// Empty for a [DiffFieldKind.recordList] field, which carries [records].
  final List<LocaleDiff> locales;

  /// Per-record changes, for a [DiffFieldKind.recordList] (owned `objectList`)
  /// field. Empty for every other kind.
  final List<RecordChange> records;

  const FieldDiff({
    required this.label,
    required this.fieldKey,
    required this.kind,
    required this.locales,
    this.translatable = false,
    this.records = const [],
  });

  /// A plain-text field under [key], from its [before] (base) and [after]
  /// (compare) values: one lane, which the view word-diffs.
  factory FieldDiff.text(
    String key,
    String label,
    String? before,
    String? after,
  ) => FieldDiff(
    label: label,
    fieldKey: key,
    kind: DiffFieldKind.text,
    locales: [_lane('', before, after)],
  );

  /// A translated text field under [key], from its values by locale code:
  /// one lane per language, each added, removed, changed or unchanged on its
  /// own.
  ///
  /// The lanes follow [locales], a lane for each even where neither side has
  /// a value, then any other code either map holds, so none is dropped.
  /// Without [locales] they follow [before]'s codes, then [after]'s new ones.
  factory FieldDiff.translated(
    String key,
    String label,
    Map<String, String?> before,
    Map<String, String?> after, {
    List<String>? locales,
  }) {
    final codes = {...?locales, ...before.keys, ...after.keys};
    return FieldDiff(
      label: label,
      fieldKey: key,
      kind: DiffFieldKind.text,
      translatable: true,
      locales: [
        for (final code in codes) _lane(code, before[code], after[code]),
      ],
    );
  }

  /// A field under [key] holding any other value — a number, a choice, a
  /// date, a list — from its [before] and [after] values, each shown as the
  /// text [format] gives it (its `toString()` without one). The op follows
  /// that text, as the reader sees it: two lists with the same items are
  /// unchanged, and a value whose text is empty is absent.
  ///
  /// [kind] tags what the value is — [DiffFieldKind.scalar],
  /// [DiffFieldKind.choice], [DiffFieldKind.media] or
  /// [DiffFieldKind.reference]; the view diffs each as its text.
  static FieldDiff scalar<T extends Object>(
    String key,
    String label,
    T? before,
    T? after, {
    String Function(T value)? format,
    DiffFieldKind kind = DiffFieldKind.scalar,
  }) {
    assert(
      const {
        DiffFieldKind.scalar,
        DiffFieldKind.choice,
        DiffFieldKind.media,
        DiffFieldKind.reference,
      }.contains(kind),
      'FieldDiff.scalar builds a one-value field; $kind has its own shape',
    );
    String? text(T? value) =>
        value == null ? null : (format?.call(value) ?? '$value');
    return FieldDiff(
      label: label,
      fieldKey: key,
      kind: kind,
      locales: [_lane('', text(before), text(after))],
    );
  }

  bool get changed =>
      locales.any((l) => l.changed) || records.any((r) => r.changed);

  Set<String> get changedLocales => {
    for (final l in locales)
      if (l.changed) l.locale,
  };

  /// The locales actually touched, in declaration order; falls back to all when
  /// nothing changed (so an unchanged field still renders its lanes).
  List<LocaleDiff> visibleLocales({bool onlyChanged = true}) =>
      onlyChanged && changed
      ? [
          for (final l in locales)
            if (l.changed) l,
        ]
      : locales;
}

/// One owned record's change inside a [DiffFieldKind.recordList] field. Keyed by
/// the stable record [id] so a reorder reads as [DiffOp.moved], not remove + add.
/// A record's children are themselves fields, so [fields] is recursive — a child
/// may be a translated lane, a rich body, or a nested record list.
@immutable
class RecordChange {
  final String id;
  final DiffOp op;

  /// Position before / after, when the record shifted.
  final int? fromIndex;
  final int? toIndex;

  /// Header label — the record's first text-ish child value, else "Item N".
  final String label;

  /// The record's child-field diffs.
  final List<FieldDiff> fields;

  const RecordChange({
    required this.id,
    required this.op,
    required this.label,
    required this.fields,
    this.fromIndex,
    this.toIndex,
  });

  bool get changed => op != DiffOp.unchanged || fields.any((f) => f.changed);

  bool get shifted =>
      fromIndex != null && toIndex != null && fromIndex != toIndex;
}

/// What a granular restore acts on: a whole field by [fieldKey], or — when
/// [recordId] is set — one record within that field's record list. The host
/// rewinds just this part of the draft to the base version.
@immutable
class RestoreTarget {
  final String fieldKey;
  final String? recordId;

  const RestoreTarget(this.fieldKey, {this.recordId});
}

/// A comparison between two [VersionRef] endpoints, decomposed per field and
/// per locale. The View renders this directly; a Screen / diff engine builds it
/// from two reconstructed entity snapshots.
@immutable
class VersionDiff {
  /// Older / left side.
  final VersionRef base;

  /// Newer / right side.
  final VersionRef compare;
  final List<FieldDiff> fields;

  /// Locale codes present across the diff, in display order (drives the filter).
  final List<String> locales;

  const VersionDiff({
    required this.base,
    required this.compare,
    required this.fields,
    this.locales = const [],
  });

  /// The diff from [base] to [compare] over [fields] — usually built with
  /// [FieldDiff.text], [FieldDiff.translated] and [FieldDiff.scalar] from the
  /// two records — in the order they are declared.
  ///
  /// Nothing is dropped: an unchanged field stays, for the view to show when
  /// the reader asks for unchanged fields. The [locales] are every language
  /// a translated field has a lane in, a record's fields included, in the
  /// order they first appear. Each field's [FieldDiff.fieldKey] must be
  /// unique, since a restore names the field by it.
  factory VersionDiff.of({
    required VersionRef base,
    required VersionRef compare,
    required List<FieldDiff> fields,
  }) {
    assert(
      fields.map((f) => f.fieldKey).toSet().length == fields.length,
      'VersionDiff.of: two fields share a key',
    );
    final locales = <String>{};
    void collect(Iterable<FieldDiff> fields) {
      for (final field in fields) {
        if (field.translatable) {
          for (final lane in field.locales) {
            if (lane.locale.isNotEmpty) locales.add(lane.locale);
          }
        }
        for (final record in field.records) {
          collect(record.fields);
        }
      }
    }

    collect(fields);
    return VersionDiff(
      base: base,
      compare: compare,
      fields: List.unmodifiable(fields),
      locales: List.unmodifiable(locales),
    );
  }

  bool get hasChanges => fields.any((f) => f.changed);

  int get changedFieldCount => fields.where((f) => f.changed).length;
}

/// The lane for [locale] between [before] and [after]; see [FieldDiff].
LocaleDiff _lane(String locale, String? before, String? after) {
  final had = before != null && before.isNotEmpty;
  final has = after != null && after.isNotEmpty;
  final op = switch ((had, has)) {
    (false, false) => DiffOp.unchanged,
    (false, true) => DiffOp.added,
    (true, false) => DiffOp.removed,
    (true, true) => before == after ? DiffOp.unchanged : DiffOp.changed,
  };
  return LocaleDiff(locale: locale, op: op, before: before, after: after);
}

/// Pure, deterministic inline diffing. No state, no I/O — safe to call at render
/// time or in a test.
abstract final class InlineDiff {
  /// Word-level diff: the segments that turn [before] into [after] — unchanged
  /// runs interleaved with [DiffOp.removed] (before-only) and [DiffOp.added]
  /// (after-only) runs. Tokenised on word / whitespace boundaries so spacing is
  /// preserved and edits land on whole words.
  static List<DiffSegment> words(String before, String after) {
    final a = _tokenize(before);
    final b = _tokenize(after);

    // LCS table over tokens.
    final n = a.length, m = b.length;
    final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        lcs[i][j] = a[i] == b[j]
            ? lcs[i + 1][j + 1] + 1
            : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
      }
    }

    final out = <DiffSegment>[];
    void emit(String text, DiffOp op) {
      if (text.isEmpty) return;
      if (out.isNotEmpty && out.last.op == op) {
        out[out.length - 1] = DiffSegment(out.last.text + text, op);
      } else {
        out.add(DiffSegment(text, op));
      }
    }

    var i = 0, j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        emit(a[i], DiffOp.unchanged);
        i++;
        j++;
      } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        emit(a[i], DiffOp.removed);
        i++;
      } else {
        emit(b[j], DiffOp.added);
        j++;
      }
    }
    while (i < n) {
      emit(a[i++], DiffOp.removed);
    }
    while (j < m) {
      emit(b[j++], DiffOp.added);
    }
    return out;
  }

  static final _token = RegExp(r'\s+|[^\s]+');

  static List<String> _tokenize(String s) => [
    for (final m in _token.allMatches(s)) m[0]!,
  ];
}
