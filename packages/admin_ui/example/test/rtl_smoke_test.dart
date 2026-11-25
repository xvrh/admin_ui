import 'package:material_ui/material_ui.dart';

import 'support/harness/harness.dart';
import 'sweeps/sweep.dart';

/// Entries this test does not pump, by id, each with the reason and the line
/// a fix starts from.
const _skipped = <String, String>{};

/// Every demo mirrored in Arabic, and in French and German, whose strings
/// run longest, Polish, whose plurals have the most forms, and Japanese,
/// written without spaces: none may throw or overflow.
void main() {
  final iris = RenderConfig.of('Iris', ThemeMode.light);
  sweep(
    passes: (_) => {
      'ar, RTL': iris.copyWith(
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
      ),
      'fr': iris.copyWith(locale: const Locale('fr')),
      'de': iris.copyWith(locale: const Locale('de')),
      'pl': iris.copyWith(locale: const Locale('pl')),
      'ja': iris.copyWith(locale: const Locale('ja')),
    },
    skipped: _skipped,
  );
}
