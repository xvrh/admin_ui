import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../elevation.dart';
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

// Audited on 18 November 2026 against shadcn/ui's registry (apps/v4 on
// main): the zinc base colour, drawn as the new-york-v4 components and the
// Vega style that carries their geometry draw it, on Tailwind CSS v4's
// scale. The CLI's default has since moved to the Nova style and the neutral
// base colour, which this is not.
//
// The kit's contrast rules, where they leave shadcn's variables:
// - a control's outline is `border` deepened to 3:1 (#919194, dark #646466),
//   where `--input` is #E4E4E7 (1.27:1 on white) and white at 15%;
// - the focus ring is `--ring` deepened to 3:1 in light mode, and drawn
//   opaque around a button, where shadcn lays it at 50%;
// - the light chart colours are deepened to 3:1.

/// shadcn/ui (zinc) — neutral, near-black primary, hairline borders, crisp.
const shadcnPalette = AdminPalette(
  primary: Color(0xFF18181B),
  primaryStrong: Color(0xFF09090B),
  primarySubtle: Color(0xFFF4F4F5),
  primaryFaint: Color(0xFFFAFAFA),
  surface: Color(0xFFFFFFFF),
  // --sidebar. shadcn's page is --background, white as its cards are; the
  // kit keeps a page a step under its cards, where it draws a chip, a lane
  // or a hovered row in the page's colour, so the page takes the sidebar's.
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
  // Tailwind v3's red-600, on which white reaches 4.5. --destructive is v4's
  // red-600, #E7000B.
  danger: Color(0xFFDC2626),
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
  primary: Color(0xFFE4E4E7), // --primary
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
  border: Color(0xFF2F2F32), // --border: white at 10%, as it lies on a card
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

/// shadcn's sidebar in dark mode: `--sidebar`, #18181B, the card's colour, a
/// step above the page. Hover lays `--sidebar-accent` over this rail at 55%,
/// as the page's palette lays it over the page.
final shadcnDarkSidebarPalette = shadcnDarkPalette.copyWith(
  background: const Color(0xFF18181B), // --sidebar
  navHoverFill: const Color(0xFF202023),
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

/// Tailwind's shadow-sm, shadow-md and shadow-lg, two layers each at 10%:
/// the active tab, a menu or popover, a dialog. Light mode only. Tailwind
/// keeps them in dark mode, where they do not show on the #09090B page; the
/// dark tokens take the kit's dark set.
const _elevation = AdminElevation(
  // 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)
  sm: [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ],
  // 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)
  md: [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ],
  // 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)
  lg: [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ],
);

/// The sidebar: SIDEBAR_WIDTH 16rem, collapsing to SIDEBAR_WIDTH_ICON 3rem,
/// over h-8 rounded-md menu buttons a gap-1 apart.
const _shell = AdminShellStyle(
  sidebarWidth: 256,
  railWidth: 48,
  itemHeight: 32,
  itemRadius: 8,
);

/// shadcn/ui — neutral zinc, near-black primary, tight type, a 3px ring flush
/// with the control.
final shadcnTheme = AdminTheme.from(
  name: 'shadcn',
  palette: shadcnPalette,
  dark: shadcnDarkPalette,
  // --radius 0.625rem: rounded-sm 6, rounded-md 8, rounded-lg 10 and
  // rounded-xl 14
  radii: const AdminRadii(
    radiusSmall: 6, // rounded-sm: a menu item
    radius: 8, // rounded-md
    radiusLarge: 14, // rounded-xl: a card
    radiusMenu: 8, // rounded-md
    radiusDialog: 10, // rounded-lg: new-york's dialog; Vega's is rounded-xl
    radiusButton: 8, // rounded-md at every size
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
  // TableHead h-10 px-2 font-medium text-foreground on no fill, TableCell
  // p-2; the header row and every row end in border-b, the --border colour
  table: const AdminTableMetrics(
    rowCompact: 40,
    rowStandard: 48,
    rowComfortable: 56,
    headerHeight: 40,
    cellPaddingX: 8,
    selectionColumnWidth: 40,
    headerFill: TableHeaderFill.surface,
    headerInk: TableHeaderInk.foreground,
    rowRule: TableRule.border,
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
  // ring colour and a 3px halo around it. A checkbox's and a radio's
  // `border`, 1px
  stroke: const AdminStroke(
    fieldFocus: 1,
    fieldError: 1,
    fieldFocusHalo: 3,
    controlStrong: 1,
  ),
  elevation: _elevation,
  // disabled:opacity-50 on every variant, which keeps a disabled destructive
  // button red. px-3, px-4 and px-6 at sm, default and lg; a button holding
  // an icon is has-[>svg]:px-2.5, px-3 and px-4, which the kit takes on the
  // icon's side
  button: const AdminButtonStyle(
    disabled: ButtonDisabledStyle.faded,
    padding: AdminButtonPadding(
      small: AdminButtonInsets.symmetric(12, startWithIcon: 10),
      medium: AdminButtonInsets.symmetric(16, startWithIcon: 12),
      large: AdminButtonInsets.symmetric(24, startWithIcon: 16),
    ),
  ),
  shell: _shell,
  darkShell: _shell.copyWith(sidebarPalette: shadcnDarkSidebarPalette),
  // TooltipContent's Arrow, and Radix's 10×5 arrow; the tooltip itself is
  // w-fit, so it wraps at the kit's measure
  // TooltipContent: rounded-md px-3 py-1.5 text-xs, shown at once
  // (delayDuration 0)
  overlay: const AdminOverlayStyle(
    tooltipArrow: true,
    tooltipRadius: 8,
    tooltipPaddingX: 12,
    tooltipPaddingY: 6,
    tooltipDelay: Duration.zero,
    arrowWidth: 10,
    arrowHeight: 5,
  ),
  // the tabs list: bg-muted rounded-lg p-[3px] behind a bg-background
  // trigger lifted by shadow-sm, font-medium
  segmented: const AdminSegmentedStyle(knobOutline: false, radius: 10),
  // Switch: h-[1.15rem] w-8 around a size-4 thumb. Checkbox: size-4.
  // Radio group: a size-4 item, filled when checked around a size-2 dot,
  // as the Vega style draws it (new-york keeps the ring around a dot)
  selection: const AdminSelectionStyle(
    toggleWidth: 32,
    toggleHeight: 18,
    toggleKnob: 16,
    checkSize: 16,
    radioSize: 16,
    radioDot: 8,
  ),
  // Slider: an h-1.5 track under a size-4 thumb, bg-white inside a 1px
  // border-primary, on shadow-sm. Its track is bg-muted, which the kit
  // draws in the border colour: bg-muted is all but the page's
  slider: const AdminSliderStyle(
    trackHeight: 6,
    thumb: SliderThumb.ringed,
    thumbSize: 16,
    thumbRing: 1,
  ),
  // Tabs, variant line: an h-9 list on no rule, font-medium triggers in
  // text-foreground/60, the active one text-foreground over a 2px
  // bg-foreground bar
  tabs: const AdminTabsStyle(
    heightSmall: 32,
    heightMedium: 36,
    heightLarge: 40,
    selectedInk: TabsSelectedInk.foreground,
    labelWeight: FontWeight.w500,
    rule: TabsRule.none,
  ),
);
