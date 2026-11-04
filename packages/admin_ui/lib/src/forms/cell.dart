/// @docImport 'field_binder.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../assets/ui/image_cropper.dart' show CropValue;
import 'record_list_cell.dart';

export 'record_list_cell.dart' show RecordListCell;

/// The typed data port a form field binds to, carrying its field [id] so
/// capabilities (comments, history) can attach without the use site naming the
/// field. A field that takes a `Cell<V>` is statically typed on `V`.
///
/// Every field renders two kinds of cell: a [ValueCell], one value, and a
/// [TranslatedCell], one value per language. A new kind either implements
/// one of those, and every field renders it as it renders that kind, or
/// implements [Cell] itself and comes with a [FieldBinder], mounted in a
/// [FieldBinderScope] above the form, that renders it. A field given a cell
/// that neither the kit nor a binder renders throws.
abstract class Cell<V> {
  String get id;
}

/// A single reactive value.
abstract class ValueCell<V> extends Cell<V> implements ValueListenable<V> {
  void set(V value);
}

/// A per-language value: one [ValueCell] per lane. Translation is thus an
/// orthogonal axis over any [V] — a field renders one body (scalar) or one per
/// lane (translated), never a separate widget per type.
abstract class TranslatedCell<V> extends Cell<V> {
  ValueCell<V> lane(String lang);
}

/// A String lane that also exposes a live [controller] — needed for
/// collaborative text editing (cursor/IME over the lane's shared text). Only
/// the String path carries it, so it lives here, not on every [ValueCell].
abstract class TextCell extends ValueCell<String> {
  TextEditingController get controller;
}

/// One lane of a translated text field: a [TextCell] forwarding to its
/// [controller]. The controller IS the value; `value`/`set` are the non-editor
/// view (the editor binds the controller directly for live collab).
class TextLane implements TextCell {
  @override
  final String id;
  @override
  final TextEditingController controller;
  TextLane(this.id, this.controller);
  @override
  String get value => controller.text;
  @override
  void set(String v) => controller.text = v;
  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);
}

/// A first-class asset reference cell — a structured value whose parts are
/// independent sub-cells (so editing [crop] never clobbers a collaborator's
/// [alt]). Not a [Cell]: it composes a [ValueCell]/[TranslatedCell] surface
/// rather than holding one scalar. [assetId] is the attached asset's
/// `Asset.id` (null = unset), [alt] its per-usage translated text, [crop] the
/// cropper's value. A backend that stores integer ids adapts at its edge.
abstract class AssetRefCell {
  String get id;
  ValueCell<String?> get assetId;
  TranslatedCell<String> get alt;
  ValueCell<CropValue?> get crop;
}

/// Field-level and language-agnostic: it hands out cells by field name; the
/// translated cell owns the lanes. Backend (draft vs local) is chosen here,
/// once, and the scope owns every controller/notifier lifecycle. This is the
/// generic surface; a host app's own document kinds (regions, links,
/// relations to its records) live on a subtype of it.
abstract class FormScope {
  TranslatedCell<String> translated(String field);
  ValueCell<int> number(String field);

  /// A nullable number — `null` is the *unset* value (a cleared input), distinct
  /// from `0`, and round-trips as absent rather than zero.
  ValueCell<int?> numberOrNull(String field);
  ValueCell<String> text(String field);

  /// A nullable string — `null` is *unset* (a cleared input), distinct from `''`.
  ValueCell<String?> textOrNull(String field);
  ValueCell<bool> boolean(String field);

  /// A nullable bool — `null` is *unset* (the key absent), distinct from
  /// `false`, round-tripping as absent rather than false.
  ValueCell<bool?> booleanOrNull(String field);
  ValueCell<double> decimal(String field);

  /// A nullable double — `null` is *unset* (key absent), distinct from `0`.
  ValueCell<double?> decimalOrNull(String field);

  /// A date/time, stored as an ISO-8601 string in the underlying scalar.
  ValueCell<DateTime> date(String field);

  /// A nullable date/time — `null` is *unset* (key absent).
  ValueCell<DateTime?> dateOrNull(String field);

  /// An enum stored as its code string. [encode]/[decode] convert `E ⇄ code`
  /// (the project convention: `(e) => e.toJson()` / `E.fromJson`); [fallback] is
  /// the value when the key is absent (typically `E.values.first`).
  ValueCell<E> enumCell<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
    required E fallback,
  });

  /// A nullable enum — `null` is *unset* (key absent), distinct from [fallback].
  ValueCell<E?> enumCellOrNull<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
  });
  ValueCell<List<String>> list(String field);

  /// A string map, as a `KeyValueField` edits it: its entries in the order
  /// they were added, and empty while the key is absent.
  ValueCell<Map<String, String>> map(String field);

  /// A first-class asset reference (assetId + translated alt + crop), whose
  /// parts merge per-field.
  AssetRefCell assetRef(String field);

  /// An owned-record list, each element editable through the typed sub-handle
  /// [H] built from a [RecordScope]. A draft backend may narrow [build] to
  /// its richer element type; a record whose fields are all generic kinds works
  /// over any backend.
  RecordListCell<H> recordList<H>(
    String field, {
    required H Function(RecordScope) build,
  });

  /// A view of this scope whose keys are prefixed with `<prefix>.` — so a nested
  /// row's handle (`SeoFields`) can be reused across entities: the prefix lives
  /// here at runtime, not baked into the generated type.
  FormScope sub(String prefix);

  void dispose();
}

/// One owned-record element as a typed cell host: a [FormScope] rooted at one
/// element of a record list, plus [remove] for the row's own delete action. A
/// generated/hand-written record handle wraps this, so the same handle reads
/// nested sub-objects ([sub]) and nested owned lists ([recordList]) exactly
/// like a top-level scope.
abstract class RecordScope implements FormScope {
  String get id;

  /// Removes this element from its owning list.
  void remove();
}

/// A [FormScope] that prepends `<prefix>.` to every field key and delegates to
/// [parent] (which owns the cells, so this holds no state).
class _PrefixedScope implements FormScope {
  final FormScope parent;
  final String prefix;
  _PrefixedScope(this.parent, this.prefix);

  @override
  TranslatedCell<String> translated(String field) =>
      parent.translated('$prefix$field');
  @override
  ValueCell<int> number(String field) => parent.number('$prefix$field');
  @override
  ValueCell<int?> numberOrNull(String field) =>
      parent.numberOrNull('$prefix$field');
  @override
  ValueCell<String> text(String field) => parent.text('$prefix$field');
  @override
  ValueCell<String?> textOrNull(String field) =>
      parent.textOrNull('$prefix$field');
  @override
  ValueCell<bool> boolean(String field) => parent.boolean('$prefix$field');
  @override
  ValueCell<bool?> booleanOrNull(String field) =>
      parent.booleanOrNull('$prefix$field');
  @override
  ValueCell<double> decimal(String field) => parent.decimal('$prefix$field');
  @override
  ValueCell<double?> decimalOrNull(String field) =>
      parent.decimalOrNull('$prefix$field');
  @override
  ValueCell<DateTime> date(String field) => parent.date('$prefix$field');
  @override
  ValueCell<DateTime?> dateOrNull(String field) =>
      parent.dateOrNull('$prefix$field');
  @override
  ValueCell<E> enumCell<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
    required E fallback,
  }) => parent.enumCell(
    '$prefix$field',
    encode: encode,
    decode: decode,
    fallback: fallback,
  );
  @override
  ValueCell<E?> enumCellOrNull<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
  }) => parent.enumCellOrNull('$prefix$field', encode: encode, decode: decode);
  @override
  ValueCell<List<String>> list(String field) => parent.list('$prefix$field');
  @override
  ValueCell<Map<String, String>> map(String field) =>
      parent.map('$prefix$field');
  @override
  AssetRefCell assetRef(String field) => parent.assetRef('$prefix$field');
  @override
  RecordListCell<H> recordList<H>(
    String field, {
    required H Function(RecordScope) build,
  }) => parent.recordList('$prefix$field', build: build);
  @override
  FormScope sub(String p) => _PrefixedScope(parent, '$prefix$p.');
  @override
  void dispose() {}
}

// ── local backend: same interface; the cells ARE the state ──────────────────
class LocalScope implements FormScope {
  final _translated = <String, _LocalTranslatedCell>{};
  final _numbers = <String, _LocalNumber>{};
  @override
  TranslatedCell<String> translated(String field) =>
      _translated.putIfAbsent(field, () => _LocalTranslatedCell(field));
  final _nullableNumbers = <String, _LocalNullableNumber>{};
  final _strings = <String, _LocalString>{};
  final _nullableStrings = <String, _LocalNullableString>{};
  final _booleans = <String, _LocalBool>{};
  final _nullableBooleans = <String, _LocalNullableBool>{};
  final _decimals = <String, _LocalDouble>{};
  final _nullableDecimals = <String, _LocalNullableDouble>{};
  final _dates = <String, _LocalDate>{};
  final _nullableDates = <String, _LocalNullableDate>{};
  final _enums = <String, ValueNotifier>{};
  final _nullableEnums = <String, ValueNotifier>{};
  final _lists = <String, _LocalStringList>{};
  final _maps = <String, _LocalStringMap>{};
  final _relations = <String, _LocalIntList>{};
  final _records = <String, RecordListCell>{};
  final _assetRefs = <String, _LocalAssetRefCell>{};
  @override
  ValueCell<int> number(String field) =>
      _numbers.putIfAbsent(field, () => _LocalNumber(field));
  @override
  ValueCell<int?> numberOrNull(String field) =>
      _nullableNumbers.putIfAbsent(field, () => _LocalNullableNumber(field));
  @override
  ValueCell<String> text(String field) =>
      _strings.putIfAbsent(field, () => _LocalString(field));
  @override
  ValueCell<String?> textOrNull(String field) =>
      _nullableStrings.putIfAbsent(field, () => _LocalNullableString(field));
  @override
  ValueCell<bool> boolean(String field) =>
      _booleans.putIfAbsent(field, () => _LocalBool(field));
  @override
  ValueCell<bool?> booleanOrNull(String field) =>
      _nullableBooleans.putIfAbsent(field, () => _LocalNullableBool(field));
  @override
  ValueCell<double> decimal(String field) =>
      _decimals.putIfAbsent(field, () => _LocalDouble(field));
  @override
  ValueCell<double?> decimalOrNull(String field) =>
      _nullableDecimals.putIfAbsent(field, () => _LocalNullableDouble(field));
  @override
  ValueCell<DateTime> date(String field) =>
      _dates.putIfAbsent(field, () => _LocalDate(field));
  @override
  ValueCell<DateTime?> dateOrNull(String field) =>
      _nullableDates.putIfAbsent(field, () => _LocalNullableDate(field));
  @override
  ValueCell<E> enumCell<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
    required E fallback,
  }) =>
      _enums.putIfAbsent(field, () => _LocalEnum<E>(field, fallback))
          as ValueCell<E>;
  @override
  ValueCell<E?> enumCellOrNull<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
  }) =>
      _nullableEnums.putIfAbsent(field, () => _LocalNullableEnum<E>(field))
          as ValueCell<E?>;
  @override
  ValueCell<List<String>> list(String field) =>
      _lists.putIfAbsent(field, () => _LocalStringList(field));
  @override
  ValueCell<Map<String, String>> map(String field) =>
      _maps.putIfAbsent(field, () => _LocalStringMap(field));

  /// A set of related record ids, as a `ReferenceField` edits them.
  ValueCell<List<int>> relation(String field) =>
      _relations.putIfAbsent(field, () => _LocalIntList(field));
  @override
  AssetRefCell assetRef(String field) =>
      _assetRefs.putIfAbsent(field, () => _LocalAssetRefCell(field));
  @override
  RecordListCell<H> recordList<H>(
    String field, {
    required H Function(RecordScope) build,
  }) =>
      _records.putIfAbsent(field, () => _LocalRecordListCell<H>(field, build))
          as RecordListCell<H>;
  @override
  FormScope sub(String prefix) => _PrefixedScope(this, '$prefix.');
  @override
  void dispose() {
    for (final c in _translated.values) {
      c.dispose();
    }
    for (final n in _numbers.values) {
      n.dispose();
    }
    for (final n in _nullableNumbers.values) {
      n.dispose();
    }
    for (final s in _strings.values) {
      s.dispose();
    }
    for (final s in _nullableStrings.values) {
      s.dispose();
    }
    for (final b in _booleans.values) {
      b.dispose();
    }
    for (final b in _nullableBooleans.values) {
      b.dispose();
    }
    for (final d in _decimals.values) {
      d.dispose();
    }
    for (final d in _nullableDecimals.values) {
      d.dispose();
    }
    for (final d in _dates.values) {
      d.dispose();
    }
    for (final d in _nullableDates.values) {
      d.dispose();
    }
    for (final e in _enums.values) {
      e.dispose();
    }
    for (final e in _nullableEnums.values) {
      e.dispose();
    }
    for (final l in _lists.values) {
      l.dispose();
    }
    for (final m in _maps.values) {
      m.dispose();
    }
    for (final r in _relations.values) {
      r.dispose();
    }
    for (final r in _records.values) {
      r.dispose();
    }
    for (final a in _assetRefs.values) {
      a.dispose();
    }
  }
}

/// An in-memory asset reference: id, alt lanes and crop, each its own cell.
class _LocalAssetRefCell implements AssetRefCell {
  @override
  final String id;
  @override
  final _LocalNullableString assetId;
  @override
  final _LocalTranslatedCell alt;
  @override
  final _LocalCrop crop;

  _LocalAssetRefCell(this.id)
    : assetId = _LocalNullableString('$id/assetId'),
      alt = _LocalTranslatedCell('$id/alt'),
      crop = _LocalCrop('$id/crop');

  void dispose() {
    assetId.dispose();
    alt.dispose();
    crop.dispose();
  }
}

class _LocalCrop extends ValueNotifier<CropValue?>
    implements ValueCell<CropValue?> {
  @override
  final String id;
  _LocalCrop(this.id) : super(null);
  @override
  void set(CropValue? v) => value = v;
}

class _LocalString extends ValueNotifier<String> implements ValueCell<String> {
  @override
  final String id;
  _LocalString(this.id) : super('');
  @override
  void set(String v) => value = v;
}

class _LocalNullableNumber extends ValueNotifier<int?>
    implements ValueCell<int?> {
  @override
  final String id;
  _LocalNullableNumber(this.id) : super(null);
  @override
  void set(int? v) => value = v;
}

class _LocalNullableString extends ValueNotifier<String?>
    implements ValueCell<String?> {
  @override
  final String id;
  _LocalNullableString(this.id) : super(null);
  @override
  void set(String? v) => value = v;
}

class _LocalBool extends ValueNotifier<bool> implements ValueCell<bool> {
  @override
  final String id;
  _LocalBool(this.id) : super(false);
  @override
  void set(bool v) => value = v;
}

class _LocalDouble extends ValueNotifier<double> implements ValueCell<double> {
  @override
  final String id;
  _LocalDouble(this.id) : super(0);
  @override
  void set(double v) => value = v;
}

class _LocalNullableBool extends ValueNotifier<bool?>
    implements ValueCell<bool?> {
  @override
  final String id;
  _LocalNullableBool(this.id) : super(null);
  @override
  void set(bool? v) => value = v;
}

class _LocalNullableDouble extends ValueNotifier<double?>
    implements ValueCell<double?> {
  @override
  final String id;
  _LocalNullableDouble(this.id) : super(null);
  @override
  void set(double? v) => value = v;
}

class _LocalDate extends ValueNotifier<DateTime>
    implements ValueCell<DateTime> {
  @override
  final String id;
  _LocalDate(this.id) : super(_epoch);
  @override
  void set(DateTime v) => value = v;
}

class _LocalNullableDate extends ValueNotifier<DateTime?>
    implements ValueCell<DateTime?> {
  @override
  final String id;
  _LocalNullableDate(this.id) : super(null);
  @override
  void set(DateTime? v) => value = v;
}

class _LocalEnum<E> extends ValueNotifier<E> implements ValueCell<E> {
  @override
  final String id;
  _LocalEnum(this.id, E fallback) : super(fallback);
  @override
  void set(E v) => value = v;
}

class _LocalNullableEnum<E> extends ValueNotifier<E?> implements ValueCell<E?> {
  @override
  final String id;
  _LocalNullableEnum(this.id) : super(null);
  @override
  void set(E? v) => value = v;
}

class _LocalStringList extends ValueNotifier<List<String>>
    implements ValueCell<List<String>> {
  @override
  final String id;
  _LocalStringList(this.id) : super(const []);
  @override
  void set(List<String> v) => value = v;
}

/// Holds an unmodifiable copy of each map it is given, so a baseline taken
/// of it cannot change under the form.
class _LocalStringMap extends ValueNotifier<Map<String, String>>
    implements ValueCell<Map<String, String>> {
  @override
  final String id;
  _LocalStringMap(this.id) : super(const {});
  @override
  void set(Map<String, String> v) => value = Map.unmodifiable(v);
}

class _LocalIntList extends ValueNotifier<List<int>>
    implements ValueCell<List<int>> {
  @override
  final String id;
  _LocalIntList(this.id) : super(const []);
  @override
  void set(List<int> v) => value = v;
}

class _LocalTranslatedCell extends TranslatedCell<String> {
  @override
  final String id;
  final _lanes = <String, TextLane>{};
  _LocalTranslatedCell(this.id);
  @override
  TextCell lane(String lang) => _lanes.putIfAbsent(
    lang,
    () => TextLane('$id/$lang', TextEditingController()),
  );
  void dispose() {
    for (final c in _lanes.values) {
      c.controller.dispose();
    }
  }
}

class _LocalNumber extends ValueNotifier<int> implements ValueCell<int> {
  @override
  final String id;
  _LocalNumber(this.id) : super(0);
  @override
  void set(int v) => value = v;
}

/// Local backend for an owned-record list: plain in-memory rows, each field a
/// lazily-created local cell — the LocalScope counterpart of a collaborative
/// backend's record list. Notifies on structural change (add/remove/move)
/// only, so the repeater rebuilds without churning per keystroke. Removed
/// elements' cells stay cached until dispose (safe against teardown-frame
/// reads, matching the draft backend).
class _LocalRecordListCell<H> extends ChangeNotifier
    implements RecordListCell<H> {
  _LocalRecordListCell(this.id, this._build);

  @override
  final String id;
  final H Function(RecordScope) _build;
  final _ids = <String>[];
  final _cells = <String, Object>{};
  var _counter = 0;

  @override
  List<H> get elements => [
    for (final eid in _ids) _build(_LocalRecordElement(this, eid)),
  ];

  @override
  void add() {
    _ids.add('r${DateTime.now().microsecondsSinceEpoch}-${_counter++}');
    notifyListeners();
  }

  @override
  void removeAt(int index) {
    _ids.removeAt(index);
    notifyListeners();
  }

  @override
  void move(int from, int to) {
    _ids.insert(to, _ids.removeAt(from));
    notifyListeners();
  }

  void _removeById(String eid) {
    if (_ids.remove(eid)) notifyListeners();
  }

  T _memo<T extends Object>(String eid, String f, T Function() create) =>
      _cells.putIfAbsent('$eid/$f', create) as T;

  @override
  void dispose() {
    for (final c in _cells.values) {
      if (c is ChangeNotifier) {
        c.dispose();
      } else if (c is _LocalTranslatedCell) {
        c.dispose();
      } else if (c is _LocalAssetRefCell) {
        c.dispose();
      }
    }
    super.dispose();
  }
}

/// One element of a [_LocalRecordListCell], seen as a [RecordScope]: each field
/// is a memoized local cell keyed by the element's stable id, so a handle read
/// across [RecordListCell.elements] rebuilds lands on the same cell.
class _LocalRecordElement implements RecordScope {
  _LocalRecordElement(this._list, this.id);
  final _LocalRecordListCell _list;
  @override
  final String id;

  String get _base => '${_list.id}/$id';

  @override
  ValueCell<String> text(String f) =>
      _list._memo(id, f, () => _LocalString('$_base/$f'));
  @override
  ValueCell<String?> textOrNull(String f) =>
      _list._memo(id, f, () => _LocalNullableString('$_base/$f'));
  @override
  ValueCell<int> number(String f) =>
      _list._memo(id, f, () => _LocalNumber('$_base/$f'));
  @override
  ValueCell<int?> numberOrNull(String f) =>
      _list._memo(id, f, () => _LocalNullableNumber('$_base/$f'));
  @override
  ValueCell<bool> boolean(String f) =>
      _list._memo(id, f, () => _LocalBool('$_base/$f'));
  @override
  ValueCell<bool?> booleanOrNull(String f) =>
      _list._memo(id, f, () => _LocalNullableBool('$_base/$f'));
  @override
  ValueCell<double> decimal(String f) =>
      _list._memo(id, f, () => _LocalDouble('$_base/$f'));
  @override
  ValueCell<double?> decimalOrNull(String f) =>
      _list._memo(id, f, () => _LocalNullableDouble('$_base/$f'));
  @override
  ValueCell<DateTime> date(String f) =>
      _list._memo(id, f, () => _LocalDate('$_base/$f'));
  @override
  ValueCell<DateTime?> dateOrNull(String f) =>
      _list._memo(id, f, () => _LocalNullableDate('$_base/$f'));
  @override
  TranslatedCell<String> translated(String f) =>
      _list._memo(id, f, () => _LocalTranslatedCell('$_base/$f'));
  @override
  ValueCell<E> enumCell<E>(
    String f, {
    required String Function(E) encode,
    required E Function(String) decode,
    required E fallback,
  }) =>
      _list._memo(id, f, () => _LocalEnum<E>('$_base/$f', fallback))
          as ValueCell<E>;
  @override
  ValueCell<E?> enumCellOrNull<E>(
    String f, {
    required String Function(E) encode,
    required E Function(String) decode,
  }) =>
      _list._memo(id, f, () => _LocalNullableEnum<E>('$_base/$f'))
          as ValueCell<E?>;

  /// A nested owned list inside this element (e.g. a gallery's `items`).
  @override
  RecordListCell<R> recordList<R>(
    String f, {
    required R Function(RecordScope) build,
  }) =>
      _list._memo(id, f, () => _LocalRecordListCell<R>('$_base/$f', build))
          as RecordListCell<R>;

  /// A sub-object view: prefixes keys with `<prefix>.` so a nested group handle
  /// reads `<prefix>.<field>` on this element.
  @override
  FormScope sub(String prefix) => _PrefixedScope(this, '$prefix.');

  @override
  ValueCell<List<String>> list(String f) =>
      _list._memo(id, f, () => _LocalStringList('$_base/$f'));
  @override
  ValueCell<Map<String, String>> map(String f) =>
      _list._memo(id, f, () => _LocalStringMap('$_base/$f'));
  @override
  AssetRefCell assetRef(String f) =>
      _list._memo(id, f, () => _LocalAssetRefCell('$_base/$f'));

  /// No-op: the owning [_LocalRecordListCell] owns and disposes every cell.
  @override
  void dispose() {}

  @override
  void remove() => _list._removeById(id);
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
