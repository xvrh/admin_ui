import 'package:material_ui/material_ui.dart';

import 'table_metrics.dart';
import 'theme.dart';
import 'themes.dart';
import 'tokens.dart';

/// Brand accents to lay over any theme, by name: the ones an
/// `AppearancePicker` offers unless given others. The picker says each name
/// in the app's language (`InputsMessages.accentName`).
const adminAccents = <String, Color>{
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

/// How an app looks: a [theme], its light or dark [mode], a brand [accent]
/// laid over it, and the [density] of its tables.
///
/// A plain value. Hold it where the app keeps its state, hand it to an
/// `AppearancePicker` to edit, and build the app's themes from it:
///
/// ```dart
/// MaterialApp(
///   theme: appearance.themeData(Brightness.light),
///   darkTheme: appearance.themeData(Brightness.dark),
///   themeMode: appearance.mode,
/// )
/// ```
///
/// [toJson] and [AdminAppearance.fromJson] persist it by the theme's name.
@immutable
class AdminAppearance {
  /// The theme, one of the list the app offers (`adminThemes` unless it
  /// offers others).
  final AdminTheme theme;

  /// Light, dark, or the device's setting.
  final ThemeMode mode;

  /// The brand colour laid over [theme] with [AdminTokens.branded]; null
  /// keeps the theme's own primary.
  final Color? accent;

  /// How tightly the app's tables pack their rows. It changes no token: the
  /// app passes it to its tables, as `CollectionTable(density:)`.
  final TableDensity density;

  const AdminAppearance({
    required this.theme,
    this.mode = ThemeMode.system,
    this.accent,
    this.density = TableDensity.standard,
  });

  /// Reads what [toJson] wrote. The theme is looked up by name in [themes]
  /// (null is [adminThemes]), and a name none of them has, or none at all,
  /// gives the first; a mode, accent or density that does not read keeps its
  /// default.
  factory AdminAppearance.fromJson(
    Map<String, Object?> json, {
    List<AdminTheme>? themes,
  }) {
    final list = themes ?? adminThemes;
    assert(list.isNotEmpty, 'fromJson needs a theme to fall back on');
    final name = json['theme'];
    final accent = json['accent'];
    return AdminAppearance(
      theme: list.firstWhere((t) => t.name == name, orElse: () => list.first),
      mode: ThemeMode.values.asNameMap()[json['mode']] ?? ThemeMode.system,
      accent: accent is int ? Color(accent) : null,
      density:
          TableDensity.values.asNameMap()[json['density']] ??
          TableDensity.standard,
    );
  }

  /// The theme's name: what [toJson] stores to find it again.
  String get themeName => theme.name;

  /// The brightness the app shows in on a device set to [platform]: the
  /// [mode]'s, or [platform]'s under [ThemeMode.system].
  Brightness resolveBrightness(Brightness platform) => switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platform,
  };

  /// The token set for [brightness]: the theme's light or dark set (the
  /// light one for a theme with no dark set), branded with [accent] when
  /// there is one.
  ///
  /// The same instance every time for the same theme, accent and
  /// brightness, from this appearance or any other, so an app that rebuilds
  /// with an unchanged look builds no tokens.
  AdminTokens tokens(Brightness brightness) {
    final cache = _tokens[theme] ??= {};
    return cache[(accent?.toARGB32(), brightness)] ??= _build(brightness);
  }

  AdminTokens _build(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? theme.dark ?? theme.tokens
        : theme.tokens;
    final accent = this.accent;
    return accent == null ? base : base.branded(accent);
  }

  /// `buildAppTheme(tokens(brightness))`, built once per token set.
  ThemeData themeData(Brightness brightness) {
    final tokens = this.tokens(brightness);
    return _themeData[tokens] ??= buildAppTheme(tokens);
  }

  /// A copy with the given members replaced. [accent] cannot be set back to
  /// null this way: [clearAccent] does that.
  AdminAppearance copyWith({
    AdminTheme? theme,
    ThemeMode? mode,
    Color? accent,
    bool clearAccent = false,
    TableDensity? density,
  }) => AdminAppearance(
    theme: theme ?? this.theme,
    mode: mode ?? this.mode,
    accent: clearAccent ? null : accent ?? this.accent,
    density: density ?? this.density,
  );

  /// The theme by name, the mode and density by their enum names, and the
  /// accent as a 32-bit ARGB integer (null for none).
  Map<String, Object?> toJson() => {
    'theme': theme.name,
    'mode': mode.name,
    'accent': accent?.toARGB32(),
    'density': density.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AdminAppearance &&
      other.theme == theme &&
      other.mode == mode &&
      other.accent == accent &&
      other.density == density;

  @override
  int get hashCode => Object.hash(theme, mode, accent, density);

  @override
  String toString() {
    final accent = this.accent;
    final hex = accent?.toARGB32().toRadixString(16).padLeft(8, '0');
    return 'AdminAppearance(${theme.name}, ${mode.name}, '
        '${hex == null ? 'theme accent' : 'accent 0x$hex'}, ${density.name})';
  }
}

/// Each theme's token sets, by accent and brightness. Held on the theme, so
/// they go when it does.
final _tokens = Expando<Map<(int?, Brightness), AdminTokens>>(
  'AdminAppearance tokens',
);

final _themeData = Expando<ThemeData>('AdminAppearance theme data');
