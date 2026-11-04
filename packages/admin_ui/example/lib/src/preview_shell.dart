import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'utils/themable_test_app.dart';

/// The themes a preview can be rendered under: all of [adminThemes]. Iris,
/// Material, shadcn and Carbon name Inter, Roboto, Inter and IBM Plex Sans,
/// which this package bundles under `assets/fonts/`. Ant uses the platform's
/// font, and Fluent names Segoe UI, which it gets only where the system has
/// it.
///
/// The Locale axis needs no font of its own: none of the theme fonts has
/// Arabic or Hebrew glyphs, and the preview runner, which does not use the
/// test font, draws those scripts in the machine's fallback font, as a device
/// would. A machine with no Arabic or Hebrew font installed draws them as
/// boxes.
final _previewThemes = adminThemes;

/// The wrapper every `@Preview` in this package names.
///
/// The same [ThemableTestApp] the catalog page mounts, so a preview opened on
/// its own is themed the way the catalog themes it. A demo that must ignore
/// theming names no wrapper.
Widget adminUiPreview(Widget child) =>
    ThemableTestApp(themes: _previewThemes, child: child);
