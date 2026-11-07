// Moves every pub dependency of the workspace to its latest release, as the
// weekly Upgrade workflow does once it has moved .fvmrc to the latest Flutter
// beta. A constraint that excludes a dependency's latest release is widened
// to it, unless check_constraints.dart's [heldBack] says why not; then
// pubspec.lock takes the newest version every constraint allows, and the
// kit's snapshots are regenerated, since a dependency can move a look.
//
//   fvm dart run tool/upgrade.dart [--summary=<file>]
//
// --summary writes what moved against HEAD as markdown, the Upgrade
// workflow's pull request description. The upgrade breaking something is not
// this tool failing: a snapshot it could not regenerate is in the summary,
// and CI on the pull request says the rest.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'check_constraints.dart' show heldBack;

const _kit = 'packages/admin_ui';

/// The kit's snapshots, each with the generator that writes it.
const _snapshots = {
  'api.txt': 'tool/gen_barrels.dart',
  'looks.txt': 'tool/gen_looks.dart',
};

Future<void> main(List<String> args) async {
  final summary = [
    for (final arg in args)
      if (arg.startsWith('--summary=')) arg.substring('--summary='.length),
  ].lastOrNull;

  final pubspecs = _pubspecs();
  final names = {
    for (final path in pubspecs)
      ..._constraints(File(path).readAsStringSync()).keys,
  }.difference(heldBack.keys.toSet()).toList()..sort();

  await _run(_flutter, ['pub', 'upgrade', '--major-versions', ...names]);
  await _run(_flutter, ['pub', 'upgrade']);

  final failed = <String>[];
  for (final MapEntry(key: snapshot, value: generator) in _snapshots.entries) {
    if (await _start(_dart, ['run', generator], _kit) != 0) {
      failed.add(snapshot);
    }
  }

  if (summary != null) {
    File(summary).writeAsStringSync(_summary(pubspecs, failed));
  }
}

/// The workspace's pubspecs: the root's, then each member's.
List<String> _pubspecs() {
  final root = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  return [
    'pubspec.yaml',
    for (final member in root['workspace'] as YamlList? ?? YamlList())
      '$member/pubspec.yaml',
  ];
}

/// Every hosted dependency of a pubspec's [sections], with its constraint;
/// null is no constraint. An SDK, path or git dependency is not one: it has
/// no release to move to.
Map<String, String?> _constraints(
  String? pubspec, {
  List<String> sections = const ['dependencies', 'dev_dependencies'],
}) {
  if (pubspec == null) return const {};
  final yaml = loadYaml(pubspec) as YamlMap;
  return {
    for (final section in sections)
      for (final MapEntry(:key, :value)
          in (yaml[section] as YamlMap? ?? YamlMap()).entries)
        if (value is String?) key as String: value,
  };
}

/// Every package pubspec.lock resolves, with its version and kind.
Map<String, ({String version, String kind})> _locked(String? lock) {
  if (lock == null) return const {};
  final packages = (loadYaml(lock) as YamlMap)['packages'] as YamlMap;
  return {
    for (final MapEntry(:key, :value) in packages.entries)
      key as String: (
        version: (value as YamlMap)['version'] as String,
        kind: value['dependency'] as String,
      ),
  };
}

String _summary(List<String> pubspecs, List<String> failed) {
  final out = StringBuffer();
  final todo = <String>[];

  final pinWas = _pin(_atHead('.fvmrc'));
  final pin = _pin(File('.fvmrc').readAsStringSync());
  if (pinWas != pin) {
    out
      ..writeln(
        '**Flutter** $pinWas → $pin '
        '([what changed](https://github.com/flutter/flutter/compare/'
        '$pinWas...$pin)).',
      )
      ..writeln()
      ..writeln(
        "CI's sweeps and tests run on $pin. Compare renders both sides with "
        'it too, so its pictures show what the packages moved, not what '
        'Flutter did.',
      )
      ..writeln();
  }

  final moved = <String>[];
  for (final path in pubspecs) {
    final was = _constraints(_atHead(path));
    final now = _constraints(File(path).readAsStringSync());
    for (final name in {...was.keys, ...now.keys}.toList()..sort()) {
      if (was[name] != now[name]) {
        moved.add(
          '| `$path` | $name | ${was[name] ?? 'any'} | '
          '${now[name] ?? 'any'} |',
        );
      }
    }
  }
  if (moved.isNotEmpty) {
    out
      ..writeln('**Constraints**')
      ..writeln()
      ..writeln('| Pubspec | Package | From | To |')
      ..writeln('|---|---|---|---|')
      ..writeAll(moved, '\n')
      ..writeln()
      ..writeln();
  }
  const kit = '$_kit/pubspec.yaml';
  final kitWas = _constraints(_atHead(kit), sections: ['dependencies']);
  final kitNow = _constraints(
    File(kit).readAsStringSync(),
    sections: ['dependencies'],
  );
  if (kitNow.entries.any((e) => kitWas[e.key] != e.value)) {
    todo.add(
      "The kit's own constraints moved, and an app resolves them with its "
      'own: record it in `$_kit/CHANGELOG.md` under the next version.',
    );
  }

  final lockWas = _locked(_atHead('pubspec.lock'));
  final lock = _locked(File('pubspec.lock').readAsStringSync());
  final resolved = [
    for (final name in {...lockWas.keys, ...lock.keys}.toList()..sort())
      if (lockWas[name]?.version != lock[name]?.version)
        '| $name | ${lockWas[name]?.version ?? '—'} | '
            '${lock[name]?.version ?? '—'} | '
            '${(lock[name] ?? lockWas[name])!.kind} |',
  ];
  if (resolved.isNotEmpty) {
    out
      ..writeln('**Resolved** (`pubspec.lock`)')
      ..writeln()
      ..writeln('| Package | From | To | Dependency |')
      ..writeln('|---|---|---|---|')
      ..writeAll(resolved, '\n')
      ..writeln()
      ..writeln();
  }

  if (heldBack.isNotEmpty) {
    out
      ..writeln('**Held back** by `tool/check_constraints.dart`')
      ..writeln()
      ..writeAll([
        for (final MapEntry(:key, :value) in heldBack.entries) '- $key: $value',
      ], '\n')
      ..writeln()
      ..writeln();
  }

  for (final snapshot in _snapshots.keys) {
    if (failed.contains(snapshot)) {
      todo.add(
        '`${_snapshots[snapshot]}` failed under this upgrade, so '
        "`$_kit/$snapshot` is as it was: CI's tests say why.",
      );
    } else if (_changed('$_kit/$snapshot')) {
      todo.add(switch (snapshot) {
        'looks.txt' =>
          '`looks.txt` moved, a change of look: record it in '
              '`$_kit/CHANGELOG.md` under a heading of its own.',
        _ =>
          '`api.txt` moved: record the change of API in '
              '`$_kit/CHANGELOG.md`.',
      });
    }
  }
  todo.add(
    "A red check is this upgrade's breakage: fix it on this branch. The "
    "next weekly run rebuilds the branch from main, unless someone else's "
    'commit is on it.',
  );
  out
    ..writeln('**Before merging**')
    ..writeln()
    ..writeAll([for (final item in todo) '- $item'], '\n')
    ..writeln();
  return out.toString();
}

String? _pin(String? fvmrc) => fvmrc == null
    ? null
    : (jsonDecode(fvmrc) as Map<String, Object?>)['flutter'] as String?;

/// [path] as HEAD has it; null when HEAD has no such file.
String? _atHead(String path) {
  final result = Process.runSync('git', ['show', 'HEAD:$path']);
  return result.exitCode == 0 ? result.stdout as String : null;
}

bool _changed(String path) =>
    Process.runSync('git', ['diff', '--quiet', 'HEAD', '--', path]).exitCode !=
    0;

/// Runs [executable] with the output on this one's, and exits with its code
/// when it fails.
Future<void> _run(String executable, List<String> arguments) async {
  final code = await _start(executable, arguments, '.');
  if (code != 0) exit(code);
}

Future<int> _start(
  String executable,
  List<String> arguments,
  String workingDirectory,
) async {
  print('> ${[executable.split('/').last, ...arguments].join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

/// The SDK running this, so `fvm dart` upgrades with the pinned Flutter.
String get _dart => Platform.resolvedExecutable;

String get _flutter {
  // <sdk>/bin/cache/dart-sdk/bin/dart
  final sdk = File(_dart).parent.parent.parent.parent.parent;
  final flutter = File('${sdk.path}/bin/flutter');
  return flutter.existsSync() ? flutter.path : 'flutter';
}
