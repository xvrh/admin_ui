import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../../tool/friction_summary.dart';
import '../../tool/kit_coverage.dart';

final _root = Directory.current;

List<File> _dartFiles(String dir) {
  final directory = Directory('${_root.path}/$dir');
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _relative(File f) => f.path.substring(_root.path.length + 1);

/// `path:line: text` for each line of [files] matching [pattern].
List<String> _matches(List<File> files, RegExp pattern) => [
  for (final f in files)
    for (final (i, line) in f.readAsLinesSync().indexed)
      if (pattern.hasMatch(line)) '${_relative(f)}:${i + 1}: ${line.trim()}',
];

void main() {
  group('the kit boundary', () {
    test("nothing imports the kit's src, another app, or the SDK Material", () {
      final forbidden = RegExp(
        r'''^\s*(import|export)\s+['"]package:('''
        r'admin_ui/src/|admin_ui_example|flutter_localizations|'
        r'flutter/material\.dart|flutter/cupertino\.dart)',
      );
      expect(
        _matches([
          ..._dartFiles('lib'),
          ..._dartFiles('test'),
          ..._dartFiles('tool'),
        ], forbidden),
        isEmpty,
      );
    });

    test('lib/ does not import flutterware', () {
      expect(
        _matches(
          _dartFiles('lib'),
          RegExp(r'''^\s*import\s+['"]package:flutterware'''),
        ),
        isEmpty,
      );
    });

    test('screens see the shop through ShopApi, never the fake below it', () {
      // A real backend swaps in behind ShopApi and AppServices with no
      // screen edited, and no demo account leaks onto its sign-in page.
      final screens = [
        ..._dartFiles('lib/src/screens'),
        ..._dartFiles('lib/src/frame'),
        ..._dartFiles('lib/src/widgets'),
      ];
      expect(
        _matches(
          screens,
          RegExp(
            r'''^\s*import\s+['"](package:reference_admin/src/|[./]*)fake/''',
          ),
        ),
        isEmpty,
      );
    });

    test('admin_ui.dart is imported by app.dart alone', () {
      final all = _matches(
        _dartFiles('lib'),
        RegExp(r'''^\s*import\s+['"]package:admin_ui/admin_ui\.dart'''),
      );
      expect(all, hasLength(1));
      expect(all.single, startsWith('lib/src/app.dart:'));
    });

    test('the pubspec depends on the allow-list only', () {
      final pubspec = loadYaml(
        File('${_root.path}/pubspec.yaml').readAsStringSync(),
      ) as YamlMap;
      expect((pubspec['dependencies'] as YamlMap).keys.toSet(), {
        'admin_ui',
        'clock',
        'collection',
        'flutter',
        'intl',
        'material_ui',
      });
      expect((pubspec['dev_dependencies'] as YamlMap).keys.toSet(), {
        'crypto',
        'flutter_lints',
        'flutter_test',
        'flutterware',
        'image',
        'yaml',
      });
    });
  });

  group('determinism', () {
    test('lib/ reads the clock and seeds its randomness', () {
      final lib = _dartFiles('lib');
      expect(_matches(lib, RegExp(r'DateTime\.now\(')), isEmpty);
      expect(_matches(lib, RegExp(r'\bRandom\(\s*\)')), isEmpty);
    });
  });

  group('friction', () {
    final entries = readFriction(
      File('${_root.path}/FRICTION.md').readAsStringSync(),
    );
    final ids = {for (final e in entries) e.id};
    final marker = RegExp(r'FRICTION\(([FT]-\d{3})\)');
    final files = [
      ..._dartFiles('lib'),
      ..._dartFiles('test'),
      ..._dartFiles('tool'),
    ];
    final marked = <String, List<String>>{};
    for (final f in files) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        for (final m in marker.allMatches(line)) {
          (marked[m[1]!] ??= []).add('${_relative(f)}:${i + 1}');
        }
      }
    }

    test('every entry is well formed and unique', () {
      expect(entries.length, ids.length, reason: 'duplicate ids');
      for (final e in entries) {
        expect(e.kind, isNotEmpty, reason: '${e.id} has no Kind');
        expect(e.level, matches(RegExp(r'^S[123]$')), reason: e.id);
        expect(e.status, isNotEmpty, reason: '${e.id} has no Status');
        expect(e.evidence, isNotEmpty, reason: '${e.id} has no Evidence');
      }
    });

    test('every marker names a known entry', () {
      final unknown = [
        for (final MapEntry(:key, :value) in marked.entries)
          if (!ids.contains(key)) '$key at ${value.join(', ')}',
      ];
      expect(unknown, isEmpty);
    });

    test('every open S1 or S2 entry marks its workaround', () {
      final unmarked = [
        for (final e in entries)
          if (e.state == 'open' &&
              (e.level == 'S1' || e.level == 'S2') &&
              !marked.containsKey(e.id))
            e.id,
      ];
      expect(unmarked, isEmpty);
    });

    test('the summary table is fresh', () {
      final markdown = File('${_root.path}/FRICTION.md').readAsStringSync();
      expect(
        withSummary(markdown),
        markdown,
        reason: 'run fvm dart run tool/friction_summary.dart',
      );
    });

    test('every status is one the process names, shown whole', () {
      // The table goes into the PR description: a status cut to its first
      // word ("not" for "not reproduced", "kit" for "kit PR #12") says
      // nothing.
      final known = RegExp(
        r'^(suspected|open|not reproduced|wontfix|deferred|kit PR #\d+|'
        r'fixed(?: \(#\d+\))?)$',
      );
      final unknown = [
        for (final e in entries)
          if (!known.hasMatch(e.shownStatus)) '${e.id}: ${e.shownStatus}',
      ];
      expect(unknown, isEmpty);
    });

    test('no entry is left suspected', () {
      final suspected = [
        for (final e in entries)
          if (e.state == 'suspected') e.id,
      ];
      expect(suspected, isEmpty);
    });
  });

  group('scenario shot names', () {
    test('are unique within each folder', () {
      final literal = RegExp(
        r'''(?:Shot\(|s\.screen\(|s\.act\(|shot:\s*|realtime\(s,\s*)\s*'([^'$]+)'(?=\s*[,)])''',
      );
      final byFolder = <String, Map<String, String>>{};
      final clashes = <String>[];
      for (final f in _dartFiles('test/scenarios')) {
        final path = _relative(f);
        final folder = path
            .replaceFirst('test/scenarios/', '')
            .split('/')
            .reversed
            .skip(1)
            .toList()
            .reversed
            .join('/');
        final seen = byFolder.putIfAbsent(folder, () => {});
        final source = f.readAsStringSync();
        // A name may repeat inside one scenario once a split has begun:
        // each branch is its own replay of the steps after it.
        final scenarios = source.split(RegExp(r'\bscenario\('));
        for (final (i, block) in scenarios.indexed) {
          final inThis = <String>{};
          for (final m in literal.allMatches(block)) {
            final name = m[1]!;
            final where = '$path#$i';
            final splitBefore = block.substring(0, m.start).contains('.split(');
            if (inThis.contains(name) && splitBefore) continue;
            if (seen.containsKey(name)) {
              clashes.add('"$name" in $where and ${seen[name]}');
            }
            seen[name] = where;
            inThis.add(name);
          }
        }
      }
      expect(clashes, isEmpty);
    });
  });

  group('kit coverage', () {
    final kit = coverage(_root);

    test('KIT_COVERAGE.md is fresh', () {
      final file = File('${_root.path}/KIT_COVERAGE.md');
      final fresh =
          file.existsSync() && file.readAsStringSync() == renderCoverage(kit);
      expect(fresh, isTrue, reason: 'run fvm dart run tool/kit_coverage.dart');
    });

    test('every unused kit symbol has a reason', () {
      final unexplained = [for (final s in kit.unexplained) s.name];
      expect(unexplained, isEmpty);
      expect(kit.staleExclusions, isEmpty, reason: 'used, yet excluded');
    });
  });
}
