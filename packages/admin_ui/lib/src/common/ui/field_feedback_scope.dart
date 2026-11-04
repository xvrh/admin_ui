import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

/// How the fields beneath it present their validation, as a form engine
/// (the forms layer's `ValueForm`) knows it: the field shells and labeled
/// fields read it, so the engine reaches them without either depending on it.
///
/// - [reserveErrorLine] keeps the room of a one-line message under every
///   field while it has none, so a message appearing on validation does not
///   push the rest of the form down, and a field no rule checks ends as far
///   from the next one as a field that has a rule. A field's own setting
///   wins. A `FormGrid` beneath closes its default row gap by the 8 above
///   that line, so the fields stay a row gap and one line apart.
/// - [pending] holds the ids of the fields whose value is being checked
///   asynchronously (a uniqueness check against a server, say); such a
///   field says so in its message line.
/// - [markOptional] says the form declares which of its fields are
///   required, in the themes that mark the optional fields rather than the
///   required ones: a field of [validated] that is not required is marked
///   optional, and every other field is left bare, as the form's required
///   ones are. Outside such a form a field that is not marked required may
///   simply not have said.
///
/// Keyed by field id (a `Cell.id`): a field whose own pending state changed
/// rebuilds, and the others do not.
class FieldFeedbackScope extends InheritedModel<String> {
  final bool reserveErrorLine;

  /// The ids of the fields the form validates, when it knows them; null
  /// takes every field as validated. Only these can be marked optional.
  final Set<String>? validated;

  final Set<String> pending;
  final bool markOptional;

  const FieldFeedbackScope({
    super.key,
    this.reserveErrorLine = false,
    this.validated,
    this.pending = const {},
    this.markOptional = false,
    required super.child,
  });

  // Aspects for the form-wide flags. A field id is a cell id, which never
  // starts with a NUL.
  static const _reserveAspect = '\u0000reserveErrorLine';
  static const _optionalAspect = '\u0000markOptional';

  /// Whether the nearest scope reserves a message line under its fields;
  /// false outside any.
  static bool reserveErrorLineOf(BuildContext context) =>
      InheritedModel.inheritFrom<FieldFeedbackScope>(
        context,
        aspect: _reserveAspect,
      )?.reserveErrorLine ??
      false;

  bool _validates(String id) => validated?.contains(id) ?? true;

  /// Whether the field [id] is being checked under the nearest scope.
  static bool isPending(BuildContext context, String id) =>
      InheritedModel.inheritFrom<FieldFeedbackScope>(
        context,
        aspect: id,
      )?.pending.contains(id) ??
      false;

  /// Whether the nearest scope's form declares its required fields, so a
  /// field is marked optional rather than required; false outside any.
  static bool markOptionalOf(BuildContext context) =>
      InheritedModel.inheritFrom<FieldFeedbackScope>(
        context,
        aspect: _optionalAspect,
      )?.markOptional ??
      false;

  /// Whether the nearest scope's form validates the field [id], so it knows
  /// whether the field is required; false outside any.
  static bool validates(BuildContext context, String id) =>
      InheritedModel.inheritFrom<FieldFeedbackScope>(
        context,
        aspect: id,
      )?._validates(id) ??
      false;

  @override
  bool updateShouldNotify(FieldFeedbackScope old) =>
      reserveErrorLine != old.reserveErrorLine ||
      markOptional != old.markOptional ||
      !setEquals(validated, old.validated) ||
      !setEquals(pending, old.pending);

  @override
  bool updateShouldNotifyDependent(
    FieldFeedbackScope old,
    Set<String> dependencies,
  ) => dependencies.any(
    (aspect) => switch (aspect) {
      _reserveAspect => reserveErrorLine != old.reserveErrorLine,
      _optionalAspect => markOptional != old.markOptional,
      final id =>
        pending.contains(id) != old.pending.contains(id) ||
            _validates(id) != old._validates(id),
    },
  );
}
