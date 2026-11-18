import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../elevation.dart';
import '../feedback_style.dart';
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
import '../state_layer.dart';
import '../stroke.dart';
import '../table_metrics.dart';
import '../tabs_style.dart';
import '../typography.dart';
import 'admin_theme.dart';

// Audited on 18 November 2026 against baseline Material 3: Material Web's
// tokens v0_192, Compose Material 3's generated tokens and material_ui
// 1.11.1. Material 3 Expressive (May 2025) is not drawn: no 56, 96 and 136
// buttons, shape morphing or spring motion.
//
// The kit's contrast rules move no Material colour: the accents reach their
// targets as authored, and the control outline is M3's own `outline`, past
// 3:1. They show in a disabled button's label, held to 2.5:1 where M3 lays
// on-surface at 38%, and in the light chart colours, deepened to 3:1.

/// Material 3 (light) — tonal purple, tinted surfaces, soft ink. The page is
/// `surfaceContainer`, cards and inputs the `surface` above it and wells the
/// `surfaceContainerLow` between them: the kit keeps a card lighter than its
/// page, where M3 sets its darker containers on a `surface` page.
const materialPalette = AdminPalette(
  primary: Color(0xFF6750A4),
  primaryStrong: Color(0xFF4F378B),
  primarySubtle: Color(0xFFEADDFF),
  primaryFaint: Color(0xFFF6EDFF),
  // surface, #FEF7FF, one step short of it in green: mixed into M3's own
  // value, the selected table row of a teal brand leaves the brand's hue.
  surface: Color(0xFFFEF8FF),
  background: Color(0xFFF3EDF7), // surfaceContainer
  surfaceMuted: Color(0xFFF7F2FA), // surfaceContainerLow
  foreground: Color(0xFF1D1B20),
  foregroundSecondary: Color(0xFF49454F),
  // onSurfaceVariant: M3's supporting text (outline #79747E is a border role).
  foregroundMuted: Color(0xFF49454F),
  foregroundSubtle: Color(0xFF938F99),
  foregroundFaint: Color(0xFFCAC4D0),
  border: Color(0xFFCAC4D0),
  borderSubtle: Color(0xFFE7E0EC),
  success: Color(0xFF2E7D32),
  warning: Color(0xFFF9A825),
  danger: Color(0xFFB3261E),
  warningText: Color(0xFF8A6500),
  highlight: Color(0xFFFDEEB8),
  modifiedFill: Color(0xFFF6EDFF),
  tabDivider: Color(0xFFCAC4D0),
  info: Color(0xFF1565C0),
  // A filled button under the pointer takes its content's state layer and
  // lightens: onPrimary over primary at 8%, 10% pressed, and onError over
  // error likewise.
  primaryHover: Color(0xFF735EAB),
  primaryActive: Color(0xFF7662AD),
  dangerHover: Color(0xFFB93730),
  dangerActive: Color(0xFFBB3C35),
  stateLayer: _stateLayer,
  controlBorder: Color(0xFF79747E), // M3 outline
  focusRing: Color(0xFF625B71), // M3 focus indicator: secondary
  chart: _chartLight,
  navSelectedFill: Color(0xFFE8DEF8), // secondaryContainer
  // onSurface at just under 6%. M3's hover layer is 8% (#E2DCE6), which
  // stands further from the page than the selection does; the kit keeps a
  // hovered item no stronger than the selected one, so the layer stops where
  // the two meet.
  navHoverFill: Color(0xFFE6E1EA),
  navSelectedText: Color(0xFF1D192B), // onSecondaryContainer
  navIndicator: Color(0x00000000),
  softFill: Color(0xFFE8DEF8), // the tonal button: secondaryContainer
  onSoft: Color(0xFF1D192B), // onSecondaryContainer
  // a plain tooltip's and a snackbar's container, and what reads on it
  inverseSurface: Color(0xFF322F35), // inverseSurface: neutral20
  onInverseSurface: Color(0xFFF5EFF7), // inverseOnSurface: neutral95
);

/// Material 3 (dark) — the page is `surface`, cards and inputs the
/// `surfaceContainer` above it.
const materialDarkPalette = AdminPalette(
  primary: Color(0xFFD0BCFF),
  primaryStrong: Color(0xFFB69DF8),
  primarySubtle: Color(0xFF4A4458), // secondaryContainer
  primaryFaint: Color(0xFF2F2C37), // primary at 8% (hover state layer)
  surface: Color(0xFF211F26), // surfaceContainer
  background: Color(0xFF141218), // surface
  surfaceMuted: Color(0xFF1D1B20), // surfaceContainerLow
  foreground: Color(0xFFE6E0E9),
  foregroundSecondary: Color(0xFFCAC4D0),
  foregroundMuted: Color(0xFFCAC4D0), // onSurfaceVariant
  foregroundSubtle: Color(0xFF938F99),
  foregroundFaint: Color(0xFF605D64),
  border: Color(0xFF49454F), // outlineVariant
  borderSubtle: Color(0xFF36343B),
  success: Color(0xFF7DD389),
  warning: Color(0xFFEBC062),
  danger: Color(0xFFF2B8B5),
  warningText: Color(0xFFD89E3C),
  highlight: Color(0xFF3B3422),
  modifiedFill: Color(0xFF272019),
  tabDivider: Color(0xFF49454F),
  info: Color(0xFF9CCAFF),
  onPrimary: Color(0xFF381E72), // M3 onPrimary
  onDanger: Color(0xFF601410), // M3 onError
  primaryHover: Color(0xFFC4AFF4), // primary + onPrimary at 8% (hover layer)
  primaryActive: Color(0xFFC1ACF1), // primary + onPrimary at 10% (pressed)
  dangerHover: Color(0xFFE6ABA8), // error + onError at 8% (hover layer)
  dangerActive: Color(0xFFE3A8A4), // error + onError at 10% (pressed layer)
  stateLayer: _stateLayer,
  controlBorder: Color(0xFF938F99), // M3 outline
  focusRing: Color(0xFFCCC2DC), // M3 focus indicator: secondary
  chart: _chartDark,
  navSelectedFill: Color(0xFF4A4458), // secondaryContainer
  navSelectedText: Color(0xFFE8DEF8), // onSecondaryContainer
  navIndicator: Color(0x00000000),
  softFill: Color(0xFF4A4458), // the tonal button: secondaryContainer
  onSoft: Color(0xFFE8DEF8), // onSecondaryContainer
  inverseSurface: Color(0xFFE6E0E9), // inverseSurface: neutral90
  onInverseSurface: Color(0xFF322F35), // inverseOnSurface: neutral20
);

/// M3's state layers: hover 8%, focus and pressed 10%, dragged 16%, for a
/// saturated tint as for the neutral wash.
const _stateLayer = AdminStateLayer(
  hover: 0.08,
  focus: 0.10,
  pressed: 0.10,
  dragged: 0.16,
  tintHover: 0.08,
  tintPressed: 0.10,
);

/// M3's type scale. Each role names the M3 style it takes, tracking
/// included; a field's text is bodyLarge, as in an M3 text field.
const _ramp = AdminTypeRamp(
  displayLarge: AdminTypeStep(57, 64, letterSpacing: -0.25),
  displayMedium: AdminTypeStep(45, 52),
  displaySmall: AdminTypeStep(36, 44),
  headlineMedium: AdminTypeStep(28, 36),
  headlineSmall: AdminTypeStep(24, 32),
  titleLarge: AdminTypeStep(22, 28),
  pageTitle: AdminTypeStep(24, 32), // headlineSmall
  heading: AdminTypeStep(16, 24, letterSpacing: 0.15), // titleMedium
  dialogTitle: AdminTypeStep(24, 32), // headlineSmall, a dialog's headline
  sectionLabel: AdminTypeStep(12, 16, letterSpacing: 0.5), // labelMedium
  fieldLabel: AdminTypeStep(12, 16, letterSpacing: 0.4), // bodySmall
  fieldText: AdminTypeStep(16, 24, letterSpacing: 0.5), // bodyLarge
  // bodySmall, a text field's supporting text
  fieldDescription: AdminTypeStep(12, 16, letterSpacing: 0.4),
  fieldMessage: AdminTypeStep(12, 16, letterSpacing: 0.4), // bodySmall
  body: AdminTypeStep(14, 20, letterSpacing: 0.25), // bodyMedium
  bodySmall: AdminTypeStep(12, 16, letterSpacing: 0.4), // bodySmall
  caption: AdminTypeStep(12, 16, letterSpacing: 0.4), // bodySmall
  micro: AdminTypeStep(11, 16, letterSpacing: 0.5), // labelSmall
  button: AdminTypeStep(14, 20, letterSpacing: 0.1), // labelLarge
  buttonSmall: AdminTypeStep(14, 20, letterSpacing: 0.1), // labelLarge
  mono: AdminTypeStep(14, 20),
  monoSmall: AdminTypeStep(12, 16),
);

// Google's Material data colours (blue, red, purple, yellow, cyan, deep orange,
// indigo, green), ordered so neighbours stay apart under protanopia and
// deuteranopia; the light steps are deepened to 3:1 on surface and background.
const _chartLight = [
  Color(0xFF4285F4),
  Color(0xFFDB4437),
  Color(0xFFAB47BC),
  Color(0xFFB08101),
  Color(0xFF0997A9),
  Color(0xFFE95C2E),
  Color(0xFF5C6BC0),
  Color(0xFF0F9D58),
];
const _chartDark = [
  Color(0xFF4285F4),
  Color(0xFFDB4437),
  Color(0xFFAB47BC),
  Color(0xFFF4B400),
  Color(0xFF00ACC1),
  Color(0xFFFF7043),
  Color(0xFF5C6BC0),
  Color(0xFF0F9D58),
];

/// M3's elevation levels 1 / 2 / 3 (md.sys.elevation): a key shadow at 30%
/// over an ambient one at 15%, one set for both modes. Cards and resting
/// lifts take level 1, menus level 2, dialogs level 3.
const _elevation = AdminElevation(
  // level 1: 0 1px 2px rgba(0,0,0,.3), 0 1px 3px 1px rgba(0,0,0,.15)
  sm: [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 1,
    ),
  ],
  // level 2: 0 1px 2px rgba(0,0,0,.3), 0 2px 6px 2px rgba(0,0,0,.15)
  md: [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 2,
    ),
  ],
  // level 3: 0 1px 3px rgba(0,0,0,.3), 0 4px 8px 3px rgba(0,0,0,.15)
  lg: [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 3,
    ),
  ],
);

/// Material 3 — tonal purple, generous radii, a 3dp focus indicator 2dp out,
/// stadium buttons and 4dp outlined fields.
final materialTheme = AdminTheme.from(
  name: 'Material',
  palette: materialPalette,
  dark: materialDarkPalette,
  radii: const AdminRadii(
    radiusSmall: 8,
    radius: 12,
    radiusLarge: 16,
    radiusMenu: 4, // corner.extraSmall
    radiusDialog: 28, // corner.extraLarge
    radiusPill: 8, // chips: corner.small
    radiusField: 4, // text fields: corner.extraSmall
    radiusButton: 999, // common buttons: corner.full
    radiusCheck: 2, // the checkbox's container
  ),
  type: const AdminTypeSpec(
    fontFamily: 'Roboto',
    heading: FontWeight.w500, // the title and label styles: Medium
    title: FontWeight.w400, // the headline styles: Regular
    label: FontWeight.w400, // bodySmall
    strong: FontWeight.w500, // labelLarge, labelSmall, titleSmall
    message: FontWeight.w400, // a text field's supporting text: bodySmall
    uppercaseLabels: false,
    ramp: _ramp,
  ),
  focus: const AdminFocusSpec(width: 3, offset: 2),
  // M3 buttons are 40, the extra-small one 32; 48 is the kit's large step.
  // Fields follow them. A text field's leading and trailing icons are 24dp
  // in M3; 20 is the largest the kit's fields hold, in a colour field's
  // swatch column and a 32dp field.
  sizes: const AdminControlSizes(
    small: 32,
    medium: 40,
    large: 48,
    fieldIcon: 20,
  ),
  // data table: 52 rows under a 56 header, 16 cell padding; the compact and
  // comfortable rows are the MUI DataGrid densities (36 / 67) on the grid
  table: const AdminTableMetrics(
    rowCompact: 36,
    rowStandard: 52,
    rowComfortable: 64,
    headerHeight: 56,
    cellPaddingX: 16,
    selectionColumnWidth: 48,
  ),
  // short2 / short4 / medium2; the standard and emphasized curves
  motion: const AdminMotion(
    fast: Duration(milliseconds: 100),
    medium: Duration(milliseconds: 200),
    slow: Duration(milliseconds: 300),
    standard: Cubic(0.2, 0, 0, 1),
    enter: Cubic(0.05, 0.7, 0.1, 1), // emphasizedDecelerate
    exit: Cubic(0.3, 0, 0.8, 0.15), // emphasizedAccelerate
    emphasized: Curves.easeInOutCubicEmphasized,
  ),
  // a focused text field's 2dp outline; a focused invalid one keeps it. An
  // unchecked checkbox's and radio's 2dp outline
  stroke: const AdminStroke(fieldFocus: 2, fieldError: 1, controlStrong: 2),
  elevation: _elevation,
  darkElevation: _elevation,
  // the outlined text field: an outline #79747E, 2dp primary on focus; a
  // required field's label ends in `*`
  field: const AdminFieldStyle(
    accentFocus: true,
    requiredMark: FieldRequiredMark.trailing,
  ),
  button: const AdminButtonStyle(
    padding: AdminButtonPadding(
      // the 32dp extra-small button: 12dp either side
      small: AdminButtonInsets.symmetric(12),
      // common buttons: 24dp either side, 16dp on the icon's
      medium: AdminButtonInsets.symmetric(24, startWithIcon: 16),
      large: AdminButtonInsets.symmetric(24, startWithIcon: 16),
    ),
    labelWeight: FontWeight.w500, // labelLarge
    strongOutline: true, // the outlined button's outline, #79747E
    accentGhost: true, // the text button's primary label
  ),
  // the navigation drawer and rail, and the small top app bar
  shell: const AdminShellStyle(
    sidebarWidth: 360,
    railWidth: 80,
    itemHeight: 56, // a destination's active indicator
    itemGap: 0, // destinations stack without a gap
    itemPaddingX: 16, // the icon 16dp inside the active indicator
    itemMarginX: 12, // the active indicator 12dp in from the drawer's edges
    itemRadius: 999, // the active indicator: corner.full
    itemIconSize: 24,
    indicator: NavIndicator.none, // the secondaryContainer pill carries it
    topBarHeight: 64,
  ),
  // the plain tooltip: no arrow, 200dp at most (PlainTooltipMaxWidth), a
  // 4dp corner, 8×4 around bodySmall
  overlay: const AdminOverlayStyle(tooltipMaxWidth: 200, tooltipRadius: 4),
  // the segmented button: outlined segments, the selected one in
  // secondaryContainer under a check, labelLarge
  segmented: const AdminSegmentedStyle(
    variant: SegmentedVariant.joined,
    checkmark: true,
  ),
  // Switch: a 52×32 track outlined in `outline` over
  // surfaceContainerHighest, its handle 16 off and 24 on. Checkbox: an 18dp
  // container outlined in onSurfaceVariant. Radio button: a 20dp icon, the
  // 2dp ring around a 10dp dot, both primary when selected
  selection: const AdminSelectionStyle(
    toggleWidth: 52,
    toggleHeight: 32,
    toggleKnob: 16,
    toggleKnobOn: 24,
    toggleOff: ToggleOffStyle.tonal,
    radioSize: 20,
    radioMark: RadioMark.dot,
    radioDot: 10,
    outline: SelectionOutline.secondary,
  ),
  // Slider: a 16dp track, secondaryContainer past the handle, parted by a
  // 4×44dp handle with 6dp either side
  slider: const AdminSliderStyle(
    trackHeight: 16,
    thumb: SliderThumb.bar,
    thumbSize: 44,
    rail: SliderRail.soft,
  ),
  // Primary tabs: a 48dp row, titleSmall labels in on-surface-variant, the
  // selected one in primary over a 3dp indicator as wide as its label,
  // rounded at the top, on the divider
  tabs: const AdminTabsStyle(
    heightSmall: 40,
    heightMedium: 48,
    heightLarge: 56,
    restInk: TabsRestInk.secondary,
    labelWeight: FontWeight.w500,
    indicatorWidth: TabsIndicatorWidth.label,
    indicatorShape: TabsIndicatorShape.roundedTop,
    indicatorThickness: 3,
  ),
  // M3 has no inline alert, and its snackbar is an inverse surface, which
  // the palette has no role for: the kit's own alert and toast
  feedback: const AdminFeedbackStyle(),
);
