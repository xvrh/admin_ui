import 'dart:async';

import 'support/fonts.dart';

/// The unit tests and the layout sweep: real fonts for every theme, then the
/// tests. The scenario folders have configs of their own.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await prepareTestFonts();
  await testMain();
}
