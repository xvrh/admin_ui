import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Token colours for code and structured-data views (JSON, code fields). Read
/// through `context.colors.syntax`; every colour is text-safe (4.5:1) on the
/// palette's `surface` and `background`, so views don't reuse raw status
/// accents as text.
@immutable
class AdminSyntaxColors {
  /// Object keys and property names.
  final Color key;

  /// String literals.
  final Color string;

  /// Numeric literals.
  final Color number;

  /// `true`, `false` and `null` — a neutral hue, so they never read as errors.
  final Color literal;

  /// Brackets, commas, colons.
  final Color punctuation;

  /// Comments and elided values.
  final Color comment;

  const AdminSyntaxColors({
    required this.key,
    required this.string,
    required this.number,
    required this.literal,
    required this.punctuation,
    required this.comment,
  });

  static AdminSyntaxColors lerp(
    AdminSyntaxColors a,
    AdminSyntaxColors b,
    double t,
  ) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return AdminSyntaxColors(
      key: c(a.key, b.key),
      string: c(a.string, b.string),
      number: c(a.number, b.number),
      literal: c(a.literal, b.literal),
      punctuation: c(a.punctuation, b.punctuation),
      comment: c(a.comment, b.comment),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminSyntaxColors &&
      other.key == key &&
      other.string == string &&
      other.number == number &&
      other.literal == literal &&
      other.punctuation == punctuation &&
      other.comment == comment;

  @override
  int get hashCode =>
      Object.hash(key, string, number, literal, punctuation, comment);
}
