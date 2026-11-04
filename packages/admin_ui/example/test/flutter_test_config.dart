import 'dart:async';

import 'support/harness/harness.dart';

/// Runs around every test file in this package, so a demo lays out on every
/// run as it does on a device: real fonts, no network, and a caret that does
/// not blink.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    runWithCatalogHarness(testMain);
