import 'dart:io';

import 'package:admin_ui/testing.dart';
import 'package:flutter/services.dart';

export 'package:admin_ui/testing.dart';

/// Loads every font the catalog renders with, so text is measured and drawn
/// in its real face rather than the test font's em-wide boxes: what the
/// kit's [loadAdminFonts] loads, from the files this package bundles under
/// `assets/fonts/`, plus the catalog's test-only faces.
///
/// `flutter_test_config.dart` runs it once per test file, outside fake async:
/// a font file loads in real time, which a `testWidgets` body never waits for.
/// Paths are relative to this package's root, where `flutter test` runs.
///
/// * Through [loadAdminFonts]: the fonts the test FontManifest lists
///   (`MaterialIcons`); Roboto under [testPlatformFamily], which
///   [withTestFontFallback] gives a theme that names no font (Ant), and
///   under Fluent's `Segoe UI` and `Georgia`, which cannot be
///   redistributed; and every family a theme's tokens name, failing on one
///   with no file.
/// * Roboto Mono under `monospace`, from `test/fonts/`.
/// * `Noto Naskh Arabic`, for Arabic, which none of the theme fonts covers,
///   and Inter's files as a symbols face for the arrows and key glyphs
///   (`→`, `⌘`, `✓`) Roboto lacks. The test engine does not fall back to
///   other fonts, so a style reaches them only by naming them:
///   [catalogFontFallback] lists them for [withTestFontFallback].
Future<void> loadTestFonts() async {
  await loadAdminFonts(fontDirectory: 'assets/fonts/');
  await loadTestFontFamily('monospace', [
    _file('test/fonts/RobotoMono-Regular.ttf'),
    _file('test/fonts/RobotoMono-Bold.ttf'),
  ]);
  await loadTestFontFamily(_arabic, [
    _file('test/fonts/NotoNaskhArabic-Regular.ttf'),
  ]);
  await loadTestFontFamily(_symbols, [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      _file('assets/fonts/Inter-$weight.ttf'),
    _file('assets/fonts/Inter-Italic.ttf'),
  ]);
}

/// The families the catalog's tests fall back to, after a theme's own, for
/// what its font lacks: symbols, then Arabic. Hand them to
/// [withTestFontFallback].
const catalogFontFallback = [_symbols, _arabic];

const _arabic = 'Noto Naskh Arabic';

/// Inter's files under their own family name, so no theme that names Inter
/// resolves to them by accident.
const _symbols = 'Test symbols';

Future<ByteData> _file(String path) async {
  final bytes = await File(path).readAsBytes().catchError(
    (Object error) =>
        throw StateError('loadTestFonts: cannot read $path ($error)'),
  );
  return ByteData.sublistView(bytes);
}
