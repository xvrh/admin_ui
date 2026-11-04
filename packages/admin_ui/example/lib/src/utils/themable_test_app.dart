import 'package:admin_ui/admin_ui.dart';
import 'package:flutterware/previews.dart';
import 'package:material_ui/material_ui.dart';

import 'test_app.dart';

/// A [TestApp] driven by shell-level axes — the controls flutterware draws
/// above whatever is on screen, in the catalog page and in a preview alike:
///
/// * **Theme** — switch between the toolkit themes.
/// * **Mode** — Light / Dark.
/// * **Brand** — rebrand the chosen theme with a client accent
///   (`tokens.branded(seed)`), proving any theme can be re-skinned by swapping
///   just the primary colour.
/// * **Direction** — Auto (the locale's), LTR or RTL: mirror any demo without
///   translating it.
/// * **Locale** — en, fr, ar or he: the kit's strings, Material's, and the
///   locale's numbers and dates. Arabic and Hebrew lay out right to left under
///   Auto; Hebrew has no kit strings, so it shows the English fallback
///   mirrored.
///
/// Drop it into the catalog's `appBuilder`, or name it from a `@Preview`'s
/// `wrapper:` (see `preview_shell.dart`). Opt-in by composition — a demo that
/// should ignore theming can be wrapped in plain [TestApp] instead. Pass
/// [themes] to narrow the list (defaults to [adminThemes]).
class ThemableTestApp extends StatelessWidget {
  final Widget child;
  final List<AdminTheme>? themes;

  const ThemableTestApp({super.key, required this.child, this.themes});

  @override
  Widget build(BuildContext context) {
    final themes = this.themes ?? adminThemes;

    return PreviewShell(
      'admin_ui',
      builder: (context, axes) {
        final theme = axes.picker<AdminTheme>('Theme', {
          for (final t in themes) t.name: t,
        }, themes.first);

        final mode = axes.picker<ThemeMode>('Mode', const {
          'Light': ThemeMode.light,
          'Dark': ThemeMode.dark,
        }, ThemeMode.light);

        final brand = axes.picker<Color?>('Brand', adminPreviewBrands, null);

        final direction = axes.picker<TextDirection?>('Direction', const {
          'Auto': null,
          'LTR': TextDirection.ltr,
          'RTL': TextDirection.rtl,
        }, null);

        final locale = axes.picker<Locale>('Locale', {
          for (final l in TestApp.locales) l.languageCode: l,
        }, TestApp.locales.first);

        var light = theme.tokens;
        var dark = theme.dark ?? theme.tokens;
        if (brand != null) {
          light = light.branded(brand);
          dark = dark.branded(brand);
        }

        return TestApp(
          theme: buildAppTheme(light),
          darkTheme: buildAppTheme(dark),
          themeMode: mode,
          locale: locale,
          textDirection: direction,
          child: child,
        );
      },
    );
  }
}

/// The Brand axis of [ThemableTestApp]: `Default` keeps the theme's own
/// primary, then the kit's [adminAccents], each laid over it with
/// `tokens.branded()`.
const adminPreviewBrands = <String, Color?>{'Default': null, ...adminAccents};
