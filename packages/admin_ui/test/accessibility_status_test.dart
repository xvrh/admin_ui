import 'dart:io';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/gen_accessibility.dart' as gen;

/// Roles a widget of the kit carries without naming them: Material's
/// progress indicator, inside `ProgressBar`.
const _inherited = {'progressBar'};

Map<String, String> _sources(String root) => {
  for (final file
      in Directory('$root/lib/src')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')))
    file.path.substring('$root/lib/src'.length + 1): file.readAsStringSync(),
};

/// The roles ACCESSIBILITY.md lists as left out: the names in code at the
/// head of each item under "Roles left out".
Set<String> _leftOut(String document) {
  final section = document.split('## Roles left out').last.split('\n## ').first;
  return {
    for (final line in section.split('\n'))
      if (line.startsWith('- '))
        for (final name in RegExp(r'`(\w+)`').allMatches(line.split(':').first))
          name.group(1)!,
  };
}

void main() {
  final root = Directory.current.path;
  final document = File('$root/ACCESSIBILITY.md').readAsStringSync();

  test('ACCESSIBILITY.md is in sync with the package (run '
      'tool/gen_accessibility.dart)', () {
    expect(
      document,
      gen.render(root, document),
      reason:
          'ACCESSIBILITY.md is stale: fvm dart run '
          'tool/gen_accessibility.dart',
    );
  });

  test('every component of the table is public', () {
    final api = File('$root/api.txt').readAsStringSync();
    expect([
      for (final component in gen.components)
        if (!RegExp(' ${component.name}\$', multiLine: true).hasMatch(api))
          component.name,
    ], isEmpty);
  });

  test('a role is in use or left out with its reason, never both and never '
      'neither', () {
    final used = gen.rolesInUse(_sources(root)).keys.toSet();
    final leftOut = _leftOut(document);
    expect(used.intersection(leftOut), isEmpty);
    expect(_inherited.intersection(leftOut), isEmpty);
    // A role Flutter adds is given to a widget, or listed with why not. The
    // list may name roles newer than the Flutter the tests run on.
    expect([
      for (final role in SemanticsRole.values)
        if (role != SemanticsRole.none &&
            !used.contains(role.name) &&
            !leftOut.contains(role.name) &&
            !_inherited.contains(role.name))
          role.name,
    ], isEmpty);
  });

  test('every role in use is asserted by a test', () {
    final tests = [
      for (final file in Directory('$root/test').listSync().whereType<File>())
        if (file.path.endsWith('_test.dart')) file.readAsStringSync(),
    ];
    expect([
      for (final role in gen.rolesInUse(_sources(root)).keys)
        if (!tests.any((test) => test.contains('SemanticsRole.$role'))) role,
    ], isEmpty);
  });
}
