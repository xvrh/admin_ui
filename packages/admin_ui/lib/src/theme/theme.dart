import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'contrast.dart';
import 'field_style.dart';
import 'palette.dart';
import 'sizes.dart';
import 'spacing.dart';
import 'stroke.dart';
import 'tokens.dart';
import 'typography.dart';

/// Builds the admin [ThemeData] for a given token set and attaches [tokens] as
/// a [ThemeExtension] so widgets can read it via `context.colors` /
/// `context.type`.
/// Material-rendered chrome (inputs, cards, dialogs, menus, snack bars,
/// selection controls) is driven by the tokens too — surfaces from the
/// palette, corners from the radii (menus, dialogs, fields and buttons from
/// their role radii), text from the type ramp — so a stock Material widget
/// dropped into the admin tracks the theme: a bare `Text` is set in
/// [AdminTypography.body], and a stock [TextField] in
/// [AdminTypography.fieldText], as tall as a kit input of the medium size and
/// drawn in the theme's field anatomy ([buildInputDecorationTheme]). The
/// accent is drawn as the kit's own controls draw it, at its contrast
/// target: a button's or a selected list tile's text in
/// [AdminPalette.primaryText], a checked, selected or on control and a tab
/// indicator in [AdminPalette.controlAccent]. Under a light brand accent,
/// [AdminPalette.primary] itself is too faint for either.
/// Density is pinned to [VisualDensity.standard] with shrink-wrapped tap
/// targets, so control heights don't change by platform.
ThemeData buildAppTheme(AdminTokens tokens) {
  final palette = tokens.palette;
  final type = tokens.typography;
  final radii = tokens.radii;
  final layer = palette.stateLayer;

  var base = ThemeData(
    colorScheme: palette.colorScheme,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  final textTheme = type.spec
      .applyFontTheme(_rampTextTheme(base.textTheme, type.spec))
      .apply(displayColor: palette.foreground, bodyColor: palette.foreground);

  final surfaceShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.radius),
    side: BorderSide(color: palette.border),
  );
  final menuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.radiusMenu),
    side: BorderSide(color: palette.border),
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.button(ControlSize.medium)),
  );
  final menuElevation = _materialElevation(tokens.elevation.md);
  final menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(palette.surface),
    surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
    shadowColor: WidgetStatePropertyAll(palette.shadow),
    elevation: WidgetStatePropertyAll(menuElevation),
    shape: WidgetStatePropertyAll(menuShape),
  );
  final quietButtonStyle = ButtonStyle(
    shape: WidgetStatePropertyAll(buttonShape),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? palette.foregroundSubtle
          : palette.foregroundSecondary,
    ),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return palette.pressedOverlay;
      if (states.contains(WidgetState.hovered)) return palette.hoverOverlay;
      if (states.contains(WidgetState.focused)) return palette.focusOverlay;
      return null;
    }),
  );
  Color? whenSelected(Set<WidgetState> states, Color selected) {
    if (!states.contains(WidgetState.selected)) return null;
    return states.contains(WidgetState.disabled)
        ? selected.withValues(alpha: layer.disabledContent)
        : selected;
  }

  final inputTheme = buildInputDecorationTheme(tokens);

  base = base.copyWith(
    primaryColor: palette.primary,
    extensions: [tokens],
    textTheme: textTheme,
    scaffoldBackgroundColor: palette.background,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: palette.background,
      foregroundColor: palette.foregroundMuted,
      elevation: 0,
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelColor: palette.foreground,
      indicatorColor: palette.controlAccent,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    inputDecorationTheme: inputTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size(10, tokens.sizes.medium),
        shape: buttonShape,
        foregroundColor: palette.primaryText,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: buttonShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: buttonShape,
        foregroundColor: palette.primaryText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: quietButtonStyle),
    iconButtonTheme: IconButtonThemeData(style: quietButtonStyle),
    listTileTheme: base.listTileTheme.copyWith(
      selectedColor: palette.primaryText,
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: tokens.stroke.hairline,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: const Color(0x00000000),
      shadowColor: palette.shadow,
      elevation: menuElevation,
      shape: menuShape,
    ),
    menuTheme: MenuThemeData(style: menuStyle),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: menuStyle,
      inputDecorationTheme: inputTheme,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.foreground,
      contentTextStyle: type.body.copyWith(color: palette.surface),
      actionTextColor: base.colorScheme.inversePrimary,
      closeIconColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.radius),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            whenSelected(states, palette.controlAccent) ??
            const Color(0x00000000),
      ),
      checkColor: WidgetStatePropertyAll(palette.onControlAccent),
      side: BorderSide(
        color: palette.controlBorder,
        width: tokens.stroke.controlStrong,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            whenSelected(states, palette.controlAccent) ??
            palette.controlBorder,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            whenSelected(states, palette.onControlAccent) ??
            palette.controlBorder,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            whenSelected(states, palette.controlAccent) ?? palette.border,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            whenSelected(states, palette.controlAccent) ??
            palette.controlBorder,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged)) {
          return palette.foregroundMuted;
        }
        if (states.contains(WidgetState.hovered)) {
          return palette.foregroundSubtle;
        }
        return palette.foregroundFaint;
      }),
      radius: Radius.circular(radii.radiusSmall),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: palette.surface,
      surfaceTintColor: const Color(0x00000000),
      shadowColor: palette.shadow,
      elevation: 0,
      shape: surfaceShape,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: palette.surface,
      surfaceTintColor: const Color(0x00000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.radiusDialog),
        side: BorderSide(color: palette.border),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
      linearTrackColor: palette.borderSubtle,
      circularTrackColor: const Color(0x00000000),
    ),
    // A bare Material Tooltip gets this chip as it is: centred below its
    // target, with no arrow. Tip adds a side, the theme's arrow and a
    // shortcut on top of it.
    tooltipTheme: TooltipThemeData(
      // A hover delay, not motion: a timer that paces the pointer, which
      // reduced motion leaves alone.
      waitDuration: const Duration(milliseconds: 400),
      // A long tip wraps at a readable measure instead of spanning the view.
      constraints: BoxConstraints(maxWidth: tokens.overlay.tooltipMaxWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.foreground,
        borderRadius: BorderRadius.circular(radii.radiusSmall),
      ),
      textStyle: type.caption.copyWith(color: palette.surface),
    ),
  );

  return base;
}

/// [theme] on the kit's ramp: each role takes the size, line and letter
/// spacing of the [AdminTypography] role it stands in for, and its weight.
/// The body roles are [AdminTypography.fieldText] (what a [TextField]
/// edits), [AdminTypography.body] (a bare [Text]) and
/// [AdminTypography.caption]; the labels [AdminTypography.button],
/// [AdminTypography.sectionLabel] and [AdminTypography.micro]; the medium and
/// small titles [AdminTypography.heading] and [AdminTypography.bodyStrong].
/// Display, headline and the large title take the ramp's own steps and keep
/// Material's weights. `headlineLarge` is left as it is. Weights are set
/// here, before [AdminTypeSpec.applyFontTheme] picks the font for each.
TextTheme _rampTextTheme(TextTheme theme, AdminTypeSpec spec) {
  final r = spec.ramp;
  TextStyle? on(TextStyle? style, AdminTypeStep step, [FontWeight? weight]) =>
      style?.copyWith(
        fontSize: step.size * spec.scale,
        height: step.line / step.size,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: step.letterSpacing + spec.tracking,
        fontWeight: weight,
      );
  return theme.copyWith(
    displayLarge: on(theme.displayLarge, r.displayLarge),
    displayMedium: on(theme.displayMedium, r.displayMedium),
    displaySmall: on(theme.displaySmall, r.displaySmall),
    headlineMedium: on(theme.headlineMedium, r.headlineMedium),
    headlineSmall: on(theme.headlineSmall, r.headlineSmall),
    titleLarge: on(theme.titleLarge, r.titleLarge),
    titleMedium: on(theme.titleMedium, r.heading, spec.heading),
    titleSmall: on(theme.titleSmall, r.body, spec.strong),
    bodyLarge: on(theme.bodyLarge, r.fieldText, spec.body),
    bodyMedium: on(theme.bodyMedium, r.body, spec.body),
    bodySmall: on(theme.bodySmall, r.caption, spec.body),
    labelLarge: on(theme.labelLarge, r.button, spec.strong),
    labelMedium: on(theme.labelMedium, r.sectionLabel, spec.heading),
    labelSmall: on(theme.labelSmall, r.micro, spec.strong),
  );
}

/// The field chrome every text input in the admin shares, in the theme's
/// field anatomy ([AdminTokens.field], resolved per state by
/// [resolveFieldChrome]): a [FieldBorder] at [AdminRadii.radiusField] — by
/// default an [AdminPalette.controlBorder] outline at rest, a stronger tone
/// under the pointer, an [AdminPalette.focusRing] outline when focused and a
/// red one in error, at the widths of [AdminTokens.stroke] — its fill,
/// [AdminPalette.placeholder] hints, and padding that centres an
/// [AdminTypography.fieldText] line in the theme's medium control height.
/// Installed as the theme's input decoration theme, and the source
/// `fieldInputDecoration` builds from. `buildAppTheme` sets the text theme's
/// `bodyLarge`, which a [TextField] edits in, to [AdminTypography.fieldText],
/// so a stock [TextField] or [TextFormField] is exactly as tall as a kit
/// input of the medium size, and looks the same.
///
/// The states live in one stateful [InputDecorationThemeData.border] (and the
/// matching outline / indicator sides) rather than in `enabledBorder` /
/// `focusedBorder`, which would override a caller's own `border:`: a field
/// that asks for `InputBorder.none`, or a smaller radius, gets exactly that.
InputDecorationThemeData buildInputDecorationTheme(AdminTokens tokens) {
  final palette = tokens.palette;
  final sizes = tokens.sizes;
  FieldChromeSpec chrome(Set<WidgetState> states) =>
      resolveFieldChrome(tokens, states);
  bool drawn(BorderSide side) => side.style != BorderStyle.none;

  return InputDecorationThemeData(
    border: FieldBorder.of(tokens),
    // For a caller's own border, which the decorator redraws in these.
    outlineBorder: WidgetStateBorderSide.resolveWith((states) {
      final c = chrome(states);
      return drawn(c.outline) ? c.outline : c.rule;
    }),
    activeIndicatorBorder: WidgetStateBorderSide.resolveWith((states) {
      final c = chrome(states);
      return drawn(c.rule) ? c.rule : c.outline;
    }),
    filled: true,
    isDense: true,
    fillColor: WidgetStateColor.resolveWith((states) => chrome(states).fill),
    hoverColor: const Color(0x00000000),
    hintStyle: TextStyle(color: palette.placeholder),
    contentPadding: EdgeInsets.symmetric(
      horizontal: sizes.fieldPaddingX,
      vertical: fieldPaddingY(tokens.typography, sizes.medium),
    ),
  );
}

/// A field's outline as one stateful [InputBorder]: [side] gives the border
/// in each set of states (see [fieldBorderSide]), resolved by the
/// [InputDecorator] as the pointer, focus and validation change, and [halo]
/// the band drawn just outside it (see [fieldFocusHalo]), if any. It draws
/// an outlined box only; [FieldBorder] draws the theme's field anatomy.
///
/// Unlike [WidgetStateInputBorder.resolveWith], it keeps its states through
/// [copyWith]: a caller that only rounds the corners differently keeps the
/// hover, focus, error and disabled looks. Passing a `borderSide` pins that
/// side in every state. Drawn directly, outside an [InputDecorator], it is
/// the resting outline.
///
/// Two are equal when they draw the same outline and halo in every state a
/// field takes — at rest, hovered, focused, disabled, and in error focused
/// or not — so a border for another validation state or another accent is a
/// change to an [InputDecoration] or a theme.
class FieldOutlineBorder extends OutlineInputBorder
    implements WidgetStateInputBorder {
  final BorderSide Function(Set<WidgetState> states) side;

  /// The band outside the outline in each set of states; null draws none.
  final BorderSide Function(Set<WidgetState> states)? halo;

  FieldOutlineBorder({
    required this.side,
    this.halo,
    super.borderRadius,
    super.gapPadding = 0,
  }) : super(borderSide: side(const {}));

  static const _states = <Set<WidgetState>>[
    {},
    {WidgetState.hovered},
    {WidgetState.focused},
    {WidgetState.disabled},
    {WidgetState.error},
    {WidgetState.error, WidgetState.focused},
  ];

  BorderSide _halo(Set<WidgetState> states) =>
      halo?.call(states) ?? BorderSide.none;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldOutlineBorder &&
        other.runtimeType == runtimeType &&
        other.borderRadius == borderRadius &&
        other.gapPadding == gapPadding &&
        _states.every(
          (states) =>
              other.side(states) == side(states) &&
              other._halo(states) == _halo(states),
        );
  }

  @override
  int get hashCode => Object.hash(
    borderRadius,
    gapPadding,
    Object.hashAll(_states.map(side)),
    Object.hashAll(_states.map(_halo)),
  );

  @override
  InputBorder resolve(Set<WidgetState> states) => halo == null
      ? OutlineInputBorder(
          borderSide: side(states),
          borderRadius: borderRadius,
          gapPadding: gapPadding,
        )
      : _HaloOutlineBorder(
          borderSide: side(states),
          halo: _halo(states),
          borderRadius: borderRadius,
          gapPadding: gapPadding,
        );

  @override
  FieldOutlineBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return FieldOutlineBorder(
      side: borderSide == null ? side : (_) => borderSide,
      halo: halo,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }
}

/// An [OutlineInputBorder] with a [halo] painted just outside it. It fades
/// the halo in and out as the decorator animates between states, so a field
/// gaining focus does not pop its halo in at the end.
class _HaloOutlineBorder extends OutlineInputBorder {
  final BorderSide halo;

  const _HaloOutlineBorder({
    required super.borderSide,
    required this.halo,
    required super.borderRadius,
    required super.gapPadding,
  });

  /// [halo] where [border] has one, else [like] faded out.
  static BorderSide _haloOf(ShapeBorder? border, BorderSide like) =>
      border is _HaloOutlineBorder && border.halo.width > 0
      ? border.halo
      : like.copyWith(color: like.color.withValues(alpha: 0));

  _HaloOutlineBorder _lerp(
    OutlineInputBorder a,
    OutlineInputBorder b,
    double t,
  ) {
    final from = _haloOf(a, _haloOf(b, BorderSide.none));
    final to = _haloOf(b, from);
    return _HaloOutlineBorder(
      borderSide: BorderSide.lerp(a.borderSide, b.borderSide, t),
      halo: BorderSide.lerp(from, to, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      gapPadding: b.gapPadding,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is OutlineInputBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is OutlineInputBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  @override
  _HaloOutlineBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => _HaloOutlineBorder(
    borderSide: borderSide ?? this.borderSide,
    halo: halo,
    borderRadius: borderRadius ?? this.borderRadius,
    gapPadding: gapPadding ?? this.gapPadding,
  );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (halo.width > 0 && halo.color.a > 0) {
      final outer = borderRadius.toRRect(rect).inflate(halo.width / 2);
      canvas.drawRRect(
        outer,
        Paint()
          ..color = halo.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = halo.width,
      );
    }
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _HaloOutlineBorder && other.halo == halo && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, halo);
}

/// A field's box in the theme's field anatomy as one stateful [InputBorder]:
/// each set of states resolves, through [resolveFieldChrome], to the
/// outline, rule and halo of an outlined, filled or underlined box
/// ([AdminFieldStyle.variant]), which the [InputDecorator] animates between
/// as the pointer, focus and validation change. A resolved one is also a
/// [ShapeBorder] a [ShapeDecoration] can draw.
///
/// [mapStates] adjusts the states the decorator reports before they
/// resolve: to fold in the disabled or error state of a scope, or to pin
/// hover in a catalog.
///
/// Like [FieldOutlineBorder], it keeps its states through [copyWith]: a
/// caller that only rounds the corners differently keeps every state's look.
/// Passing a `borderSide` pins that outline in every state. Drawn directly,
/// outside an [InputDecorator], it is the resting box. Every state resolves
/// to an [OutlineInputBorder] with no gap, so the decorator lays out a
/// filled or underlined field exactly as an outlined one.
///
/// Two are equal when they draw the same box in every state a field takes —
/// at rest, hovered, focused, disabled, and in error focused or not.
class FieldBorder extends OutlineInputBorder implements WidgetStateInputBorder {
  final AdminPalette palette;
  final AdminStroke stroke;
  final AdminFieldStyle style;

  /// The states to resolve in place of those the decorator reports; null
  /// takes them as they are.
  final Set<WidgetState> Function(Set<WidgetState> states)? mapStates;

  /// The outline [copyWith] pinned in every state, if any.
  final BorderSide? _pinned;

  FieldBorder({
    required this.palette,
    required this.stroke,
    this.style = const AdminFieldStyle(),
    required super.borderRadius,
    this.mapStates,
    super.gapPadding = 0,
  }) : _pinned = null,
       super(borderSide: _restingSide(palette, stroke, style, mapStates));

  /// [tokens]' palette, stroke and field style, at [borderRadius] or else
  /// the theme's [AdminRadii.radiusField].
  FieldBorder.of(
    AdminTokens tokens, {
    BorderRadius? borderRadius,
    Set<WidgetState> Function(Set<WidgetState> states)? mapStates,
  }) : this(
         palette: tokens.palette,
         stroke: tokens.stroke,
         style: tokens.field,
         borderRadius:
             borderRadius ?? BorderRadius.circular(tokens.radii.radiusField),
         mapStates: mapStates,
       );

  const FieldBorder._withSide({
    required this.palette,
    required this.stroke,
    required this.style,
    required this.mapStates,
    required BorderSide pinned,
    required super.borderRadius,
    required super.gapPadding,
  }) : _pinned = pinned,
       super(borderSide: pinned);

  /// The resting outline, or the rule of a box that draws none.
  static BorderSide _restingSide(
    AdminPalette palette,
    AdminStroke stroke,
    AdminFieldStyle style,
    Set<WidgetState> Function(Set<WidgetState> states)? mapStates,
  ) {
    final spec = FieldChromeSpec.of(
      palette,
      mapStates?.call(const {}) ?? const {},
      stroke: stroke,
      style: style,
    );
    return _width(spec.outline) > 0 ? spec.outline : spec.rule;
  }

  static const _states = <Set<WidgetState>>[
    {},
    {WidgetState.hovered},
    {WidgetState.focused},
    {WidgetState.disabled},
    {WidgetState.error},
    {WidgetState.error, WidgetState.focused},
  ];

  /// The chrome in [states], after [mapStates].
  FieldChromeSpec chromeOf(Set<WidgetState> states) => FieldChromeSpec.of(
    palette,
    mapStates?.call(states) ?? states,
    stroke: stroke,
    style: style,
  );

  @override
  InputBorder resolve(Set<WidgetState> states) {
    final spec = chromeOf(states);
    final pinned = _pinned;
    if (pinned != null ||
        (spec.variant == FieldVariant.outlined && _width(spec.rule) == 0)) {
      // Drawn as FieldOutlineBorder draws it, so the two agree state by
      // state.
      final side = pinned ?? spec.outline;
      return stroke.fieldFocusHalo > 0
          ? _HaloOutlineBorder(
              borderSide: side,
              halo: spec.halo,
              borderRadius: borderRadius,
              gapPadding: gapPadding,
            )
          : OutlineInputBorder(
              borderSide: side,
              borderRadius: borderRadius,
              gapPadding: gapPadding,
            );
    }
    return _FieldSpecBorder(spec, borderRadius);
  }

  InputBorder get _rest => resolve(const {});

  @override
  EdgeInsetsGeometry get dimensions => _rest.dimensions;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _rest.getOuterPath(rect, textDirection: textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _rest.getInnerPath(rect, textDirection: textDirection);

  @override
  bool get preferPaintInterior => _rest.preferPaintInterior;

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) => _rest.paintInterior(canvas, rect, paint, textDirection: textDirection);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) => _rest.paint(
    canvas,
    rect,
    gapStart: gapStart,
    gapExtent: gapExtent,
    gapPercentage: gapPercentage,
    textDirection: textDirection,
  );

  @override
  FieldBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    final pinned = borderSide ?? _pinned;
    if (pinned == null) {
      return FieldBorder(
        palette: palette,
        stroke: stroke,
        style: style,
        borderRadius: borderRadius ?? this.borderRadius,
        mapStates: mapStates,
        gapPadding: gapPadding ?? this.gapPadding,
      );
    }
    return FieldBorder._withSide(
      palette: palette,
      stroke: stroke,
      style: style,
      mapStates: mapStates,
      pinned: pinned,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FieldBorder ||
        other.runtimeType != runtimeType ||
        other.borderRadius != borderRadius ||
        other.gapPadding != gapPadding) {
      return false;
    }
    // The same inputs draw the same box, which a field rebuilt on every
    // keystroke meets far more often than two different ones that agree.
    if (identical(other.palette, palette) &&
        other.stroke == stroke &&
        other.style == style &&
        identical(other.mapStates, mapStates) &&
        other._pinned == _pinned) {
      return true;
    }
    return _states.every((states) => other.resolve(states) == resolve(states));
  }

  @override
  int get hashCode => Object.hash(
    borderRadius,
    gapPadding,
    Object.hashAll(_states.map(resolve)),
  );
}

/// One state of a [FieldBorder] whose box is not a plain outline: the
/// [FieldChromeSpec]'s outline, rule and halo at [borderRadius]. An
/// [OutlineInputBorder] with no gap, so the decorator lays it out as it
/// does an outlined field. It fades its sides and halo as the decorator
/// animates between states.
class _FieldSpecBorder extends OutlineInputBorder {
  final FieldChromeSpec spec;

  _FieldSpecBorder(this.spec, BorderRadius borderRadius)
    : super(
        borderSide: spec.outline,
        borderRadius: spec.corners(borderRadius),
        gapPadding: 0,
      );

  @override
  EdgeInsetsGeometry get dimensions => spec.border;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.toRRect(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final edges = spec.border;
    Radius less(Radius r, double by) => Radius.circular(math.max(0, r.x - by));
    final inner = edges.deflateRect(rect);
    return Path()..addRRect(
      RRect.fromRectAndCorners(
        inner,
        topLeft: less(borderRadius.topLeft, math.max(edges.left, edges.top)),
        topRight: less(borderRadius.topRight, math.max(edges.right, edges.top)),
        bottomLeft: less(
          borderRadius.bottomLeft,
          math.max(edges.left, edges.bottom),
        ),
        bottomRight: less(
          borderRadius.bottomRight,
          math.max(edges.right, edges.bottom),
        ),
      ),
    );
  }

  /// [from] lerped toward [to]; an edge that one side does not draw fades
  /// in (or out) in the other's colour, so it never flashes black.
  static BorderSide _fade(BorderSide from, BorderSide to, double t) {
    BorderSide clear(BorderSide like) => like.copyWith(
      color: like.color.withValues(alpha: 0),
      width: 0,
      style: BorderStyle.solid,
    );
    final a = _width(from) > 0 ? from : clear(to);
    final b = _width(to) > 0 ? to : clear(from);
    return BorderSide.lerp(a, b, t);
  }

  static _FieldSpecBorder _lerp(
    _FieldSpecBorder a,
    _FieldSpecBorder b,
    double t,
  ) => _FieldSpecBorder(
    FieldChromeSpec(
      variant: b.spec.variant,
      fill: Color.lerp(a.spec.fill, b.spec.fill, t)!,
      outline: _fade(a.spec.outline, b.spec.outline, t),
      rule: _fade(a.spec.rule, b.spec.rule, t),
      halo: _fade(a.spec.halo, b.spec.halo, t),
    ),
    BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is _FieldSpecBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is _FieldSpecBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  @override
  _FieldSpecBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => _FieldSpecBorder(
    FieldChromeSpec(
      variant: spec.variant,
      fill: spec.fill,
      outline: borderSide ?? spec.outline,
      rule: spec.rule,
      halo: spec.halo,
    ),
    borderRadius ?? this.borderRadius,
  );

  @override
  _FieldSpecBorder scale(double t) => _FieldSpecBorder(
    FieldChromeSpec(
      variant: spec.variant,
      fill: spec.fill,
      outline: spec.outline.scale(t),
      rule: spec.rule.scale(t),
      halo: spec.halo.scale(t),
    ),
    borderRadius * t,
  );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final outer = borderRadius.toRRect(rect);
    final halo = spec.halo;
    if (_width(halo) > 0 && halo.color.a > 0) {
      canvas.drawRRect(
        outer.inflate(halo.width / 2),
        Paint()
          ..color = halo.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = halo.width,
      );
    }
    final outline = spec.outline;
    if (_width(outline) > 0) {
      canvas.drawRRect(outer.deflate(outline.width / 2), outline.toPaint());
    }
    final rule = spec.rule;
    if (_width(rule) > 0) {
      canvas
        ..save()
        ..clipRRect(outer)
        ..drawRect(
          Rect.fromLTRB(
            rect.left,
            rect.bottom - rule.width,
            rect.right,
            rect.bottom,
          ),
          Paint()..color = rule.color,
        )
        ..restore();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _FieldSpecBorder &&
      other.spec == spec &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(spec, borderRadius);
}

/// The vertical padding that centres one [AdminTypography.fieldText] line in
/// a control [height].
double fieldPaddingY(AdminTypography type, double height) {
  final text = type.fieldText;
  final line = text.fontSize! * (text.height ?? 1);
  return height > line ? (height - line) / 2 : 0;
}

/// The outline of an outlined field in [states], at the widths of [stroke]
/// and in the accents of [style] (pass `context.stroke` and
/// `context.fieldStyle`). It is the edge [resolveFieldChrome] strokes round
/// a [FieldVariant.outlined] box; a filled or underlined box draws a rule
/// too, so a body draws its box with [resolveFieldChrome], and this suits
/// an outline of its own only. The edge:
/// - [WidgetState.disabled]: [AdminStroke.control], halfway from
///   [AdminPalette.controlBorder] to [AdminPalette.border] — quieter than an
///   enabled field, but still a box on a page as pale as its fill;
/// - [WidgetState.error]: [AdminStroke.fieldError] [AdminPalette.danger];
///   focused, the wider of that and [AdminStroke.fieldFocus];
/// - [WidgetState.focused]: [AdminStroke.fieldFocus]
///   [AdminPalette.focusRing] ([AdminPalette.controlAccent] with
///   [AdminFieldStyle.accentFocus]), with [fieldFocusHalo] around it where
///   the theme draws one;
/// - [WidgetState.hovered]: [AdminStroke.control]
///   [AdminPalette.controlBorder] with up to 30% of
///   [AdminPalette.foreground] laid over it — a step stronger than at rest.
///   Where the focus outline is no wider than the resting one, the step
///   stops at the focus colour's contrast on the fill, so a hovered field
///   never outweighs a focused one. With [AdminFieldStyle.accentHover], the
///   focus accent eased toward the fill instead;
/// - otherwise [AdminStroke.control] [AdminPalette.controlBorder].
BorderSide fieldBorderSide(
  AdminPalette palette,
  Set<WidgetState> states, {
  required AdminStroke stroke,
  AdminFieldStyle style = const AdminFieldStyle(),
}) {
  if (states.contains(WidgetState.disabled)) {
    return BorderSide(
      color: Color.lerp(palette.border, palette.controlBorder, 0.5)!,
      width: stroke.control,
    );
  }
  final focused = states.contains(WidgetState.focused);
  if (states.contains(WidgetState.error)) {
    return BorderSide(
      color: palette.danger,
      width: focused
          ? math.max(stroke.fieldError, stroke.fieldFocus)
          : stroke.fieldError,
    );
  }
  final focus = style.accentFocus ? palette.controlAccent : palette.focusRing;
  if (focused) {
    return BorderSide(color: focus, width: stroke.fieldFocus);
  }
  if (states.contains(WidgetState.hovered)) {
    return BorderSide(
      color: style.accentHover
          ? _easedAccent(
              focus,
              palette.fieldFill,
              floor: math.max(
                _uiContrast,
                contrastRatio(palette.controlBorder, palette.fieldFill),
              ),
            )
          : _hoverStep(
              palette,
              stroke,
              edge: palette.controlBorder,
              focus: focus,
              fill: palette.surface,
            ),
      width: stroke.control,
    );
  }
  return BorderSide(color: palette.controlBorder, width: stroke.control);
}

/// A hovered edge: [edge] with up to 30% of [AdminPalette.foreground] laid
/// over it. Where the focus stroke is no wider than the resting one, the step
/// stops at [focus]'s contrast on [fill]; see [fieldBorderSide].
Color _hoverStep(
  AdminPalette palette,
  AdminStroke stroke, {
  required Color edge,
  required Color focus,
  required Color fill,
}) {
  Color at(double t) =>
      Color.alphaBlend(palette.foreground.withValues(alpha: t), edge);
  const step = 0.3;
  final full = at(step);
  if (stroke.fieldFocus > stroke.control) return full;
  final cap = contrastRatio(focus, fill);
  if (contrastRatio(full, fill) <= cap) return full;
  var (lo, hi) = (0.0, step);
  for (var i = 0; i < 10; i++) {
    final mid = (lo + hi) / 2;
    if (contrastRatio(at(mid), fill) <= cap) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return at(lo);
}

const _uiContrast = 3.0;

/// [accent] eased toward [fill] as far as it keeps [floor] contrast there,
/// as painted: a lighter step of the accent, which never outweighs the
/// accent itself; see [AdminFieldStyle.accentHover].
Color _easedAccent(Color accent, Color fill, {required double floor}) {
  bool holds(double t) =>
      contrastRatio(Color(Color.lerp(accent, fill, t)!.toARGB32()), fill) >=
      floor;
  if (!holds(0)) return accent;
  var (lo, hi) = (0.0, 1.0);
  for (var i = 0; i < 12; i++) {
    final mid = (lo + hi) / 2;
    if (holds(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return Color(Color.lerp(accent, fill, lo)!.toARGB32());
}

/// The halo a focused field draws just outside its edge:
/// [AdminStroke.fieldFocusHalo] wide, in [AdminPalette.focusRing] (or
/// [AdminPalette.controlAccent] for a [style] with
/// [AdminFieldStyle.accentFocus]) at [AdminFieldStyle.haloOpacity], by
/// default half; or in error [AdminPalette.danger] at a fifth (two fifths in
/// a dark theme) — shadcn's `ring-ring/50` and `ring-destructive/20`.
/// [BorderSide.none] for a field that is not focused or is disabled, and in
/// a theme that draws no halo. Pass `context.stroke` and
/// `context.fieldStyle`.
BorderSide fieldFocusHalo(
  AdminPalette palette,
  Set<WidgetState> states, {
  required AdminStroke stroke,
  AdminFieldStyle style = const AdminFieldStyle(),
}) {
  if (stroke.fieldFocusHalo <= 0 ||
      !states.contains(WidgetState.focused) ||
      states.contains(WidgetState.disabled)) {
    return BorderSide.none;
  }
  final dark = palette.brightness == Brightness.dark;
  final accent = style.accentFocus ? palette.controlAccent : palette.focusRing;
  return BorderSide(
    color: states.contains(WidgetState.error)
        ? palette.danger.withValues(alpha: dark ? 0.4 : 0.2)
        : accent.withValues(alpha: style.haloOpacity),
    width: stroke.fieldFocusHalo,
    strokeAlign: BorderSide.strokeAlignOutside,
  );
}

/// The fill of a field in [states]: [AdminPalette.fieldFill], or while
/// [WidgetState.disabled] [AdminPalette.foreground] laid over it at 4% (8% in
/// a dark theme) — a box that still stands off the page where the page and
/// the fill are one colour, as in several dark palettes. A filled field's
/// hover fill is [resolveFieldChrome]'s.
Color fieldFillColor(AdminPalette palette, Set<WidgetState> states) {
  if (!states.contains(WidgetState.disabled)) return palette.fieldFill;
  final dark = palette.brightness == Brightness.dark;
  return Color.alphaBlend(
    palette.foreground.withValues(alpha: dark ? 0.08 : 0.04),
    palette.fieldFill,
  );
}

/// What a field's box draws in one set of states, in the theme's field
/// anatomy: its [fill], the [outline] stroked around it, the [rule] along
/// its bottom (drawn over the outline's bottom edge), and the [halo] just
/// outside it. A side the box does not draw is [BorderSide.none]. Every
/// edge is drawn inside the box, the halo outside it.
///
/// Resolve one with [resolveFieldChrome]; draw it with [FieldBorder] (an
/// [InputDecorator]), or [fieldDecoration] and [fieldForegroundDecoration]
/// (a box).
@immutable
class FieldChromeSpec {
  /// The box this is a state of; a [FieldVariant.filled] box is square at
  /// the bottom.
  final FieldVariant variant;

  final Color fill;
  final BorderSide outline;
  final BorderSide rule;
  final BorderSide halo;

  const FieldChromeSpec({
    required this.variant,
    required this.fill,
    this.outline = BorderSide.none,
    this.rule = BorderSide.none,
    this.halo = BorderSide.none,
  });

  /// [palette]'s field chrome in [states], at the widths of [stroke], in the
  /// anatomy of [style]; see [resolveFieldChrome]. Resolved once per
  /// palette, stroke, style and state: a field resolves its states on every
  /// build, and a hover edge searches for its contrast.
  factory FieldChromeSpec.of(
    AdminPalette palette,
    Set<WidgetState> states, {
    required AdminStroke stroke,
    AdminFieldStyle style = const AdminFieldStyle(),
  }) {
    final key = (
      stroke,
      style,
      states.contains(WidgetState.disabled),
      states.contains(WidgetState.error),
      states.contains(WidgetState.focused),
      states.contains(WidgetState.hovered),
    );
    final cache = _cache[palette] ??= {};
    return cache[key] ??= FieldChromeSpec._resolve(
      palette,
      states,
      stroke: stroke,
      style: style,
    );
  }

  /// The specs [FieldChromeSpec.of] has resolved, per palette (held weakly)
  /// and per stroke, style and the four states a field's chrome reads.
  static final _cache =
      Expando<
        Map<
          (AdminStroke, AdminFieldStyle, bool, bool, bool, bool),
          FieldChromeSpec
        >
      >('FieldChromeSpec');

  static FieldChromeSpec _resolve(
    AdminPalette palette,
    Set<WidgetState> states, {
    required AdminStroke stroke,
    required AdminFieldStyle style,
  }) {
    final variant = style.variant;
    final disabled = states.contains(WidgetState.disabled);
    final focused = states.contains(WidgetState.focused) && !disabled;
    final hovered = states.contains(WidgetState.hovered) && !disabled;
    final underline = style.focusIndicator == FieldFocusIndicator.underline;
    FieldChromeSpec spec({
      BorderSide outline = BorderSide.none,
      BorderSide rule = BorderSide.none,
    }) => FieldChromeSpec(
      variant: variant,
      fill: variant == FieldVariant.filled && hovered
          ? palette.fieldFillHover
          : fieldFillColor(palette, states),
      outline: outline,
      rule: rule,
      halo: fieldFocusHalo(palette, states, stroke: stroke, style: style),
    );
    BorderSide side(Color color, [double? width]) =>
        BorderSide(color: color, width: width ?? stroke.control);

    final restOutline = switch (variant) {
      FieldVariant.outlined => side(palette.controlBorder),
      FieldVariant.filled => BorderSide.none,
      FieldVariant.underlined => side(palette.border),
    };
    final restRule = variant == FieldVariant.outlined
        ? BorderSide.none
        : side(palette.fieldRule);

    if (disabled) {
      final quiet = side(
        Color.lerp(palette.border, palette.controlBorder, 0.5)!,
      );
      return variant == FieldVariant.filled
          ? spec(rule: quiet)
          : spec(outline: quiet);
    }
    if (states.contains(WidgetState.error)) {
      final marked = side(
        palette.danger,
        focused
            ? math.max(stroke.fieldError, stroke.fieldFocus)
            : stroke.fieldError,
      );
      if (!underline) return spec(outline: marked);
      return spec(
        outline: restOutline.style == BorderStyle.none
            ? BorderSide.none
            : side(palette.danger, stroke.fieldError),
        rule: marked,
      );
    }
    if (focused) {
      final accent = side(
        style.accentFocus ? palette.controlAccent : palette.focusRing,
        stroke.fieldFocus,
      );
      return underline
          ? spec(outline: restOutline, rule: accent)
          : spec(outline: accent);
    }
    if (hovered) {
      final focus = style.accentFocus
          ? palette.controlAccent
          : palette.focusRing;
      final fill = palette.fieldFill;
      Color stepped(Color edge) => style.accentHover
          ? _easedAccent(
              focus,
              fill,
              floor: math.max(_uiContrast, contrastRatio(edge, fill)),
            )
          : _hoverStep(palette, stroke, edge: edge, focus: focus, fill: fill);
      return variant == FieldVariant.outlined
          ? spec(outline: side(stepped(palette.controlBorder)))
          : spec(outline: restOutline, rule: side(stepped(palette.fieldRule)));
    }
    return spec(outline: restOutline, rule: restRule);
  }

  /// What the edges take inside the box, side by side: the [outline]'s
  /// width, and at the bottom the wider of it and the [rule]. A box that
  /// keeps its content still across states pads by its resting padding plus
  /// the resting state's [border], minus this one's; a [Container] with
  /// [fieldDecoration] adds this back as the decoration's own padding.
  EdgeInsets get border {
    final o = _width(outline);
    return EdgeInsets.fromLTRB(o, o, o, math.max(o, _width(rule)));
  }

  /// A copy with the given parts replaced: the same box in other colours,
  /// such as a filter trigger's applied state.
  FieldChromeSpec copyWith({
    Color? fill,
    BorderSide? outline,
    BorderSide? rule,
    BorderSide? halo,
  }) => FieldChromeSpec(
    variant: variant,
    fill: fill ?? this.fill,
    outline: outline ?? this.outline,
    rule: rule ?? this.rule,
    halo: halo ?? this.halo,
  );

  /// This box as a [Decoration] at [borderRadius], without its halo (see
  /// [fieldDecoration], which draws a resolved state with it).
  Decoration decoration(BorderRadius borderRadius) {
    if (variant != FieldVariant.filled &&
        _width(rule) == 0 &&
        _width(outline) > 0) {
      return BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: outline.color, width: outline.width),
      );
    }
    // The halo is the foreground's, so it is painted once.
    return ShapeDecoration(
      color: fill,
      shape: _FieldSpecBorder(copyWith(halo: BorderSide.none), borderRadius),
    );
  }

  /// [borderRadius] as this box draws it: square at the bottom for a
  /// [FieldVariant.filled] one.
  BorderRadius corners(BorderRadius borderRadius) =>
      variant == FieldVariant.filled
      ? borderRadius.copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero)
      : borderRadius;

  @override
  bool operator ==(Object other) =>
      other is FieldChromeSpec &&
      other.variant == variant &&
      other.fill == fill &&
      other.outline == outline &&
      other.rule == rule &&
      other.halo == halo;

  @override
  int get hashCode => Object.hash(variant, fill, outline, rule, halo);

  @override
  String toString() =>
      'FieldChromeSpec(${variant.name}, fill $fill, outline $outline, '
      'rule $rule, halo $halo)';
}

double _width(BorderSide side) =>
    side.style == BorderStyle.none ? 0 : side.width;

/// A field's chrome in [states] — the one place the input theme,
/// `fieldInputDecoration`, `FieldChrome` and every field body take it from —
/// in the anatomy of [AdminTokens.field], at the widths of
/// [AdminTokens.stroke]:
///
/// - [FieldVariant.outlined]: an outline on every side, as
///   [fieldBorderSide] draws it.
/// - [FieldVariant.filled]: an [AdminPalette.fieldFill] box with an
///   [AdminPalette.fieldRule] rule at the bottom and no outline. Hovered, the
///   rule takes the hover step and the fill [AdminPalette.fieldFillHover].
/// - [FieldVariant.underlined]: an [AdminPalette.border] outline and an
///   [AdminPalette.fieldRule] rule. Hovered, the rule takes the hover step.
///
/// Focused, a [FieldFocusIndicator.outline] field strokes its whole edge
/// [AdminStroke.fieldFocus] wide (inside the box, as Carbon's 2px `$focus`),
/// while a [FieldFocusIndicator.underline] one keeps its resting outline and
/// thickens its rule to that width (M3's filled field, Fluent's brand
/// underline). The focused edge is [AdminPalette.focusRing], or
/// [AdminPalette.controlAccent] with [AdminFieldStyle.accentFocus]; with
/// [AdminFieldStyle.accentHover] the hovered one is that accent eased toward
/// the fill as far as it keeps 3:1 there and the resting edge's contrast. In
/// error the edge focus marks turns [AdminPalette.danger],
/// [AdminStroke.fieldError] wide (the wider of it and the focus stroke while
/// focused). Disabled, the edge is a quieter tone and the fill
/// [fieldFillColor]'s. The halo is [fieldFocusHalo]'s.
FieldChromeSpec resolveFieldChrome(
  AdminTokens tokens,
  Set<WidgetState> states,
) => FieldChromeSpec.of(
  tokens.palette,
  states,
  stroke: tokens.stroke,
  style: tokens.field,
);

/// A box-drawn field body's decoration in [states] (see
/// [resolveFieldChrome]), at [borderRadius] (pass
/// `BorderRadius.circular(context.radii.radiusField)`): a [BoxDecoration]
/// for an outline alone, else a [ShapeDecoration] that paints the rule too.
/// Either way its padding is [FieldChromeSpec.border]. The halo is
/// [fieldForegroundDecoration]'s.
Decoration fieldDecoration(
  AdminTokens tokens,
  Set<WidgetState> states,
  BorderRadius borderRadius,
) => resolveFieldChrome(tokens, states).decoration(borderRadius);

/// The halo around a box-drawn field in [states], for a
/// `foregroundDecoration`: drawn outside the box, so it takes no room and
/// moves nothing. Null where the field draws none; see [fieldFocusHalo].
Decoration? fieldForegroundDecoration(
  AdminTokens tokens,
  Set<WidgetState> states,
  BorderRadius borderRadius,
) {
  final spec = resolveFieldChrome(tokens, states);
  if (_width(spec.halo) <= 0) return null;
  return BoxDecoration(
    borderRadius: spec.corners(borderRadius),
    border: Border.fromBorderSide(spec.halo),
  );
}

/// A Material elevation roughly equivalent to [shadows]: the largest vertical
/// offset, which is how far a Material shadow of that elevation drops.
double _materialElevation(List<BoxShadow> shadows) => shadows.fold(
  0,
  (elevation, shadow) =>
      shadow.offset.dy > elevation ? shadow.offset.dy : elevation,
);
