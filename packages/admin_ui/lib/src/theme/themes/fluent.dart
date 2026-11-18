import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../elevation.dart';
import '../field_style.dart';
import '../focus.dart';
import '../motion.dart';
import '../overlay_style.dart';
import '../palette.dart';
import '../radii.dart';
import '../segmented_style.dart';
import '../selection_style.dart';
import '../shell_style.dart';
import '../sizes.dart';
import '../slider_style.dart';
import '../stroke.dart';
import '../table_metrics.dart';
import '../tabs_style.dart';
import '../typography.dart';
import 'admin_theme.dart';

// Audited on 18 November 2026 against Fluent 2 for the web: the
// webLightTheme and webDarkTheme of @fluentui/react-components 9.75.2. The
// segmented control is the Windows Community Toolkit's Segmented, since
// React v9 ships none.
//
// The kit's rules move little here: a control's outline is Fluent's own
// colorNeutralStrokeAccessible, and the brand reaches its targets as
// authored, the dark compound brand standing in for the brand background on
// a checked control.
// - A placeholder is the muted text's grey, #616161, where Fluent's is
//   colorNeutralForeground4, #707070.
// - A disabled button's label is held to 2.5:1, where
//   colorNeutralForegroundDisabled is #BDBDBD.
// - The status warning is turned in hue, to stand apart from the danger: see
//   the palettes.
// - The light chart colours are held to 3:1.

/// Microsoft Fluent (light) — communication blue, Fluent 2's neutral greys,
/// low radii. The page is colorNeutralBackground2, cards and inputs
/// colorNeutralBackground1 above it, and the wells colorNeutralBackground3.
const fluentPalette = AdminPalette(
  primary: Color(0xFF0F6CBD),
  primaryStrong: Color(0xFF0C5A9E),
  primarySubtle: Color(0xFFEBF3FC),
  primaryFaint: Color(0xFFF5FAFE),
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFFAFAFA), // colorNeutralBackground2
  surfaceMuted: Color(0xFFF5F5F5), // colorNeutralBackground3
  foreground: Color(0xFF242424),
  foregroundSecondary: Color(0xFF424242),
  foregroundMuted: Color(0xFF616161),
  foregroundSubtle: Color(0xFF707070), // colorNeutralForeground4
  foregroundFaint: Color(0xFFBDBDBD), // colorNeutralForegroundDisabled
  border: Color(0xFFD1D1D1), // colorNeutralStroke1: a Button's and Input's
  borderSubtle: Color(0xFFE0E0E0), // colorNeutralStroke2: a divider
  success: Color(0xFF107C10),
  // Fluent 2's status warning is an orange, colorStatusWarningBackground3
  // #F7630C under colorStatusWarningForeground1 #BC4B09, close in hue to the
  // cranberry danger. The kit keeps its four status accents apart in hue, so
  // that a changed line is told from a removed one without their words: each
  // is turned 8° toward yellow, the least that parts them, and the text then
  // deepened to 4.5:1 on its tint.
  warning: Color(0xFFF7820C),
  danger: Color(0xFFC50F1F),
  warningText: Color(0xFFAA5908),
  highlight: Color(0xFFFFF4CE),
  modifiedFill: Color(0xFFFDF6E3),
  tabDivider: Color(0xFFE1DFDD),
  info: Color(0xFF0078D4),
  primaryHover: Color(0xFF115EA3), // colorBrandBackgroundHover
  primaryActive: Color(0xFF0C3B5E), // colorBrandBackgroundPressed
  controlBorder: Color(0xFF616161), // colorNeutralStrokeAccessible
  focusRing: Color(0xFF000000), // colorStrokeFocus2
  chart: _chartLight,
  // The subtle ramp, a step stronger for selection than for hover; the brand
  // indicator bar carries the selection.
  navSelectedFill: Color(0xFFE0E0E0), // colorSubtleBackgroundPressed
  navHoverFill: Color(0xFFEBEBEB), // colorSubtleBackgroundSelected
  navSelectedText: Color(0xFF242424), // colorNeutralForeground1
);

/// Microsoft Fluent (dark) — the page is colorNeutralBackground2, cards and
/// inputs colorNeutralBackground1 above it; the primary button is the brand
/// ramp's colorBrandBackground with white text, as in webDarkTheme.
const fluentDarkPalette = AdminPalette(
  primary: Color(0xFF115EA3), // colorBrandBackground
  primaryStrong: Color(0xFF0F6CBD), // colorBrandBackgroundHover
  primarySubtle: Color(0xFF2A3F52),
  primaryFaint: Color(0xFF293641),
  surface: Color(0xFF292929), // colorNeutralBackground1
  background: Color(0xFF1F1F1F), // colorNeutralBackground2
  surfaceMuted: Color(0xFF242424),
  foreground: Color(0xFFFFFFFF),
  foregroundSecondary: Color(0xFFD6D6D6),
  foregroundMuted: Color(0xFFADADAD),
  foregroundSubtle: Color(0xFF858585),
  foregroundFaint: Color(0xFF5C5C5C),
  border: Color(0xFF666666), // colorNeutralStroke1
  borderSubtle: Color(0xFF525252), // colorNeutralStroke2
  success: Color(0xFF54B054), // colorStatusSuccessForeground1
  // colorStatusWarningForeground1, #FAA06B, turned 7° toward yellow, as the
  // light palette's is turned, to stand apart from the danger in hue.
  warning: Color(0xFFFAB16B),
  danger: Color(0xFFDC626D), // colorStatusDangerForeground1
  warningText: Color(0xFFFAB16B),
  highlight: Color(0xFF332D17),
  modifiedFill: Color(0xFF2A231C),
  tabDivider: Color(0xFF484644),
  info: Color(0xFF479EF5),
  primaryHover: Color(0xFF0F6CBD), // colorBrandBackgroundHover
  primaryActive: Color(0xFF0C3B5E), // colorBrandBackgroundPressed
  controlBorder: Color(0xFFADADAD), // colorNeutralStrokeAccessible
  // Checked, selected and on controls take the compound brand, not the
  // brand background: #115EA3 is 2.2:1 on the card.
  controlAccent: Color(0xFF479EF5), // colorCompoundBrandBackground
  focusRing: Color(0xFFFFFFFF), // colorStrokeFocus2
  chart: _chartDark,
  // The subtle ramp, a step stronger for selection than for hover.
  navSelectedFill: Color(0xFF383838), // colorSubtleBackgroundHover
  navHoverFill: Color(0xFF333333), // colorSubtleBackgroundSelected
  navSelectedText: Color(0xFFFFFFFF), // colorNeutralForeground1
  navIndicator: Color(0xFF479EF5), // colorCompoundBrandStroke
);

/// The Fluent 2 type ramp: body1 (14/20) for body, controls and labels,
/// caption1 (12/16) and caption2 (10/14) below it, subtitle and title steps
/// above.
const _ramp = AdminTypeRamp(
  displayLarge: AdminTypeStep(40, 52), // largeTitle
  displayMedium: AdminTypeStep(32, 40), // title1
  displaySmall: AdminTypeStep(28, 36), // title2
  headlineMedium: AdminTypeStep(24, 32), // title3
  headlineSmall: AdminTypeStep(20, 28), // subtitle1, a dialog's title
  titleLarge: AdminTypeStep(20, 28), // subtitle1
  pageTitle: AdminTypeStep(24, 32), // title3
  heading: AdminTypeStep(16, 22), // subtitle2
  sectionLabel: AdminTypeStep(12, 16), // caption1Strong
  fieldLabel: AdminTypeStep(14, 20), // body1
  fieldText: AdminTypeStep(14, 20),
  fieldDescription: AdminTypeStep(12, 16), // caption1, a Field's hint
  fieldMessage: AdminTypeStep(12, 16), // caption1
  body: AdminTypeStep(14, 20),
  bodySmall: AdminTypeStep(12, 16),
  caption: AdminTypeStep(12, 16),
  micro: AdminTypeStep(10, 14), // caption2
  button: AdminTypeStep(14, 20),
  buttonSmall: AdminTypeStep(12, 16), // a small button's caption1
  mono: AdminTypeStep(14, 20),
  monoSmall: AdminTypeStep(12, 16),
);

// Fluent's data-visualisation palette (cornflower, hot pink, pumpkin, teal,
// light green, orchid, forest, cyan), reordered so neighbours stay apart under
// protanopia and deuteranopia; each is at 3:1 on surface and background.
const _chartLight = [
  Color(0xFF637CEF),
  Color(0xFFE3008C),
  Color(0xFFCA5010),
  Color(0xFF289FA3),
  Color(0xFF13A10E),
  Color(0xFF9373C0),
  Color(0xFF57811B),
  Color(0xFF3A96DD),
];
const _chartDark = [
  Color(0xFF637CEF),
  Color(0xFFE3008C),
  Color(0xFFCA5010),
  Color(0xFF2AA0A4),
  Color(0xFF13A10E),
  Color(0xFF9373C0),
  Color(0xFF57811B),
  Color(0xFF3A96DD),
];

/// Fluent's shadow ramp, an ambient shadow under a key one: shadow4 for a
/// card, shadow16 for a menu or popover, shadow64 for a dialog. The dark
/// theme deepens both, from 12% and 14% to 24% and 28%.
AdminElevation _elevation({required Color ambient, required Color key}) =>
    AdminElevation(
      // shadow4: 0 0 2px ambient, 0 2px 4px key
      sm: [
        BoxShadow(color: ambient, blurRadius: 2),
        BoxShadow(color: key, offset: const Offset(0, 2), blurRadius: 4),
      ],
      // shadow16: 0 0 2px ambient, 0 8px 16px key
      md: [
        BoxShadow(color: ambient, blurRadius: 2),
        BoxShadow(color: key, offset: const Offset(0, 8), blurRadius: 16),
      ],
      // shadow64: 0 0 8px ambient, 0 32px 64px key
      lg: [
        BoxShadow(color: ambient, blurRadius: 8),
        BoxShadow(color: key, offset: const Offset(0, 32), blurRadius: 64),
      ],
    );

/// Microsoft Fluent — communication blue, low radii, a two-tone 2px focus
/// stroke, underlined inputs.
final fluentTheme = AdminTheme.from(
  name: 'Fluent',
  palette: fluentPalette,
  dark: fluentDarkPalette,
  radii: const AdminRadii(
    radiusSmall: 2,
    radius: 4,
    radiusLarge: 4, // a Card's borderRadiusMedium
    radiusMenu: 4, // borderRadiusMedium
    radiusDialog: 8, // borderRadiusXLarge
    radiusPill: 4,
    radiusField: 4, // an Input's borderRadiusMedium
    radiusButton: 4, // a Button's borderRadiusMedium, at every size
  ),
  type: const AdminTypeSpec(
    fontFamily: 'Segoe UI',
    heading: FontWeight.w600,
    label: FontWeight.w400, // Label
    uppercaseLabels: false,
    ramp: _ramp,
  ),
  // a 2px colorStrokeFocus2 ring with 1px of colorStrokeFocus1 inside it
  focus: const AdminFocusSpec(width: 2, offset: 0, innerWidth: 1),
  // Fluent 2 small / medium / large controls, and a medium Input's 20px
  // icon. Fluent sets it spacingHorizontalXS, 4, from the text; 6 is the
  // least that leaves the kit's 24px slot for a field's trailing action.
  sizes: const AdminControlSizes(
    small: 24,
    medium: 32,
    large: 40,
    fieldIcon: 20,
    fieldIconGap: 6,
  ),
  // the 20px icon of a medium Button, MenuItem and Tab
  iconSizes: const AdminIconSizes(md: 20),
  // Fluent 2 Table: small (34, on the grid) and medium rows, a header as tall
  // as a row, spacingHorizontalS cells, a 44 selection cell
  table: const AdminTableMetrics(
    rowCompact: 32,
    rowStandard: 44,
    rowComfortable: 52,
    headerHeight: 44,
    cellPaddingX: 8,
    selectionColumnWidth: 44,
    // TableHeaderCell: fontWeightRegular on no background; the header row
    // and every row end in colorNeutralStroke2
    headerText: TableHeaderText.body,
    headerFill: TableHeaderFill.surface,
    headerInk: TableHeaderInk.foreground,
    headerRule: TableRule.subtle,
  ),
  // durationFaster / Normal / Gentle on curveEasyEase, curveDecelerateMid
  // and curveAccelerateMid; curveEasyEaseMax for a larger move
  motion: const AdminMotion(
    fast: Duration(milliseconds: 100),
    medium: Duration(milliseconds: 200),
    slow: Duration(milliseconds: 250),
    standard: Cubic(0.33, 0, 0.67, 1),
    enter: Cubic(0, 0, 0, 1),
    exit: Cubic(1, 0, 1, 1),
    emphasized: Cubic(0.8, 0, 0.2, 1),
  ),
  // A focused input's 2px colorCompoundBrandStroke underline; an invalid one
  // keeps its 1px red border. A Checkbox's and Radio's strokeWidthThin
  // outline, and a Tab's strokeWidthThicker indicator.
  stroke: const AdminStroke(
    fieldFocus: 2,
    fieldError: 1,
    controlStrong: 1,
    indicator: 3,
  ),
  elevation: _elevation(
    ambient: const Color(0x1F000000),
    key: const Color(0x24000000),
  ),
  darkElevation: _elevation(
    ambient: const Color(0x3D000000),
    key: const Color(0x47000000),
  ),
  // Input: a 1px colorNeutralStroke1 box over a colorNeutralStrokeAccessible
  // bottom stroke, and on focus the brand underline alone, the frame kept.
  // Label: a required one ends in a colorPaletteRedForeground3 `*`
  field: const AdminFieldStyle(
    variant: FieldVariant.underlined,
    focusIndicator: FieldFocusIndicator.underline,
    accentFocus: true,
    requiredMark: FieldRequiredMark.trailing,
  ),
  button: const AdminButtonStyle(
    padding: AdminButtonPadding(
      small: AdminButtonInsets.symmetric(8), // spacingHorizontalS
      medium: AdminButtonInsets.symmetric(12), // `5px 12px`: spacingHorizontalM
      large: AdminButtonInsets.symmetric(16), // spacingHorizontalL
    ),
    minWidth: AdminButtonMinWidth(small: 64, medium: 96, large: 96),
    labelWeight: FontWeight.w600, // fontWeightSemibold
  ),
  // NavDrawer: 260px wide, collapsing to a 48px rail, 40px items with 20px
  // icons, the selected one marked by a 4px brand bar; a 48px header
  shell: const AdminShellStyle(
    sidebarWidth: 260,
    railWidth: 48,
    itemHeight: 40,
    itemRadius: 4, // borderRadiusMedium
    itemIconSize: 20,
    indicator: NavIndicator.bar,
    indicatorWidth: 4,
    topBarHeight: 48,
  ),
  // Tooltip: withArrow, maxWidth 240px, a 6px arrowHeight
  overlay: const AdminOverlayStyle(tooltipArrow: true, tooltipMaxWidth: 240),
  // the Windows Community Toolkit's Segmented: an outlined track, the
  // selected item raised in ControlFillColorDefault over a short accent
  // pill, regular labels
  segmented: const AdminSegmentedStyle(
    inset: 2,
    trackOutline: true,
    indicator: true,
    labelWeight: FontWeight.w400,
  ),
  // Switch: a 40×20 track with a 1px colorNeutralStrokeAccessible border,
  // clear while off, around a thumb in the border's colour; the thumb is an
  // 18px CircleFilled glyph, whose disc is 14. Checkbox and Radio: a 16px
  // indicator; a checked Radio keeps its ring, in the brand stroke, around
  // a 12px CircleFilled, a 10px dot
  selection: const AdminSelectionStyle(
    toggleWidth: 40,
    toggleHeight: 20,
    toggleKnob: 14,
    toggleOff: ToggleOffStyle.outlined,
    checkSize: 16,
    radioSize: 16,
    radioMark: RadioMark.dot,
    radioDot: 10,
  ),
  // Slider: a 4px rail in colorNeutralStrokeAccessible under a 20px thumb,
  // the brand colour inside a band of colorNeutralBackground1 a fifth of
  // the thumb wide, edged in colorNeutralStroke1
  slider: const AdminSliderStyle(
    thumb: SliderThumb.inset,
    thumbSize: 20,
    thumbRing: 4,
    rail: SliderRail.control,
  ),
  // TabList: tabs 32 / 44 / 52 tall on no rule, body1 in
  // colorNeutralForeground2, the selected one body1Strong in
  // colorNeutralForeground1 over a strokeWidthThicker brand indicator, inset
  // from the tab's sides and round at its ends
  tabs: const AdminTabsStyle(
    heightSmall: 32,
    heightMedium: 44,
    heightLarge: 52,
    selectedInk: TabsSelectedInk.foreground,
    restInk: TabsRestInk.secondary,
    labelWeight: FontWeight.w400,
    selectedLabelWeight: FontWeight.w600,
    indicatorWidth: TabsIndicatorWidth.label,
    indicatorShape: TabsIndicatorShape.pill,
    rule: TabsRule.none,
  ),
);
