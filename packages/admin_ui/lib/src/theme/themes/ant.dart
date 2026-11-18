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

// Audited on 18 November 2026 against Ant Design 6.7.1, whose seed tokens
// are v5's.
//
// The kit's contrast rules, where they leave Ant's tokens:
// - a control's outline is `border` deepened to 3:1 (#8E8E8E, dark #626262),
//   where colorBorder is #D9D9D9 (1.41:1 on white) and #424242;
// - a placeholder is the muted text's grey, at 4.5:1, where
//   colorTextPlaceholder is #BFBFBF;
// - a filled button darkens under the pointer, toward colorPrimaryActive,
//   where Ant's lightens to colorPrimaryHover #4096FF, on which white is
//   2.99:1;
// - the focus ring is the primary at 3:1, where Ant's outline is
//   colorPrimaryBorder #91CAFF;
// - a disabled button's label is held to 2.5:1, where Ant's is #BFBFBF;
// - the light chart colours are deepened to 3:1.

/// Ant Design (light) — enterprise blue, opacity-based grays, dense. The page
/// is colorBgLayout, cards and inputs colorBgContainer, and a table's header
/// and the wells colorFillAlter, #FAFAFA.
///
/// Deviates from Ant's tokens where they miss WCAG AA. White text on
/// colorPrimary #1677FF and colorError #FF4D4F is under 4.5:1 (and near-black
/// on #1677FF too), so each fill moves toward Ant's own active shade (#0958D9,
/// #D9363E) just far enough for white to reach it. Secondary text is the
/// lightest grey that holds 4.5:1 on every surface, between colorTextSecondary
/// and colorTextTertiary (#8C8C8C, 3.4:1).
const antPalette = AdminPalette(
  primary: Color(0xFF136FF6),
  primaryStrong: Color(0xFF0958D9),
  primarySubtle: Color(0xFFE6F4FF),
  primaryFaint: Color(0xFFF0F7FF),
  surface: Color(0xFFFFFFFF), // colorBgContainer
  background: Color(0xFFF5F5F5), // colorBgLayout
  surfaceMuted: Color(0xFFFAFAFA), // colorFillAlter: a table's header
  foreground: Color(0xFF1F1F1F),
  foregroundSecondary: Color(0xFF595959),
  foregroundMuted: Color(0xFF707070),
  foregroundSubtle: Color(0xFFBFBFBF),
  foregroundFaint: Color(0xFFD9D9D9),
  border: Color(0xFFD9D9D9),
  borderSubtle: Color(0xFFF0F0F0),
  success: Color(0xFF52C41A),
  warning: Color(0xFFFAAD14),
  danger: Color(0xFFDB373F),
  warningText: Color(0xFFA26100), // 4.5:1 on the page as on its tint
  highlight: Color(0xFFFFF1B8),
  modifiedFill: Color(0xFFFFF7E6),
  tabDivider: Color(0xFFF0F0F0), // colorBorderSecondary
  info: Color(0xFF0958D9), // blue-7: Ant's colorInfo is the primary itself
  chart: _chartLight,
  navIndicator: Color(0x00000000),
);

/// Ant Design (dark) — the page is colorBgLayout, cards and inputs
/// colorBgContainer above it.
const antDarkPalette = AdminPalette(
  primary: Color(0xFF1668DC),
  primaryStrong: Color(0xFF1554AD),
  // colorPrimaryBg, which the dark algorithm sets to the blue ramp's third
  // step, and the ramp's first step, which it was before that.
  primarySubtle: Color(0xFF15325B),
  primaryFaint: Color(0xFF111A2C),
  surface: Color(0xFF141414), // colorBgContainer
  background: Color(0xFF000000), // colorBgLayout
  // Between the page and the card. A dark table's header is colorFillAlter,
  // #1D1D1D, lighter than the card; the kit keeps a well under its surface.
  surfaceMuted: Color(0xFF0A0A0A),
  foreground: Color(0xFFE0E0E0),
  foregroundSecondary: Color(0xFFC2C2C2),
  foregroundMuted: Color(0xFF8C8C8C),
  foregroundSubtle: Color(0xFF6E6E6E),
  foregroundFaint: Color(0xFF595959),
  border: Color(0xFF424242), // colorBorder
  borderSubtle: Color(0xFF303030), // colorBorderSecondary
  success: Color(0xFF49AA19),
  warning: Color(0xFFD89614),
  danger: Color(0xFFD44244), // colorError, deepened until white reaches 4.5
  warningText: Color(0xFFC08612),
  highlight: Color(0xFF2B2412),
  modifiedFill: Color(0xFF241F18),
  tabDivider: Color(0xFF303030), // colorBorderSecondary
  info: Color(0xFF3C89E8), // blue-7 (dark)
  chart: _chartDark,
  navIndicator: Color(0x00000000),
);

/// Ant Design's dark Sider and Menu (`theme="dark"`), the sidebar of the
/// classic layout in the light theme: the #001529 rail, items in white at
/// 65%, and the selected item filled with colorPrimary under white text.
/// Greys are Ant's white-alpha steps laid over the rail.
const antSiderPalette = AdminPalette(
  primary: Color(0xFF136FF6), // colorPrimary, as deepened in antPalette
  primaryStrong: Color(0xFF0958D9),
  primarySubtle: Color(0xFF043164),
  primaryFaint: Color(0xFF022A56),
  surface: Color(0xFF002140), // triggerBg: the Sider's collapse trigger
  background: Color(0xFF001529), // siderBg, darkItemBg
  surfaceMuted: Color(0xFF001B35),
  foreground: Color(0xFFFFFFFF), // darkItemHoverColor
  foregroundSecondary: Color(0xFFA6ADB4), // darkItemColor: white at 65%
  foregroundMuted: Color(0xFFA6ADB4), // darkGroupTitleColor: white at 65%
  foregroundSubtle: Color(0xFF40505E), // darkItemDisabledColor: white at 25%
  foregroundFaint: Color(0xFF263849), // white at 15%
  border: Color(0xFF1F3143), // colorSplit: white at 12%
  borderSubtle: Color(0xFF0F2336), // white at 6%
  success: Color(0xFF49AA19),
  warning: Color(0xFFD89614),
  danger: Color(0xFFD44244),
  warningText: Color(0xFFD89614), // colorWarningText, 4.5:1 on its navy tint
  highlight: Color(0xFF2B2412),
  modifiedFill: Color(0xFF241F18),
  tabDivider: Color(0xFF1F3143),
  info: Color(0xFF3C89E8),
  navSelectedFill: Color(0xFF136FF6), // darkItemSelectedBg: colorPrimary
  navSelectedText: Color(0xFFFFFFFF), // darkItemSelectedColor
  navIndicator: Color(0x00000000),
);

/// Ant's scale: fontSize 14 on a 22px line for body, controls and labels,
/// fontSizeSM 12 on 20 below it, and the fontSizeHeading steps above.
const _ramp = AdminTypeRamp(
  displayLarge: AdminTypeStep(38, 46), // heading 1
  displayMedium: AdminTypeStep(30, 38), // heading 2
  displaySmall: AdminTypeStep(24, 32), // heading 3
  headlineMedium: AdminTypeStep(20, 28), // heading 4
  headlineSmall: AdminTypeStep(16, 24), // heading 5, a modal's title
  titleLarge: AdminTypeStep(16, 24),
  pageTitle: AdminTypeStep(20, 28), // heading 4
  heading: AdminTypeStep(16, 24), // fontSizeLG
  sectionLabel: AdminTypeStep(12, 20),
  fieldLabel: AdminTypeStep(14, 22),
  fieldText: AdminTypeStep(14, 22),
  fieldDescription: AdminTypeStep(14, 22), // a form item's extra line
  fieldMessage: AdminTypeStep(14, 22), // a form item's explain line
  body: AdminTypeStep(14, 22),
  bodySmall: AdminTypeStep(12, 20), // fontSizeSM
  caption: AdminTypeStep(12, 20),
  micro: AdminTypeStep(12, 20),
  button: AdminTypeStep(14, 22),
  buttonSmall: AdminTypeStep(14, 22), // a small button keeps fontSize
  mono: AdminTypeStep(14, 22),
  monoSmall: AdminTypeStep(12, 20),
);

// AntV's categorical palette, reordered so neighbours stay apart under
// protanopia and deuteranopia (AntV's own order puts red beside yellow); the
// light steps are deepened to 3:1 on surface and background.
const _chartLight = [
  Color(0xFF558AF8),
  Color(0xFF0CA173),
  Color(0xFF945FB9),
  Color(0xFFB38703),
  Color(0xFF5D7092),
  Color(0xFFD67518),
  Color(0xFF3D98BB),
  Color(0xFFE86452),
];
const _chartDark = [
  Color(0xFF5B8FF9),
  Color(0xFF5AD8A6),
  Color(0xFF945FB9),
  Color(0xFFF6BD16),
  Color(0xFF5D7092),
  Color(0xFFFF9845),
  Color(0xFF6DC8EC),
  Color(0xFFE86452),
];

/// Ant's shadows: boxShadowTertiary for a resting lift, boxShadowSecondary
/// for a dropdown or popover, and boxShadow, the same three layers, for a
/// modal. Dark mode keeps them in black: since 6.3.6 Ant's dark algorithm
/// draws them from a light colorShadow, white at 20%, a glow the kit does
/// not take.
const _elevation = AdminElevation(
  // 0 1px 2px rgba(0,0,0,.05), 0 1px 6px -1px rgba(0,0,0,.03),
  // 0 2px 4px rgba(0,0,0,.03), as deepened in 6.4.4
  sm: [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 1),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 2), blurRadius: 4),
  ],
  md: _secondary,
  lg: _secondary,
);

// 0 6px 16px rgba(0,0,0,.08), 0 3px 6px -4px rgba(0,0,0,.12),
// 0 9px 28px 8px rgba(0,0,0,.05)
const _secondary = [
  BoxShadow(color: Color(0x14000000), offset: Offset(0, 6), blurRadius: 16),
  BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 3),
    blurRadius: 6,
    spreadRadius: -4,
  ),
  BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 9),
    blurRadius: 28,
    spreadRadius: 8,
  ),
];

/// Layout.Sider at 200px, collapsing to 80, over a Menu of 40px items
/// (itemHeight) 4px apart (itemMarginBlock) and 4px in from the Sider's
/// edges (itemMarginInline), indented 24 (inlineIndent) and rounded 8
/// (itemBorderRadius), their icons at fontSize 14, the selection carried by
/// the fill alone; Layout.Header at 64.
const _shell = AdminShellStyle(
  sidebarWidth: 200,
  railWidth: 80,
  itemHeight: 40,
  itemGap: 4,
  itemPaddingX: 24,
  itemMarginX: 4,
  itemRadius: 8,
  itemIconSize: 14,
  indicator: NavIndicator.none,
  topBarHeight: 64,
);

/// Ant Design — enterprise blue, small radii, a primary-hover outline and a
/// soft focus ring on fields, the dark sider in light mode.
final antTheme = AdminTheme.from(
  name: 'Ant',
  palette: antPalette,
  dark: antDarkPalette,
  radii: const AdminRadii(
    radiusSmall: 4,
    radius: 6,
    radiusLarge: 8,
    radiusMenu: 8, // borderRadiusLG
    radiusDialog: 8, // borderRadiusLG
    radiusPill: 4, // borderRadiusSM
    radiusField: 6, // an Input's borderRadius
    // Buttons derive theirs: borderRadiusSM at small, borderRadius above.
  ),
  type: const AdminTypeSpec(
    heading: FontWeight.w600,
    label: FontWeight.w400, // a form item's label
    uppercaseLabels: false,
    ramp: _ramp,
  ),
  // lineWidthFocus 3, outlineOffset 1
  focus: const AdminFocusSpec(width: 3, offset: 1),
  // controlHeightSM / controlHeight / controlHeightLG
  sizes: const AdminControlSizes(small: 24, medium: 32, large: 40),
  // Table size small / middle / large; the middle cell's paddingXS inline and
  // a controlHeight selection column
  table: const AdminTableMetrics(
    rowCompact: 40,
    rowStandard: 48,
    rowComfortable: 56,
    headerHeight: 48,
    cellPaddingX: 8,
    selectionColumnWidth: 32,
  ),
  // motionDurationFast / Mid / Slow on motionEaseInOut and motionEaseOut;
  // the exit curve is CSS's ease-in cubic, which no Ant token names;
  // motionEaseOutCirc for a larger move
  motion: const AdminMotion(
    fast: Duration(milliseconds: 100),
    medium: Duration(milliseconds: 200),
    slow: Duration(milliseconds: 300),
    pulse: Duration(milliseconds: 700), // half of Skeleton's 1.4s cycle
    standard: Cubic(0.645, 0.045, 0.355, 1),
    enter: Cubic(0.215, 0.61, 0.355, 1),
    exit: Cubic(0.55, 0.055, 0.675, 0.19),
    emphasized: Cubic(0.08, 0.82, 0.17, 1),
  ),
  // lineWidth 1 in every state, a Checkbox's and a Radio's included; focus
  // shows as the outline's colour and a 2px activeShadow ring
  stroke: const AdminStroke(
    fieldFocus: 1,
    fieldError: 1,
    fieldFocusHalo: 2,
    controlStrong: 1,
  ),
  elevation: _elevation,
  darkElevation: _elevation,
  // Input: activeBorderColor colorPrimary, hoverBorderColor
  // colorPrimaryHover, and activeShadow `0 0 0 2px rgba(5,145,255,.1)`,
  // here at 20% so the 2px band still reads beside the 1px outline.
  // Form requiredMark: a colorError `*` before the label, marginInlineEnd
  // marginXXS
  field: const AdminFieldStyle(
    accentFocus: true,
    accentHover: true,
    haloOpacity: 0.2,
    requiredMark: FieldRequiredMark.leading,
  ),
  button: const AdminButtonStyle(
    // paddingInline 15 (7 small) inside the 1px border
    padding: AdminButtonPadding(
      small: AdminButtonInsets.symmetric(8),
      medium: AdminButtonInsets.symmetric(16),
      large: AdminButtonInsets.symmetric(16),
    ),
    labelWeight: FontWeight.w400, // fontWeight 400
    accentHover: true, // defaultHoverColor, defaultHoverBorderColor
  ),
  // the dark sider the classic layout draws on a light page
  shell: _shell.copyWith(sidebarPalette: antSiderPalette),
  darkShell: _shell,
  // Tooltip: an arrow, maxWidth 250; sizePopupArrow 16
  overlay: const AdminOverlayStyle(
    tooltipArrow: true,
    tooltipMaxWidth: 250,
    arrowWidth: 16,
    arrowHeight: 8,
  ),
  // Segmented: trackBg behind an itemSelectedBg thumb lifted by
  // boxShadowTertiary, trackPadding 2, regular labels
  segmented: const AdminSegmentedStyle(
    inset: 2,
    knobOutline: false,
    labelWeight: FontWeight.w400,
  ),
  // Switch: trackMinWidth 44, trackHeight 22, an 18px handle. Checkbox:
  // controlInteractiveSize, 16. Radio: radioSize 16, a colorPrimary disc
  // around a dotSize 6 dot
  selection: const AdminSelectionStyle(
    toggleWidth: 44,
    toggleHeight: 22,
    toggleKnob: 18,
    checkSize: 16,
    radioSize: 16,
    radioDot: 6,
  ),
  // Slider: railSize 4 under a handleSize 10 handle in colorBgElevated,
  // ringed by handleLineWidth 2: 14 across. Its rail is colorFillTertiary,
  // black at 4%, which the kit draws in the border colour
  slider: const AdminSliderStyle(
    thumb: SliderThumb.ringed,
    thumbSize: 14,
    thumbRing: 2,
  ),
  // Tabs: horizontalItemPadding 12 (8 small, 16 large) around a 22px line,
  // 24 at large: 38 / 46 / 56 tall. Regular labels in colorText,
  // itemSelectedColor colorPrimary, over a 2px ink bar as wide as the label,
  // on a colorBorderSecondary rule
  tabs: const AdminTabsStyle(
    heightSmall: 38,
    heightMedium: 46,
    heightLarge: 56,
    restInk: TabsRestInk.foreground,
    labelWeight: FontWeight.w400,
    indicatorWidth: TabsIndicatorWidth.label,
  ),
);
