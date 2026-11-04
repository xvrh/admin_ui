import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, listEquals;
import 'package:material_ui/material_ui.dart';

import 'fonts.dart';
import 'palette.dart';

/// One step of an [AdminTypeRamp]: a font [size] on a fixed [line] box, both
/// whole logical pixels at scale 1, and the step's own [letterSpacing].
///
/// The line is what a style's `height` becomes (`line / size`, evenly led),
/// so a line of text takes the same box in every font, and a control sized
/// from the line centres its text whatever the font's metrics.
@immutable
class AdminTypeStep {
  /// The font size, in logical pixels at scale 1.
  final double size;

  /// The height of one line, in logical pixels at scale 1.
  final double line;

  /// Letter spacing in logical pixels; [AdminTypeSpec.tracking] is added to
  /// it.
  final double letterSpacing;

  const AdminTypeStep(this.size, this.line, {this.letterSpacing = 0});

  /// A copy with the given fields replaced.
  AdminTypeStep copyWith({double? size, double? line, double? letterSpacing}) =>
      AdminTypeStep(
        size ?? this.size,
        line ?? this.line,
        letterSpacing: letterSpacing ?? this.letterSpacing,
      );

  static AdminTypeStep lerp(AdminTypeStep a, AdminTypeStep b, double t) =>
      AdminTypeStep(
        lerpDouble(a.size, b.size, t)!,
        lerpDouble(a.line, b.line, t)!,
        letterSpacing: lerpDouble(a.letterSpacing, b.letterSpacing, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is AdminTypeStep &&
      other.size == size &&
      other.line == line &&
      other.letterSpacing == letterSpacing;

  @override
  int get hashCode => Object.hash(size, line, letterSpacing);

  @override
  String toString() =>
      'AdminTypeStep($size/$line'
      '${letterSpacing == 0 ? '' : ', letterSpacing $letterSpacing'})';
}

/// A theme's type scale: one [AdminTypeStep] per role of [AdminTypography],
/// plus the display, headline and title steps of the Material text theme
/// that `buildAppTheme` installs. Each shipped theme takes its steps from
/// its design system's own scale (the README lists them); [defaultTypeRamp]
/// is the kit's own.
///
/// Weights and colours are not here: [AdminTypeSpec] picks the weights, the
/// palette the colours.
@immutable
class AdminTypeRamp {
  /// The Material text theme's `displayLarge`.
  final AdminTypeStep displayLarge;

  /// The Material text theme's `displayMedium`.
  final AdminTypeStep displayMedium;

  /// The Material text theme's `displaySmall`.
  final AdminTypeStep displaySmall;

  /// The Material text theme's `headlineMedium`.
  final AdminTypeStep headlineMedium;

  /// The Material text theme's `headlineSmall`: a stock dialog's title.
  final AdminTypeStep headlineSmall;

  /// The Material text theme's `titleLarge`: a stock app bar's title.
  final AdminTypeStep titleLarge;

  /// [AdminTypography.pageTitle]: the title at the top of a page.
  final AdminTypeStep pageTitle;

  /// [AdminTypography.heading]: a card's or a section's heading.
  final AdminTypeStep heading;

  /// [AdminTypography.sectionLabel]: a small label over a group.
  final AdminTypeStep sectionLabel;

  /// [AdminTypography.fieldLabel]: the label over a field.
  final AdminTypeStep fieldLabel;

  /// [AdminTypography.fieldText]: the text inside a control. Its line must
  /// fit the theme's smallest control height.
  final AdminTypeStep fieldText;

  /// [AdminTypography.fieldDescription]: the help line under a field's
  /// label.
  final AdminTypeStep fieldDescription;

  /// [AdminTypography.fieldMessage]: a field's error or warning line.
  final AdminTypeStep fieldMessage;

  /// [AdminTypography.body], and its strong and muted variants.
  final AdminTypeStep body;

  /// [AdminTypography.bodySmall]: dense control text.
  final AdminTypeStep bodySmall;

  /// [AdminTypography.caption]: supporting text, a field's description.
  final AdminTypeStep caption;

  /// [AdminTypography.micro]: badges and small capitals.
  final AdminTypeStep micro;

  /// [AdminTypography.button]: a button's label.
  final AdminTypeStep button;

  /// [AdminTypography.buttonSmall]: a small button's label.
  final AdminTypeStep buttonSmall;

  /// [AdminTypography.mono]: code and structured data.
  final AdminTypeStep mono;

  /// [AdminTypography.monoSmall]: dense code, a code editor's gutter.
  final AdminTypeStep monoSmall;

  const AdminTypeRamp({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.pageTitle,
    required this.heading,
    required this.sectionLabel,
    required this.fieldLabel,
    required this.fieldText,
    required this.fieldDescription,
    required this.fieldMessage,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.micro,
    required this.button,
    required this.buttonSmall,
    required this.mono,
    required this.monoSmall,
  });

  /// A copy with the given steps replaced.
  AdminTypeRamp copyWith({
    AdminTypeStep? displayLarge,
    AdminTypeStep? displayMedium,
    AdminTypeStep? displaySmall,
    AdminTypeStep? headlineMedium,
    AdminTypeStep? headlineSmall,
    AdminTypeStep? titleLarge,
    AdminTypeStep? pageTitle,
    AdminTypeStep? heading,
    AdminTypeStep? sectionLabel,
    AdminTypeStep? fieldLabel,
    AdminTypeStep? fieldText,
    AdminTypeStep? fieldDescription,
    AdminTypeStep? fieldMessage,
    AdminTypeStep? body,
    AdminTypeStep? bodySmall,
    AdminTypeStep? caption,
    AdminTypeStep? micro,
    AdminTypeStep? button,
    AdminTypeStep? buttonSmall,
    AdminTypeStep? mono,
    AdminTypeStep? monoSmall,
  }) => AdminTypeRamp(
    displayLarge: displayLarge ?? this.displayLarge,
    displayMedium: displayMedium ?? this.displayMedium,
    displaySmall: displaySmall ?? this.displaySmall,
    headlineMedium: headlineMedium ?? this.headlineMedium,
    headlineSmall: headlineSmall ?? this.headlineSmall,
    titleLarge: titleLarge ?? this.titleLarge,
    pageTitle: pageTitle ?? this.pageTitle,
    heading: heading ?? this.heading,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    fieldLabel: fieldLabel ?? this.fieldLabel,
    fieldText: fieldText ?? this.fieldText,
    fieldDescription: fieldDescription ?? this.fieldDescription,
    fieldMessage: fieldMessage ?? this.fieldMessage,
    body: body ?? this.body,
    bodySmall: bodySmall ?? this.bodySmall,
    caption: caption ?? this.caption,
    micro: micro ?? this.micro,
    button: button ?? this.button,
    buttonSmall: buttonSmall ?? this.buttonSmall,
    mono: mono ?? this.mono,
    monoSmall: monoSmall ?? this.monoSmall,
  );

  static AdminTypeRamp lerp(AdminTypeRamp a, AdminTypeRamp b, double t) {
    AdminTypeStep s(AdminTypeStep x, AdminTypeStep y) =>
        AdminTypeStep.lerp(x, y, t);
    return AdminTypeRamp(
      displayLarge: s(a.displayLarge, b.displayLarge),
      displayMedium: s(a.displayMedium, b.displayMedium),
      displaySmall: s(a.displaySmall, b.displaySmall),
      headlineMedium: s(a.headlineMedium, b.headlineMedium),
      headlineSmall: s(a.headlineSmall, b.headlineSmall),
      titleLarge: s(a.titleLarge, b.titleLarge),
      pageTitle: s(a.pageTitle, b.pageTitle),
      heading: s(a.heading, b.heading),
      sectionLabel: s(a.sectionLabel, b.sectionLabel),
      fieldLabel: s(a.fieldLabel, b.fieldLabel),
      fieldText: s(a.fieldText, b.fieldText),
      fieldDescription: s(a.fieldDescription, b.fieldDescription),
      fieldMessage: s(a.fieldMessage, b.fieldMessage),
      body: s(a.body, b.body),
      bodySmall: s(a.bodySmall, b.bodySmall),
      caption: s(a.caption, b.caption),
      micro: s(a.micro, b.micro),
      button: s(a.button, b.button),
      buttonSmall: s(a.buttonSmall, b.buttonSmall),
      mono: s(a.mono, b.mono),
      monoSmall: s(a.monoSmall, b.monoSmall),
    );
  }

  /// Every step by its role's name, in declaration order.
  Map<String, AdminTypeStep> get steps => {
    'displayLarge': displayLarge,
    'displayMedium': displayMedium,
    'displaySmall': displaySmall,
    'headlineMedium': headlineMedium,
    'headlineSmall': headlineSmall,
    'titleLarge': titleLarge,
    'pageTitle': pageTitle,
    'heading': heading,
    'sectionLabel': sectionLabel,
    'fieldLabel': fieldLabel,
    'fieldText': fieldText,
    'fieldDescription': fieldDescription,
    'fieldMessage': fieldMessage,
    'body': body,
    'bodySmall': bodySmall,
    'caption': caption,
    'micro': micro,
    'button': button,
    'buttonSmall': buttonSmall,
    'mono': mono,
    'monoSmall': monoSmall,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminTypeRamp &&
          listEquals(other.steps.values.toList(), steps.values.toList());

  @override
  int get hashCode => Object.hashAll(steps.values);
}

/// The kit's own ramp (Iris): 13/20 body and control text, 12/16 labels,
/// captions, descriptions and messages, an 11/14 micro step, and a 22/28 page title.
const defaultTypeRamp = AdminTypeRamp(
  displayLarge: AdminTypeStep(36, 44),
  displayMedium: AdminTypeStep(28, 36),
  displaySmall: AdminTypeStep(24, 32),
  headlineMedium: AdminTypeStep(20, 28),
  headlineSmall: AdminTypeStep(18, 24),
  titleLarge: AdminTypeStep(18, 24),
  pageTitle: AdminTypeStep(22, 28),
  heading: AdminTypeStep(16, 24),
  sectionLabel: AdminTypeStep(12, 16, letterSpacing: 0.3),
  fieldLabel: AdminTypeStep(12, 16),
  fieldText: AdminTypeStep(13, 20),
  fieldDescription: AdminTypeStep(12, 16),
  fieldMessage: AdminTypeStep(12, 16),
  body: AdminTypeStep(13, 20),
  bodySmall: AdminTypeStep(12, 18),
  caption: AdminTypeStep(12, 16),
  micro: AdminTypeStep(11, 14, letterSpacing: 0.2),
  button: AdminTypeStep(13, 20),
  buttonSmall: AdminTypeStep(12, 16),
  mono: AdminTypeStep(13, 20),
  monoSmall: AdminTypeStep(12, 16),
);

/// Per-theme typography knobs. Each theme picks a font family, weight scheme,
/// [ramp], scale and tracking; [AdminTypography.from] bakes these into
/// styles.
@immutable
class AdminTypeSpec {
  /// Multiplies every size and line in the [ramp] (density / scale).
  final double scale;

  /// The size, line and letter spacing of each role.
  final AdminTypeRamp ramp;

  /// The family the theme's text is set in (`Inter`, `Segoe UI`), drawn
  /// where the app bundles it and in the platform's font where it does not;
  /// [AdminFonts.resolver] can load it another way. Null draws in the
  /// platform's font.
  final String? fontFamily;

  /// Families to draw a character from when the theme's font has no glyph
  /// for it (a script it does not cover, say), tried in order after the
  /// style's own fallback and the platform's UI font. Null leaves it to the
  /// platform's fallback, which a device has and a test engine lacks: there
  /// a missing glyph is a box.
  ///
  /// The platform's UI font (the family the Material typography names for
  /// the platform, and on the web the engine's default, Roboto) goes before
  /// these because the engine takes a text field's strut, which places the
  /// baseline in its fixed line, from the first family of the list it finds,
  /// and a character from the first family that has it. Where a style's own
  /// family is absent — a platform name on the web, `Segoe UI` off Windows —
  /// a script font next in line would set that baseline by its own ascent
  /// and descent (Noto Naskh Arabic's put Latin text 1.6px high in a 20px
  /// line) and draw the spaces, digits and punctuation it also covers.
  ///
  /// Only a style that names a family carries it. The engine reads a
  /// fallback on a style with no family as that style's whole family list,
  /// behind the platform's default font, so a rich-text span in such a style
  /// would lose its parent's family. With no [fontFamily], the kit's own
  /// styles therefore keep none, and the
  /// fallback reaches their text through the Material text theme
  /// ([applyFontTheme]), whose styles name the platform's font, and the
  /// ambient [DefaultTextStyle] built from it.
  final List<String>? fontFamilyFallback;

  /// The family of [AdminTypography.mono] and [AdminTypography.monoSmall]:
  /// the platform's monospace family by default, where the platform has one
  /// by that name.
  final String monoFontFamily;

  /// Families a mono style falls back to, in order, where [monoFontFamily]
  /// is absent: macOS, for one, has no family named `monospace`.
  final List<String> monoFontFamilyFallback;

  /// Weight for headings, section labels, page/section titles.
  final FontWeight heading;

  /// Weight for a field's label ([AdminTypography.fieldLabel]); [heading]
  /// when null. The reference systems set it lighter than a heading: regular
  /// in Carbon, Fluent, Ant and Material, medium in shadcn.
  final FontWeight? label;

  /// Weight for emphasised body, buttons, micro labels.
  final FontWeight strong;

  /// Weight for plain body, captions.
  final FontWeight body;

  /// Added to every style's letter-spacing, on top of the [ramp] step's own.
  /// The shipped themes leave it at 0 and track per step.
  final double tracking;

  /// Field labels in capitals, tracked out — the kit's own look. False sets
  /// them in sentence case, as the reference systems do. Every field label
  /// reads it through [AdminTypography.fieldLabelText].
  final bool uppercaseLabels;

  const AdminTypeSpec({
    this.scale = 1.0,
    this.ramp = defaultTypeRamp,
    this.fontFamily,
    this.fontFamilyFallback,
    this.monoFontFamily = 'monospace',
    this.monoFontFamilyFallback = const ['Menlo', 'Consolas', 'Courier New'],
    this.heading = FontWeight.w700,
    this.label,
    this.strong = FontWeight.w600,
    this.body = FontWeight.w400,
    this.tracking = 0.0,
    this.uppercaseLabels = true,
  });

  /// A copy with the given fields replaced.
  AdminTypeSpec copyWith({
    double? scale,
    AdminTypeRamp? ramp,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? monoFontFamily,
    List<String>? monoFontFamilyFallback,
    FontWeight? heading,
    FontWeight? label,
    FontWeight? strong,
    FontWeight? body,
    double? tracking,
    bool? uppercaseLabels,
  }) => AdminTypeSpec(
    scale: scale ?? this.scale,
    ramp: ramp ?? this.ramp,
    fontFamily: fontFamily ?? this.fontFamily,
    fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
    monoFontFamily: monoFontFamily ?? this.monoFontFamily,
    monoFontFamilyFallback:
        monoFontFamilyFallback ?? this.monoFontFamilyFallback,
    heading: heading ?? this.heading,
    label: label ?? this.label,
    strong: strong ?? this.strong,
    body: body ?? this.body,
    tracking: tracking ?? this.tracking,
    uppercaseLabels: uppercaseLabels ?? this.uppercaseLabels,
  );

  /// Applies this spec's font to [style]: its [fontFamily], through
  /// [AdminFonts.resolve], else the style keeps its family (platform
  /// default). [fontFamilyFallback] goes after the style's own fallback and
  /// the platform's UI font when the result names a family.
  TextStyle applyFont(TextStyle style) {
    if (fontFamily case final family?) {
      return _withFallback(AdminFonts.resolve(family, style));
    }
    return _withFallback(style);
  }

  /// Applies this spec's monospace font to [style]: [monoFontFamily] with
  /// [monoFontFamilyFallback]; the platform's UI font and then
  /// [fontFamilyFallback] go after it.
  TextStyle applyMonoFont(TextStyle style) => _withFallback(
    style.copyWith(
      fontFamily: monoFontFamily,
      fontFamilyFallback: monoFontFamilyFallback,
    ),
  );

  /// Whether [style] is in this spec's monospace font, as [applyMonoFont]
  /// sets it.
  bool isMono(TextStyle style) => style.fontFamily == monoFontFamily;

  /// Applies this spec's font across a whole Material [TextTheme] (used for the
  /// bare `Text` / dialog defaults that don't read [AdminTypography]).
  TextTheme applyFontTheme(TextTheme theme) {
    var fonted = theme;
    if (fontFamily case final family?) {
      fonted = AdminFonts.resolver == null
          ? theme.apply(fontFamily: family)
          : _mapTextTheme(
              theme,
              (style) =>
                  style == null ? null : AdminFonts.resolve(family, style),
            );
    }
    if (fontFamilyFallback == null) return fonted;
    return _mapTextTheme(
      fonted,
      (style) => style == null ? null : _withFallback(style),
    );
  }

  /// [style] with the platform's UI families, then [fontFamilyFallback],
  /// after its own fallback, unless it names no family (see
  /// [fontFamilyFallback]).
  TextStyle _withFallback(TextStyle style) {
    final extra = fontFamilyFallback;
    final family = style.fontFamily;
    if (extra == null || family == null) return style;
    final fallback = [...?style.fontFamilyFallback];
    for (final f in [..._platformFamilies(), ...extra]) {
      if (f != family && !fallback.contains(f)) fallback.add(f);
    }
    return style.copyWith(fontFamilyFallback: fallback);
  }

  /// The families the platform sets its UI text in: those the Material
  /// typography names for [defaultTargetPlatform], then, on the web, where
  /// none of those names is a font, the engine's default, Roboto.
  static List<String> _platformFamilies() {
    final body = Typography.material2021(platform: defaultTargetPlatform)
        .black
        .bodyMedium;
    return [
      ?body?.fontFamily,
      ...?body?.fontFamilyFallback,
      if (kIsWeb) 'Roboto',
    ];
  }

  static TextTheme _mapTextTheme(
    TextTheme theme,
    TextStyle? Function(TextStyle? style) map,
  ) => TextTheme(
    displayLarge: map(theme.displayLarge),
    displayMedium: map(theme.displayMedium),
    displaySmall: map(theme.displaySmall),
    headlineLarge: map(theme.headlineLarge),
    headlineMedium: map(theme.headlineMedium),
    headlineSmall: map(theme.headlineSmall),
    titleLarge: map(theme.titleLarge),
    titleMedium: map(theme.titleMedium),
    titleSmall: map(theme.titleSmall),
    bodyLarge: map(theme.bodyLarge),
    bodyMedium: map(theme.bodyMedium),
    bodySmall: map(theme.bodySmall),
    labelLarge: map(theme.labelLarge),
    labelMedium: map(theme.labelMedium),
    labelSmall: map(theme.labelSmall),
  );

  @override
  bool operator ==(Object other) =>
      other is AdminTypeSpec &&
      other.scale == scale &&
      other.ramp == ramp &&
      other.fontFamily == fontFamily &&
      listEquals(other.fontFamilyFallback, fontFamilyFallback) &&
      other.monoFontFamily == monoFontFamily &&
      listEquals(other.monoFontFamilyFallback, monoFontFamilyFallback) &&
      other.heading == heading &&
      other.label == label &&
      other.strong == strong &&
      other.body == body &&
      other.tracking == tracking &&
      other.uppercaseLabels == uppercaseLabels;

  @override
  int get hashCode => Object.hash(
    scale,
    ramp,
    fontFamily,
    fontFamilyFallback == null ? null : Object.hashAll(fontFamilyFallback!),
    monoFontFamily,
    Object.hashAll(monoFontFamilyFallback),
    heading,
    label,
    strong,
    body,
    tracking,
    uppercaseLabels,
  );
}

/// Per-theme typography — the spec's [AdminTypeRamp] with component colours
/// resolved from an [AdminPalette] and weights/scale/family from an
/// [AdminTypeSpec]. Provided via [AdminTokens]; read via `context.type`.
///
/// Every style built by [AdminTypography.from] has a whole-pixel size (at
/// scale 1) on a fixed line box: `height` is the step's line over its size,
/// evenly led.
@immutable
class AdminTypography {
  /// The Material text theme's display, headline and title sizes (the
  /// ramp's steps at the spec's scale).
  final double sizeDisplayLarge;
  final double sizeDisplayMedium;
  final double sizeDisplaySmall;
  final double sizeHeadlineMedium;
  final double sizeHeadlineSmall;
  final double sizeTitleLarge;

  /// A field's label, in [AdminPalette.foregroundSecondary] at the spec's
  /// label weight: never the ambient text colour. Set its text with
  /// [fieldLabelText], which applies the theme's casing.
  final TextStyle fieldLabel;

  /// The text inside a control — an input's value and hint, a trigger's
  /// value — on the ramp's fixed line, so a field's height follows the
  /// control-size tokens rather than the font's metrics.
  final TextStyle fieldText;

  /// The help line under a field's label, in [AdminPalette.foregroundMuted]:
  /// [caption]'s size in most themes, the body size where the reference
  /// system sets its field help at body size (shadcn, Ant).
  final TextStyle fieldDescription;

  /// A field's error or warning line, at weight 500 on its fixed line, so a
  /// leading glyph centres on its first line. Colourless: the message picks
  /// the danger or warning text colour.
  final TextStyle fieldMessage;

  final TextStyle pageTitle;
  final TextStyle heading;
  final TextStyle sectionLabel;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle bodyMuted;

  /// One step below [body] — dense control text: picker cells, chips,
  /// inline hints, list-row secondaries.
  final TextStyle bodySmall;

  /// Supporting text in [AdminPalette.foregroundMuted]: a hint, a field's
  /// description.
  final TextStyle caption;
  final TextStyle micro;
  final TextStyle button;

  /// A small button's label. Colourless, as [button] is.
  final TextStyle buttonSmall;

  /// Code and structured data, in the spec's monospace font
  /// ([AdminTypeSpec.applyMonoFont]). Change its weight with [weighted],
  /// which keeps the monospace font.
  final TextStyle mono;

  /// [mono] a step smaller: dense code, a code editor's gutter.
  final TextStyle monoSmall;

  /// The spec these styles were built from — kept so chrome (e.g. the Material
  /// [TextTheme] in `buildAppTheme`) can apply the same font.
  final AdminTypeSpec spec;

  /// A typography built by hand. [fieldDescription] defaults to [caption],
  /// [buttonSmall] to [button], [mono] to [body] and [monoSmall] to [mono];
  /// [AdminTypography.from] sets all four.
  const AdminTypography({
    required this.sizeDisplayLarge,
    required this.sizeDisplayMedium,
    required this.sizeDisplaySmall,
    required this.sizeHeadlineMedium,
    required this.sizeHeadlineSmall,
    required this.sizeTitleLarge,
    required this.fieldLabel,
    required this.fieldText,
    TextStyle? fieldDescription,
    required this.fieldMessage,
    required this.pageTitle,
    required this.heading,
    required this.sectionLabel,
    required this.body,
    required this.bodyStrong,
    required this.bodyMuted,
    required this.bodySmall,
    required this.caption,
    required this.micro,
    required this.button,
    TextStyle? buttonSmall,
    TextStyle? mono,
    TextStyle? monoSmall,
    required this.spec,
  }) : fieldDescription = fieldDescription ?? caption,
       buttonSmall = buttonSmall ?? button,
       mono = mono ?? body,
       monoSmall = monoSmall ?? mono ?? body;

  factory AdminTypography.from(
    AdminPalette p, [
    AdminTypeSpec spec = const AdminTypeSpec(),
  ]) {
    final r = spec.ramp;
    TextStyle metrics(
      AdminTypeStep step, {
      required FontWeight weight,
      Color? color,
      double letterSpacing = 0,
    }) => TextStyle(
      fontSize: step.size * spec.scale,
      fontWeight: weight,
      color: color,
      letterSpacing: step.letterSpacing + letterSpacing + spec.tracking,
      height: step.line / step.size,
      leadingDistribution: TextLeadingDistribution.even,
    );
    TextStyle style(
      AdminTypeStep step, {
      required FontWeight weight,
      Color? color,
      double letterSpacing = 0,
    }) => spec.applyFont(
      metrics(step, weight: weight, color: color, letterSpacing: letterSpacing),
    );
    TextStyle mono(AdminTypeStep step) => spec.applyMonoFont(
      metrics(step, weight: spec.body, color: p.foreground),
    );

    return AdminTypography(
      sizeDisplayLarge: r.displayLarge.size * spec.scale,
      sizeDisplayMedium: r.displayMedium.size * spec.scale,
      sizeDisplaySmall: r.displaySmall.size * spec.scale,
      sizeHeadlineMedium: r.headlineMedium.size * spec.scale,
      sizeHeadlineSmall: r.headlineSmall.size * spec.scale,
      sizeTitleLarge: r.titleLarge.size * spec.scale,
      fieldLabel: style(
        r.fieldLabel,
        weight: spec.label ?? spec.heading,
        color: p.foregroundSecondary,
        letterSpacing: spec.uppercaseLabels ? 0.4 : 0,
      ),
      fieldText: style(r.fieldText, weight: spec.body, color: p.foreground),
      fieldDescription: style(
        r.fieldDescription,
        weight: spec.body,
        color: p.foregroundMuted,
      ),
      fieldMessage: style(r.fieldMessage, weight: FontWeight.w500),
      pageTitle: style(r.pageTitle, weight: spec.heading, color: p.foreground),
      heading: style(r.heading, weight: spec.heading, color: p.foreground),
      sectionLabel: style(
        r.sectionLabel,
        weight: spec.heading,
        color: p.foregroundSecondary,
      ),
      body: style(r.body, weight: spec.body, color: p.foreground),
      bodyStrong: style(r.body, weight: spec.strong, color: p.foreground),
      bodyMuted: style(r.body, weight: spec.body, color: p.foregroundMuted),
      bodySmall: style(r.bodySmall, weight: spec.body, color: p.foreground),
      caption: style(r.caption, weight: spec.body, color: p.foregroundMuted),
      micro: style(r.micro, weight: spec.strong, color: p.foregroundMuted),
      button: style(r.button, weight: spec.strong),
      buttonSmall: style(r.buttonSmall, weight: spec.strong),
      mono: mono(r.mono),
      monoSmall: mono(r.monoSmall),
      spec: spec,
    );
  }

  /// [label] as a field label shows it: in capitals when the theme's
  /// [AdminTypeSpec.uppercaseLabels] says so. Screen readers get [label]
  /// itself.
  String fieldLabelText(String label) =>
      spec.uppercaseLabels ? label.toUpperCase() : label;

  /// [style] at [weight], in this typography's font — its monospace font for
  /// a [mono] style. Use it rather than `copyWith(fontWeight:)` on one of
  /// these styles: a Google font loads each weight as a family of its own,
  /// which a copied style keeps, so it would draw the old weight's face (or
  /// a synthesised bold) under the new weight.
  TextStyle weighted(TextStyle style, FontWeight weight) {
    final copy = style.copyWith(fontWeight: weight);
    return spec.isMono(style) ? spec.applyMonoFont(copy) : spec.applyFont(copy);
  }

  static AdminTypography lerp(AdminTypography a, AdminTypography b, double t) {
    TextStyle s(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    double d(double x, double y) => x + (y - x) * t;
    return AdminTypography(
      sizeDisplayLarge: d(a.sizeDisplayLarge, b.sizeDisplayLarge),
      sizeDisplayMedium: d(a.sizeDisplayMedium, b.sizeDisplayMedium),
      sizeDisplaySmall: d(a.sizeDisplaySmall, b.sizeDisplaySmall),
      sizeHeadlineMedium: d(a.sizeHeadlineMedium, b.sizeHeadlineMedium),
      sizeHeadlineSmall: d(a.sizeHeadlineSmall, b.sizeHeadlineSmall),
      sizeTitleLarge: d(a.sizeTitleLarge, b.sizeTitleLarge),
      fieldLabel: s(a.fieldLabel, b.fieldLabel),
      fieldText: s(a.fieldText, b.fieldText),
      fieldDescription: s(a.fieldDescription, b.fieldDescription),
      fieldMessage: s(a.fieldMessage, b.fieldMessage),
      pageTitle: s(a.pageTitle, b.pageTitle),
      heading: s(a.heading, b.heading),
      sectionLabel: s(a.sectionLabel, b.sectionLabel),
      body: s(a.body, b.body),
      bodyStrong: s(a.bodyStrong, b.bodyStrong),
      bodyMuted: s(a.bodyMuted, b.bodyMuted),
      bodySmall: s(a.bodySmall, b.bodySmall),
      caption: s(a.caption, b.caption),
      micro: s(a.micro, b.micro),
      button: s(a.button, b.button),
      buttonSmall: s(a.buttonSmall, b.buttonSmall),
      mono: s(a.mono, b.mono),
      monoSmall: s(a.monoSmall, b.monoSmall),
      spec: t < 0.5 ? a.spec : b.spec,
    );
  }

  List<Object> get _props => [
    sizeDisplayLarge,
    sizeDisplayMedium,
    sizeDisplaySmall,
    sizeHeadlineMedium,
    sizeHeadlineSmall,
    sizeTitleLarge,
    fieldLabel,
    fieldText,
    fieldDescription,
    fieldMessage,
    pageTitle,
    heading,
    sectionLabel,
    body,
    bodyStrong,
    bodyMuted,
    bodySmall,
    caption,
    micro,
    button,
    buttonSmall,
    mono,
    monoSmall,
    spec,
  ];

  @override
  bool operator ==(Object other) =>
      other is AdminTypography && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);
}
