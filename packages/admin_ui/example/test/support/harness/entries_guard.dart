import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'entries.dart';

/// Registers the tests that keep a package's demo entries whole: the sweeps
/// pump every catalog page and every `@Preview` the catalog leaves out, and
/// these fail when a preview is in neither, so a new demo cannot go
/// untested unnoticed.
///
/// [catalog] is the package's catalog pages, whose source is the map literal
/// that follows [catalogStart] in [catalogFile], listing each demo as
/// `const X()`. [previewOnly] is the package's previews the catalog leaves
/// out, and [entries] all of its entries. The scan reads every file under
/// `lib/`, and must find at least [minPreviews], [knownPreview] among them.
void entriesGuard({
  required List<DemoEntry> Function() catalog,
  required List<PreviewOnlyDemo> previewOnly,
  required List<DemoEntry> Function() entries,
  required String catalogFile,
  required String catalogStart,
  required int minPreviews,
  required String knownPreview,
}) {
  late final previews = scanPreviews(Directory('lib'));
  late final constructors = catalogConstructors(
    File(catalogFile),
    catalogStart,
  );

  test('the scan finds the previews', () {
    expect(previews.length, greaterThanOrEqualTo(minPreviews));
    expect(previews, contains(knownPreview));
  });

  test('the catalog source matches the catalog', () {
    expect(
      [for (final c in constructors) c.split('.').first],
      [for (final e in catalog()) e.build().runtimeType.toString()],
      reason: '$catalogFile lists a demo other than as `const X()`',
    );
  });

  test('every @Preview is in the catalog or in previewOnly', () {
    final listed = {
      ...constructors,
      for (final p in previewOnly) p.constructor,
    };
    final missing = [
      for (final MapEntry(key: constructor, value: name) in previews.entries)
        if (!listed.contains(constructor)) "$constructor ('$name')",
    ];
    expect(
      missing,
      isEmpty,
      reason:
          'Add these to the catalog ($catalogFile) or to previewOnly '
          '(test/support/entries.dart)',
    );
  });

  test('previewOnly names live previews the catalog leaves out', () {
    for (final demo in previewOnly) {
      expect(
        previews[demo.constructor],
        demo.name,
        reason: '${demo.constructor} is not a preview named "${demo.name}"',
      );
      expect(
        constructors,
        isNot(contains(demo.constructor)),
        reason:
            '${demo.constructor} is in the catalog: drop it from previewOnly',
      );
      expect(
        demo.build().runtimeType.toString(),
        demo.constructor.split('.').first,
      );
    }
  });

  test('ids are unique', () {
    final all = entries();
    expect(all.map((e) => e.id).toSet(), hasLength(all.length));
  });
}

/// Every `@Preview` constructor under [lib], as `Class` or `Class.named`, to
/// the `name:` it gives.
Map<String, String> scanPreviews(Directory lib) {
  final annotated = RegExp(
    r"@Preview\(((?:[^()]|\([^()]*\))*)\)\s*const\s+(\w+(?:\.\w+)?)\(",
  );
  final name = RegExp(r"name:\s*'([^']*)'");
  final previews = <String, String>{};
  for (final file in lib.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    final source = file.readAsStringSync();
    final found = annotated.allMatches(source).toList();
    expect(
      found,
      hasLength(RegExp(r'@Preview\(').allMatches(source).length),
      reason: '${file.path}: a @Preview not followed by a const constructor',
    );
    for (final match in found) {
      previews[match[2]!] = name.firstMatch(match[1]!)?[1] ?? '';
    }
  }
  return previews;
}

/// The constructors the catalog literal after [start] in [file] calls, in
/// order, up to the literal's closing `};`.
List<String> catalogConstructors(File file, String start) {
  final source = file.readAsStringSync();
  final from = source.indexOf(start);
  if (from < 0) throw StateError('${file.path} has no "$start"');
  final end = source.indexOf('\n};', from);
  final body = source.substring(from, end < 0 ? source.length : end);
  return [
    for (final match in RegExp(r'const\s+(\w+(?:\.\w+)?)\(').allMatches(body))
      match[1]!,
  ];
}
