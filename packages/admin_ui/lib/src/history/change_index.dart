import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'diff_model.dart';

/// One field's pending change, reduced to what inline chrome renders: the
/// field marker, its changed lanes, per-record ops and per-block ops.
/// Value-equal, so a scope can tell whether a dependent's chrome actually
/// moved between two index generations.
@immutable
class FieldChangeSummary {
  final bool modified;

  /// Changed language codes. The language-agnostic axis is [shared], not a
  /// lane, so this set is what the "Edited · EN, FR" detail lists.
  final Set<String> lanes;

  /// A language-agnostic change: a scalar/binding/structure edit, or a
  /// translatable field's `''` lane (layout structure, asset binding).
  final bool shared;

  /// Record id → op, changed records only.
  final Map<String, DiffOp> records;

  /// Locale (`''` = shared lane) → block id → op, changed blocks only.
  final Map<String, Map<String, DiffOp>> blocks;

  const FieldChangeSummary({
    required this.modified,
    this.lanes = const {},
    this.shared = false,
    this.records = const {},
    this.blocks = const {},
  });

  static const none = FieldChangeSummary(modified: false);

  static const _setEq = SetEquality<String>();
  static const _deepEq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is FieldChangeSummary &&
      other.modified == modified &&
      other.shared == shared &&
      _setEq.equals(other.lanes, lanes) &&
      _deepEq.equals(other.records, records) &&
      _deepEq.equals(other.blocks, blocks);

  @override
  int get hashCode => Object.hash(
    modified,
    shared,
    _setEq.hash(lanes),
    _deepEq.hash(records),
    _deepEq.hash(blocks),
  );
}

/// Path-addressable lookup over one [VersionDiff]'s fields — the single source
/// every inline "differs from live" cue reads, so field markers, lane tints,
/// block decorations and the publish cockpit can never disagree.
///
/// Paths follow the form's cell-id convention: `field` for a top-level field,
/// `field/<recordId>` for one owned record, `field/<recordId>/child` for a
/// record's child field, nesting recursively.
class FieldChangeIndex {
  final List<FieldDiff> fields;

  FieldChangeIndex(this.fields)
    : _byKey = {for (final f in fields) f.fieldKey: f};

  static final empty = FieldChangeIndex(const []);

  final Map<String, FieldDiff> _byKey;
  final Map<String, FieldChangeSummary> _summaries = {};

  FieldChangeSummary summaryOf(String path) =>
      _summaries.putIfAbsent(path, () => _resolveSummary(path));

  /// The diff node at [path] — a top-level or record-child field. For rendering
  /// a field's quick diff; markers go through [summaryOf].
  FieldDiff? diffOf(String path) {
    final direct = _byKey[path];
    if (direct != null) return direct;
    return switch (_resolve(path)) {
      final FieldDiff f => f,
      _ => null,
    };
  }

  FieldChangeSummary _resolveSummary(String path) => switch (_resolve(path)) {
    final FieldDiff f => _summarize(f),
    final RecordChange r => _recordSummary(r),
    _ => FieldChangeSummary.none,
  };

  /// Walks `field/recordId/child/...` to the [FieldDiff] or [RecordChange] the
  /// path names, or null.
  Object? _resolve(String path) {
    final direct = _byKey[path];
    if (direct != null) return direct;
    final segs = path.split('/');
    FieldDiff? field = _byKey[segs.first];
    var i = 1;
    while (field != null && i < segs.length) {
      final rec = field.records.firstWhereOrNull((r) => r.id == segs[i]);
      if (rec == null) return null;
      i++;
      if (i == segs.length) return rec;
      field = rec.fields.firstWhereOrNull((f) => f.fieldKey == segs[i]);
      i++;
      if (i == segs.length) return field;
    }
    return field;
  }

  FieldChangeSummary _summarize(FieldDiff f) {
    if (!f.changed) return FieldChangeSummary.none;
    if (f.records.isNotEmpty) {
      final lanes = <String>{};
      var shared = false;
      final records = <String, DiffOp>{};
      for (final r in f.records) {
        if (!r.changed) continue;
        records[r.id] = r.op == DiffOp.unchanged ? DiffOp.changed : r.op;
        final (l, s) = _recordAxes(r);
        lanes.addAll(l);
        shared = shared || s;
      }
      return FieldChangeSummary(
        modified: true,
        lanes: lanes,
        shared: shared,
        records: records,
      );
    }
    final blocks = <String, Map<String, DiffOp>>{};
    for (final l in f.locales) {
      final ops = {
        for (final b in l.blocks)
          if (b.op != DiffOp.unchanged) b.id: b.op,
      };
      if (ops.isNotEmpty) blocks[l.locale] = ops;
    }
    return FieldChangeSummary(
      modified: true,
      lanes: {
        for (final l in f.locales)
          if (l.changed && l.locale.isNotEmpty) l.locale,
      },
      shared: f.translatable
          ? f.locales.any((l) => l.locale.isEmpty && l.changed)
          : f.locales.any((l) => l.changed),
      blocks: blocks,
    );
  }

  FieldChangeSummary _recordSummary(RecordChange r) {
    if (!r.changed) return FieldChangeSummary.none;
    final (lanes, shared) = _recordAxes(r);
    return FieldChangeSummary(modified: true, lanes: lanes, shared: shared);
  }

  /// A record's changed languages + whether it carries a shared change — a
  /// structural op (add/remove/reorder) or a language-agnostic child edit.
  /// Recurses into nested owned lists.
  (Set<String>, bool) _recordAxes(RecordChange r) {
    final lanes = <String>{};
    var shared = r.op != DiffOp.unchanged && r.op != DiffOp.changed;
    for (final f in r.fields) {
      if (!f.changed) continue;
      if (f.records.isNotEmpty) {
        for (final nested in f.records) {
          if (!nested.changed) continue;
          final (l, s) = _recordAxes(nested);
          lanes.addAll(l);
          shared = shared || s;
        }
      } else if (f.translatable) {
        for (final l in f.locales) {
          if (!l.changed) continue;
          if (l.locale.isEmpty) {
            shared = true;
          } else {
            lanes.add(l.locale);
          }
        }
      } else {
        shared = true;
      }
    }
    return (lanes, shared);
  }
}
