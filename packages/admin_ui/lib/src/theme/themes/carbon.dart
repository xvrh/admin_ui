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

/// IBM Carbon (white/g10) — structured grays, blue 60, square corners.
const carbonPalette = AdminPalette(
  primary: Color(0xFF0F62FE),
  primaryStrong: Color(0xFF0050E6), // $button-primary-hover
  primarySubtle: Color(0xFFEDF5FF),
  primaryFaint: Color(0xFFF6FAFF),
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFF4F4F4),
  surfaceMuted: Color(0xFFFAFAFA),
  foreground: Color(0xFF161616),
  foregroundSecondary: Color(0xFF393939),
  foregroundMuted: Color(0xFF525252),
  foregroundSubtle: Color(0xFF6F6F6F),
  foregroundFaint: Color(0xFFA8A8A8),
  border: Color(0xFFE0E0E0),
  borderSubtle: Color(0xFFF4F4F4),
  success: Color(0xFF24A148),
  warning: Color(0xFFF1C21B),
  danger: Color(0xFFDA1E28),
  warningText: Color(0xFF8E6A00),
  highlight: Color(0xFFFCF4D6),
  modifiedFill: Color(0xFFFCF4D6),
  tabDivider: Color(0xFFE0E0E0),
  info: Color(0xFF0043CE), // $support-info
  primaryActive: Color(0xFF002D9C), // $button-primary-active
  controlBorder: Color(0xFF8D8D8D), // $border-strong-01
  focusRing: Color(0xFF0F62FE), // $focus
  chart: _chartLight,
  listHighlight: Color(0xFFE8E8E8), // $layer-hover-01
  navSelectedFill: Color(0xFFE0E0E0), // $layer-selected-01
  navHoverFill: Color(0xFFE8E8E8), // $layer-hover-01
  navSelectedText: Color(0xFF161616), // $text-primary
  navIndicator: Color(0xFF0F62FE), // $border-interactive
  // A field is $field-01, the white surface, on the #F4F4F4 page.
  fieldFillHover: Color(0xFFE8E8E8), // $field-hover-01
  neutralFill: Color(0xFF393939), // $button-secondary (Gray 80)
  neutralFillHover: Color(0xFF474747), // $button-secondary-hover
  neutralFillActive: Color(0xFF6F6F6F), // $button-secondary-active
);

/// IBM Carbon (g100) — the page is $background, cards and inputs $layer-01
/// above it; the primary and danger buttons keep their light-theme fills with
/// white text.
const carbonDarkPalette = AdminPalette(
  primary: Color(0xFF0F62FE), // $button-primary
  primaryStrong: Color(0xFF0050E6), // $button-primary-hover
  primarySubtle: Color(0xFF213251),
  primaryFaint: Color(0xFF232D40),
  surface: Color(0xFF262626), // $layer-01
  background: Color(0xFF161616), // $background
  surfaceMuted: Color(0xFF1C1C1C),
  foreground: Color(0xFFF4F4F4),
  foregroundSecondary: Color(0xFFC6C6C6),
  foregroundMuted: Color(
    0xFFA8A8A8,
  ), // gray 40: holds 4.5:1 on the selection tints too
  foregroundSubtle: Color(0xFF6F6F6F),
  foregroundFaint: Color(0xFF525252),
  border: Color(0xFF393939), // $border-subtle-01
  borderSubtle: Color(0xFF333333),
  success: Color(0xFF42BE65),
  warning: Color(0xFFF1C21B),
  danger: Color(0xFFDA1E28), // $button-danger-primary, the same in g100
  warningText: Color(0xFFD2A800),
  highlight: Color(0xFF332C12),
  modifiedFill: Color(0xFF26201A),
  tabDivider: Color(0xFF525252),
  info: Color(0xFF4589FF), // $support-info
  primaryText: Color(0xFF78A9FF), // $link-primary
  dangerText: Color(0xFFFF8389), // $text-error
  primaryActive: Color(0xFF002D9C), // $button-primary-active
  controlBorder: Color(0xFF6F6F6F), // $border-strong-01
  focusRing: Color(0xFFFFFFFF), // $focus
  chart: _chartDark,
  listHighlight: Color(0xFF333333), // $layer-hover-01
  navSelectedFill: Color(0xFF393939), // $layer-selected-01
  navHoverFill: Color(0xFF333333), // $layer-hover-01
  navSelectedText: Color(0xFFF4F4F4), // $text-primary
  navIndicator: Color(0xFF4589FF), // $border-interactive
  // A field is $field-01, the #262626 surface, on the #161616 page.
  fieldFillHover: Color(0xFF333333), // $field-hover-01
  neutralFill: Color(0xFF6F6F6F), // $button-secondary
  neutralFillHover: Color(0xFF5E5E5E), // $button-secondary-hover
  neutralFillActive: Color(0xFF393939), // $button-secondary-active
);

/// Carbon's UI shell header, which is g100 in every theme: a #161616
/// ($background) bar over a $border-subtle rule, $text-primary labels, the
/// white $focus, and $field-01 fields. The top bar draws with it in light
/// and dark alike.
const carbonShellPalette = AdminPalette(
  primary: Color(0xFF0F62FE), // $button-primary
  primaryStrong: Color(0xFF0050E6), // $button-primary-hover
  primarySubtle: Color(0xFF213251),
  primaryFaint: Color(0xFF232D40),
  surface: Color(0xFF161616), // the header: $background
  background: Color(0xFF161616), // $background
  surfaceMuted: Color(0xFF1C1C1C),
  foreground: Color(0xFFF4F4F4), // $text-primary
  foregroundSecondary: Color(0xFFC6C6C6), // $text-secondary, $icon-secondary
  foregroundMuted: Color(0xFFA8A8A8), // gray 40
  foregroundSubtle: Color(0xFF6F6F6F),
  foregroundFaint: Color(0xFF525252),
  border: Color(0xFF393939), // $border-subtle
  borderSubtle: Color(0xFF262626),
  success: Color(0xFF42BE65),
  warning: Color(0xFFF1C21B),
  danger: Color(0xFFDA1E28), // $button-danger-primary
  warningText: Color(0xFFD2A800),
  highlight: Color(0xFF332C12),
  modifiedFill: Color(0xFF26201A),
  tabDivider: Color(0xFF525252),
  info: Color(0xFF4589FF), // $support-info
  primaryText: Color(0xFF78A9FF), // $link-primary
  dangerText: Color(0xFFFF8389), // $text-error
  primaryActive: Color(0xFF002D9C), // $button-primary-active
  controlBorder: Color(0xFF6F6F6F), // $border-strong-01
  focusRing: Color(0xFFFFFFFF), // $focus
  listHighlight: Color(0xFF292929), // $background-hover
  navSelectedFill: Color(0xFF393939), // $layer-selected
  navHoverFill: Color(0xFF292929), // $background-hover
  navSelectedText: Color(0xFFF4F4F4), // $text-primary
  navIndicator: Color(0xFF4589FF), // $border-interactive
  fieldFill: Color(0xFF262626), // $field-01
  fieldFillHover: Color(0xFF333333), // $field-hover-01
);

/// Carbon's shadow, for the few surfaces it lifts (menus, popovers, a
/// modal): `0 2px 6px $shadow`.
AdminElevation _elevation(Color shadow) {
  final lift = [
    BoxShadow(color: shadow, offset: const Offset(0, 2), blurRadius: 6),
  ];
  return AdminElevation(sm: lift, md: lift, lg: lift);
}

/// Carbon's productive type set: body-01 (14/20) for body, body-compact-01
/// (14/18) in controls, label-01 and helper-text-01 (12/16) for labels and
/// help, heading-compact and productive headings above.
const _ramp = AdminTypeRamp(
  displayLarge: AdminTypeStep(42, 50), // heading-06
  displayMedium: AdminTypeStep(32, 40), // heading-05
  displaySmall: AdminTypeStep(28, 36), // heading-04
  headlineMedium: AdminTypeStep(20, 28), // heading-03
  headlineSmall: AdminTypeStep(20, 28), // heading-03, a modal's title
  titleLarge: AdminTypeStep(20, 28), // heading-03
  pageTitle: AdminTypeStep(28, 36), // heading-04
  heading: AdminTypeStep(16, 22), // heading-compact-02
  // heading-compact-01
  sectionLabel: AdminTypeStep(14, 18, letterSpacing: 0.16),
  fieldLabel: AdminTypeStep(12, 16, letterSpacing: 0.32), // label-01
  fieldText: AdminTypeStep(14, 18, letterSpacing: 0.16), // body-compact-01
  // helper-text-01
  fieldDescription: AdminTypeStep(12, 16, letterSpacing: 0.32),
  fieldMessage: AdminTypeStep(12, 16, letterSpacing: 0.32),
  body: AdminTypeStep(14, 20, letterSpacing: 0.16), // body-01
  bodySmall: AdminTypeStep(12, 16, letterSpacing: 0.32), // label-01
  caption: AdminTypeStep(12, 16, letterSpacing: 0.32), // helper-text-01
  micro: AdminTypeStep(12, 16, letterSpacing: 0.32), // label-01
  button: AdminTypeStep(14, 18, letterSpacing: 0.16), // body-compact-01
  buttonSmall: AdminTypeStep(14, 18, letterSpacing: 0.16),
  mono: AdminTypeStep(14, 20, letterSpacing: 0.32), // code-02
  monoSmall: AdminTypeStep(12, 16, letterSpacing: 0.32), // code-01
);

// Carbon's categorical palettes, in their prescribed order.
const _chartLight = [
  Color(0xFF6929C4),
  Color(0xFF1192E8),
  Color(0xFF005D5D),
  Color(0xFF9F1853),
  Color(0xFFFA4D56),
  Color(0xFF570408),
  Color(0xFF198038),
  Color(0xFF002D9C),
];
const _chartDark = [
  Color(0xFF8A3FFC),
  Color(0xFF33B1FF),
  Color(0xFF007D79),
  Color(0xFFFF7EB6),
  Color(0xFFFA4D56),
  Color(0xFFFFF1F1),
  Color(0xFF6FDC8C),
  Color(0xFF4589FF),
];

/// IBM Carbon — structured grays, square corners, filled fields, a 2px focus
/// border drawn inside the control's edge, and the g100 header.
final carbonTheme = AdminTheme.from(
  name: 'Carbon',
  palette: carbonPalette,
  dark: carbonDarkPalette,
  // Square throughout: buttons, fields, tiles, menus, modals and
  // notifications. Tags keep their pill (radiusPill).
  radii: const AdminRadii(
    radiusSmall: 0,
    radius: 0,
    radiusLarge: 0,
    radiusMenu: 0,
    radiusDialog: 0,
  ),
  type: const AdminTypeSpec(
    fontFamily: 'IBM Plex Sans',
    heading: FontWeight.w600,
    label: FontWeight.w400, // label-01
    uppercaseLabels: false,
    ramp: _ramp,
  ),
  focus: const AdminFocusSpec(width: 2, offset: -2),
  // sm / md / lg fields and buttons (field md 40)
  sizes: const AdminControlSizes(small: 32, medium: 40, large: 48),
  // DataTable md / lg / xl rows under a lg header, spacing-05 cells; its sm
  // row (32) would leave a sm control no room
  table: const AdminTableMetrics(
    rowCompact: 40,
    rowStandard: 48,
    rowComfortable: 64,
    headerHeight: 48,
    cellPaddingX: 16,
    selectionColumnWidth: 48,
  ),
  // fast-02 / moderate-01 / moderate-02 on the productive curves; the
  // expressive standard curve for a larger move
  motion: const AdminMotion(
    fast: Duration(milliseconds: 110),
    medium: Duration(milliseconds: 150),
    slow: Duration(milliseconds: 240),
    pulse: Duration(milliseconds: 1500), // the skeleton's 3s cycle
    standard: Cubic(0.2, 0, 0.38, 0.9),
    enter: Cubic(0, 0, 0.38, 0.9),
    exit: Cubic(0.2, 0, 1, 0.9),
    emphasized: Cubic(0.4, 0.14, 0.3, 1),
  ),
  // the 2px $focus and $support-error outlines
  stroke: const AdminStroke(fieldFocus: 2, fieldError: 2),
  elevation: _elevation(const Color(0x4D000000)), // $shadow: black at 30%
  darkElevation: _elevation(const Color(0xCC000000)), // g100: black at 80%
  // TextInput: a $field-01 box with a $border-strong-01 bottom rule, and
  // the 2px $focus (or $support-error) outline inset over its whole edge.
  // Forms mark the optional fields, "(optional)" after the label, and leave
  // the required ones bare
  field: const AdminFieldStyle(
    variant: FieldVariant.filled,
    requiredMark: FieldRequiredMark.optionalText,
  ),
  button: const AdminButtonStyle(
    labelAlignment: ButtonLabelAlignment.start,
    iconPlacement: ButtonIconPlacement.end,
    // `15px … 63px` inside the 1px border: the label at 16, the end kept
    // clear for the icon; the 32px small button keeps the 1:4 proportion
    padding: AdminButtonPadding(
      small: AdminButtonInsets(start: 12, end: 48),
      medium: AdminButtonInsets(start: 16, end: 64),
      large: AdminButtonInsets(start: 16, end: 64),
    ),
    labelWeight: FontWeight.w400, // body-compact-01
    filledSecondary: true, // $button-secondary
    accentGhost: true, // the ghost button's $link-primary label
  ),
  // the UI shell: a 16rem side nav collapsing to a 3rem rail, 2rem links
  // with no gap between them, the current one marked by a 3px
  // $border-interactive rule; the 3rem g100 header
  shell: const AdminShellStyle(
    sidebarWidth: 256,
    railWidth: 48,
    itemHeight: 32,
    itemGap: 0,
    itemPaddingX: 16, // $spacing-05
    itemRadius: 0,
    indicator: NavIndicator.edge,
    indicatorWidth: 3,
    topBarHeight: 48,
    topBarPalette: carbonShellPalette,
  ),
  // Tooltip: a caret, max-inline-size 18rem; the caret is 0.75rem × 0.375rem
  overlay: const AdminOverlayStyle(tooltipArrow: true, tooltipMaxWidth: 288),
);
