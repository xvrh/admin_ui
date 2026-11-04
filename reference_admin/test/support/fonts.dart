import 'package:admin_ui/testing.dart';
import 'package:flutterware/flutter_test.dart' show loadScenarioFonts;
import 'package:reference_admin/src/appearance/themes.dart';

Future<void>? _preparing;

/// Makes every theme's text measure and draw in its real face, in both
/// lanes: a bare `flutter test` and the flutterware runner. Runs in real
/// time, before `runScenarios`, from each folder's `flutter_test_config`,
/// through the kit's [loadAdminFonts]:
///
/// - Roboto under `Segoe UI`, Fluent's family, which cannot ship;
/// - every theme's font, light and dark, from `assets/fonts/`; a family
///   with no file fails here, naming the theme and the family.
///
/// `Noto Naskh Arabic` is a FontManifest family, which flutterware loads.
Future<void> prepareScenarioFonts() => _preparing ??= loadAdminFonts(
  themes: appThemes,
  fontDirectory: 'assets/fonts',
  standIns: const {'Segoe UI': 'Roboto'},
  fontManifest: false,
);

/// [prepareScenarioFonts], and what the plain tests (the sweep, the unit
/// tests) need besides: `runScenarios` loads these itself, a bare test does
/// not. The FontManifest families (Noto Naskh Arabic, the Material icons),
/// and Roboto under [testPlatformFamily], the family the test platform's
/// Material typography names for a theme that names none (Ant): without it
/// that text measures in the test font's wide boxes.
Future<void> prepareTestFonts() async {
  await loadScenarioFonts();
  await loadAdminFonts(
    themes: appThemes,
    fontDirectory: 'assets/fonts',
    standIns: const {testPlatformFamily: 'Roboto', 'Segoe UI': 'Roboto'},
    fontManifest: false,
  );
}
