import 'package:flutter/foundation.dart';

/// A stable string id for a sortable/filterable field. Declared once per
/// collection (ideally backed by an `enum`'s `.name` for an exhaustive fetcher
/// switch) and interpreted only by the fetcher. A string so the whole query
/// serializes — saved views, URL state, telemetry — with no codec.
typedef FieldId = String;

/// A single active filter condition. [field] is the [FieldId] the fetcher reads.
/// Values are typed per variant so the fetcher pattern-matches without casting.
@immutable
sealed class FilterCondition {
  final FieldId field;
  final String? label;
  const FilterCondition(this.field, {this.label});

  /// True when this condition carries a usable value (else it's a no-op the
  /// controller drops rather than sending).
  bool get isActive;
}

/// Free-text match on one field.
class TextFilter extends FilterCondition {
  final String value;
  const TextFilter(super.field, this.value, {super.label});
  @override
  bool get isActive => value.isNotEmpty;
}

/// Multi-select over a fixed option set; [selected] holds option ids.
class OptionsFilter extends FilterCondition {
  final Set<String> selected;
  const OptionsFilter(super.field, this.selected, {super.label});
  @override
  bool get isActive => selected.isNotEmpty;
}

/// Numeric range; either bound may be null (open-ended).
class NumberRangeFilter extends FilterCondition {
  final num? min;
  final num? max;
  const NumberRangeFilter(super.field, {this.min, this.max, super.label});
  @override
  bool get isActive => min != null || max != null;
}

/// Date range; either bound may be null (open-ended).
class DateRangeFilter extends FilterCondition {
  final DateTime? from;
  final DateTime? to;
  const DateRangeFilter(super.field, {this.from, this.to, super.label});
  @override
  bool get isActive => from != null || to != null;
}

/// A required boolean state.
class BoolFilter extends FilterCondition {
  final bool value;
  const BoolFilter(super.field, this.value, {super.label});
  @override
  bool get isActive => true;
}

/// Self-describing JSON for a condition — a `type` tag plus the [FieldId] and
/// the typed value. Lets a saved view / URL state round-trip with no registry.
extension FilterConditionJson on FilterCondition {
  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{
      'field': field,
      if (label != null) 'label': label,
    };
    return switch (this) {
      TextFilter(:final value) => {...base, 'type': 'text', 'value': value},
      OptionsFilter(:final selected) => {
        ...base,
        'type': 'options',
        'selected': selected.toList(),
      },
      NumberRangeFilter(:final min, :final max) => {
        ...base,
        'type': 'numberRange',
        'min': min,
        'max': max,
      },
      DateRangeFilter(:final from, :final to) => {
        ...base,
        'type': 'dateRange',
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
      },
      BoolFilter(:final value) => {...base, 'type': 'bool', 'value': value},
    };
  }
}

/// Rebuilds a condition from [FilterConditionJson.toJson]. Returns null for an
/// unknown `type` or a missing field, so a decoder drops conditions the schema
/// no longer recognises rather than throwing.
FilterCondition? filterConditionFromJson(Map<String, dynamic> json) {
  final field = json['field'] as FieldId?;
  if (field == null) return null;
  final label = json['label'] as String?;
  DateTime? parse(Object? v) =>
      v == null ? null : DateTime.tryParse(v as String);
  // An unknown `type` is dropped (returns null) so older clients tolerate
  // payloads a newer client wrote — the forward-compat contract. The version
  // field on the [ViewState] payload is the hook for an explicit migration if
  // an encoding ever changes incompatibly.
  return switch (json['type']) {
    'text' => TextFilter(field, json['value'] as String? ?? '', label: label),
    'options' => OptionsFilter(field, {
      ...?(json['selected'] as List?)?.cast<String>(),
    }, label: label),
    'numberRange' => NumberRangeFilter(
      field,
      min: json['min'] as num?,
      max: json['max'] as num?,
      label: label,
    ),
    'dateRange' => DateRangeFilter(
      field,
      from: parse(json['from']),
      to: parse(json['to']),
      label: label,
    ),
    'bool' => BoolFilter(field, json['value'] as bool? ?? false, label: label),
    _ => null,
  };
}
