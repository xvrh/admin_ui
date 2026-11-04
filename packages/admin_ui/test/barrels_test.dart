import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/gen_barrels.dart' as gen;

void main() {
  test('public barrels are in sync with src/ (run tool/gen_barrels.dart)', () {
    final root = Directory.current.path;
    final barrels = gen.buildBarrels(root);

    barrels.forEach((name, barrel) {
      final path = '$root/lib/$name';
      expect(File(path).existsSync(), isTrue, reason: 'missing lib/$name');
      expect(
        gen.normalize(gen.readBarrelFile(path)),
        gen.normalize(barrel.lines),
        reason: 'lib/$name is stale — run: fvm dart run tool/gen_barrels.dart',
      );
    });
  });

  test('api.txt lists the public surface (run tool/gen_barrels.dart)', () {
    final root = Directory.current.path;
    final api = File('$root/api.txt');
    expect(api.existsSync(), isTrue, reason: 'missing api.txt');
    expect(
      api.readAsStringSync(),
      gen.renderApi(gen.buildBarrels(root)),
      reason: 'api.txt is stale — run: fvm dart run tool/gen_barrels.dart',
    );
  });

  test('testing.dart is a barrel of its own: no umbrella re-exports it, and '
      'nothing under lib reaches flutter_test', () {
    final barrels = gen.buildBarrels(Directory.current.path);
    expect(barrels['testing.dart']!.symbols, contains('loadAdminFonts'));
    for (final umbrella in gen.umbrellas) {
      expect(umbrella.sources, isNot(contains('testing.dart')));
    }
    final importers = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            file.readAsStringSync().contains('package:flutter_test/'))
          file.path,
    ];
    expect(importers, isEmpty);
  });

  test('exportsOf reads annotations and follows re-exports', () {
    final dir = Directory.systemTemp.createTempSync('gen_barrels_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/leaf.dart').writeAsStringSync('''
class Shown {}
class Hidden {}
''');
    File('${dir.path}/a.dart').writeAsStringSync('''
import 'package:meta/meta.dart';
export 'leaf.dart' hide Hidden;

@internal
void helper() {}

@visibleForTesting
const seam = 1;

@Deprecated('Use Current')
typedef Old = Current;

class Current {}

class _Private {}
''');

    final symbols = gen.exportsOf('${dir.path}/a.dart');
    expect(
      symbols.keys,
      unorderedEquals(['helper', 'seam', 'Old', 'Current', 'Shown']),
    );
    expect(symbols['helper']!.internal, isTrue);
    expect(symbols['seam']!.internal, isTrue);
    expect(symbols['Current']!.internal, isFalse);
    expect(symbols['Old']!.deprecated, isTrue);
    expect(symbols['Current']!.deprecated, isFalse);
  });

  test('hidden helpers are left out, and deprecated symbols marked', () {
    final barrels = gen.buildBarrels(Directory.current.path);
    final widgets = barrels['widgets.dart']!.symbols;
    expect(widgets, contains('Calendar'));
    expect(widgets, isNot(contains('MonthCalendar')));
    expect(widgets, isNot(contains('flattenJson')));
    expect(barrels['assets.dart']!.symbols, isNot(contains('cropMove')));

    expect(barrels['theme.dart']!.symbols['AdminTokens'], isFalse);
    // Only a barrel that names a deprecated symbol silences the lint.
    for (final MapEntry(key: name, value: barrel) in barrels.entries) {
      expect(
        barrel.namesDeprecated,
        barrel.symbols.values.any((deprecated) => deprecated),
        reason: name,
      );
    }
  });
}
