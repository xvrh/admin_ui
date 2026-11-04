import 'dart:convert';

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui_example/src/utils/themable_test_app.dart';
import 'package:material_ui/material_ui.dart';

import 'entries.dart';

/// The shipped themes' names, in [adminThemes] order.
const themeNames = ['Iris', 'Material', 'shadcn', 'Ant', 'Fluent', 'Carbon'];

/// The [adminThemes] entry called [name].
AdminTheme themeNamed(String name) => adminThemes.firstWhere(
  (theme) => theme.name == name,
  orElse: () => throw ArgumentError.value(name, 'name', 'No such theme'),
);

/// How `pumpEntry` renders a demo: the axes the catalog's preview shell
/// offers, plus the platform settings the sweeps turn.
@immutable
class RenderConfig {
  final AdminTheme theme;
  final ThemeMode mode;

  /// An accent to rebrand the theme with (`tokens.branded`), null for its own
  /// primary. [brandName] names it in [toString].
  final Color? brand;
  final String? brandName;

  final Locale locale;

  /// Forces a direction whatever [locale] is; null takes the locale's.
  final TextDirection? direction;

  /// The platform text scale, which overlays inherit too.
  final double textScale;

  /// The platform asking for less motion: both Android's "remove
  /// animations" (`MediaQuery.disableAnimations`, which also cuts
  /// `AnimationController`s short) and iOS's "reduce motion"
  /// (`MediaQuery.reduceMotion`).
  final bool disableAnimations;

  const RenderConfig({
    required this.theme,
    this.mode = ThemeMode.light,
    this.brand,
    this.brandName,
    this.locale = const Locale('en'),
    this.direction,
    this.textScale = 1,
    this.disableAnimations = false,
  }) : assert(brand == null || brandName != null, 'A brand needs a name');

  /// [theme] in [mode], English, no brand.
  factory RenderConfig.of(String theme, ThemeMode mode) =>
      RenderConfig(theme: themeNamed(theme), mode: mode);

  /// This config rebranded with the [adminPreviewBrands] accent called
  /// [name]; `Default` drops the brand.
  RenderConfig withBrand(String name) {
    if (!adminPreviewBrands.containsKey(name)) {
      throw ArgumentError.value(name, 'name', 'Not in adminPreviewBrands');
    }
    final color = adminPreviewBrands[name];
    return RenderConfig(
      theme: theme,
      mode: mode,
      brand: color,
      brandName: color == null ? null : name,
      locale: locale,
      direction: direction,
      textScale: textScale,
      disableAnimations: disableAnimations,
    );
  }

  /// A copy with the given settings replaced; the brand is kept (see
  /// [withBrand]).
  RenderConfig copyWith({
    AdminTheme? theme,
    ThemeMode? mode,
    Locale? locale,
    TextDirection? direction,
    double? textScale,
    bool? disableAnimations,
  }) => RenderConfig(
    theme: theme ?? this.theme,
    mode: mode ?? this.mode,
    brand: brand,
    brandName: brandName,
    locale: locale ?? this.locale,
    direction: direction ?? this.direction,
    textScale: textScale ?? this.textScale,
    disableAnimations: disableAnimations ?? this.disableAnimations,
  );

  /// The light or dark token set, rebranded when [brand] is set. A light-only
  /// theme renders its light tokens in dark mode, as the preview shell does.
  AdminTokens get tokens {
    var tokens = mode == ThemeMode.dark
        ? theme.dark ?? theme.tokens
        : theme.tokens;
    if (brand case final brand?) tokens = tokens.branded(brand);
    return tokens;
  }

  @override
  String toString() => [
    theme.name,
    mode.name,
    ?brandName,
    if (locale != const Locale('en')) locale.toLanguageTag(),
    if (direction case final direction?) direction.name,
    if (textScale != 1) 'x${_scale(textScale)}',
    if (disableAnimations) 'reduced motion',
  ].join(' · ');
}

/// Every theme in light then dark: the 12 combinations, [adminThemes] order.
final allCombos = [
  for (final theme in themeNames)
    for (final mode in const [ThemeMode.light, ThemeMode.dark])
      RenderConfig.of(theme, mode),
];

/// The theme and mode [entry] is pumped in when a sweep pumps it once: the
/// one its id hashes to, which stays put when other demos come and go.
RenderConfig homeCombo(DemoEntry entry) =>
    allCombos[stableIndex(entry.id, allCombos.length)];

String _scale(double scale) =>
    scale == scale.roundToDouble() ? '${scale.round()}' : '$scale';

/// A spread of [id]s over `0 <= i < n` that stays put when other ids come and
/// go: FNV-1a (32-bit) over the id's UTF-8 bytes, modulo [n]. Never
/// `String.hashCode`, which is not stable across runs, nor a list index, which
/// shifts every later entry when one is inserted.
int stableIndex(String id, int n) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(id)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash % n;
}
