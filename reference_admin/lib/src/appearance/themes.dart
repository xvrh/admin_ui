import 'package:admin_ui/theme.dart';
import 'package:flutter/widgets.dart';

/// The house theme, built as the kit's README shows a theme of your own:
/// Iris with a garden green, softer corners and Inter, plus a chart series
/// that leads with the green.
// FRICTION(F-024): copyWith(primary: …) and branded() keep the base
// theme's chart series, so the README's recipe draws every chart in Iris
// indigo; the series is set by hand.
final greenhouseTheme = AdminTheme.from(
  name: 'Greenhouse',
  palette: irisPalette.copyWith(
    primary: const Color(0xFF2F7D4F),
    primaryStrong: const Color(0xFF256640),
    primarySubtle: const Color(0xFFD7EEDF),
    primaryFaint: const Color(0xFFEFF8F2),
    chart: _greenhouseChartLight,
  ),
  dark: irisDarkPalette
      .branded(const Color(0xFF4CB47A))
      .copyWith(chart: _greenhouseChartDark),
  radii: const AdminRadii(radiusSmall: 6, radius: 10, radiusLarge: 16),
  type: const AdminTypeSpec(fontFamily: 'Inter', uppercaseLabels: false),
);

// Iris' ramp with the garden green first and Iris' indigo last, neighbours
// still apart in hue and warmth, each at 3:1 on the surfaces.
const _greenhouseChartLight = [
  Color(0xFF2F7D4F),
  Color(0xFFF06403),
  Color(0xFF0090FF),
  Color(0xFFB68805),
  Color(0xFFAB4ABA),
  Color(0xFF04A190),
  Color(0xFFE93D82),
  Color(0xFF5B5BD6),
];
const _greenhouseChartDark = [
  Color(0xFF4CB47A),
  Color(0xFFF76B15),
  Color(0xFF0090FF),
  Color(0xFFFAC037),
  Color(0xFFAB4ABA),
  Color(0xFF12A594),
  Color(0xFFE93D82),
  Color(0xFF5C5CD7),
];

/// The six kit themes and the house one, in the order pickers list them.
final appThemes = <AdminTheme>[...adminThemes, greenhouseTheme];

/// The theme named [name], or Iris.
AdminTheme themeNamed(String? name) =>
    appThemes.firstWhere((t) => t.name == name, orElse: () => irisTheme);

/// The family every token set falls back to for Arabic, which none of the
/// theme fonts covers.
const arabicFallback = 'Noto Naskh Arabic';

/// [tokens] with [arabicFallback] after the families they already fall
/// back to.
// FRICTION(F-006): the shipped typography has no Arabic fallback, so every
// token set is rebuilt through AdminTypography.from.
AdminTokens withArabicFallback(AdminTokens tokens) {
  final spec = tokens.typography.spec;
  final fallback = spec.fontFamilyFallback ?? const <String>[];
  if (fallback.contains(arabicFallback)) return tokens;
  return tokens.copyWith(
    typography: AdminTypography.from(
      tokens.palette,
      spec.copyWith(fontFamilyFallback: [...fallback, arabicFallback]),
    ),
  );
}

/// The token set the app renders [theme] with: its light or dark set,
/// branded by [accent] when there is one, with the Arabic fallback.
AdminTokens appTokens(AdminTheme theme, {bool dark = false, Color? accent}) {
  var tokens = dark ? (theme.dark ?? theme.tokens) : theme.tokens;
  if (accent != null) tokens = tokens.branded(accent);
  return withArabicFallback(tokens);
}
