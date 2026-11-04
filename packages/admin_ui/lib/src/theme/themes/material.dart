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
import '../state_layer.dart';
import '../stroke.dart';
import '../table_metrics.dart';
import '../typography.dart';
import 'admin_theme.dart';

/// Material 3 (light) — tonal purple, tinted surfaces, soft ink.
const materialPalette = AdminPalette(
  primary: Color(0xFF6750A4),
  primaryStrong: Color(0xFF4F378B),
  primarySubtle: Color(0xFFEADDFF),
  primaryFaint: Color(0xFFF6EDFF),
  surface: Color(0xFFFFFBFE),
  background: Color(0xFFF3EDF7),
  surfaceMuted: Color(0xFFFEF7FF),
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
  stateLayer: _stateLayer,
  controlBorder: Color(0xFF79747E), // M3 outline
  focusRing: Color(0xFF625B71), // M3 focus indicator: secondary
  chart: _chartLight,
  navSelectedFill: Color(0xFFE8DEF8), // secondaryContainer
  navSelectedText: Color(0xFF1D192B), // onSecondaryContainer
  navIndicator: Color(0x00000000),
  softFill: Color(0xFFE8DEF8), // the tonal button: secondaryContainer
  onSoft: Color(0xFF1D192B), // onSecondaryContainer
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
  ),
  type: const AdminTypeSpec(
    fontFamily: 'Roboto',
    heading: FontWeight.w600,
    label: FontWeight.w400, // bodySmall
    uppercaseLabels: false,
    ramp: _ramp,
  ),
  focus: const AdminFocusSpec(width: 3, offset: 2),
  // M3 buttons are 40 (small 32, large 48); fields follow them
  sizes: const AdminControlSizes(small: 32, medium: 40, large: 48),
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
  // a focused text field's 2dp outline; a focused invalid one keeps it
  stroke: const AdminStroke(fieldFocus: 2, fieldError: 1),
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
  // the plain tooltip: no arrow, and 200dp at most (PlainTooltipMaxWidth)
  overlay: const AdminOverlayStyle(tooltipMaxWidth: 200),
);
