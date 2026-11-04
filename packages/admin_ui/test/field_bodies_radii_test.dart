import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Field parts take their corners from the theme's radius roles
/// (`context.radii.radiusField`, `radius`, `radiusSmall`, `radiusCheck`,
/// `radiusPill`), so Carbon stays square and Material rounds: a literal
/// corner looks right in one theme only.
void main() {
  test('field parts use radius roles, not literal corners', () {
    final literal = RegExp(r'BorderRadius\.circular\(\s*-?[0-9]');
    final files = [
      ...Directory('lib/src/fields')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('lib/src/common/ui/checkbox.dart'),
      File('lib/src/common/ui/field_presence.dart'),
    ];
    expect(files.length, greaterThan(10), reason: 'run from the package root');

    final hits = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) {
          hits.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  // A body that builds its own outline from `fieldBorderSide` draws an
  // outlined box in a filled or underlined theme. Every box comes from the
  // theme's anatomy instead: `FieldChrome`, `fieldInputDecoration`,
  // `FieldBorder`, or `fieldDecoration` over `resolveFieldChrome`.
  test('field bodies draw the theme\'s anatomy, not an edge of their own', () {
    final handDrawn = RegExp(
      r'\bfieldBorderSide\(|\bFieldOutlineBorder\(|\bfieldFocusHalo\('
      r'|\.(borderSide|borderColor|focusHalo)\(',
    );
    final files = [
      ...Directory('lib/src/fields')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      for (final name in [
        'combobox',
        'input_decoration',
        'input_field',
        'password_field',
        'search_field',
      ])
        File('lib/src/common/ui/$name.dart'),
    ];
    final hits = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (handDrawn.hasMatch(lines[i])) {
          hits.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
