import 'package:material_ui/material_ui.dart';

/// How the kit sets a theme's font family on the styles it draws.
///
/// By default the family is the style's `fontFamily`: drawn where the app
/// bundles it (`flutter: fonts:` in its pubspec), and in the platform's font
/// where it does not. The kit ships no font file and fetches none.
///
/// To load a family another way, such as from Google Fonts at runtime, set
/// [resolver] before the first theme's tokens are built:
///
/// ```dart
/// AdminFonts.resolver = (family, style) =>
///     GoogleFonts.asMap().containsKey(family)
///     ? GoogleFonts.getFont(family, textStyle: style)
///     : null;
/// ```
abstract final class AdminFonts {
  /// [style] set in [family], or null to set the family as is. Called for
  /// the family of a theme's text, never for its monospace family.
  static TextStyle? Function(String family, TextStyle style)? resolver;

  /// [style] in [family], through [resolver] when it gives one.
  static TextStyle resolve(String family, TextStyle style) =>
      resolver?.call(family, style) ?? style.copyWith(fontFamily: family);
}
