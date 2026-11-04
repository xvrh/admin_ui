import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widgets take their colours from the palette, not literals', () {
    // A literal colour ignores the theme: white text on a light dark-mode
    // primary, a grey that is right in one palette only, a black scrim token
    // nobody can override. Content on a fill uses the palette's on-colours
    // (onPrimary, onDanger, foregroundOn), dims use scrim / shadow, content
    // over photos uses onImage / imageScrim, and everything else a role.
    // Only lib/src/theme/, where those roles are defined, may name colours;
    // transparent is no colour, and is allowed anywhere.
    final literal = RegExp(
      r'\bColors\.(?!transparent\b)\w+|\bColor\(0x(?!00000000\))[0-9a-fA-F]+',
    );
    final offenders = <String, List<String>>{};
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/src/theme/')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (!literal.hasMatch(line) || _allowed(path, line)) continue;
        (offenders[path] ??= []).add('  ${i + 1}: ${line.trim()}');
      }
    }

    final files = offenders.keys.toList()..sort();
    final count = offenders.values.fold(0, (sum, sites) => sum + sites.length);
    final listing = [
      for (final file in files) ...[file, ...offenders[file]!],
    ].join('\n');
    expect(
      count,
      0,
      reason:
          'use a palette role (onPrimary, onDanger, foregroundOn, scrim, '
          'shadow, onImage, imageScrim, …) instead of a colour literal: '
          '$count sites in ${files.length} files:\n$listing',
    );
  });
}

/// The literals that are not theme colours.
bool _allowed(String path, String line) {
  // The tab strip's edge fade is a ShaderMask: only the gradient's alpha is
  // read, so white here means "opaque", not a colour.
  if (path.endsWith('common/ui/tabs.dart')) {
    return RegExp(r'^\s*(_fade\w+ \? Colors\.transparent : )?Colors\.white,$')
        .hasMatch(line);
  }
  // A hex value the user typed, made opaque: data, not a theme colour.
  if (path.endsWith('fields/ui/color_body.dart')) {
    return line.trim() == 'return Color(0xFF000000 | v);';
  }
  return false;
}
