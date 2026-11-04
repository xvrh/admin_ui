import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../focus.dart';
import '../motion.dart';
import '../overlay_style.dart';
import '../palette.dart';
import '../radii.dart';
import '../sizes.dart';
import '../stroke.dart';
import '../table_metrics.dart';
import '../typography.dart';
import 'admin_theme.dart';

/// shadcn/ui (zinc) — neutral, near-black primary, hairline borders, crisp.
const shadcnPalette = AdminPalette(
  primary: Color(0xFF18181B),
  primaryStrong: Color(0xFF09090B),
  primarySubtle: Color(0xFFF4F4F5),
  primaryFaint: Color(0xFFFAFAFA),
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFFAFAFA),
  surfaceMuted: Color(0xFFF4F4F5),
  foreground: Color(0xFF09090B),
  foregroundSecondary: Color(0xFF27272A),
  foregroundMuted: Color(0xFF71717A),
  foregroundSubtle: Color(0xFFA1A1AA),
  foregroundFaint: Color(0xFFD4D4D8),
  border: Color(0xFFE4E4E7),
  borderSubtle: Color(0xFFF4F4F5),
  success: Color(0xFF16A34A),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFDC2626), // red-600: white text on it reaches 4.5
  warningText: Color(0xFF92660A),
  highlight: Color(0xFFFEF9C3),
  modifiedFill: Color(0xFFFAF5E6),
  tabDivider: Color(0xFFE4E4E7),
  info: Color(0xFF2563EB),
  focusRing: Color(0xFF90909B), // --ring (zinc-400) deepened to 3:1
  chart: _chartLight,
  listHighlight: Color(0xFFF4F4F5), // --accent
  // --sidebar-accent, deepened to 1.08:1 on the rail so hover shows, and a
  // step deeper again for the selection so it still reads beside a hovered
  // row.
  navSelectedFill: Color(0xFFE9E9EB),
  navHoverFill: Color(0xFFF0F0F1),
  navSelectedText: Color(0xFF18181B), // --sidebar-accent-foreground
  navIndicator: Color(0x00000000),
);

/// shadcn/ui (zinc, dark) — the page is `--background`, cards and popovers
/// `--card` above it, selection `--accent`.
const shadcnDarkPalette = AdminPalette(
  primary: Color(0xFFFAFAFA),
  primaryStrong: Color(0xFFD4D4D8),
  primarySubtle: Color(0xFF27272A), // --accent
  primaryFaint: Color(0xFF1F1F22),
  surface: Color(0xFF18181B), // --card
  background: Color(0xFF09090B), // --background
  surfaceMuted: Color(0xFF111113),
  foreground: Color(0xFFFAFAFA),
  foregroundSecondary: Color(0xFFE4E4E7),
  foregroundMuted: Color(0xFFA1A1AA),
  foregroundSubtle: Color(0xFF71717A),
  foregroundFaint: Color(0xFF52525B),
  border: Color(0xFF27272A),
  borderSubtle: Color(0xFF1F1F22),
  success: Color(0xFF4ADE80),
  warning: Color(0xFFFBBF24),
  danger: Color(0xFFF87171),
  warningText: Color(0xFFD9A036),
  highlight: Color(0xFF2D2A1E),
  modifiedFill: Color(0xFF231F1A),
  tabDivider: Color(0xFF3F3F46),
  info: Color(0xFF60A5FA),
  focusRing: Color(0xFF71717A), // --ring (zinc-500)
  chart: _chartDark,
  listHighlight: Color(0xFF27272A), // --accent
  // --sidebar-accent for the selection; hover lays it over the rail at 55%,
  // so a hovered row never matches the selected one.
  navSelectedFill: Color(0xFF27272A),
  navHoverFill: Color(0xFF1A1A1C),
  navSelectedText: Color(0xFFFAFAFA), // --sidebar-accent-foreground
  navIndicator: Color(0x00000000),
);

/// Tailwind's scale: text-sm (14/20) for body, controls and labels, text-xs
/// (12/16) below it, text-lg to text-4xl above. Headings take tracking-tight
/// (-0.025em); nothing smaller is tracked.
const _ramp = AdminTypeRamp(
  displayLarge: AdminTypeStep(36, 40, letterSpacing: -0.9), // text-4xl
  displayMedium: AdminTypeStep(30, 36, letterSpacing: -0.75), // text-3xl
  displaySmall: AdminTypeStep(24, 32, letterSpacing: -0.6), // text-2xl
  headlineMedium: AdminTypeStep(20, 28, letterSpacing: -0.5), // text-xl
  headlineSmall: AdminTypeStep(18, 28, letterSpacing: -0.45), // text-lg
  titleLarge: AdminTypeStep(18, 28, letterSpacing: -0.45), // text-lg
  pageTitle: AdminTypeStep(24, 32, letterSpacing: -0.6), // text-2xl
  heading: AdminTypeStep(18, 28, letterSpacing: -0.45), // text-lg
  sectionLabel: AdminTypeStep(12, 16), // text-xs
  fieldLabel: AdminTypeStep(14, 20), // text-sm
  fieldText: AdminTypeStep(14, 20),
  fieldDescription: AdminTypeStep(14, 20), // FormDescription: text-sm
  fieldMessage: AdminTypeStep(14, 20), // FormMessage: text-sm
  body: AdminTypeStep(14, 20),
  bodySmall: AdminTypeStep(12, 16),
  caption: AdminTypeStep(12, 16),
  micro: AdminTypeStep(12, 16),
  button: AdminTypeStep(14, 20),
  buttonSmall: AdminTypeStep(14, 20), // size="sm" keeps text-sm
  mono: AdminTypeStep(14, 20),
  monoSmall: AdminTypeStep(12, 16),
);

// --chart-1…5 of each mode, extended to eight with the other mode's hues,
// ordered so neighbours stay apart under protanopia and deuteranopia; the light
// steps are deepened to 3:1 on surface and background. shadcn's own ramp
// changes hue between modes, and so does this one.
const _chartLight = [
  Color(0xFFF54A00),
  Color(0xFF009689),
  Color(0xFF104E64),
  Color(0xFFB78402),
  Color(0xFF155DFC),
  Color(0xFFCB7A05),
  Color(0xFF9810FA),
  Color(0xFFEC003F),
];
const _chartDark = [
  Color(0xFF1E54F3),
  Color(0xFF00BC7D),
  Color(0xFFAD46FF),
  Color(0xFFFE9A00),
  Color(0xFF009689),
  Color(0xFFF54A00),
  Color(0xFF00B8DB),
  Color(0xFFFF2056),
];

/// shadcn/ui — neutral zinc, near-black primary, tight type, a 3px ring flush
/// with the control.
final shadcnTheme = AdminTheme.from(
  name: 'shadcn',
  palette: shadcnPalette,
  dark: shadcnDarkPalette,
  radii: const AdminRadii(
    radiusSmall: 6,
    radius: 8,
    radiusLarge: 12,
    radiusMenu: 8, // rounded-md
    radiusDialog: 12, // rounded-lg
  ),
  type: const AdminTypeSpec(
    fontFamily: 'Inter',
    heading: FontWeight.w600,
    label: FontWeight.w500, // Label: font-medium
    strong: FontWeight.w500,
    uppercaseLabels: false,
    ramp: _ramp,
  ),
  focus: const AdminFocusSpec(width: 3, offset: 0),
  sizes: const AdminControlSizes(small: 32, medium: 36, large: 40), // h-8/9/10
  // TableHead h-10 px-2 font-medium, TableCell p-2
  table: const AdminTableMetrics(
    rowCompact: 40,
    rowStandard: 48,
    rowComfortable: 56,
    headerHeight: 40,
    cellPaddingX: 8,
    selectionColumnWidth: 40,
  ),
  // duration-150 / 200 / 300 on Tailwind's ease-in-out, ease-out and ease-in
  motion: const AdminMotion(
    fast: Duration(milliseconds: 150),
    medium: Duration(milliseconds: 200),
    slow: Duration(milliseconds: 300),
    pulse: Duration(milliseconds: 1000), // animate-pulse: a 2s cycle
    standard: Cubic(0.4, 0, 0.2, 1),
    enter: Cubic(0, 0, 0.2, 1),
    exit: Cubic(0.4, 0, 1, 1),
    emphasized: Cubic(0.4, 0, 0.2, 1),
  ),
  // focus-visible:border-ring ring-[3px] ring-ring/50: a 1px border in the
  // ring colour and a 3px halo around it
  stroke: const AdminStroke(fieldFocus: 1, fieldError: 1, fieldFocusHalo: 3),
  // disabled:opacity-50 on every variant, which keeps a disabled destructive
  // button red
  button: const AdminButtonStyle(disabled: ButtonDisabledStyle.faded),
  // TooltipContent's Arrow, and Radix's 10×5 arrow; the tooltip itself is
  // w-fit, so it wraps at the kit's measure
  overlay: const AdminOverlayStyle(
    tooltipArrow: true,
    arrowWidth: 10,
    arrowHeight: 5,
  ),
);
