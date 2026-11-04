// Generates admin_ui's layered public barrels with explicit `show` lists, and
// api.txt, the golden list of what they export.
//
//   fvm dart run tool/gen_barrels.dart           # write barrels and api.txt
//   fvm dart run tool/gen_barrels.dart --check    # fail if out of date
//
// Each leaf source file is exported with an explicit `show` of its public
// top-level symbols (extracted via the analyzer), so the public API surface is
// fully controlled. A declaration annotated `@internal` or `@visibleForTesting`
// stays out of it, and so does any symbol listed in [hide]. Files that
// themselves re-export (`export '...'`) are passed through, their own
// combinators trusted, with a `hide` of whatever of theirs those two rules
// leave out.
//
// api.txt lists every symbol each barrel exports, re-exported files expanded,
// so a change to the public surface shows up in review.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';

final _formatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

class ExportLine {
  final String uri;
  final List<String>? show; // null => export everything (no combinator)
  final List<String> hide; // only without [show]: a pass-through's leftovers
  ExportLine(this.uri, this.show, [this.hide = const []]);
}

class BarrelData {
  final String doc;
  final List<ExportLine> lines;

  /// What the barrel exports, by name: whether it is deprecated. For an
  /// umbrella, the barrels it re-exports.
  final Map<String, bool> symbols;

  /// Whether a combinator names a deprecated symbol, which the analyzer
  /// counts as a use of it.
  final bool namesDeprecated;

  BarrelData(
    this.doc,
    this.lines, {
    this.symbols = const {},
    this.namesDeprecated = false,
  });
}

/// A curated barrel built from leaf sources (paths relative to `lib/src`).
/// A source ending in `.dart` is a single file; otherwise it is a directory
/// scanned non-recursively for `*.dart`.
class BarrelDef {
  final String out;
  final String doc;
  final List<String> sources;
  final Set<String> exclude; // basenames skipped within scanned dirs
  const BarrelDef(this.out, this.doc, this.sources, {this.exclude = const {}});
}

const curated = <BarrelDef>[
  BarrelDef(
    'theme.dart',
    'Admin design tokens — palette, spacing, typography, theming.',
    ['theme'],
  ),
  BarrelDef(
    'widgets.dart',
    'Pure presentational primitives — Flutter-only, no app state.',
    [
      'common/ui',
      'common/fuzzy.dart',
      'common/motion.dart',
      'common/text_metrics.dart',
    ],
    exclude: {'control_label.dart'},
  ),
  BarrelDef(
    'fields.dart',
    'Field bodies — pure views over a typed `Cell` — and the language lanes.',
    ['fields/ui', 'i18n'],
  ),
  BarrelDef('shell.dart', 'App scaffolding — sidebar, top bar, page headers.', [
    'shell/ui',
  ]),
  BarrelDef(
    'auth.dart',
    'Pure auth form views — slot-based SSO, no transport.',
    ['auth/ui'],
  ),
  BarrelDef(
    'history.dart',
    'Revision/diff views — block, text and version-timeline.',
    ['history', 'history/ui'],
  ),
  BarrelDef(
    'collection.dart',
    'Collection/table layer — data model, controllers and views.',
    ['collection', 'collection/ui'],
    exclude: {'view_support.dart'},
  ),
  BarrelDef(
    'forms.dart',
    'Form layer — cells, binder, field presets, dirty tracking, save bar.',
    ['forms'],
    exclude: {'record_list_cell.dart', 'relayed_scopes.dart'},
  ),
  BarrelDef(
    'assets.dart',
    'Media/asset feature — library picker, image cropper, source capability.',
    ['assets', 'assets/ui'],
  ),
  BarrelDef(
    'comments.dart',
    'Comments capability — field anchors, mentions and their field, and the field button.',
    ['comments', 'comments/ui'],
  ),
  BarrelDef(
    'l10n.dart',
    'Localisation: AdminLocalizations, its delegate and locale formatters.',
    ['l10n', 'l10n/sections'],
  ),
  // Neither umbrella re-exports it: it depends on flutter_test.
  BarrelDef(
    'testing.dart',
    'Test support for apps on the kit: real fonts in widget tests, and a '
        'check for text drawn in none. It depends on flutter_test, so import '
        'it from tests only; neither admin_ui.dart nor ui.dart exports it.',
    ['testing'],
  ),
];

/// Umbrella barrels re-export sibling barrels (paths relative to `lib`).
const umbrellas = <BarrelDef>[
  BarrelDef(
    'ui.dart',
    'The design system without the data layer — theme, primitives, shell, '
        'auth, history and localisation; no fields, forms or app state.',
    [
      'theme.dart',
      'widgets.dart',
      'shell.dart',
      'auth.dart',
      'history.dart',
      'l10n.dart',
    ],
  ),
  BarrelDef(
    'admin_ui.dart',
    'The whole admin UI kit — ui.dart plus fields, collections, forms, assets '
        'and comments.',
    [
      'ui.dart',
      'fields.dart',
      'collection.dart',
      'forms.dart',
      'assets.dart',
      'comments.dart',
    ],
  ),
];

/// Symbols to omit from the public surface, keyed by source uri: helpers the
/// widgets are built from, which only the package's own tests call (they
/// import `src/` directly). A stale entry fails the build.
const hide = <String, Set<String>>{
  'src/assets/ui/image_cropper.dart': {
    'CropHandleX',
    'cropClampFocal',
    'cropFlip',
    'cropHitTest',
    'cropMove',
    'cropNudge',
    'cropResize',
    'cropRotate',
    'cropToNorm',
    'cropToPixels',
    'cropZoom',
    'framedImageRect',
    'straightenCoverScale',
  },
  'src/collection/saved_view.dart': {'savedViewSchemaVersion'},
  'src/collection/ui/filter_bar.dart': {'fmtDate'},
  'src/common/ui/chart.dart': {'chartSeriesColors'},
  'src/common/ui/json_view.dart': {
    'JsonNode',
    'JsonNodeKind',
    'JsonRow',
    'JsonSearchResult',
    'buildJsonTree',
    'flattenJson',
    'jsonSearch',
  },
  'src/common/ui/tree.dart': {
    'excludeSubtree',
    'flattenTree',
    'projectTreeDrop',
  },
  'src/common/ui/upload.dart': {'formatBytes'},
  'src/fields/ui/code_body.dart': {
    'JsonToken',
    'autoEditOnChange',
    'codeIndent',
    'tokenizeJson',
    'validateJson',
  },
  'src/fields/ui/color_body.dart': {'normalizeHex', 'parseHexColor'},
  'src/fields/ui/date_body.dart': {'DateMaskFormatter'},
};

/// Annotations that keep a declaration out of the barrels.
const _unexported = {'internal', 'visibleForTesting'};

Map<String, BarrelData> buildBarrels(String packageRoot) {
  final out = <String, BarrelData>{};
  final libDir = Directory('$packageRoot/lib');
  final exports = <String, Map<String, SymbolInfo>>{};
  final unhidden = {
    for (final e in hide.entries) e.key: {...e.value},
  };

  for (final def in curated) {
    final lines = <ExportLine>[];
    final symbols = <String, bool>{};
    var namesDeprecated = false;
    for (final source in def.sources) {
      final files = _resolveSources(libDir, 'src/$source', def.exclude);
      for (final uri in files) {
        final path = '${libDir.path}/$uri';
        final hidden = hide[uri] ?? const <String>{};
        final exported = exportsOf(path, exports);
        unhidden[uri]?.removeAll(exported.keys);
        final ExportLine line;
        if (_hasExport(_parse(path))) {
          final left = [
            for (final MapEntry(:key, :value) in exported.entries)
              if (value.internal || hidden.contains(key)) key,
          ]..sort();
          line = ExportLine(uri, null, left);
        } else {
          final shown = [
            for (final MapEntry(:key, :value) in exported.entries)
              if (!value.internal && !hidden.contains(key)) key,
          ]..sort();
          // A file of internal helpers only exports nothing.
          if (shown.isEmpty) continue;
          line = ExportLine(uri, shown);
        }
        lines.add(line);
        for (final MapEntry(:key, :value) in exported.entries) {
          if (line.show?.contains(key) ?? !line.hide.contains(key)) {
            symbols[key] = value.deprecated;
          }
        }
        namesDeprecated |= [
          ...?line.show,
          ...line.hide,
        ].any((name) => exported[name]!.deprecated);
      }
    }
    // Sorted by uri so the output is stable under tool/format.dart's
    // directive ordering.
    lines.sort((a, b) => a.uri.compareTo(b.uri));
    out[def.out] = BarrelData(
      def.doc,
      lines,
      symbols: symbols,
      namesDeprecated: namesDeprecated,
    );
  }

  final stale = [
    for (final MapEntry(:key, :value) in unhidden.entries)
      for (final name in value) '$key: $name',
  ];
  if (stale.isNotEmpty) {
    throw StateError(
      '`hide` names symbols no barrel exports; update it:\n'
      '  ${stale.join('\n  ')}',
    );
  }

  for (final def in umbrellas) {
    final lines = [for (final u in def.sources) ExportLine(u, null)]
      ..sort((a, b) => a.uri.compareTo(b.uri));
    out[def.out] = BarrelData(
      def.doc,
      lines,
      symbols: {for (final u in def.sources) u: false},
    );
  }

  return out;
}

List<String> _resolveSources(
  Directory libDir,
  String rel,
  Set<String> exclude,
) {
  if (rel.endsWith('.dart')) return [rel];
  final dir = Directory('${libDir.path}/$rel');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.dart') && !exclude.contains(n))
          .map((n) => '$rel/$n')
          .toList()
        ..sort();
  return files;
}

CompilationUnit _parse(String path) => parseFile(
  path: path,
  featureSet: FeatureSet.latestLanguageVersion(),
  throwIfDiagnostics: false,
).unit;

bool _hasExport(CompilationUnit unit) =>
    unit.directives.any((d) => d is ExportDirective);

/// A public top-level declaration: whether it is `@Deprecated`, and whether
/// it is annotated to stay out of the barrels.
typedef SymbolInfo = ({bool deprecated, bool internal});

Map<String, SymbolInfo> _publicSymbols(CompilationUnit unit) {
  final out = <String, SymbolInfo>{};
  void add(String? n, Declaration d) {
    if (n == null || n.startsWith('_')) return;
    final names = {for (final a in d.metadata) a.name.name.split('.').last};
    out[n] = (
      deprecated: names.contains('Deprecated') || names.contains('deprecated'),
      internal: names.any(_unexported.contains),
    );
  }

  for (final d in unit.declarations) {
    switch (d) {
      case ClassDeclaration() || EnumDeclaration():
        // analyzer 13 holds the class/enum name in `namePart`.
        add((d as dynamic).namePart.beginToken.lexeme as String, d);
      case MixinDeclaration():
        add(d.name.lexeme, d);
      case ExtensionDeclaration():
        add(d.name?.lexeme, d);
      case FunctionDeclaration():
        add(d.name.lexeme, d);
      case TypeAlias():
        add(d.name.lexeme, d);
      case TopLevelVariableDeclaration():
        for (final v in d.variables.variables) {
          add(v.name.lexeme, d);
        }
    }
  }
  return out;
}

/// Everything the file at [path] exports: its own public declarations plus
/// what its `export` directives pass on, through their combinators. [memo]
/// caches the answer per file across calls.
Map<String, SymbolInfo> exportsOf(
  String path, [
  Map<String, Map<String, SymbolInfo>>? memo,
]) {
  memo ??= {};
  if (memo[path] case final hit?) return hit;
  final unit = _parse(path);
  final out = _publicSymbols(unit);
  for (final d in unit.directives.whereType<ExportDirective>()) {
    final uri = d.uri.stringValue!;
    if (uri.contains(':')) {
      throw UnsupportedError('$path re-exports $uri; only relative exports');
    }
    final target = File(path).parent.uri.resolve(uri).toFilePath();
    var names = exportsOf(target, memo);
    for (final c in d.combinators) {
      final show = c is ShowCombinator;
      final listed = {
        if (c is ShowCombinator) ...c.shownNames.map((n) => n.name),
        if (c is HideCombinator) ...c.hiddenNames.map((n) => n.name),
      };
      names = {
        for (final MapEntry(:key, :value) in names.entries)
          if (listed.contains(key) == show) key: value,
      };
    }
    out.addAll(names);
  }
  return memo[path] = out;
}

/// Parses an on-disk barrel into its export lines (for the check/test path).
List<ExportLine> readBarrelFile(String path) => readBarrelExports(_parse(path));

/// Parses the export directives of an existing barrel for the check/test path.
List<ExportLine> readBarrelExports(CompilationUnit unit) {
  final out = <ExportLine>[];
  for (final d in unit.directives) {
    if (d is! ExportDirective) continue;
    List<String>? show;
    var hidden = <String>[];
    for (final c in d.combinators) {
      if (c is ShowCombinator) {
        show = c.shownNames.map((n) => n.name).toList()..sort();
      } else if (c is HideCombinator) {
        hidden = c.hiddenNames.map((n) => n.name).toList()..sort();
      }
    }
    out.add(ExportLine(d.uri.stringValue!, show, hidden));
  }
  return out;
}

/// Normalizes a barrel's exports to `{uri: 'A,B,C' | '*' | '*-A,B'}` for
/// comparison.
Map<String, String> normalize(List<ExportLine> lines) => {
  for (final l in lines)
    l.uri: switch (l.show) {
      final show? => (show.toList()..sort()).join(','),
      null when l.hide.isEmpty => '*',
      null => '*-${(l.hide.toList()..sort()).join(',')}',
    },
};

String render(String name, BarrelData data) {
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/gen_barrels.dart — do not edit by hand.')
    ..writeln('// Run `fvm dart run tool/gen_barrels.dart` to refresh.')
    ..writeln('//');
  if (data.namesDeprecated) {
    b
      ..writeln('// Deprecated aliases stay exported until they are removed.')
      ..writeln('// ignore_for_file: deprecated_member_use_from_same_package')
      ..writeln('//');
  }
  for (final line in _wrap(data.doc, 80 - '/// '.length)) {
    b.writeln('/// $line');
  }
  b
    ..writeln('library;')
    ..writeln();
  // Laid out the way tool/format.dart leaves it, which drops blank lines
  // between directives, so regenerating needs no reformatting.
  String? group;
  for (final l in data.lines) {
    final g = l.uri.contains('/')
        ? l.uri.substring(0, l.uri.lastIndexOf('/'))
        : null;
    if (g != group && g != null) {
      b.writeln('// $g');
      if (group == null) b.writeln();
      group = g;
    }
    b.write("export '${l.uri}'");
    if (l.show case final show?) b.write(' show ${show.join(', ')}');
    if (l.hide.isNotEmpty) b.write(' hide ${l.hide.join(', ')}');
    b.writeln(';');
  }
  return b.toString();
}

/// [text] broken into lines of at most [width] characters, between words.
List<String> _wrap(String text, int width) {
  final lines = <String>[];
  var line = '';
  for (final word in text.split(' ')) {
    if (line.isNotEmpty && line.length + 1 + word.length > width) {
      lines.add(line);
      line = word;
    } else {
      line = line.isEmpty ? word : '$line $word';
    }
  }
  return lines..add(line);
}

/// api.txt: one line per barrel and exported symbol, sorted.
String renderApi(Map<String, BarrelData> barrels) {
  final umbrellaNames = {for (final u in umbrellas) u.out};
  final lines = [
    for (final MapEntry(key: barrel, value: data) in barrels.entries)
      for (final MapEntry(key: symbol, value: deprecated)
          in data.symbols.entries)
        umbrellaNames.contains(barrel)
            ? '$barrel re-exports $symbol'
            : '$barrel $symbol${deprecated ? ' (deprecated)' : ''}',
  ]..sort();
  return [
    '# GENERATED by tool/gen_barrels.dart — do not edit by hand.',
    '# The public API of package:admin_ui: one line per barrel and exported',
    '# symbol. ui.dart and admin_ui.dart re-export whole barrels.',
    ...lines,
    '',
  ].join('\n');
}

void main(List<String> args) {
  final check = args.contains('--check');
  final root = Directory.current.path;
  final data = buildBarrels(root);
  final apiFile = File('$root/api.txt');
  final api = renderApi(data);
  var stale = false;

  data.forEach((name, barrel) {
    final file = File('$root/lib/$name');
    final expected = normalize(barrel.lines);
    if (check) {
      final actual = file.existsSync()
          ? normalize(readBarrelFile(file.path))
          : <String, String>{};
      if (actual.toString() != expected.toString()) {
        stale = true;
        stdout.writeln('STALE: $name');
      }
    } else {
      file.writeAsStringSync(_formatter.format(render(name, barrel)));
      stdout.writeln('wrote lib/$name (${barrel.lines.length} exports)');
    }
  });

  if (check) {
    if (!apiFile.existsSync() || apiFile.readAsStringSync() != api) {
      stale = true;
      stdout.writeln('STALE: api.txt');
    }
  } else {
    apiFile.writeAsStringSync(api);
    stdout.writeln('wrote api.txt');
  }

  if (check && stale) {
    stderr.writeln(
      'Barrels are out of date. Run: '
      'fvm dart run tool/gen_barrels.dart',
    );
    exit(1);
  }
}
