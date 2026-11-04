import 'package:admin_ui/admin_ui.dart';

/// Every shipped theme in both modes, keyed `'<theme> Light'` and
/// `'<theme> Dark'`, then the palettes a theme's frame draws with in place of
/// its page's ([shippedChromePalettes]). Read through [AdminTheme.palette],
/// which builds no tokens and so fetches no Google Font.
final shippedPalettes = <String, AdminPalette>{
  for (final theme in adminThemes) ...{
    '${theme.name} Light': theme.palette,
    '${theme.name} Dark': ?theme.darkPalette,
  },
  ...shippedChromePalettes,
};

/// The sidebar and top-bar palettes the shipped themes' [AdminShellStyle]s
/// carry, keyed by what they draw.
const shippedChromePalettes = <String, AdminPalette>{
  'Carbon Header': carbonShellPalette,
  'Ant Sider': antSiderPalette,
};

/// The dark palette of every shipped theme, keyed by theme name.
final shippedDarkPalettes = <String, AdminPalette>{
  for (final theme in adminThemes) theme.name: ?theme.darkPalette,
};
