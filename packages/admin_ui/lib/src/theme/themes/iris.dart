import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../field_style.dart';
import '../focus.dart';
import '../motion.dart';
import '../overlay_style.dart';
import '../palette.dart';
import '../shell_style.dart';
import '../sizes.dart';
import '../stroke.dart';
import '../table_metrics.dart';
import '../typography.dart';
import 'admin_theme.dart';

/// Iris — the kit's own look, and the palette behind `defaultTokens`.
const irisPalette = AdminPalette(
  primary: Color(0xFF5b5bd6),
  primaryStrong: Color(0xFF4a4ac4),
  primarySubtle: Color(0xFFeeeefb),
  primaryFaint: Color(0xFFf5f5fd),
  surface: Color(0xFFffffff),
  background: Color(0xFFf7f8fa),
  surfaceMuted: Color(0xFFfbfbfa),
  foreground: Color(0xFF15181d),
  foregroundSecondary: Color(0xFF3a3d43),
  foregroundMuted: Color(0xFF6b7280),
  foregroundSubtle: Color(0xFF9aa1ac),
  foregroundFaint: Color(0xFFc4c7cd),
  border: Color(0xFFe8eaee),
  borderSubtle: Color(0xFFf0f1f4),
  success: Color(0xFF2f9e63),
  warning: Color(0xFFcf8a00),
  danger: Color(0xFFd14639),
  warningText: Color(0xFF966400),
  highlight: Color(0xFFfdeeb8),
  modifiedFill: Color(0xFFFBF3E0),
  tabDivider: Color(0xFFc5cfdc),
  info: Color(0xFF4EABFB),
  chart: _chartLight,
);

/// Iris (dark) — the page is [AdminPalette.background], cards and inputs
/// [AdminPalette.surface] a step lighter above it.
const irisDarkPalette = AdminPalette(
  primary: Color(0xFF8B8BF0),
  primaryStrong: Color(0xFF6F6FE0),
  primarySubtle: Color(0xFF2E3150),
  primaryFaint: Color(0xFF262940),
  surface: Color(0xFF1E212C),
  background: Color(0xFF15171F),
  surfaceMuted: Color(0xFF1A1D26),
  foreground: Color(0xFFECEDF2),
  foregroundSecondary: Color(0xFFCDCFD9),
  foregroundMuted: Color(0xFF9A9DAD),
  foregroundSubtle: Color(0xFF73768A),
  foregroundFaint: Color(0xFF565A6E),
  border: Color(0xFF30344A),
  borderSubtle: Color(0xFF282B3A),
  success: Color(0xFF6FD68A),
  warning: Color(0xFFE6B450),
  danger: Color(0xFFF07171),
  warningText: Color(0xFFCB983B),
  highlight: Color(0xFF2E2A1C),
  modifiedFill: Color(0xFF24201C),
  tabDivider: Color(0xFF383D4F),
  info: Color(0xFF4EABFB),
  chart: _chartDark,
);

// A designed categorical ramp on Radix step-9 hues (iris, orange, teal, amber,
// plum, grass, blue, crimson), ordered so neighbours stay apart under
// protanopia and deuteranopia, each at 3:1 on surface and background. Same hue
// per slot in both modes.
const _chartLight = [
  Color(0xFF5B5BD6),
  Color(0xFFF06403),
  Color(0xFF04A190),
  Color(0xFFB68805),
  Color(0xFFAB4ABA),
  Color(0xFF41A253),
  Color(0xFF0090FF),
  Color(0xFFE93D82),
];
const _chartDark = [
  Color(0xFF5C5CD7),
  Color(0xFFF76B15),
  Color(0xFF12A594),
  Color(0xFFFAC037),
  Color(0xFFAB4ABA),
  Color(0xFF46A758),
  Color(0xFF0090FF),
  Color(0xFFE93D82),
];

/// Iris — the kit's own look: an indigo primary on cool greys, set in
/// Inter, and the kit's own type ramp, motion, control sizes, table and
/// anatomy.
///
/// Inter draws where the app bundles it, as shadcn's does, and the platform
/// font elsewhere (see the README's "Fonts"). `defaultTokens` is Iris in the
/// platform font.
final irisTheme = AdminTheme.from(
  name: 'Iris',
  palette: irisPalette,
  dark: irisDarkPalette,
  // 13/20 body. Inter's ascent less its descent is its cap height, so an
  // evenly led line centres its capitals in a control.
  type: const AdminTypeSpec(fontFamily: 'Inter', ramp: defaultTypeRamp),
  focus: const AdminFocusSpec(width: 2, offset: 2),
  sizes: defaultControlSizes, // the kit's own ramp
  table: defaultTableMetrics, // the kit's own table
  motion: defaultMotion, // 120 / 180 / 240ms
  stroke: const AdminStroke(), // 1.5px focused and invalid fields
  field: const AdminFieldStyle(), // an outlined box, focused in focusRing
  button: const AdminButtonStyle(), // centred, height / 2 - 4 either side
  shell: const AdminShellStyle(), // a 240 / 64 sidebar, a 56 top bar
  overlay: const AdminOverlayStyle(), // plain tooltips at 280, a 12×6 arrow
);
