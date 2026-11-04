import 'dart:async';

import 'package:flutterware/flutter_test.dart';

import '../../../support/fonts.dart';
import '../../../support/profiles.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await prepareScenarioFonts();
  return runScenarios(testMain, profile: phoneStory, settle: Settle.strict);
}
