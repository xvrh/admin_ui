import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import 'contrast.dart';
import 'state_layer.dart';
import 'syntax.dart';

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _nearBlack = Color(0xFF18181B);
const _transparent = Color(0x00000000);

/// A complete colour palette for the admin UI. One instance per theme; provided
/// to the tree via [AdminTokens] and read through `context.colors`. The shipped
/// palettes live with their themes in `themes/` (e.g. `themes/iris.dart`).
///
/// The required colours are the authored base, named by role: `primary*` for
/// the brand accent, `surface*` and [background] for what things sit on,
/// `foreground*` for text from strongest to faintest, `border*` for lines.
/// Each family's plain name is its main step, and `Subtle`/`Faint` step away
/// from it toward [surface] in both modes. The optional roles ([onPrimary],
/// [primaryText], [controlBorder], …) default to values derived from that
/// base so each pairing meets its WCAG contrast target; a theme authors one
/// only where the derived value is not the look it wants.
@immutable
class AdminPalette {
  // ── primary ──

  /// The brand accent: primary buttons, selected controls, the focus ring
  /// where it reaches 3:1. As text, use [primaryText].
  final Color primary;

  /// [primary] a step deeper: the hover fill [primaryHover] derives under
  /// light content.
  final Color primaryStrong;

  /// A soft [primary] tint: a selected item's fill, the primary container.
  final Color primarySubtle;

  /// A fainter tint than [primarySubtle], nearer [surface]: an unread row, a
  /// previewed selection.
  final Color primaryFaint;

  // ── surfaces ──

  /// Cards, inputs and overlays (menus, popovers, dialogs): the Material
  /// `ColorScheme.surface`, and the lightest surface in both modes.
  final Color surface;

  /// The page and its rails, under [surface] cards.
  final Color background;

  /// A muted well set off from [surface]: table headers, nested panels. Where
  /// it sits against [background] is the theme's call — between the page and
  /// [surface] in some, a step below the page in others.
  final Color surfaceMuted;

  // ── text ──

  /// Body text and icons.
  final Color foreground;

  /// A step quieter than [foreground]: field and section labels, quiet
  /// buttons, secondary icons.
  final Color foregroundSecondary;

  /// Supporting text — captions, hints, secondary cells — at 4.5:1 on
  /// [surface] and [background].
  final Color foregroundMuted;

  /// Tertiary glyphs and text quieter than [foregroundMuted], not held to
  /// 4.5:1: inactive handles, empty-state marks, disabled labels. Input hints
  /// use [placeholder].
  final Color foregroundSubtle;

  /// The quietest step: disabled glyphs, decorative marks and unfilled
  /// tracks.
  final Color foregroundFaint;

  // ── borders ──

  /// Dividers, card edges and rules. A control's outline is [controlBorder].
  final Color border;

  /// A fainter rule than [border], nearer [surface]: row rules and nested
  /// separators.
  final Color borderSubtle;

  // ── status ── (accents for fills, dots and borders; each has a text-safe
  // `*Text` role and an `on*` role for content on it)

  final Color success;
  final Color warning;
  final Color danger;

  /// [warning] as text: 4.5:1 on [surface] and on its status fill.
  final Color warningText;

  final Color info;

  // ── marks ──

  /// The fill behind text that a note or comment is anchored to.
  final Color highlight;

  /// The fill of a field whose value differs from the one it overrides.
  final Color modifiedFill;

  /// The rule under a tab bar.
  final Color tabDivider;

  /// The opacities [hoverOverlay], [focusOverlay], [pressedOverlay],
  /// [draggedOverlay] and the primary overlays lay their colour at. The
  /// kit's own by default; the Material palettes set M3's.
  final AdminStateLayer stateLayer;

  // authored roles; null means derived (see the getters)
  final Color? _onPrimary;
  final Color? _onDanger;
  final Color? _onSuccess;
  final Color? _onWarning;
  final Color? _onInfo;
  final Color? _primaryText;
  final Color? _dangerText;
  final Color? _successText;
  final Color? _infoText;
  final Color? _primaryHover;
  final Color? _primaryActive;
  final Color? _dangerHover;
  final Color? _dangerActive;
  final Color? _focusRing;
  final Color? _controlBorder;
  final Color? _controlAccent;
  final Color? _placeholder;
  final Color? _scrim;
  final Color? _shadow;
  final List<Color>? _chart;
  final Color? _listHighlight;
  final Color? _separator;
  final Color? _navSelectedFill;
  final Color? _navHoverFill;
  final Color? _navSelectedText;
  final Color? _navIndicator;
  final Color? _tableRowStripe;
  final Color? _tableRowHover;
  final Color? _tableRowSelected;
  final Color? _tableRowSelectedHover;
  final Color? _fieldFill;
  final Color? _fieldFillHover;
  final Color? _fieldRule;
  final Color? _softFill;
  final Color? _onSoft;
  final Color? _neutralFill;
  final Color? _neutralFillHover;
  final Color? _neutralFillActive;
  final Color? _onNeutralFill;

  const AdminPalette({
    required this.primary,
    required this.primaryStrong,
    required this.primarySubtle,
    required this.primaryFaint,
    required this.surface,
    required this.background,
    required this.surfaceMuted,
    required this.foreground,
    required this.foregroundSecondary,
    required this.foregroundMuted,
    required this.foregroundSubtle,
    required this.foregroundFaint,
    required this.border,
    required this.borderSubtle,
    required this.success,
    required this.warning,
    required this.danger,
    required this.warningText,
    required this.info,
    required this.highlight,
    required this.modifiedFill,
    required this.tabDivider,
    this.stateLayer = const AdminStateLayer(),
    this._onPrimary,
    this._onDanger,
    this._onSuccess,
    this._onWarning,
    this._onInfo,
    this._primaryText,
    this._dangerText,
    this._successText,
    this._infoText,
    this._primaryHover,
    this._primaryActive,
    this._dangerHover,
    this._dangerActive,
    this._focusRing,
    this._controlBorder,
    this._controlAccent,
    this._placeholder,
    this._scrim,
    this._shadow,
    this._chart,
    this._listHighlight,
    this._separator,
    this._navSelectedFill,
    this._navHoverFill,
    this._navSelectedText,
    this._navIndicator,
    this._tableRowStripe,
    this._tableRowHover,
    this._tableRowSelected,
    this._tableRowSelectedHover,
    this._fieldFill,
    this._fieldFillHover,
    this._fieldRule,
    this._softFill,
    this._onSoft,
    this._neutralFill,
    this._neutralFillHover,
    this._neutralFillActive,
    this._onNeutralFill,
  });

  /// Brightness inferred from [surface] — drives the Material [colorScheme]
  /// and lets the same palette shape serve a light or a dark theme.
  Brightness get brightness => ThemeData.estimateBrightnessForColor(surface);

  _DerivedRoles get _derived => _derivedCache[this] ??= _DerivedRoles(this);

  // ── contrast helpers ──

  /// White or near-black (#18181B), whichever has the higher WCAG contrast
  /// against [fill]. The content colour for anything drawn on a solid fill
  /// that has no authored on-colour (a swatch, a peer's avatar colour).
  Color foregroundOn(Color fill) =>
      contrastRatio(_white, fill) >= contrastRatio(_nearBlack, fill)
      ? _white
      : _nearBlack;

  /// [accent] adjusted until it reads as text on every one of [surfaces]
  /// (default [surface] and [background]) at [minContrast]: its HSL lightness
  /// moves, in small steps, toward whichever of black or white contrasts more
  /// with the surfaces (the [foreground] side, for the palette's own
  /// surfaces). Returned unchanged when it already passes; hue and saturation
  /// are kept. Answers are cached per palette, so a widget can ask on every
  /// build.
  Color readableOn(
    Color accent, {
    List<Color>? surfaces,
    double minContrast = 4.5,
  }) {
    final query = _ReadableQuery(
      accent,
      List.unmodifiable(surfaces ?? [surface, background]),
      minContrast,
    );
    final cache = _derived.readable;
    final hit = cache[query];
    if (hit != null) return hit;
    if (cache.length >= _readableCacheLimit) cache.clear();
    return cache[query] = _readable(accent, query.surfaces, minContrast);
  }

  // ── content on fills ──

  /// Content colour on a [primary] fill: authored, or [foregroundOn] it.
  Color get onPrimary => _onPrimary ?? foregroundOn(primary);

  /// Content colour on a [danger] fill.
  Color get onDanger => _onDanger ?? foregroundOn(danger);

  /// Content colour on a [success] fill.
  Color get onSuccess => _onSuccess ?? foregroundOn(success);

  /// Content colour on a [warning] fill.
  Color get onWarning => _onWarning ?? foregroundOn(warning);

  /// Content colour on an [info] fill.
  Color get onInfo => _onInfo ?? foregroundOn(info);

  /// White: content over photos and video, which stays light in every theme.
  /// Pair it with [imageScrim].
  Color get onImage => _white;

  /// A fixed dark wash laid over imagery under [onImage] content.
  Color get imageScrim => _black.withValues(alpha: 0.6);

  // ── text-safe accents ── (4.5:1 on surface, background and the accent's own
  // soft fill; the raw accent stays for fills, dots and borders)

  /// The primary as text or a small glyph: links, selected tab labels, text on
  /// [primarySubtle].
  Color get primaryText => _primaryText ?? _derived.primaryText;

  /// [danger] as text: error captions, soft danger tags.
  Color get dangerText => _dangerText ?? _derived.dangerText;

  /// [success] as text.
  Color get successText => _successText ?? _derived.successText;

  /// [info] as text.
  Color get infoText => _infoText ?? _derived.infoText;

  /// Code and structured-data token colours, each text-safe on [surface] and
  /// [background].
  AdminSyntaxColors get syntax => _derived.syntax;

  // ── interaction & focus ── (interactive surfaces read these instead of
  // hardcoding overlay alphas; the opacities are the [stateLayer]'s)

  /// [foreground] laid over a surface under the pointer, at
  /// [AdminStateLayer.hover].
  Color get hoverOverlay => foreground.withValues(alpha: stateLayer.hover);

  /// [foreground] laid over a control with keyboard focus that shows it as a
  /// wash, at [AdminStateLayer.focus].
  Color get focusOverlay => foreground.withValues(alpha: stateLayer.focus);

  /// [foreground] laid over a pressed control, at [AdminStateLayer.pressed].
  Color get pressedOverlay => foreground.withValues(alpha: stateLayer.pressed);

  /// [foreground] laid over an item being dragged, at
  /// [AdminStateLayer.dragged].
  Color get draggedOverlay => foreground.withValues(alpha: stateLayer.dragged);

  /// Primary-tinted hover / press wash — the *link* affordance (e.g.
  /// breadcrumb crumbs), as opposed to the neutral [hoverOverlay] used by
  /// controls: [primary] at [AdminStateLayer.tintHover] and
  /// [AdminStateLayer.tintPressed], by default a touch stronger than the
  /// neutral pair since a saturated tint reads fainter.
  Color get primaryHoverOverlay =>
      primary.withValues(alpha: stateLayer.tintHover);
  Color get primaryPressedOverlay =>
      primary.withValues(alpha: stateLayer.tintPressed);

  /// The [primary] fill while hovered: authored, or derived by which side
  /// [onPrimary] sits on. Under light content it is [primaryStrong] — unless
  /// [onPrimary] reads worse there than on [primary] and under 4.5:1, in which
  /// case [primary] is shaded one step away from [onPrimary]. Under dark
  /// content (a light primary, as in most dark themes) it is [onPrimary] laid
  /// over [primary] at 8%, Material's hover state layer: a slight darkening —
  /// or, where [primaryActive]'s layer would take [onPrimary] under 4.5:1,
  /// white at 8%, the same small step the other way.
  Color get primaryHover => _primaryHover ?? _derived.primaryHover;

  /// The [primary] fill while pressed: under light content, [primaryHover]'s
  /// step taken once more, as far as [onPrimary] keeps 4.5:1; under dark
  /// content, the [primaryHover] layer at 12%.
  Color get primaryActive => _primaryActive ?? _derived.primaryActive;

  /// The [danger] fill while hovered: under light content, [danger] darkened
  /// by the ratio [primaryStrong] moves [primary]'s lightness; under dark
  /// content, the state layer [primaryHover] takes — [onDanger] over [danger]
  /// at 8%, or white where that would cost [onDanger] its 4.5:1.
  Color get dangerHover => _dangerHover ?? _derived.dangerHover;

  /// The [danger] fill while pressed: two of [dangerHover]'s steps, or its
  /// layer at 12%.
  Color get dangerActive => _dangerActive ?? _derived.dangerActive;

  /// Opaque keyboard-focus ring, at least 3:1 against [surface],
  /// [background] and [fieldFill]: [primary] when it gets there, otherwise
  /// [primaryText]. Width and offset come from `context.focus`.
  Color get focusRing => _focusRing ?? _derived.focusRing;

  /// Boundary of a control that must be found to be used — input outlines,
  /// unchecked checkbox and radio rings, the off switch track — at least 3:1
  /// against [surface] and [background]. [border] stays for dividers and card
  /// edges.
  Color get controlBorder => _controlBorder ?? _derived.controlBorder;

  /// The fill or ring that marks a control as on: a checked Check, a selected
  /// radio, an on Toggle track, a Slider's active track and thumb, a picked
  /// calendar day or media tile, and a field's focused edge where the theme
  /// draws it in the accent. At least 3:1 against [surface], [background]
  /// and [fieldFill]: authored, or [primary] when [primary] already reaches
  /// that, otherwise [primary] with its HSL lightness moved (hue kept) until
  /// it does.
  Color get controlAccent => _controlAccent ?? _derived.controlAccent;

  /// Content drawn on a [controlAccent] fill: the check glyph, the on toggle's
  /// knob, the selected radio's centre, a picked day's number. [onPrimary]
  /// while [controlAccent] is [primary], otherwise [foregroundOn] it.
  Color get onControlAccent => _derived.onControlAccent;

  /// The [controlAccent] fill while hovered: [primaryHover] while
  /// [controlAccent] is [primary], otherwise [controlAccent] stepped the way
  /// [primaryHover] steps [primary], so [onControlAccent] keeps its contrast.
  /// Like [primaryHover], it may stand nearer [surface] than the rest fill.
  Color get controlAccentHover => _derived.controlAccentHover;

  /// Input placeholder text, at least 4.5:1 on [surface]: [foregroundMuted]
  /// when it gets there, otherwise [foregroundSubtle] darkened (or lightened)
  /// until it does.
  Color get placeholder => _placeholder ?? _derived.placeholder;

  /// Supporting text — captions, SKUs, subtitles, hints — drawn on a tinted
  /// fill: a selected table row or card, a highlighted menu or palette row,
  /// a [surfaceMuted] header. At least 4.5:1 on [surface], [background],
  /// [surfaceMuted], [primarySubtle], [primaryFaint], [listHighlight],
  /// [tableRowSelected], [tableRowSelectedHover] and [hoverOverlay] over
  /// [surface]: [foregroundMuted] where it already reaches that on all of
  /// them, otherwise [foregroundMuted] with its lightness moved until it does.
  Color get foregroundMutedOnTint => _derived.foregroundMutedOnTint;

  /// Modal barrier: black at 45% in light themes, 60% in dark ones — a scrim
  /// always dims, never lightens the page.
  Color get scrim =>
      _scrim ??
      _black.withValues(alpha: brightness == Brightness.dark ? 0.6 : 0.45);

  /// Base colour for drop and drag shadows; callers set the alpha.
  Color get shadow => _shadow ?? _black;

  /// Categorical series colours, at least 8, each at least 3:1 on [surface]
  /// and [background]. Independent of the primary, so a brand swap keeps
  /// charts stable.
  List<Color> get chart => _chart ?? _derived.chart;

  // ── lists & overlays ──

  /// The neutral hover and keyboard highlight of a row on a [surface]
  /// overlay — menu items, command palette results, notifications, combobox
  /// options: authored, or [foreground] laid over [surface] at 6% (8% in a
  /// dark theme).
  Color get listHighlight => _listHighlight ?? _derived.listHighlight;

  /// Dividers inside an overlay (menu separators, a palette's header and
  /// footer rules): authored, or whichever of [border] and [borderSubtle]
  /// stands further from [surface].
  Color get separator => _separator ?? _derived.separator;

  // ── navigation ── (a sidebar's items on the [background] rail)

  /// The selected item's fill: authored, or [primarySubtle] — deepened toward
  /// [primary] where it would otherwise stand closer to [background] than
  /// [navHoverFill] does, so selection never reads weaker than hover.
  Color get navSelectedFill => _navSelectedFill ?? _derived.navSelectedFill;

  /// An item's fill under the pointer: authored, or [foreground] laid over
  /// [background] at 5% (8% in a dark theme).
  Color get navHoverFill => _navHoverFill ?? _derived.navHoverFill;

  /// The selected item's label and icon, at least 4.5:1 on [navSelectedFill]:
  /// authored, or [primaryText] adjusted until it reads there.
  Color get navSelectedText => _navSelectedText ?? _derived.navSelectedText;

  /// The bar at the selected item's leading edge; transparent draws none.
  /// Authored, or [primary] adjusted to 3:1 against [background] and
  /// [navSelectedFill].
  Color get navIndicator => _navIndicator ?? _derived.navIndicator;

  // ── tables ── (a data grid's rows on [surface]; the grid paints
  // [tableRowHover] over whichever of the other fills a row has)

  /// The alternate row's fill when a table is striped: authored, or
  /// [foreground] laid over [surface] at 2.5% (3.5% in a dark theme). Opaque
  /// and neutral — a brand never tints it, so a stripe is never mistaken for a
  /// selection.
  Color get tableRowStripe => _tableRowStripe ?? _derived.tableRowStripe;

  /// A translucent wash the table lays over a row under the pointer — over
  /// [surface], [tableRowStripe] or [tableRowSelected] alike, so hover never
  /// hides the fill beneath it: authored, or [foreground] at 4% (6% in a dark
  /// theme).
  Color get tableRowHover => _tableRowHover ?? _derived.tableRowHover;

  /// A selected row's fill, opaque: authored, or [primary] mixed into
  /// [surface] at 10% (18% in a dark theme) — pushed further toward [primary]
  /// where it would otherwise stand closer to [surface] than [tableRowHover]
  /// over [tableRowStripe] does, so selection never reads weaker than a
  /// hovered stripe.
  Color get tableRowSelected => _tableRowSelected ?? _derived.tableRowSelected;

  /// A selected row under the pointer: authored, or [tableRowHover] laid over
  /// [tableRowSelected].
  Color get tableRowSelectedHover =>
      _tableRowSelectedHover ??
      Color.alphaBlend(tableRowHover, tableRowSelected);

  // ── fields ── (the box of an input or a picker trigger, drawn as the
  // theme's `AdminFieldStyle` says)

  /// A field's fill: authored, or [surface].
  Color get fieldFill => _fieldFill ?? surface;

  /// A filled field's fill under the pointer: authored, or [hoverOverlay]
  /// laid over [fieldFill].
  Color get fieldFillHover =>
      _fieldFillHover ?? Color.alphaBlend(hoverOverlay, fieldFill);

  /// The bottom rule of a filled or underlined field: the edge that marks
  /// it as a field, so at least 3:1 against [fieldFill], [surface] and
  /// [background]. Authored, or [controlBorder] adjusted until it gets there.
  Color get fieldRule => _fieldRule ?? _derived.fieldRule;

  // ── soft and neutral fills ── (a tonal button, a filled neutral one)

  /// A soft, tonal fill: authored, or [primarySubtle]. It follows the brand.
  Color get softFill => _softFill ?? primarySubtle;

  /// Content on [softFill], at least 4.5:1 there: authored, or [primaryText]
  /// adjusted until it reads there. It follows the brand.
  Color get onSoft => _onSoft ?? _derived.onSoft;

  /// A filled neutral control, such as Carbon's secondary button: authored,
  /// or [foregroundSecondary].
  Color get neutralFill => _neutralFill ?? foregroundSecondary;

  /// [neutralFill] under the pointer: authored, or the neutral hover wash
  /// turned around, [surface] laid over [neutralFill] at
  /// [AdminStateLayer.hover], a step toward the page.
  Color get neutralFillHover =>
      _neutralFillHover ??
      Color.alphaBlend(
        surface.withValues(alpha: stateLayer.hover),
        neutralFill,
      );

  /// [neutralFill] pressed: authored, or [surface] laid over [neutralFill] at
  /// [AdminStateLayer.pressed].
  Color get neutralFillActive =>
      _neutralFillActive ??
      Color.alphaBlend(
        surface.withValues(alpha: stateLayer.pressed),
        neutralFill,
      );

  /// Content on [neutralFill], [neutralFillHover] and [neutralFillActive]:
  /// authored, or [foregroundOn] [neutralFill].
  Color get onNeutralFill => _onNeutralFill ?? foregroundOn(neutralFill);

  // ── status surfaces ── (soft fill / border derived from a status accent like
  // [success]/[warning]/[danger]/[info], so themes only author the accent)
  Color statusFill(Color accent) => Color.lerp(accent, surface, 0.88)!;
  Color statusBorder(Color accent) => Color.lerp(accent, surface, 0.62)!;

  /// Material scheme derived from this palette — light or dark per
  /// [brightness]. Every role is set, so stock Material widgets draw from the
  /// palette rather than from Material's fallbacks.
  ColorScheme get colorScheme {
    final dark = brightness == Brightness.dark;
    // Lowest → highest container steps away from the page, toward the text.
    final steps = [surface, background, surfaceMuted]
      ..sort((a, b) {
        final byLuminance = relativeLuminance(b)
            .compareTo(relativeLuminance(a));
        return dark ? -byLuminance : byLuminance;
      });
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primarySubtle,
      onPrimaryContainer: primaryText,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: primarySubtle,
      onSecondaryContainer: primaryText,
      tertiary: info,
      onTertiary: onInfo,
      tertiaryContainer: statusFill(info),
      onTertiaryContainer: infoText,
      error: danger,
      onError: onDanger,
      errorContainer: statusFill(danger),
      onErrorContainer: dangerText,
      surface: surface,
      onSurface: foreground,
      onSurfaceVariant: foregroundMuted,
      surfaceDim: dark ? steps.first : steps.last,
      surfaceBright: dark ? steps.last : steps.first,
      surfaceContainerLowest: steps[0],
      surfaceContainerLow: Color.lerp(steps[0], steps[1], 0.5),
      surfaceContainer: steps[1],
      surfaceContainerHigh: Color.lerp(steps[1], steps[2], 0.5),
      surfaceContainerHighest: steps[2],
      outline: controlBorder,
      outlineVariant: border,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: foreground,
      onInverseSurface: surface,
      inversePrimary: readableOn(primary, surfaces: [foreground]),
      surfaceTint: _transparent,
    );
  }

  AdminPalette copyWith({
    Color? primary,
    Color? primaryStrong,
    Color? primarySubtle,
    Color? primaryFaint,
    Color? surface,
    Color? background,
    Color? surfaceMuted,
    Color? foreground,
    Color? foregroundSecondary,
    Color? foregroundMuted,
    Color? foregroundSubtle,
    Color? foregroundFaint,
    Color? border,
    Color? borderSubtle,
    Color? success,
    Color? warning,
    Color? danger,
    Color? warningText,
    Color? info,
    Color? highlight,
    Color? modifiedFill,
    Color? tabDivider,
    AdminStateLayer? stateLayer,
    Color? onPrimary,
    Color? onDanger,
    Color? onSuccess,
    Color? onWarning,
    Color? onInfo,
    Color? primaryText,
    Color? dangerText,
    Color? successText,
    Color? infoText,
    Color? primaryHover,
    Color? primaryActive,
    Color? dangerHover,
    Color? dangerActive,
    Color? focusRing,
    Color? controlBorder,
    Color? controlAccent,
    Color? placeholder,
    Color? scrim,
    Color? shadow,
    List<Color>? chart,
    Color? listHighlight,
    Color? separator,
    Color? navSelectedFill,
    Color? navHoverFill,
    Color? navSelectedText,
    Color? navIndicator,
    Color? tableRowStripe,
    Color? tableRowHover,
    Color? tableRowSelected,
    Color? tableRowSelectedHover,
    Color? fieldFill,
    Color? fieldFillHover,
    Color? fieldRule,
    Color? softFill,
    Color? onSoft,
    Color? neutralFill,
    Color? neutralFillHover,
    Color? neutralFillActive,
    Color? onNeutralFill,
  }) {
    return AdminPalette(
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      primaryFaint: primaryFaint ?? this.primaryFaint,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      foreground: foreground ?? this.foreground,
      foregroundSecondary: foregroundSecondary ?? this.foregroundSecondary,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      foregroundSubtle: foregroundSubtle ?? this.foregroundSubtle,
      foregroundFaint: foregroundFaint ?? this.foregroundFaint,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      warningText: warningText ?? this.warningText,
      info: info ?? this.info,
      highlight: highlight ?? this.highlight,
      modifiedFill: modifiedFill ?? this.modifiedFill,
      tabDivider: tabDivider ?? this.tabDivider,
      stateLayer: stateLayer ?? this.stateLayer,
      onPrimary: onPrimary ?? _onPrimary,
      onDanger: onDanger ?? _onDanger,
      onSuccess: onSuccess ?? _onSuccess,
      onWarning: onWarning ?? _onWarning,
      onInfo: onInfo ?? _onInfo,
      primaryText: primaryText ?? _primaryText,
      dangerText: dangerText ?? _dangerText,
      successText: successText ?? _successText,
      infoText: infoText ?? _infoText,
      primaryHover: primaryHover ?? _primaryHover,
      primaryActive: primaryActive ?? _primaryActive,
      dangerHover: dangerHover ?? _dangerHover,
      dangerActive: dangerActive ?? _dangerActive,
      focusRing: focusRing ?? _focusRing,
      controlBorder: controlBorder ?? _controlBorder,
      controlAccent: controlAccent ?? _controlAccent,
      placeholder: placeholder ?? _placeholder,
      scrim: scrim ?? _scrim,
      shadow: shadow ?? _shadow,
      chart: chart ?? _chart,
      listHighlight: listHighlight ?? _listHighlight,
      separator: separator ?? _separator,
      navSelectedFill: navSelectedFill ?? _navSelectedFill,
      navHoverFill: navHoverFill ?? _navHoverFill,
      navSelectedText: navSelectedText ?? _navSelectedText,
      navIndicator: navIndicator ?? _navIndicator,
      tableRowStripe: tableRowStripe ?? _tableRowStripe,
      tableRowHover: tableRowHover ?? _tableRowHover,
      tableRowSelected: tableRowSelected ?? _tableRowSelected,
      tableRowSelectedHover: tableRowSelectedHover ?? _tableRowSelectedHover,
      fieldFill: fieldFill ?? _fieldFill,
      fieldFillHover: fieldFillHover ?? _fieldFillHover,
      fieldRule: fieldRule ?? _fieldRule,
      softFill: softFill ?? _softFill,
      onSoft: onSoft ?? _onSoft,
      neutralFill: neutralFill ?? _neutralFill,
      neutralFillHover: neutralFillHover ?? _neutralFillHover,
      neutralFillActive: neutralFillActive ?? _neutralFillActive,
      onNeutralFill: onNeutralFill ?? _onNeutralFill,
    );
  }

  /// Interpolates every colour. An optional role that neither side authored
  /// stays derived; otherwise the two resolved values are interpolated.
  static AdminPalette lerp(AdminPalette a, AdminPalette b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    Color? o(Color? x, Color? y, Color resolvedX, Color resolvedY) =>
        x == null && y == null ? null : c(resolvedX, resolvedY);
    List<Color>? chart() {
      if (a._chart == null && b._chart == null) return null;
      final (x, y) = (a.chart, b.chart);
      return [
        for (var i = 0; i < (t < 0.5 ? x.length : y.length); i++)
          c(x[i % x.length], y[i % y.length]),
      ];
    }

    return AdminPalette(
      primary: c(a.primary, b.primary),
      primaryStrong: c(a.primaryStrong, b.primaryStrong),
      primarySubtle: c(a.primarySubtle, b.primarySubtle),
      primaryFaint: c(a.primaryFaint, b.primaryFaint),
      surface: c(a.surface, b.surface),
      background: c(a.background, b.background),
      surfaceMuted: c(a.surfaceMuted, b.surfaceMuted),
      foreground: c(a.foreground, b.foreground),
      foregroundSecondary: c(a.foregroundSecondary, b.foregroundSecondary),
      foregroundMuted: c(a.foregroundMuted, b.foregroundMuted),
      foregroundSubtle: c(a.foregroundSubtle, b.foregroundSubtle),
      foregroundFaint: c(a.foregroundFaint, b.foregroundFaint),
      border: c(a.border, b.border),
      borderSubtle: c(a.borderSubtle, b.borderSubtle),
      success: c(a.success, b.success),
      warning: c(a.warning, b.warning),
      danger: c(a.danger, b.danger),
      warningText: c(a.warningText, b.warningText),
      info: c(a.info, b.info),
      highlight: c(a.highlight, b.highlight),
      modifiedFill: c(a.modifiedFill, b.modifiedFill),
      tabDivider: c(a.tabDivider, b.tabDivider),
      stateLayer: AdminStateLayer.lerp(a.stateLayer, b.stateLayer, t),
      onPrimary: o(a._onPrimary, b._onPrimary, a.onPrimary, b.onPrimary),
      onDanger: o(a._onDanger, b._onDanger, a.onDanger, b.onDanger),
      onSuccess: o(a._onSuccess, b._onSuccess, a.onSuccess, b.onSuccess),
      onWarning: o(a._onWarning, b._onWarning, a.onWarning, b.onWarning),
      onInfo: o(a._onInfo, b._onInfo, a.onInfo, b.onInfo),
      primaryText: o(
        a._primaryText,
        b._primaryText,
        a.primaryText,
        b.primaryText,
      ),
      dangerText: o(a._dangerText, b._dangerText, a.dangerText, b.dangerText),
      successText: o(
        a._successText,
        b._successText,
        a.successText,
        b.successText,
      ),
      infoText: o(a._infoText, b._infoText, a.infoText, b.infoText),
      primaryHover: o(
        a._primaryHover,
        b._primaryHover,
        a.primaryHover,
        b.primaryHover,
      ),
      primaryActive: o(
        a._primaryActive,
        b._primaryActive,
        a.primaryActive,
        b.primaryActive,
      ),
      dangerHover: o(
        a._dangerHover,
        b._dangerHover,
        a.dangerHover,
        b.dangerHover,
      ),
      dangerActive: o(
        a._dangerActive,
        b._dangerActive,
        a.dangerActive,
        b.dangerActive,
      ),
      focusRing: o(a._focusRing, b._focusRing, a.focusRing, b.focusRing),
      controlBorder: o(
        a._controlBorder,
        b._controlBorder,
        a.controlBorder,
        b.controlBorder,
      ),
      controlAccent: o(
        a._controlAccent,
        b._controlAccent,
        a.controlAccent,
        b.controlAccent,
      ),
      placeholder: o(
        a._placeholder,
        b._placeholder,
        a.placeholder,
        b.placeholder,
      ),
      scrim: o(a._scrim, b._scrim, a.scrim, b.scrim),
      shadow: o(a._shadow, b._shadow, a.shadow, b.shadow),
      chart: chart(),
      listHighlight: o(
        a._listHighlight,
        b._listHighlight,
        a.listHighlight,
        b.listHighlight,
      ),
      separator: o(a._separator, b._separator, a.separator, b.separator),
      navSelectedFill: o(
        a._navSelectedFill,
        b._navSelectedFill,
        a.navSelectedFill,
        b.navSelectedFill,
      ),
      navHoverFill: o(
        a._navHoverFill,
        b._navHoverFill,
        a.navHoverFill,
        b.navHoverFill,
      ),
      navSelectedText: o(
        a._navSelectedText,
        b._navSelectedText,
        a.navSelectedText,
        b.navSelectedText,
      ),
      navIndicator: o(
        a._navIndicator,
        b._navIndicator,
        a.navIndicator,
        b.navIndicator,
      ),
      tableRowStripe: o(
        a._tableRowStripe,
        b._tableRowStripe,
        a.tableRowStripe,
        b.tableRowStripe,
      ),
      tableRowHover: o(
        a._tableRowHover,
        b._tableRowHover,
        a.tableRowHover,
        b.tableRowHover,
      ),
      tableRowSelected: o(
        a._tableRowSelected,
        b._tableRowSelected,
        a.tableRowSelected,
        b.tableRowSelected,
      ),
      tableRowSelectedHover: o(
        a._tableRowSelectedHover,
        b._tableRowSelectedHover,
        a.tableRowSelectedHover,
        b.tableRowSelectedHover,
      ),
      fieldFill: o(a._fieldFill, b._fieldFill, a.fieldFill, b.fieldFill),
      fieldFillHover: o(
        a._fieldFillHover,
        b._fieldFillHover,
        a.fieldFillHover,
        b.fieldFillHover,
      ),
      fieldRule: o(a._fieldRule, b._fieldRule, a.fieldRule, b.fieldRule),
      softFill: o(a._softFill, b._softFill, a.softFill, b.softFill),
      onSoft: o(a._onSoft, b._onSoft, a.onSoft, b.onSoft),
      neutralFill: o(
        a._neutralFill,
        b._neutralFill,
        a.neutralFill,
        b.neutralFill,
      ),
      neutralFillHover: o(
        a._neutralFillHover,
        b._neutralFillHover,
        a.neutralFillHover,
        b.neutralFillHover,
      ),
      neutralFillActive: o(
        a._neutralFillActive,
        b._neutralFillActive,
        a.neutralFillActive,
        b.neutralFillActive,
      ),
      onNeutralFill: o(
        a._onNeutralFill,
        b._onNeutralFill,
        a.onNeutralFill,
        b.onNeutralFill,
      ),
    );
  }

  /// Returns this palette rebranded with [seed] as the primary colour. Use it
  /// to brand any theme for a client by swapping just the accent.
  ///
  /// The seed's lightness is nudged, minimally, until white or near-black
  /// reads on it at 4.5:1, so the primary fill is AA for any seed.
  /// [primaryStrong] is recomputed from it, [primarySubtle] and
  /// [primaryFaint] tint it toward this palette's own [surface] (dark tints in
  /// a dark theme), and the authored primary-derived roles ([onPrimary],
  /// [primaryText], [primaryHover], [primaryActive], [focusRing],
  /// [controlAccent]) are dropped so they re-derive from the seed, as is a
  /// [navIndicator] that draws a bar, and the table selection
  /// ([tableRowSelected], [tableRowSelectedHover]), so the selected item
  /// takes the brand. The navigation selection keeps its anatomy in the
  /// brand's colour: a selection filled with the primary itself (Ant's dark
  /// sider) is filled with the seed under its readable on-colour; a neutral
  /// one (Carbon's `$layer-selected`, Fluent's subtle fill, shadcn's
  /// `--sidebar-accent`) is kept, the indicator carrying the brand; a tinted
  /// one ([navSelectedFill], [navSelectedText]) re-derives from the brand's
  /// tint. The neutral [navHoverFill], [listHighlight], [separator],
  /// [tableRowStripe] and [tableRowHover] are kept, as is a transparent
  /// [navIndicator]. The soft fill ([softFill], [onSoft]) re-derives from
  /// the brand's tint; the field roles ([fieldFill], [fieldFillHover],
  /// [fieldRule]) and the neutral fill ([neutralFill] and its states,
  /// [onNeutralFill]) are kept. [chart] is kept: charts don't follow the
  /// brand. So is the [stateLayer].
  AdminPalette branded(Color seed) {
    final fill = _withReadableForeground(seed);
    final dark = brightness == Brightness.dark;
    final selection = _navSelectedFill;
    final (Color? navFill, Color? navText) = switch (selection) {
      null => (null, null),
      _ when contrastRatio(selection, primary) < _sameColour => (
        fill,
        foregroundOn(fill),
      ),
      _ when _isNeutral(selection) => (selection, _navSelectedText),
      _ => (null, null),
    };
    return AdminPalette(
      primary: fill,
      primaryStrong: _shadeAway(fill, foregroundOn(fill), _stateStep),
      primarySubtle: Color.lerp(fill, surface, dark ? 0.80 : 0.88)!,
      primaryFaint: Color.lerp(fill, surface, dark ? 0.88 : 0.94)!,
      surface: surface,
      background: background,
      surfaceMuted: surfaceMuted,
      foreground: foreground,
      foregroundSecondary: foregroundSecondary,
      foregroundMuted: foregroundMuted,
      foregroundSubtle: foregroundSubtle,
      foregroundFaint: foregroundFaint,
      border: border,
      borderSubtle: borderSubtle,
      success: success,
      warning: warning,
      danger: danger,
      warningText: warningText,
      info: info,
      highlight: highlight,
      modifiedFill: modifiedFill,
      tabDivider: tabDivider,
      stateLayer: stateLayer,
      onDanger: _onDanger,
      onSuccess: _onSuccess,
      onWarning: _onWarning,
      onInfo: _onInfo,
      dangerText: _dangerText,
      successText: _successText,
      infoText: _infoText,
      dangerHover: _dangerHover,
      dangerActive: _dangerActive,
      controlBorder: _controlBorder,
      placeholder: _placeholder,
      scrim: _scrim,
      shadow: _shadow,
      chart: _chart,
      listHighlight: _listHighlight,
      separator: _separator,
      navSelectedFill: navFill,
      navHoverFill: _navHoverFill,
      navSelectedText: navText,
      navIndicator: _navIndicator?.a == 0 ? _navIndicator : null,
      tableRowStripe: _tableRowStripe,
      tableRowHover: _tableRowHover,
      fieldFill: _fieldFill,
      fieldFillHover: _fieldFillHover,
      fieldRule: _fieldRule,
      neutralFill: _neutralFill,
      neutralFillHover: _neutralFillHover,
      neutralFillActive: _neutralFillActive,
      onNeutralFill: _onNeutralFill,
    );
  }

  /// [seed] with its lightness moved the least distance (either way) that
  /// lets [foregroundOn] reach 4.5:1 on it.
  Color _withReadableForeground(Color seed) {
    bool passes(Color c) => contrastRatio(foregroundOn(c), c) >= _textContrast;
    if (passes(seed)) return seed;
    final hsl = HSLColor.fromColor(seed);
    for (var step = 1; step <= 200; step++) {
      for (final delta in [-step * 0.005, step * 0.005]) {
        final lightness = hsl.lightness + delta;
        if (lightness < 0 || lightness > 1) continue;
        final candidate = hsl.withLightness(lightness).toColor();
        if (passes(candidate)) return candidate;
      }
    }
    return seed;
  }

  /// The authored colours, in declaration order: the required roles, then the
  /// optional roles (null where left to derive). [chart] is compared apart.
  List<Color?> get _authored => [
    primary,
    primaryStrong,
    primarySubtle,
    primaryFaint,
    surface,
    background,
    surfaceMuted,
    foreground,
    foregroundSecondary,
    foregroundMuted,
    foregroundSubtle,
    foregroundFaint,
    border,
    borderSubtle,
    success,
    warning,
    danger,
    warningText,
    info,
    highlight,
    modifiedFill,
    tabDivider,
    _onPrimary,
    _onDanger,
    _onSuccess,
    _onWarning,
    _onInfo,
    _primaryText,
    _dangerText,
    _successText,
    _infoText,
    _primaryHover,
    _primaryActive,
    _dangerHover,
    _dangerActive,
    _focusRing,
    _controlBorder,
    _controlAccent,
    _placeholder,
    _scrim,
    _shadow,
    _listHighlight,
    _separator,
    _navSelectedFill,
    _navHoverFill,
    _navSelectedText,
    _navIndicator,
    _tableRowStripe,
    _tableRowHover,
    _tableRowSelected,
    _tableRowSelectedHover,
    _fieldFill,
    _fieldFillHover,
    _fieldRule,
    _softFill,
    _onSoft,
    _neutralFill,
    _neutralFillHover,
    _neutralFillActive,
    _onNeutralFill,
  ];

  /// Two palettes are equal when they author the same colours: the same
  /// required roles, the same optional roles (and chart) set to the same
  /// values, and the same [stateLayer]. The derived roles follow from those,
  /// so they are not compared.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPalette &&
          listEquals(other._authored, _authored) &&
          listEquals(other._chart, _chart) &&
          other.stateLayer == stateLayer;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_authored),
    _chart == null ? null : Object.hashAll(_chart),
    stateLayer,
  );
}

const _textContrast = 4.5;
const _uiContrast = 3.0;

/// Under this contrast two colours read as one: a selection filled with the
/// primary itself.
const _sameColour = 1.1;

/// Whether [color] is a grey: its channels within a few steps of each other,
/// with no hue a brand would recolour.
bool _isNeutral(Color color) {
  final channels = [color.r, color.g, color.b];
  return channels.reduce(math.max) - channels.reduce(math.min) < 0.04;
}

const _stateStep = 0.07;

/// How much further from the page a selected table row stands than a hovered
/// stripe, as a contrast ratio: enough that the two never read as one.
const _selectionLead = 1.04;

/// Material's hover and pressed state-layer opacities.
const _hoverLayer = 0.08;
const _pressedLayer = 0.12;

/// Designed categorical fallbacks, ordered so neighbours differ in hue and
/// warmth. Each entry is still lifted to 3:1 against the palette's surfaces.
const _chartLight = [
  Color(0xFF2563EB),
  Color(0xFFEA580C),
  Color(0xFF0D9488),
  Color(0xFFE11D48),
  Color(0xFF7C3AED),
  Color(0xFF16A34A),
  Color(0xFFC026D3),
  Color(0xFFB45309),
];
const _chartDark = [
  Color(0xFF60A5FA),
  Color(0xFFFB923C),
  Color(0xFF2DD4BF),
  Color(0xFFFB7185),
  Color(0xFFA78BFA),
  Color(0xFF4ADE80),
  Color(0xFFE879F9),
  Color(0xFFFBBF24),
];

final _derivedCache = Expando<_DerivedRoles>('AdminPalette derived roles');

/// Cached [AdminPalette.readableOn] answers kept per palette before the cache
/// starts over — well above what a theme's own roles and widgets ask, so only
/// a stream of arbitrary colours (a picker being dragged) ever resets it.
const _readableCacheLimit = 512;

/// One [AdminPalette.readableOn] question, compared by value.
@immutable
class _ReadableQuery {
  final Color accent;
  final List<Color> surfaces;
  final double minContrast;

  const _ReadableQuery(this.accent, this.surfaces, this.minContrast);

  @override
  bool operator ==(Object other) =>
      other is _ReadableQuery &&
      other.accent == accent &&
      other.minContrast == minContrast &&
      listEquals(other.surfaces, surfaces);

  @override
  int get hashCode =>
      Object.hash(accent, minContrast, Object.hashAll(surfaces));
}

/// The derived roles that take a search to compute, worked out once per
/// palette instance.
class _DerivedRoles {
  final AdminPalette p;
  final readable = <_ReadableQuery, Color>{};

  _DerivedRoles(this.p);

  late final Color primaryText = p.readableOn(
    p.primary,
    surfaces: [p.surface, p.background, p.primarySubtle],
  );
  late final Color dangerText = _statusText(p.danger);
  late final Color successText = _statusText(p.success);
  late final Color infoText = _statusText(p.info);

  Color _statusText(Color accent) => p.readableOn(
    accent,
    surfaces: [p.surface, p.background, p.statusFill(accent)],
  );

  late final Color focusRing =
      _worst(p.primary, [p.surface, p.background, p.fieldFill]) >= _uiContrast
      ? p.primary
      : p.primaryText;

  late final Color controlBorder = _search(
    p.border,
    (t) => Color.lerp(p.border, p.foreground, t)!,
    [p.surface, p.background],
    _uiContrast,
  );

  late final Color controlAccent = p.readableOn(
    p.primary,
    surfaces: [p.surface, p.background, p.fieldFill],
    minContrast: _uiContrast,
  );

  late final Color onControlAccent = p.controlAccent == p.primary
      ? p.onPrimary
      : p.foregroundOn(p.controlAccent);

  late final Color controlAccentHover = p.controlAccent == p.primary
      ? p.primaryHover
      : _StateLayer.under(
              p.controlAccent,
              p.onControlAccent,
            )?.at(_hoverLayer) ??
            _shadeAway(p.controlAccent, p.onControlAccent, _stateStep);

  late final Color placeholder =
      contrastRatio(p.foregroundMuted, p.surface) >= _textContrast
      ? p.foregroundMuted
      : p.readableOn(p.foregroundSubtle, surfaces: [p.surface]);

  late final Color foregroundMutedOnTint = p.readableOn(
    p.foregroundMuted,
    surfaces: [
      p.surface,
      p.background,
      p.surfaceMuted,
      p.primarySubtle,
      p.primaryFaint,
      p.listHighlight,
      p.tableRowSelected,
      p.tableRowSelectedHover,
      Color.alphaBlend(p.hoverOverlay, p.surface),
    ],
  );

  late final _StateLayer? _primaryLayer = _StateLayer.under(
    p.primary,
    p.onPrimary,
  );

  late final Color primaryHover =
      _primaryLayer?.at(_hoverLayer) ??
      (contrastRatio(p.onPrimary, p.primaryStrong) >=
              math.min(_textContrast, contrastRatio(p.onPrimary, p.primary))
          ? p.primaryStrong
          : _shadeAway(p.primary, p.onPrimary, _stateStep));

  late final Color primaryActive =
      _primaryLayer?.at(_pressedLayer) ?? _primaryActiveStep();

  Color _primaryActiveStep() {
    final rest = HSLColor.fromColor(p.primary).lightness;
    final hover = HSLColor.fromColor(p.primaryHover);
    final delta = hover.lightness - rest;
    if (delta.abs() < 0.02) {
      return _shadeAway(p.primary, p.onPrimary, 2 * _stateStep);
    }
    for (final share in const [1.0, 0.5, 0.25]) {
      final lightness = hover.lightness + delta * share;
      if (lightness < 0 || lightness > 1) continue;
      final candidate = hover.withLightness(lightness).toColor();
      if (contrastRatio(p.onPrimary, candidate) >= _textContrast) {
        return candidate;
      }
    }
    return p.primaryHover;
  }

  /// The lightness step [AdminPalette.primaryStrong] takes from
  /// [AdminPalette.primary], as a ratio applied to [AdminPalette.danger] and
  /// kept within a visible, not heavy-handed, range.
  late final double _dangerStep = () {
    final rest = HSLColor.fromColor(p.primary).lightness;
    final hover = HSLColor.fromColor(p.primaryStrong).lightness;
    final ratio = rest == 0 ? 1.0 : hover / rest;
    final step = HSLColor.fromColor(p.danger).lightness * (1 - ratio).abs();
    return step.clamp(0.03, _stateStep);
  }();

  late final _StateLayer? _dangerLayer = _StateLayer.under(
    p.danger,
    p.onDanger,
  );

  late final Color dangerHover =
      _dangerLayer?.at(_hoverLayer) ??
      _shadeAway(p.danger, p.onDanger, _dangerStep);

  late final Color dangerActive =
      _dangerLayer?.at(_pressedLayer) ??
      _shadeAway(p.danger, p.onDanger, 2 * _dangerStep);

  late final Color listHighlight = Color.alphaBlend(
    p.foreground.withValues(alpha: _dark ? 0.08 : 0.06),
    p.surface,
  );

  late final Color separator =
      contrastRatio(p.border, p.surface) >=
          contrastRatio(p.borderSubtle, p.surface)
      ? p.border
      : p.borderSubtle;

  late final Color navHoverFill = Color.alphaBlend(
    p.foreground.withValues(alpha: _dark ? 0.08 : 0.05),
    p.background,
  );

  late final Color navSelectedFill = _search(
    p.primarySubtle,
    (t) => Color.lerp(p.primarySubtle, p.primary, t)!,
    [p.background],
    contrastRatio(p.navHoverFill, p.background),
  );

  late final Color fieldRule = p.readableOn(
    p.controlBorder,
    surfaces: [p.fieldFill, p.surface, p.background],
    minContrast: _uiContrast,
  );

  late final Color onSoft = p.readableOn(p.primaryText, surfaces: [p.softFill]);

  late final Color navSelectedText = p.readableOn(
    p.primaryText,
    surfaces: [p.navSelectedFill],
  );

  late final Color navIndicator = p.readableOn(
    p.primary,
    surfaces: [p.background, p.navSelectedFill],
    minContrast: _uiContrast,
  );

  late final Color tableRowStripe = Color.alphaBlend(
    p.foreground.withValues(alpha: _dark ? 0.035 : 0.025),
    p.surface,
  );

  late final Color tableRowHover = p.foreground.withValues(
    alpha: _dark ? 0.06 : 0.04,
  );

  late final Color tableRowSelected = () {
    final start = Color.lerp(p.surface, p.primary, _dark ? 0.18 : 0.10)!;
    final hoveredStripe = Color.alphaBlend(p.tableRowHover, p.tableRowStripe);
    return _search(start, (t) => Color.lerp(start, p.primary, t)!, [
      p.surface,
    ], contrastRatio(hoveredStripe, p.surface) * _selectionLead);
  }();

  bool get _dark => p.brightness == Brightness.dark;

  late final List<Color> chart = [
    for (final c in p.brightness == Brightness.dark ? _chartDark : _chartLight)
      p.readableOn(
        c,
        surfaces: [p.surface, p.background],
        minContrast: _uiContrast,
      ),
  ];

  late final AdminSyntaxColors syntax = () {
    final key = p.readableOn(p.infoText);
    final violet = HSLColor.fromAHSL(
      1,
      270,
      0.6,
      p.brightness == Brightness.dark ? 0.75 : 0.5,
    ).toColor();
    // Literals are violet, or a neutral when the keys already read violet, so
    // `true` and `null` never share a hue with keys or with the error red.
    final keyHue = HSLColor.fromColor(key).hue;
    final gap = (keyHue - 270).abs() % 360;
    final keyIsViolet = math.min(gap, 360 - gap) < 35;
    return AdminSyntaxColors(
      key: key,
      string: p.readableOn(p.successText),
      number: p.readableOn(p.warningText),
      literal: p.readableOn(keyIsViolet ? p.foregroundSecondary : violet),
      punctuation: p.readableOn(p.foregroundMuted),
      comment: p.readableOn(p.foregroundSubtle),
    );
  }();
}

/// The hover and pressed treatment of a light fill under dark content:
/// Material's state layer, that content laid over the fill — or white, the same
/// small step the other way, where even the pressed layer would take the
/// content under 4.5:1 (or under the fill's own contrast, when that is lower).
/// Chosen once per fill, so both states move the same way.
class _StateLayer {
  final Color fill;
  final Color layer;

  const _StateLayer._(this.fill, this.layer);

  /// Null when [on] is the lighter of the two: those fills step by shade.
  static _StateLayer? under(Color fill, Color on) {
    if (relativeLuminance(on) >= relativeLuminance(fill)) return null;
    final floor = math.min(_textContrast, contrastRatio(on, fill));
    final pressed = _StateLayer._(fill, on).at(_pressedLayer);
    return _StateLayer._(
      fill,
      contrastRatio(on, pressed) >= floor ? on : _white,
    );
  }

  Color at(double opacity) =>
      Color.alphaBlend(layer.withValues(alpha: opacity), fill);
}

/// [fill] with its HSL lightness moved [amount] away from [on], so content
/// drawn in [on] gains contrast — stopping short of pure white or black, and
/// moving toward [on] instead when less than half the move fits (a near-white
/// or near-black fill).
Color _shadeAway(Color fill, Color on, double amount) {
  final hsl = HSLColor.fromColor(fill);
  final sign = relativeLuminance(on) < relativeLuminance(fill) ? 1 : -1;
  var lightness = (hsl.lightness + sign * amount).clamp(0.03, 0.97);
  if ((lightness - hsl.lightness).abs() < amount / 2) {
    lightness = hsl.lightness - sign * amount;
  }
  return hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
}

/// The lowest contrast [color] has against any of [surfaces] — as computed,
/// and as both are painted, so a colour found right at a threshold still
/// meets it on screen.
double _worst(Color color, List<Color> surfaces) {
  final painted = _painted(color);
  return surfaces
      .map(
        (s) => math.min(
          contrastRatio(color, s),
          contrastRatio(painted, _painted(s)),
        ),
      )
      .reduce(math.min);
}

/// [color] at the 8 bits a channel it is painted with.
Color _painted(Color color) => Color(color.toARGB32());

Color _readable(Color accent, List<Color> surfaces, double minContrast) {
  final hsl = HSLColor.fromColor(accent);
  final target = _worst(_black, surfaces) >= _worst(_white, surfaces) ? 0 : 1;
  return _search(
    accent,
    (t) => hsl
        .withLightness(
          (hsl.lightness + (target - hsl.lightness) * t).clamp(0.0, 1.0),
        )
        .toColor(),
    surfaces,
    minContrast,
  );
}

/// The colour along [path] (t from 0 at [start] to 1) closest to [start] that
/// reaches [minContrast] against every one of [surfaces]: coarse steps to the
/// first passing point, then a bisection back toward the last failing one.
/// Returns the far end when nothing along the path passes.
Color _search(
  Color start,
  Color Function(double t) path,
  List<Color> surfaces,
  double minContrast,
) {
  if (_worst(start, surfaces) >= minContrast) return start;
  const step = 0.02;
  for (var t = step; t < 1 + step / 2; t += step) {
    final hi = math.min(t, 1.0);
    if (_worst(path(hi), surfaces) < minContrast) continue;
    var (lo, pass) = (hi - step, hi);
    for (var i = 0; i < 8; i++) {
      final mid = (lo + pass) / 2;
      if (_worst(path(mid), surfaces) >= minContrast) {
        pass = mid;
      } else {
        lo = mid;
      }
    }
    return path(pass);
  }
  return path(1);
}
