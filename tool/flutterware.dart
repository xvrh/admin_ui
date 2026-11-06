import 'package:flutterware/plugins.dart';

/// What flutterware offers for this repository.
///
/// `fw status` for what the tools say, `fw actions` for what they can do. The
/// GUI, the CLI and the MCP server are three renderings of this file.

// Admin apps are desktop-shaped, so the previews declare a window rather than
// a phone.
const adminUi = Pkg('packages/admin_ui');
const adminUiExample = Pkg('packages/admin_ui/example');

/// The reference admin: the kit consumed through its public barrels only,
/// over an in-memory fake shop, exercised and exported by its scenarios.
const referenceAdmin = Pkg('reference_admin');

const packages = [adminUi, adminUiExample, referenceAdmin];

/// The window sizes an admin is used at. The head is the default, and the
/// narrow one is where panels break.
const adminCanvas = PreviewCanvas(
  '',
  devices: [Devices.window, Devices.smallWindow, Devices.wideWindow],
);

void main() => Flutterware.configure((fw) {
  fw.identity(
    const ProjectIdentity(
      package: referenceAdmin,
      icon: 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',
    ),
  );

  fw.changes(
    ChangesConfig(
      attention: [
        'tool/flutterware.dart',
        'CLAUDE.md',
        'pubspec.yaml',
        '.fvmrc',
        'packages/admin_ui/lib/*.dart',
        'packages/admin_ui/api.txt',
        'packages/admin_ui/looks.txt',
        '.github/workflows/**',
      ],
    ),
  );

  fw.use(Dependencies(packages: DependenciesPackage.each(packages)));
  fw.use(Assets(packages: AssetsPackage.each(packages)));
  fw.use(
    Previews(
      packages: [
        for (var pkg in packages) .new(pkg, canvases: [adminCanvas]),
      ],
    ),
  );

  fw.use(
    Run(
      packages: [
        .new(
          adminUiExample,
          entrypoints: [
            Entrypoint(
              'lib/main.dart',
              name: 'Admin UI catalog',
              description:
                  'Every widget of the kit, no backend — the fastest place '
                  'to try a component change',
              platforms: [RunPlatform.desktop],
            ),
          ],
        ),
        .new(
          referenceAdmin,
          entrypoints: [
            Entrypoint(
              'lib/main.dart',
              name: 'Reference admin',
              description:
                  'The reference app over its in-memory fake shop — no '
                  'server; seeded demo accounts',
              platforms: [RunPlatform.desktop, RunPlatform.web],
              knobs: [
                Knob('latencyMs', label: 'Fake latency (ms)'),
                Knob('seed', label: 'Seed'),
                Knob('signedIn', label: 'Start signed in'),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  fw.use(
    Scenarios(
      // Not the example: it has no scenarios, and a declared package with
      // none leaves `fw compare` without a scenario verdict.
      packages: [
        // test/scenarios only: the unit tests and the layout sweep beside it
        // are plain tests, not scenarios.
        .new(
          referenceAdmin,
          directory: 'test/scenarios',
          languages: ['en', 'fr', 'ar'],
        ),
      ],
    ),
  );

  fw.use(Lints());
});
