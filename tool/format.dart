// The repository's formatter: `dart format`, imports sorted into one block
// each of imports, exports and parts (`dart:` and `package:` first), and a
// package's own imports under `lib/` made relative. CI checks with it, so
// format with it rather than bare `dart format`.
//
//   dart run tool/format.dart                  # format in place
//   dart run tool/format.dart --check          # no writes; exit 1 when dirty
//   dart run tool/format.dart lib/a.dart test/ # only these paths
//
// It formats the Dart files git tracks or would track: ignored ones (build
// output, .dart_tool) are left alone.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final _formatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

void main(List<String> args) {
  final check = args.contains('--check');
  final paths = [
    for (final arg in args)
      if (!arg.startsWith('--')) p.normalize(p.absolute(arg)),
  ];
  final root = _gitRoot();
  final changed = <String>[];
  for (final relative in _dartFiles(root)) {
    final path = p.join(root, relative);
    if (paths.isNotEmpty &&
        !paths.any((given) => path == given || p.isWithin(given, path))) {
      continue;
    }
    final file = File(path);
    final source = file.readAsStringSync();
    final formatted = formatSource(source, path);
    if (formatted == source) continue;
    changed.add(relative);
    if (!check) file.writeAsStringSync(formatted, flush: true);
  }
  if (changed.isEmpty) return;
  print(
    '${changed.length} file(s) ${check ? 'need formatting' : 'formatted'}:',
  );
  for (final file in changed) {
    print('  $file');
  }
  if (check) {
    print('Run `dart run tool/format.dart` and commit.');
    exit(1);
  }
}

/// [source], the file at [path], as this tool writes it.
String formatSource(String source, String path) {
  var out = source;
  final package = _packageOf(path);
  if (package != null && p.isWithin(p.join(package.directory, 'lib'), path)) {
    out = _relativeImports(out, path, package);
  }
  // A comment carried with a moved directive shifts the offsets of the next
  // pass, so sort to the fixpoint (two passes in practice).
  for (var i = 0; i < 5; i++) {
    final again = _sortDirectives(out);
    if (again == out) break;
    out = again;
  }
  return out;
}

String _gitRoot() {
  final result = Process.runSync('git', ['rev-parse', '--show-toplevel']);
  if (result.exitCode != 0) throw StateError('Not in a git repository');
  return (result.stdout as String).trim();
}

/// The Dart files git tracks, or would track, relative to [root].
List<String> _dartFiles(String root) {
  final result = Process.runSync('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    '*.dart',
  ], workingDirectory: root);
  if (result.exitCode != 0) throw StateError('git ls-files failed');
  return [
    for (final line in LineSplitter.split(result.stdout as String))
      if (line.isNotEmpty && File(p.join(root, line)).existsSync()) line,
  ]..sort();
}

typedef _Package = ({String name, String directory});

final _packages = <String, _Package?>{};

/// The package whose `pubspec.yaml` is nearest above [path].
_Package? _packageOf(String path) {
  final directory = p.dirname(path);
  return _packages.putIfAbsent(directory, () {
    final pubspec = File(p.join(directory, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final yaml = loadYaml(pubspec.readAsStringSync()) as YamlMap;
      return (name: yaml['name'] as String, directory: directory);
    }
    final parent = p.dirname(directory);
    return parent == directory ? null : _packageOf(directory);
  });
}

/// [source] with its imports of `package:<its package>/` made relative.
String _relativeImports(String source, String path, _Package package) {
  final unit = parseString(content: source, path: path).unit;
  final prefix = 'package:${package.name}/';
  final fromLib = p.relative(
    p.dirname(path),
    from: p.join(package.directory, 'lib'),
  );
  var out = source;
  for (final directive
      in unit.directives.reversed.whereType<NamespaceDirective>()) {
    final uri = directive.uri.stringValue!;
    if (!uri.startsWith(prefix)) continue;
    final relative = p.posix.relative(
      uri.substring(prefix.length),
      from: p.split(fromLib).join('/'),
    );
    out = out.replaceRange(
      directive.uri.offset,
      directive.uri.end,
      directive.uri.toSource().replaceAll(uri, relative),
    );
  }
  return out;
}

/// [source] with its imports, exports and parts each sorted into one block,
/// then formatted.
String _sortDirectives(String source) {
  final unit = parseString(content: source).unit;
  final directives = unit.directives.whereType<UriBasedDirective>().toList();
  if (directives.isEmpty) return _formatter.format(source);

  // Each directive owns the text from the end of the previous one to its own
  // end, so the comments above a directive move with it. The first owns its
  // metadata, and what is above it stays put.
  final first = directives.first;
  final start =
      (first.metadata.beginToken ?? first.firstTokenAfterCommentAndMetadata)
          .offset;
  final spans = <UriBasedDirective, String>{};
  var from = start;
  for (final directive in directives) {
    final text = directive.toSource();
    spans[directive] = source
        .substring(from, directive.end)
        .replaceAll(text, text.replaceAll('"', "'"));
    from = directive.end;
  }

  // A block keeps the line breaks before its first directive, so the blank
  // line above an export stays, and drops every blank line after it.
  String block(Iterable<UriBasedDirective> group) {
    final sorted = group.toList()..sort(_compare);
    final lines = LineSplitter.split(
      '${sorted.map((d) => spans[d]).join()}\n\n',
    );
    final kept = [
      for (final (i, line) in lines.indexed)
        if (i == 0 || line.trim().isNotEmpty) line,
    ];
    return '\n${kept.join('\n')}';
  }

  final sorted =
      block(directives.whereType<ImportDirective>()) +
      block(directives.whereType<ExportDirective>()) +
      block(directives.whereType<PartDirective>());
  return _formatter.format(
    source.substring(0, start) + sorted + source.substring(from),
  );
}

int _compare(UriBasedDirective a, UriBasedDirective b) {
  final x = a.uri.stringValue!;
  final y = b.uri.stringValue!;
  final xScheme = x.contains(':');
  final yScheme = y.contains(':');
  if (xScheme != yScheme) return xScheme ? -1 : 1;
  return x.compareTo(y);
}
