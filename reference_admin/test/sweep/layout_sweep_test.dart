import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reference_admin/src/api/shop_api.dart';
import 'package:reference_admin/src/app.dart';
import 'package:reference_admin/src/appearance/themes.dart';
import 'package:reference_admin/src/fake/fake_shop_api.dart';
import 'package:reference_admin/src/routing/routes.dart';
import 'package:reference_admin/src/services.dart';

// Every page, pumped through the whole app, across themes, modes, languages
// and widths, failing on any exception or overflow. A plain test outside
// test/scenarios: nothing here is a picture.
//
// The gate runs a rotating covering array: page r gets four theme/modes,
// (4r + k) mod 14 for k in 0..3, each paired with the language × width
// combination (r + k) mod 8, so every theme/mode meets several pages and
// every combination is hit. `--dart-define=reference_admin.sweep=full` runs
// every page in every theme/mode and every combination, by hand before a
// kit release.

const _full = String.fromEnvironment('reference_admin.sweep') == 'full';

const _pages = <AppRoute>[
  SignIn(),
  SetPassword('invite-7'),
  ...everyPage,
  Forbidden(Team()),
];

final _themeModes = [
  for (final theme in appThemes)
    for (final dark in [false, true]) (theme: theme.name, dark: dark),
];

const _combos = [
  (language: 'en', width: 1280.0, height: 800.0),
  (language: 'fr', width: 1280.0, height: 800.0),
  (language: 'ar', width: 1280.0, height: 800.0),
  (language: 'en', width: 393.0, height: 852.0),
  (language: 'fr', width: 393.0, height: 852.0),
  (language: 'ar', width: 393.0, height: 852.0),
  // The medium layout (the rail): a small window, and a tablet upright.
  (language: 'fr', width: 1024.0, height: 700.0),
  (language: 'ar', width: 820.0, height: 1180.0),
];

void main() {
  for (final (r, page) in _pages.indexed) {
    final runs = _full
        ? [
            for (var t = 0; t < _themeModes.length; t++)
              for (var c = 0; c < _combos.length; c++) (t, c),
          ]
        : [
            for (var k = 0; k < 4; k++)
              ((4 * r + k) % _themeModes.length, (r + k) % _combos.length),
          ];
    for (final (t, c) in runs) {
      final themeMode = _themeModes[t];
      final combo = _combos[c];
      final label =
          '${page.uri} · ${themeMode.theme} ${themeMode.dark ? 'dark' : 'light'}'
          ' · ${combo.language} · ${combo.width.toInt()}';
      testWidgets(label, (tester) async {
        tester.view
          ..physicalSize = Size(combo.width, combo.height)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final services = AppServices.fake(
          latency: Latency.none,
          seed: page is Setup ? DemoSeed.empty : DemoSeed.demo,
          signInAs: page.isPublic
              ? null
              : page is Forbidden
              ? Role.viewer
              : Role.owner,
        );
        services.appearance.apply(
          UserPrefs(
            theme: themeMode.theme,
            mode: themeMode.dark ? AppearanceMode.dark : AppearanceMode.light,
            locale: combo.language,
          ),
        );
        await tester.pumpWidget(
          ReferenceAdminApp(
            services: services,
            initialRoute: page is Forbidden ? page.from : page,
          ),
        );
        // Bounded, not pumpAndSettle: a page may hold a spinner on purpose.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(
          services.router.route.runtimeType,
          page.runtimeType,
          reason: 'the guards sent ${page.uri} elsewhere',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 11));
      });
    }
  }
}
