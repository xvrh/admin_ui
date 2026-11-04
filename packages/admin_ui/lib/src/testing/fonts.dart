import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../theme/themes.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The family the test platform's Material typography names for its text,
/// Roboto: `flutter test` runs as Android. [withTestFontFallback] gives it to
/// a theme that names no font (Ant), and [loadAdminFonts] registers it.
const testPlatformFamily = 'Roboto';

final _families = <String>{};

/// The families [loadAdminFonts] and [loadTestFontFamily] registered.
/// [textWithoutFont] counts text in any of them as drawn.
Set<String> get testFontFamilies => UnmodifiableSetView(_families);

/// Registers [fonts], one file per weight and style, as [family], and adds it
/// to [testFontFamilies]. For a family of the app's own, a script fallback
/// say, that [loadAdminFonts] does not know.
Future<void> loadTestFontFamily(
  String family,
  Iterable<Future<ByteData>> fonts,
) async {
  final loader = FontLoader(family);
  fonts.forEach(loader.addFont);
  await loader.load();
  _families.add(family);
}

/// Loads every font the kit's themes draw with, so a widget test measures
/// and draws text in its real face rather than the test font's em-wide
/// boxes.
///
/// Call it once per test file from `flutter_test_config.dart`, after
/// `TestWidgetsFlutterBinding.ensureInitialized()` and before anything
/// builds a theme's tokens: a font file loads in real time, which a
/// `testWidgets` body never waits for.
///
/// - The families the asset bundle's `FontManifest.json` declares (the
///   app's `fonts:`, `MaterialIcons`), unless [fontManifest] is false.
/// - With a [fontDirectory] (relative to the working directory, the
///   package's root under `flutter test`), the family of each file there,
///   named as `Inter-Regular.ttf` or `IBMPlexSans-SemiBold.ttf` are: the
///   family without spaces, a hyphen, the style. For a package whose tests
///   bundle no fonts.
/// - [standIns]: each family, keyed, registered from the files of the face
///   it names. By default Roboto, under [testPlatformFamily], the family the
///   Material text theme names, which a theme that names no font (Ant) draws
///   in; and under faces that cannot be redistributed: Fluent's `Segoe UI`,
///   and `Georgia`. A test of layout and colour under those needs a face of
///   the right size, not the missing one's glyphs.
///
/// Every family the light and dark tokens of [themes] (by default
/// [adminThemes]) name must come from one of those, or this fails naming
/// the theme and the family to bundle.
///
/// The kit ships no font file: bundle the ones your themes name, as the
/// README's "Fonts" says.
Future<void> loadAdminFonts({
  Iterable<AdminTheme>? themes,
  String? fontDirectory,
  Map<String, String> standIns = const {
    testPlatformFamily: 'Roboto',
    'Segoe UI': 'Roboto',
    'Georgia': 'Roboto',
  },
  bool fontManifest = true,
}) async {
  final faces = <String, List<Future<ByteData> Function()>>{};
  if (fontManifest) {
    for (final (family, assets) in await _manifestFamilies()) {
      faces[family] = [
        for (final asset in assets) () => rootBundle.load(asset),
      ];
    }
  }
  final files = fontDirectory == null
      ? const <String, List<File>>{}
      : _directoryFaces(fontDirectory);
  final where = [
    if (fontManifest) 'the FontManifest',
    ?fontDirectory,
  ].join(' or ');

  List<Future<ByteData> Function()>? faceOf(String family) =>
      faces[family] ??
      [
        for (final file in files[family.replaceAll(' ', '')] ?? <File>[])
          () async => ByteData.sublistView(await file.readAsBytes()),
      ].nullIfEmpty;

  final wanted = <String, List<Future<ByteData> Function()>>{};
  for (final theme in themes ?? adminThemes) {
    for (final (mode, tokens) in [
      ('light', theme.tokens),
      if (theme.dark case final dark?) ('dark', dark),
    ]) {
      final family = tokens.typography.spec.fontFamily;
      if (family == null || wanted.containsKey(family)) continue;
      if (standIns.containsKey(family)) continue;
      wanted[family] =
          faceOf(family) ??
          (throw StateError(
            'loadAdminFonts: the ${theme.name} $mode theme draws in $family, '
            'and no font of that family is in $where. Bundle it under '
            '`flutter: fonts:` in pubspec.yaml, or leave the theme out of '
            'themes.',
          ));
    }
  }
  for (final MapEntry(key: family, value: face) in standIns.entries) {
    wanted[family] =
        faceOf(face) ??
        (throw StateError(
          'loadAdminFonts: no $face font in $where to stand in for $family.',
        ));
  }
  for (final MapEntry(key: family, value: loads) in faces.entries) {
    wanted.putIfAbsent(family, () => loads);
  }
  for (final MapEntry(key: family, value: loads) in wanted.entries) {
    await loadTestFontFamily(family, [for (final load in loads) load()]);
  }
}

/// [tokens] with their typography rebuilt for the test engine, which draws a
/// glyph the named families lack as a box where a device would find a
/// system font:
///
/// - a theme that names no font (Ant) is given [testPlatformFamily]. On a
///   device its text draws in the platform's font, whether it inherits the
///   family the Material text theme names or has none at all (a tooltip's,
///   which replaces the ambient style); the test engine draws text with no
///   family in boxes, and measures it by them too;
/// - [fallback] goes after the spec's own fallback: the families that hold
///   symbols or scripts the theme's font lacks (Arabic, say), registered
///   with [loadTestFontFamily].
///
/// The typography is rebuilt from its spec by `AdminTypography.from`, so a
/// typography built by hand loses its own styles.
AdminTokens withTestFontFallback(
  AdminTokens tokens, {
  List<String> fallback = const [],
}) {
  final spec = tokens.typography.spec;
  return tokens.copyWith(
    typography: AdminTypography.from(
      tokens.palette,
      spec.copyWith(
        fontFamily: spec.fontFamily == null ? testPlatformFamily : null,
        fontFamilyFallback: fallback.isEmpty
            ? null
            : [...?spec.fontFamilyFallback, ...fallback],
      ),
    ),
  );
}

/// The text on screen the test engine draws in its box font, each run
/// described as `"text" in families`: empty when every run is in a loaded
/// face. Glyphs a loaded family lacks are not caught here.
///
/// A run's families are resolved as the engine resolves them: a span whose
/// style names a family or a fallback replaces its parent's list with
/// `[family, ...fallback]`, where no family is the default one; any other
/// span keeps its parent's. The first family of the list the engine finds
/// draws the run: one of [testFontFamilies] is a real face, while the
/// default family, or none found at all, is the box font.
List<String> textWithoutFont() {
  final found = <String>[];
  void visit(InlineSpan span, List<String?> families) {
    final style = span.style;
    if (style != null &&
        (style.fontFamily != null ||
            (style.fontFamilyFallback?.isNotEmpty ?? false))) {
      families = [style.fontFamily, ...?style.fontFamilyFallback];
    }
    if (span is! TextSpan) return;
    final text = span.text?.trim() ?? '';
    if (text.isNotEmpty && !_drawnInLoadedFont(families)) {
      final shown = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      final named = families.map((family) => family ?? 'the default family');
      found.add('"$shown" in ${named.join(', ')}');
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      visit(child, families);
    }
  }

  void walk(RenderObject render) {
    switch (render) {
      case RenderParagraph(:final text):
      case RenderEditable(text: final text?):
        visit(text, const [null]);
    }
    render.visitChildren(walk);
  }

  RendererBinding.instance.renderViews.forEach(walk);
  return found;
}

/// Whether text in [families] is drawn in a font the tests loaded: the
/// engine skips a family it does not know and stops at the first it does,
/// and the default family (null) is the box font.
bool _drawnInLoadedFont(List<String?> families) {
  for (final family in families) {
    if (family == null) return false;
    if (_families.contains(family)) return true;
  }
  return false;
}

/// The families of the asset bundle's `FontManifest.json`, each with its
/// assets; none when the bundle has no manifest.
Future<List<(String, List<String>)>> _manifestFamilies() async {
  final String source;
  try {
    source = await rootBundle.loadString('FontManifest.json');
  } on FlutterError {
    return const [];
  }
  return [
    for (final family in (json.decode(source) as List).cast<Map>())
      (
        family['family'] as String,
        [
          for (final font in (family['fonts'] as List).cast<Map>())
            font['asset'] as String,
        ],
      ),
  ];
}

/// The font files in [path], by the family their name starts with
/// (`IBMPlexSans` for `IBMPlexSans-SemiBold.ttf`).
Map<String, List<File>> _directoryFaces(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) {
    throw StateError(
      'loadAdminFonts: no font directory at ${directory.absolute.path}',
    );
  }
  final faces = <String, List<File>>{};
  for (final file in directory.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
    final dash = name.indexOf('-');
    if (dash < 1) continue;
    faces.putIfAbsent(name.substring(0, dash), () => []).add(file);
  }
  for (final files in faces.values) {
    files.sort((a, b) => a.path.compareTo(b.path));
  }
  return faces;
}

extension<T> on List<T> {
  List<T>? get nullIfEmpty => isEmpty ? null : this;
}
