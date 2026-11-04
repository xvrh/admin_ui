import 'dart:async';

import 'package:admin_ui/testing.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs around every test file in this package.
///
/// The package bundles no fonts, so Iris's Inter is loaded from the
/// example's files before the tests start: a test on `irisTheme` measures
/// its text in Inter, as an app that bundles it draws it. Nothing else is
/// loaded, so text in any other family stays in the test font the tests'
/// numbers assume.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAdminFonts(
    themes: [irisTheme],
    fontDirectory: 'example/assets/fonts',
    standIns: const {},
    fontManifest: false,
  );
  await testMain();
}
