import 'package:flutter/widgets.dart';

import '../breakpoints.dart';
import '../button_style.dart';
import '../elevation.dart';
import '../field_style.dart';
import '../focus.dart';
import '../motion.dart';
import '../overlay_style.dart';
import '../palette.dart';
import '../radii.dart';
import '../shell_style.dart';
import '../sizes.dart';
import '../stroke.dart';
import '../table_metrics.dart';
import '../tokens.dart';
import '../typography.dart';

/// A named theme: a display [name] plus its [AdminTokens].
///
/// Themes are plain values, not a closed enum — define your own anywhere with
/// [AdminTheme.from] and hand it to whatever renders a theme list (e.g. the
/// catalog's `ThemableTestApp`). Nothing in this package needs to change to add
/// one. The shipped themes each live in their own file under `themes/`.
@immutable
class AdminTheme {
  final String name;

  /// Light token set.
  final AdminTokens tokens;

  /// Optional dark token set; null if the theme is light-only.
  final AdminTokens? dark;

  const AdminTheme({required this.name, required this.tokens, this.dark});

  /// Builds a theme from a light [palette] and an optional [dark] palette; both
  /// share the [radii], [type], [focus] ring, control [sizes] (left out,
  /// [defaultControlSizes]), [table] metrics (left out,
  /// [defaultTableMetrics]), [motion] (left out, [defaultMotion]), [stroke]
  /// widths, [iconSizes], the [field], [button] and [overlay] anatomy, and
  /// the layout [breakpoints] (left out, [AdminBreakpoints]' defaults).
  /// The light set takes [elevation] and [shell], the dark set
  /// [darkElevation] and [darkShell]; left out, each mode gets the shadows
  /// that suit its palette's brightness ([defaultElevation] or
  /// [defaultDarkElevation]), and the dark set the light [shell].
  ///
  /// The token sets are built the first time [tokens] or [dark] is read, not
  /// here: building typography is what calls `AdminFonts.resolver`, so
  /// listing themes (a picker, `adminThemes`) loads no font, and a resolver
  /// that fetches one does so only once something reads its tokens.
  factory AdminTheme.from({
    required String name,
    required AdminPalette palette,
    AdminPalette? dark,
    AdminRadii? radii,
    AdminTypeSpec? type,
    AdminElevation? elevation,
    AdminElevation? darkElevation,
    AdminFocusSpec? focus,
    AdminControlSizes? sizes,
    AdminTableMetrics? table,
    AdminMotion? motion,
    AdminStroke? stroke,
    AdminIconSizes? iconSizes,
    AdminFieldStyle? field,
    AdminButtonStyle? button,
    AdminShellStyle? shell,
    AdminShellStyle? darkShell,
    AdminOverlayStyle? overlay,
    AdminBreakpoints? breakpoints,
  }) = _PaletteTheme;

  bool get hasDark => dark != null;

  /// The light palette, readable without building [tokens] (and so without
  /// loading the theme's font) — for swatches in a theme picker.
  AdminPalette get palette => tokens.palette;

  /// The dark palette, or null for a light-only theme; see [palette].
  AdminPalette? get darkPalette => dark?.palette;

  /// A copy rebranded with [seed] as the primary colour (see
  /// [AdminTokens.branded]), applied to both the light and dark token sets.
  AdminTheme branded(String name, Color seed) => AdminTheme(
    name: name,
    tokens: tokens.branded(seed),
    dark: dark?.branded(seed),
  );

  // [name] is the identity, on purpose: themes are equal iff their names
  // match, so a picker keyed by theme keeps its selection when the list is
  // rebuilt (a theme re-branded on every build included), and names must be
  // unique within a list. Compare [tokens] to ask whether two look the same.
  @override
  bool operator ==(Object other) => other is AdminTheme && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// [AdminTheme.from]: holds the inputs and builds each token set on first read.
class _PaletteTheme implements AdminTheme {
  @override
  final String name;

  @override
  final AdminPalette palette;

  @override
  final AdminPalette? darkPalette;

  final AdminRadii? radii;
  final AdminTypeSpec? type;
  final AdminElevation? elevation;
  final AdminElevation? darkElevation;
  final AdminFocusSpec? focus;
  final AdminControlSizes? sizes;
  final AdminTableMetrics? table;
  final AdminMotion? motion;
  final AdminStroke? stroke;
  final AdminIconSizes? iconSizes;
  final AdminFieldStyle? field;
  final AdminButtonStyle? button;
  final AdminShellStyle? shell;
  final AdminShellStyle? darkShell;
  final AdminOverlayStyle? overlay;
  final AdminBreakpoints? breakpoints;

  _PaletteTheme({
    required this.name,
    required this.palette,
    AdminPalette? dark,
    this.radii,
    this.type,
    this.elevation,
    this.darkElevation,
    this.focus,
    this.sizes,
    this.table,
    this.motion,
    this.stroke,
    this.iconSizes,
    this.field,
    this.button,
    this.shell,
    this.darkShell,
    this.overlay,
    this.breakpoints,
  }) : darkPalette = dark;

  @override
  late final AdminTokens tokens = _build(palette, elevation, shell);

  @override
  late final AdminTokens? dark = switch (darkPalette) {
    final p? => _build(p, darkElevation, darkShell ?? shell),
    null => null,
  };

  AdminTokens _build(
    AdminPalette palette,
    AdminElevation? elevation,
    AdminShellStyle? shell,
  ) => AdminTokens.from(
    palette: palette,
    radii: radii,
    type: type,
    elevation: elevation,
    focus: focus,
    sizes: sizes,
    table: table,
    motion: motion,
    stroke: stroke,
    iconSizes: iconSizes,
    field: field,
    button: button,
    shell: shell,
    overlay: overlay,
    breakpoints: breakpoints,
  );

  @override
  bool get hasDark => darkPalette != null;

  /// Rebrands the palettes (the shell's own included) only; the copy stays
  /// lazy.
  @override
  AdminTheme branded(String name, Color seed) => _PaletteTheme(
    name: name,
    palette: palette.branded(seed),
    dark: darkPalette?.branded(seed),
    radii: radii,
    type: type,
    elevation: elevation,
    darkElevation: darkElevation,
    focus: focus,
    sizes: sizes,
    table: table,
    motion: motion,
    stroke: stroke,
    iconSizes: iconSizes,
    field: field,
    button: button,
    shell: shell?.branded(seed),
    darkShell: darkShell?.branded(seed),
    overlay: overlay,
    breakpoints: breakpoints,
  );

  @override
  bool operator ==(Object other) => other is AdminTheme && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
