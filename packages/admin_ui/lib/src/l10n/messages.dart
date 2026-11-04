import 'package:intl/intl.dart';

/// The base of every set of the kit's strings: [AdminLocalizations] and
/// each of its sections.
///
/// A message that counts something picks its form with [plural], under the
/// CLDR rules of [localeName], and prints the count with [number]; it never
/// tests `n == 1` or appends an 's'. A message with a value in it takes the
/// value as a parameter and places it itself, since word order differs
/// between languages: `String selected(int count)`, not a prefix the caller
/// concatenates.
abstract class AdminMessages {
  const AdminMessages(this.localeName);

  /// The intl locale the messages are written in, such as 'en', 'fr' or
  /// 'ar'. It picks the plural rules and the digits of [number].
  final String localeName;

  /// One of the forms for [count], chosen by the plural rules of
  /// [localeName]. [other] is required; a form a language does not use is
  /// left out, and a missing one falls back to [other].
  ///
  /// An exact 0, 1 or 2 takes [zero], [one] or [two] when given, even where
  /// the language's rules do not distinguish it: English has no zero
  /// category, but `zero: 'No items'` still reads better than '0 items'.
  /// Arabic uses all six forms: 0 zero, 1 one, 2 two, 3–10 few, 11–99 many,
  /// 100 and above other.
  String plural(
    num count, {
    String? zero,
    String? one,
    String? two,
    String? few,
    String? many,
    required String other,
  }) => Intl.plural(
    count,
    zero: zero,
    one: one,
    two: two,
    few: few,
    many: many,
    other: other,
    locale: localeName,
  );

  /// [value] in the digits and separators of [localeName]: 1,234.5 in
  /// English, 1 234,5 in French.
  String number(num value) =>
      NumberFormat.decimalPattern(localeName).format(value);
}
