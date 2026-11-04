import 'package:material_ui/material_ui.dart';

import 'breakpoints.dart';
import 'button_style.dart';
import 'elevation.dart';
import 'field_style.dart';
import 'focus.dart';
import 'motion.dart';
import 'overlay_style.dart';
import 'palette.dart';
import 'radii.dart';
import 'shell_style.dart';
import 'sizes.dart';
import 'stroke.dart';
import 'table_metrics.dart';
import 'themes/iris.dart';
import 'typography.dart';

/// The complete set of themeable design tokens, carried on [ThemeData] as a
/// [ThemeExtension]. Read them all with `context.adminTokens`, or one part
/// through the `context.colors` / `context.radii` / `context.type` /
/// `context.sizes` / `context.motion` / … accessors below; switch themes by
/// building a [ThemeData] with a different [AdminTokens] (see
/// `buildAppTheme`).
///
/// Beside the scales, four anatomy members give each theme the shapes of
/// its reference system, so a component reads them rather than asking which
/// theme it is in: [field] (outlined, filled or underlined boxes), [button]
/// (alignment, padding, weight, disabled look), [shell] (the sidebar's and
/// top bar's geometry and palettes) and [overlay] (tooltip and popover
/// arrows, a tooltip's measure). [breakpoints] are the window widths where
/// the layouts change.
@immutable
class AdminTokens extends ThemeExtension<AdminTokens> {
  final AdminPalette palette;
  final AdminRadii radii;
  final AdminTypography typography;
  final AdminElevation elevation;
  final AdminFocusSpec focus;
  final AdminControlSizes sizes;
  final AdminTableMetrics table;

  /// Durations and curves. Read through `context.motion`, which zeroes the
  /// durations while animations are disabled.
  final AdminMotion motion;

  /// Line widths: outlines, focused and invalid fields, indicators.
  final AdminStroke stroke;

  /// Glyph sizes.
  final AdminIconSizes iconSizes;

  /// The anatomy of a field's box. Read through `context.fieldStyle`.
  final AdminFieldStyle field;

  /// The anatomy of a button. Read through `context.buttonStyle`.
  final AdminButtonStyle button;

  /// The geometry and palettes of the app frame. Read through
  /// `context.shellStyle`.
  final AdminShellStyle shell;

  /// The anatomy of tooltips and popovers. Read through
  /// `context.overlayStyle`.
  final AdminOverlayStyle overlay;

  /// The widths where the compact, medium and expanded layouts start. Read
  /// through `context.breakpoints`, or classify the window with
  /// [AdminBreakpoint.of].
  final AdminBreakpoints breakpoints;

  const AdminTokens({
    required this.palette,
    required this.radii,
    required this.typography,
    required this.elevation,
    this.focus = const AdminFocusSpec(),
    this.sizes = defaultControlSizes,
    this.table = defaultTableMetrics,
    this.motion = defaultMotion,
    this.stroke = const AdminStroke(),
    this.iconSizes = const AdminIconSizes(),
    this.field = const AdminFieldStyle(),
    this.button = const AdminButtonStyle(),
    this.shell = const AdminShellStyle(),
    this.overlay = const AdminOverlayStyle(),
    this.breakpoints = const AdminBreakpoints(),
  });

  /// Builds a token set from a [palette], with optional [radii], typography
  /// [type] spec, [elevation], [focus] ring, control [sizes], [table]
  /// metrics, [motion], [stroke] widths, [iconSizes], the [field],
  /// [button], [shell] and [overlay] anatomy, and the layout [breakpoints].
  /// Typography colours
  /// are derived from the palette so they stay in sync (and [copyWith] keeps
  /// them so). Without an [elevation], a dark palette gets
  /// [defaultDarkElevation] (shadows must be denser to read on a dark page)
  /// and a light one [defaultElevation].
  factory AdminTokens.from({
    required AdminPalette palette,
    AdminRadii? radii,
    AdminTypeSpec? type,
    AdminElevation? elevation,
    AdminFocusSpec? focus,
    AdminControlSizes? sizes,
    AdminTableMetrics? table,
    AdminMotion? motion,
    AdminStroke? stroke,
    AdminIconSizes? iconSizes,
    AdminFieldStyle? field,
    AdminButtonStyle? button,
    AdminShellStyle? shell,
    AdminOverlayStyle? overlay,
    AdminBreakpoints? breakpoints,
  }) {
    return AdminTokens(
      palette: palette,
      radii: radii ?? defaultRadii,
      typography: AdminTypography.from(palette, type ?? const AdminTypeSpec()),
      elevation:
          elevation ??
          (palette.brightness == Brightness.dark
              ? defaultDarkElevation
              : defaultElevation),
      focus: focus ?? const AdminFocusSpec(),
      sizes: sizes ?? defaultControlSizes,
      table: table ?? defaultTableMetrics,
      motion: motion ?? defaultMotion,
      stroke: stroke ?? const AdminStroke(),
      iconSizes: iconSizes ?? const AdminIconSizes(),
      field: field ?? const AdminFieldStyle(),
      button: button ?? const AdminButtonStyle(),
      shell: shell ?? const AdminShellStyle(),
      overlay: overlay ?? const AdminOverlayStyle(),
      breakpoints: breakpoints ?? const AdminBreakpoints(),
    );
  }

  /// Rebrands this token set: [seed] becomes the primary colour and the
  /// primary roles are recomputed from it (see [AdminPalette.branded]), in
  /// the page's palette and in the [shell]'s own sidebar and top bar
  /// palettes. Surfaces, text, status, radii and typography are untouched —
  /// so any theme can be branded for a client by swapping just the accent.
  AdminTokens branded(Color seed) =>
      copyWith(palette: palette.branded(seed), shell: shell.branded(seed));

  /// A copy with the given members replaced.
  ///
  /// A new [palette] without a [typography] re-derives the typography from
  /// it, with the same [AdminTypography.spec], when the current typography is
  /// the one [AdminTypography.from] derives from the current palette — so its
  /// text colours follow the new palette. A typography built by hand is kept
  /// as it is.
  @override
  AdminTokens copyWith({
    AdminPalette? palette,
    AdminRadii? radii,
    AdminTypography? typography,
    AdminElevation? elevation,
    AdminFocusSpec? focus,
    AdminControlSizes? sizes,
    AdminTableMetrics? table,
    AdminMotion? motion,
    AdminStroke? stroke,
    AdminIconSizes? iconSizes,
    AdminFieldStyle? field,
    AdminButtonStyle? button,
    AdminShellStyle? shell,
    AdminOverlayStyle? overlay,
    AdminBreakpoints? breakpoints,
  }) {
    return AdminTokens(
      palette: palette ?? this.palette,
      radii: radii ?? this.radii,
      typography: typography ?? _typographyFor(palette),
      elevation: elevation ?? this.elevation,
      focus: focus ?? this.focus,
      sizes: sizes ?? this.sizes,
      table: table ?? this.table,
      motion: motion ?? this.motion,
      stroke: stroke ?? this.stroke,
      iconSizes: iconSizes ?? this.iconSizes,
      field: field ?? this.field,
      button: button ?? this.button,
      shell: shell ?? this.shell,
      overlay: overlay ?? this.overlay,
      breakpoints: breakpoints ?? this.breakpoints,
    );
  }

  /// [typography] for [newPalette]: re-derived when it was derived from
  /// [palette], otherwise kept.
  AdminTypography _typographyFor(AdminPalette? newPalette) {
    if (newPalette == null || newPalette == palette) return typography;
    final spec = typography.spec;
    if (typography != AdminTypography.from(palette, spec)) return typography;
    return AdminTypography.from(newPalette, spec);
  }

  @override
  AdminTokens lerp(ThemeExtension<AdminTokens>? other, double t) {
    if (other is! AdminTokens) return this;
    return AdminTokens(
      palette: AdminPalette.lerp(palette, other.palette, t),
      radii: AdminRadii.lerp(radii, other.radii, t),
      typography: AdminTypography.lerp(typography, other.typography, t),
      elevation: AdminElevation.lerp(elevation, other.elevation, t),
      focus: AdminFocusSpec.lerp(focus, other.focus, t),
      sizes: AdminControlSizes.lerp(sizes, other.sizes, t),
      table: AdminTableMetrics.lerp(table, other.table, t),
      motion: AdminMotion.lerp(motion, other.motion, t),
      stroke: AdminStroke.lerp(stroke, other.stroke, t),
      iconSizes: AdminIconSizes.lerp(iconSizes, other.iconSizes, t),
      field: AdminFieldStyle.lerp(field, other.field, t),
      button: AdminButtonStyle.lerp(button, other.button, t),
      shell: AdminShellStyle.lerp(shell, other.shell, t),
      overlay: AdminOverlayStyle.lerp(overlay, other.overlay, t),
      breakpoints: AdminBreakpoints.lerp(breakpoints, other.breakpoints, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminTokens &&
          other.palette == palette &&
          other.radii == radii &&
          other.typography == typography &&
          other.elevation == elevation &&
          other.focus == focus &&
          other.sizes == sizes &&
          other.table == table &&
          other.motion == motion &&
          other.stroke == stroke &&
          other.iconSizes == iconSizes &&
          other.field == field &&
          other.button == button &&
          other.shell == shell &&
          other.overlay == overlay &&
          other.breakpoints == breakpoints;

  @override
  int get hashCode => Object.hash(
    palette,
    radii,
    typography,
    elevation,
    focus,
    sizes,
    table,
    motion,
    stroke,
    iconSizes,
    field,
    button,
    shell,
    overlay,
    breakpoints,
  );
}

/// Iris's palette and metrics in the platform font, light: what the kit
/// draws with when no theme is above it. It names no font, so building it
/// never starts a font load, even offline. `irisTheme` is Iris proper, in
/// Inter.
final defaultTokens = AdminTokens.from(palette: irisPalette);

var _debugReportedMissingTokens = false;

/// Checks a lookup that found no [AdminTokens], in a debug build: throws when
/// no material_ui [Theme] is above [context] at all, and otherwise prints a
/// warning, once per isolate. Only this fallback path walks the tree.
bool _debugCheckMissingTokens(BuildContext context) {
  if (context.findAncestorWidgetOfExactType<Theme>() == null) {
    throw FlutterError.fromParts([
      ErrorSummary(
        'No material_ui Theme above ${context.widget.runtimeType} to read '
        'the AdminTokens from.',
      ),
      ErrorDescription(
        'admin_ui reads its design tokens from the AdminTokens extension of '
        'the enclosing Theme of package:material_ui. A MaterialApp from '
        "package:flutter/material.dart installs the SDK's own Theme, which "
        'the kit cannot see, so every colour, font and radius would silently '
        'be the Iris defaults.',
      ),
      ErrorHint(
        // Not user-facing: a developer error, like the summary above.
        'Build the app with the MaterialApp of package:material_ui and '
        '`theme: buildAppTheme(tokens)`. `AdminScope(tokens: …)` is no way '
        "round it: the kit's dialogs would still find no material_ui "
        'MaterialLocalizations, so an app on the MaterialApp of '
        'package:flutter/material.dart is not supported. A release build '
        'falls back to defaultTokens (Iris, light).',
      ),
      context.describeElement('The widget reading the tokens was'),
    ]);
  }
  if (!_debugReportedMissingTokens) {
    _debugReportedMissingTokens = true;
    debugPrint(
      'admin_ui: the Theme above ${context.widget.runtimeType} carries no '
      'AdminTokens, so the kit draws with defaultTokens (Iris, light). Build '
      "the app's material_ui theme with buildAppTheme(tokens), or wrap the "
      'kit in AdminScope(tokens: …). A route pushed above the home route is '
      'outside an AdminScope placed there, and needs its own. Reported once.',
    );
  }
  return true;
}

/// Reads the kit's [AdminTokens] from a [BuildContext].
///
/// It is separate from [AdminTokensContext], the short token getters, so an
/// app that hides those (`hide AdminTokensContext`, for a `colors` of its
/// own) still reaches the tokens.
extension AdminThemeContext on BuildContext {
  /// All admin design tokens for the active theme: the [AdminTokens]
  /// extension of the enclosing material_ui [Theme], which `buildAppTheme`
  /// installs.
  ///
  /// Without one it falls back to [defaultTokens], Iris light:
  ///
  /// - under a material_ui [Theme] that carries no tokens (a `MaterialApp`
  ///   given no `buildAppTheme` theme), with a warning the first time in a
  ///   debug build;
  /// - with no material_ui [Theme] above at all (an app built on
  ///   `package:flutter/material.dart`, whose [Theme] this lookup cannot see,
  ///   or on none), in a release build only: a debug build throws a
  ///   [FlutterError] that names the fix.
  AdminTokens get adminTokens {
    final tokens = Theme.of(this).extension<AdminTokens>();
    if (tokens != null) return tokens;
    assert(_debugCheckMissingTokens(this));
    return defaultTokens;
  }
}

/// The short token getters: `context.colors`, `context.type`, … Each reads
/// [AdminThemeContext.adminTokens]. They are the kit's one unprefixed
/// extension; an app whose own getters clash hides it.
extension AdminTokensContext on BuildContext {
  /// The active colour palette. `context.colors.primary`, …
  AdminPalette get colors => adminTokens.palette;

  /// The active corner radii. `context.radii.radius`, …
  AdminRadii get radii => adminTokens.radii;

  /// The active typography. `context.type.body`, …
  AdminTypography get type => adminTokens.typography;

  /// The active shadow set. `context.elevation.md`, …
  AdminElevation get elevation => adminTokens.elevation;

  /// The active focus-ring geometry. `context.focus.width`, … (its colour is
  /// `context.colors.focusRing`).
  AdminFocusSpec get focus => adminTokens.focus;

  /// The active control geometry. `context.sizes.medium`, …
  AdminControlSizes get sizes => adminTokens.sizes;

  /// The active data-table geometry. `context.tableMetrics.rowHeight(…)`, …
  AdminTableMetrics get tableMetrics => adminTokens.table;

  /// The active motion: `context.motion.medium`, `context.motion.enter`, …
  /// [AdminMotion.reduced] — every duration zero — while the platform asks
  /// for less motion ([MediaQuery.disableAnimations]), so an animation that
  /// reads its duration here lands on its end state at once.
  AdminMotion get motion {
    final motion = adminTokens.motion;
    return MediaQuery.maybeDisableAnimationsOf(this) ?? false
        ? motion.reduced
        : motion;
  }

  /// The active line widths. `context.stroke.fieldFocus`, …
  AdminStroke get stroke => adminTokens.stroke;

  /// The active glyph sizes. `context.iconSizes.md`, …
  AdminIconSizes get iconSizes => adminTokens.iconSizes;

  /// The active field anatomy. `context.fieldStyle.variant`, … (resolved
  /// per state by `resolveFieldChrome`).
  AdminFieldStyle get fieldStyle => adminTokens.field;

  /// The active button anatomy. `context.buttonStyle.paddingOf(…)`, …
  AdminButtonStyle get buttonStyle => adminTokens.button;

  /// The active frame geometry. `context.shellStyle.sidebarWidth`, …
  AdminShellStyle get shellStyle => adminTokens.shell;

  /// The active tooltip and popover anatomy.
  /// `context.overlayStyle.arrowWidth`, …
  AdminOverlayStyle get overlayStyle => adminTokens.overlay;

  /// The active layout breakpoints. `context.breakpoints.medium`, … (the
  /// window's class is [AdminBreakpoint.of]).
  AdminBreakpoints get breakpoints => adminTokens.breakpoints;
}
