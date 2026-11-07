import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../l10n/admin_ui_localizations.dart';
import 'cell.dart';

/// Checks one value of a field: the message that says what is wrong with
/// [value], in the words of [l10n], or null when it is valid.
typedef FieldValidator<V> = String? Function(V value, AdminLocalizations l10n);

/// Checks one value of a field where the answer takes a while, typically a
/// server's: the message, already in the user's language, or null when it
/// is valid.
typedef AsyncFieldValidator<V> = Future<String?> Function(V value);

/// The everyday [FieldValidator]s, each worded by `l10n.fields` unless it is
/// given its own [message].
///
/// Every one but [required] passes an empty value, so an optional field left
/// blank is valid; pair it with [required] to require the field.
abstract final class Validators {
  /// Fails an empty value: null, a text of nothing but whitespace, an empty
  /// list, set or map. `false` and `0` are values.
  ///
  /// A field whose rules hold it counts as required, and is marked so.
  static FieldValidator<V> required<V>({String? message}) {
    String? check(V value, AdminLocalizations l10n) =>
        isEmptyValue(value) ? message ?? l10n.fields.valueRequired : null;
    _required[check] = true;
    return check;
  }

  /// Fails a text shorter than [min] characters, as the user sees them.
  static FieldValidator<V> minLength<V>(int min, {String? message}) =>
      (value, l10n) => switch (value) {
        final String text when _filled(text) && text.characters.length < min =>
          message ?? l10n.fields.tooShort(min),
        _ => null,
      };

  /// Fails a text longer than [max] characters, as the user sees them.
  static FieldValidator<V> maxLength<V>(int max, {String? message}) =>
      (value, l10n) => switch (value) {
        final String text when text.characters.length > max =>
          message ?? l10n.fields.tooLong(max),
        _ => null,
      };

  /// Fails a text [pattern] has no match in. Anchor the pattern (`^…$`) to
  /// require the whole text to match.
  static FieldValidator<V> pattern<V>(RegExp pattern, {String? message}) =>
      (value, l10n) => switch (value) {
        final String text when _filled(text) && !pattern.hasMatch(text) =>
          message ?? l10n.fields.invalidFormat,
        _ => null,
      };

  /// Fails a text that is not an email address: something, an `@`, and a
  /// domain with a dot, with no spaces. The server has the last word.
  static FieldValidator<V> email<V>({String? message}) =>
      (value, l10n) => switch (value) {
        final String text when _filled(text) && !_email.hasMatch(text.trim()) =>
          message ?? l10n.fields.invalidEmail,
        _ => null,
      };

  /// Fails a text that is not an absolute http or https address with a host.
  static FieldValidator<V> url<V>({String? message}) =>
      (value, l10n) => switch (value) {
        final String text when _filled(text) && !_isWebAddress(text) =>
          message ?? l10n.fields.invalidUrl,
        _ => null,
      };

  /// Fails a number below [min].
  static FieldValidator<V> min<V>(num min, {String? message}) =>
      (value, l10n) => value is num && value < min
      ? message ?? l10n.fields.tooSmall(l10n.fields.number(min))
      : null;

  /// Fails a number above [max].
  static FieldValidator<V> max<V>(num max, {String? message}) =>
      (value, l10n) => value is num && value > max
      ? message ?? l10n.fields.tooLarge(l10n.fields.number(max))
      : null;

  static final _required = Expando<bool>();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool _isWebAddress(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static bool _filled(String text) => text.trim().isNotEmpty;
}

/// Whether [value] is what [Validators.required] fails: null, a text of
/// nothing but whitespace, or an empty collection.
@internal
bool isEmptyValue(Object? value) => switch (value) {
  null => true,
  final String text => text.trim().isEmpty,
  final Iterable<Object?> items => items.isEmpty,
  final Map<Object?, Object?> entries => entries.isEmpty,
  _ => false,
};

/// Whether [validator] is a [Validators.required].
@internal
bool isRequiredValidator(Function validator) =>
    Validators._required[validator] ?? false;

/// When a field's message shows. The field validates either way; this only
/// decides when the user is told.
enum ValidationMode {
  /// Once the field differs from the value the form started from (it stays
  /// shown if it is edited back), or after a submit attempt: the user is
  /// not told a field is wrong before touching it.
  onEdit,

  /// After a submit attempt only, then live as the user fixes each field.
  onSubmit,

  /// At once, pristine fields included.
  always,
}

/// A validation rule of a `ValueFormController`, filed under the field id of
/// the cell it is about.
sealed class ValidationRule {
  const ValidationRule();

  /// The id the rule's message is filed under, which the field showing it
  /// registers under too.
  String get fieldId;
}

/// A field's own rules: the sync [validators] run in order and the first
/// message wins; the [asyncValidators] run after them, only on a value the
/// sync ones pass, [debounce] after the last edit. A newer edit drops an
/// older check's answer, and while a check runs the field carries no message
/// and is pending. Either may be left out: a rule may only set
/// [visibleWhen].
///
/// [visibleWhen] hides the field while it returns false: a hidden field is
/// never validated, carries no message and is not required. It is asked
/// again whenever one of [dependsOn] notifies, or, when [dependsOn] is
/// empty, on any edit of the form.
///
/// A [TranslatedCell] is validated lane by lane over [lanes], which it
/// requires; the first failing lane's message is filed under the cell's id.
///
/// [id] files the message under another id than the cell's: an asset
/// reference validated through its `assetId` part files it under the
/// reference's, which its field registers under.
///
/// Inside a `rules` list, Dart can reach an async validator before it has
/// inferred `V` from the cell, and then types the validator's parameter as
/// `Object?`: type the parameter (`(String email) async => …`) or the rule
/// (`FieldRules<String>(…)`).
final class FieldRules<V> extends ValidationRule {
  final Cell<V> cell;
  final List<FieldValidator<V>> validators;
  final List<AsyncFieldValidator<V>> asyncValidators;
  final Duration debounce;
  final bool Function()? visibleWhen;
  final List<Listenable> dependsOn;
  final List<String>? lanes;

  @override
  final String fieldId;

  FieldRules(
    this.cell, {
    this.validators = const [],
    this.asyncValidators = const [],
    this.debounce = const Duration(milliseconds: 300),
    this.visibleWhen,
    Iterable<Listenable> dependsOn = const [],
    this.lanes,
    String? id,
  }) : assert(
         lanes != null || cell is! TranslatedCell<V>,
         'FieldRules of a translated cell name the lanes they validate: '
         'pass lanes:',
       ),
       dependsOn = List.unmodifiable(dependsOn),
       fieldId = id ?? cell.id;

  /// Whether [validators] hold a [Validators.required].
  bool get isRequired => validators.any(isRequiredValidator);

  /// Whether there are [asyncValidators].
  @internal
  bool get hasAsync => asyncValidators.isNotEmpty;

  /// The values validated: the cell's, or one per lane of [lanes].
  @internal
  List<V> readValues() {
    final cell = this.cell;
    if (cell is TranslatedCell<V>) {
      return [
        for (final lang in lanes ?? const <String>[]) cell.lane(lang).value,
      ];
    }
    return switch (cell) {
      final ValueListenable<V> listenable => [listenable.value],
      _ => const [],
    };
  }

  /// The first message [validators] give for [values], or null.
  @internal
  String? validate(List<V> values, AdminLocalizations l10n) {
    for (final value in values) {
      for (final validator in validators) {
        if (validator(value, l10n) case final message?) return message;
      }
    }
    return null;
  }

  /// The first message [asyncValidators] give for [values], or null. A check
  /// that throws passes: the server that failed to answer checks again on
  /// submit. An [Error] it throws is reported to [FlutterError.onError], so
  /// a bug in the check still shows.
  @internal
  Future<String?> validateAsync(List<V> values) async {
    for (final value in values) {
      for (final validator in asyncValidators) {
        try {
          if (await validator(value) case final message?) return message;
        } catch (error, stack) {
          if (error is Error) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stack,
                library: 'admin_ui forms',
                context: ErrorDescription('while checking a field'),
              ),
            );
          }
        }
      }
    }
    return null;
  }
}

/// How many items a list holds: at least [minItems], and at most [maxItems]
/// when there is one. [cell] is a record list (a `RecordListField`'s rows)
/// or a list value (tags, a multi-select, a reference field's links).
///
/// The message, [message] or else "Add at least 1 item" / "Keep at most 5
/// items" in the app's language, is filed under the list's id, where its
/// field shows it and a `ValidationSummary` links to it; a list whose
/// [minItems] is one or more counts as required, and is marked so. It is
/// checked again as rows are added and removed.
final class ListRules extends ValidationRule {
  final Cell<List<Object?>> cell;
  final int minItems;
  final int? maxItems;

  /// Replaces the built-in message, whichever bound the list misses.
  final String? message;

  ListRules(this.cell, {this.minItems = 1, this.maxItems, this.message})
    : assert(minItems >= 0, 'minItems counts items'),
      assert(
        maxItems == null || maxItems >= minItems,
        'maxItems is minItems or more',
      );

  @override
  String get fieldId => cell.id;

  /// Whether the list needs an item, which marks it required.
  bool get isRequired => minItems > 0;

  /// How many items [cell] holds now.
  @internal
  int count() => switch (cell) {
    final RecordListCell<Object?> list => list.elements.length,
    final ValueListenable<List<Object?>> list => list.value.length,
    _ => 0,
  };

  /// The message for a list of [count] items, or null when it is within
  /// bounds.
  @internal
  String? check(int count, AdminLocalizations l10n) {
    if (count < minItems) return message ?? l10n.fields.addAtLeast(minItems);
    final max = maxItems;
    if (max != null && count > max) {
      return message ?? l10n.fields.keepAtMost(max);
    }
    return null;
  }
}

/// A check across fields — a confirmation matching its password, an end
/// after its start — whose message is filed under [target]'s id. [check]
/// reads the cells it compares itself; [watch] names them. It runs after
/// [target]'s own sync rules pass, and its message shows when [target]'s
/// would: editing a watched field re-checks it, but reveals nothing.
final class FormRule extends ValidationRule {
  final List<Cell> watch;
  final Cell target;
  final String? Function(AdminLocalizations l10n) check;

  FormRule({
    required Iterable<Cell> watch,
    required this.target,
    required this.check,
  }) : watch = List.unmodifiable(watch);

  @override
  String get fieldId => target.id;
}

/// What a `ValueFormController`'s `onSubmit` throws when the server refuses
/// the value: [message] becomes the controller's `submitError` (shown by the
/// save status in place of its generic one) and each of [fieldErrors], keyed
/// by field id, shows under its field until the field is edited. Anything
/// else thrown becomes its `submitFailure`, which the save status words
/// through `ErrorTextScope`.
class FormSubmitException implements Exception {
  final String? message;
  final Map<String, String> fieldErrors;

  const FormSubmitException({this.message, this.fieldErrors = const {}});

  @override
  String toString() => [
    'FormSubmitException',
    ?message,
    if (fieldErrors.isNotEmpty) '$fieldErrors',
  ].join(': ');
}
