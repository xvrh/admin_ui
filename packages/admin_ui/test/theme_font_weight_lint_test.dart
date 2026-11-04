import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widgets change a weight through context.type.weighted', () {
    // A Google font (Inter, Roboto, IBM Plex) registers each weight as a
    // family of its own. A style copied or merged with a new fontWeight keeps
    // the old weight's family, so it draws that face bolded synthetically, or
    // unchanged, instead of loading the real semibold or bold file.
    // `context.type.weighted(style, weight)` re-applies the theme font for the
    // new weight. Only lib/src/theme/, which builds the type ramp, may set one.
    final weight = RegExp(r'\bfontWeight:');
    final offenders = <String, List<String>>{};
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/src/theme/')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (!weight.hasMatch(line)) continue;
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
          'use context.type.weighted(style, weight) instead of setting '
          'fontWeight: it re-applies the theme font, so a Google font loads '
          'the real weight file instead of synthesising one. $count sites in '
          '${files.length} files:\n$listing',
    );
  });
}
