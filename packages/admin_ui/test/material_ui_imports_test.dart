import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Material comes from material_ui across the kit', () {
    // package:flutter/material.dart is a second copy of Material, not an
    // alias: a Theme or MaterialLocalizations it provides is invisible to a
    // lookup through material_ui, so a stray import compiles and then renders
    // with the wrong theme. The kit's sources, tests and tools are scanned,
    // its example's too.
    final legacyImport = RegExp(
      r"^\s*(import|export)\s+'package:flutter/(material|cupertino)\.dart'",
      multiLine: true,
    );
    final offenders = <String>[];
    for (final entity in Directory.current.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.substring(Directory.current.path.length + 1);
      final parts = path.split(Platform.pathSeparator);
      if (parts.contains('build') ||
          parts.contains('.dart_tool') ||
          parts.contains('ephemeral')) {
        continue;
      }
      if (legacyImport.hasMatch(entity.readAsStringSync())) {
        offenders.add(path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'import package:material_ui/material_ui.dart (or cupertino_ui) '
          'instead:\n  ${offenders.join('\n  ')}',
    );
  });
}
