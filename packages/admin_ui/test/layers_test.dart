// The layer order of lib/src. Each top-level directory sits on a layer, and
// a file imports (or exports) only its own directory and the layers below
// it: never a higher layer, and never another directory on its own layer.
// The order keeps the generic building blocks free of what is built on
// them, so a lower layer can be used, tested and moved on its own.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each top-level directory of lib/src and its layer, bottom to top.
const layers = {
  'theme': 0,
  'l10n': 1,
  'common': 2,
  'i18n': 3,
  'shell': 4,
  'auth': 4,
  'history': 5,
  'comments': 5,
  'collection': 5,
  'fields': 6,
  'assets': 7,
  'forms': 8,
  'testing': 9,
};

/// Imports the order allows all the same, as `from -> to` under lib/src,
/// each with why. An entry no import needs any more fails, so the list only
/// shrinks.
const allowed = <String, String>{};

/// Why [from] may not import [to], both paths under lib/src; null when it
/// may.
String? ruleBroken(String from, String to) {
  final source = from.split('/').first;
  final target = to.split('/').first;
  if (source == target) return null;
  final (a, b) = (layers[source], layers[target]);
  if (a == null) return '$source/ has no layer in `layers`';
  if (b == null) return '$target/ has no layer in `layers`';
  if (b > a) {
    return 'upward: $source (layer $a) imports $target (layer $b)';
  }
  if (b == a) {
    return 'sibling: $source and $target share layer $a, and siblings never '
        'import each other';
  }
  return null;
}

/// One import or export in lib/src.
typedef Edge = ({String from, int line, String uri, String? to});

/// Every import and export of every file under lib/src, conditional ones
/// included. `to` is the target's path under lib/src, or null for another
/// package, a `dart:` library, or a public barrel of this one (which a
/// source file must not import: see the test).
List<Edge> edges() {
  final src = Directory('lib/src').absolute;
  final out = <Edge>[];
  final files =
      src
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final from = file.path.substring(src.path.length + 1);
    final unit = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
    ).unit;
    for (final directive in unit.directives.whereType<NamespaceDirective>()) {
      final line = unit.lineInfo.getLocation(directive.offset).lineNumber;
      for (final uri in [
        directive.uri.stringValue!,
        for (final c in directive.configurations) c.uri.stringValue!,
      ]) {
        out.add((from: from, line: line, uri: uri, to: _resolve(from, uri)));
      }
    }
  }
  return out;
}

String? _resolve(String from, String uri) {
  const self = 'package:admin_ui/src/';
  if (uri.startsWith(self)) return uri.substring(self.length);
  if (uri.contains(':')) return null;
  final base = Uri.parse('file:///src/$from');
  final path = base.resolve(uri).path;
  return path.startsWith('/src/') ? path.substring('/src/'.length) : path;
}

void main() {
  test('every directory of lib/src has a layer, and every layer a '
      'directory', () {
    final dirs = {
      for (final d in Directory('lib/src').listSync().whereType<Directory>())
        // A directory git left empty holds no layer.
        if (d.listSync(recursive: true).any((f) => f.path.endsWith('.dart')))
          d.uri.pathSegments.where((s) => s.isNotEmpty).last,
    };
    expect(
      dirs.difference(layers.keys.toSet()),
      isEmpty,
      reason: 'place each new directory of lib/src in `layers`',
    );
    expect(
      layers.keys.toSet().difference(dirs),
      isEmpty,
      reason: 'drop the layers whose directory is gone',
    );
    expect(
      Directory('lib/src').listSync().whereType<File>(),
      isEmpty,
      reason: 'every file of lib/src sits in a layer directory',
    );
  });

  test('no file imports a higher layer or a sibling', () {
    final broken = [
      for (final e in edges())
        if (e.uri.startsWith('package:admin_ui/') && e.to == null)
          '${e.from}:${e.line} imports ${e.uri}: a source file imports the '
              'file it needs, never a public barrel'
        else if (e.to case final to?
            when !allowed.containsKey('${e.from} -> $to'))
          if (ruleBroken(e.from, to) case final rule?)
            '${e.from}:${e.line} imports $to: $rule',
    ];
    expect(broken, isEmpty, reason: broken.join('\n'));
  });

  test('every allowed import is still there', () {
    final present = {
      for (final e in edges())
        if (e.to case final to?) '${e.from} -> $to',
    };
    final stale = [
      for (final edge in allowed.keys)
        if (!present.contains(edge)) edge,
    ];
    expect(stale, isEmpty, reason: 'drop these from `allowed`');
    for (final edge in allowed.keys) {
      final [from, to] = edge.split(' -> ');
      expect(
        ruleBroken(from, to),
        isNotNull,
        reason: '$edge breaks no rule: drop it from `allowed`',
      );
    }
  });

  test('the rules', () {
    expect(ruleBroken('forms/a.dart', 'fields/ui/b.dart'), isNull);
    expect(ruleBroken('fields/ui/a.dart', 'fields/ui/b.dart'), isNull);
    expect(ruleBroken('common/ui/a.dart', 'theme/tokens.dart'), isNull);
    expect(
      ruleBroken('common/ui/a.dart', 'fields/ui/b.dart'),
      'upward: common (layer 2) imports fields (layer 6)',
    );
    expect(
      ruleBroken('shell/ui/a.dart', 'auth/ui/b.dart'),
      startsWith('sibling'),
    );
    expect(
      ruleBroken('widgets/a.dart', 'theme/b.dart'),
      'widgets/ has no layer in `layers`',
    );
    expect(_resolve('fields/ui/a.dart', '../../i18n/b.dart'), 'i18n/b.dart');
    expect(
      _resolve('forms/a.dart', 'package:admin_ui/src/theme/b.dart'),
      'theme/b.dart',
    );
    expect(
      _resolve('forms/a.dart', 'package:collection/collection.dart'),
      isNull,
    );
  });
}
