import 'package:flutter/widgets.dart';

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
import '../typography.dart';
import 'admin_theme.dart';

/// Ant Design (light) — enterprise blue, opacity-based grays, dense.
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
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFFAFAFA),
  surfaceMuted: Color(0xFFF5F5F5),
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
  warningText: Color(0xFFA36200),
  highlight: Color(0xFFFFF1B8),
  modifiedFill: Color(0xFFFFF7E6),
  tabDivider: Color(0xFFD9D9D9),
  info: Color(0xFF0958D9), // blue-7: Ant's colorInfo is the primary itself
  chart: _chartLight,
  navIndicator: Color(0x00000000),
);

/// Ant Design (dark) — the page is colorBgLayout, cards and inputs
/// colorBgContainer above it.
const antDarkPalette = AdminPalette(
  primary: Color(0xFF1668DC),
  primaryStrong: Color(0xFF1554AD),
  primarySubtle: Color(0xFF112545), // colorPrimaryBgHover
  primaryFaint: Color(0xFF111A2C), // colorPrimaryBg
  surface: Color(0xFF141414), // colorBgContainer
  background: Color(0xFF000000), // colorBgLayout
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
  tabDivider: Color(0xFF424242),
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
  // A group title's white at 45% is under 4.5:1 here; white at 55%.
  foregroundMuted: Color(0xFF8C969F),
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
  Color(0xFF5A8EF8),
  Color(0xFF0CA576),
  Color(0xFF945FB9),
  Color(0xFFB68A03),
  Color(0xFF5D7092),
  Color(0xFFDA7718),
  Color(0xFF3E9BBE),
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
/// modal. The dark algorithm keeps them.
const _elevation = AdminElevation(
  // 0 1px 2px rgba(0,0,0,.03), 0 1px 6px -1px rgba(0,0,0,.02),
  // 0 2px 4px rgba(0,0,0,.02)
  sm: [
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 1),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(color: Color(0x05000000), offset: Offset(0, 2), blurRadius: 4),
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
/// (itemBorderRadius), the selection carried by the fill alone;
/// Layout.Header at 64.
const _shell = AdminShellStyle(
  sidebarWidth: 200,
  railWidth: 80,
  itemHeight: 40,
  itemGap: 4,
  itemPaddingX: 24,
  itemMarginX: 4,
  itemRadius: 8,
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
  focus: const AdminFocusSpec(width: 2, offset: 2),
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
  // motionDurationFast / Mid / Slow on motionEaseInOut, motionEaseOut and
  // motionEaseIn; motionEaseOutCirc for a modal's zoom
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
  // lineWidth 1 in every state; focus shows as the outline's colour and a
  // 2px activeShadow ring
  stroke: const AdminStroke(fieldFocus: 1, fieldError: 1, fieldFocusHalo: 2),
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
);
