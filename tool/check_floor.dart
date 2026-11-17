// Checks the kit on the oldest Flutter it admits, the lower bound of the
// `environment: flutter:` in packages/admin_ui/pubspec.yaml. An app builds
// the commit it pins with its own Flutter, which can trail the one .fvmrc
// pins by months, and the rest of CI runs only that one. A change that takes
// a later API passes there and breaks such an app when it moves its pin.
//
// The kit is resolved alone, as an app's `git:` dependency resolves it, in a
// copy outside the workspace, and
//
// - at the lowest versions its constraints admit, its lib/ is analyzed: an
//   API taken from a later release of a dependency fails here;
// - at the latest versions the floor admits, its lib/, test/ and tool/ are
//   analyzed and its tests run.
//
//   fvm dart run tool/check_floor.dart --flutter=<the root of a floor SDK>
//
// `fvm install 3.47.5` puts one in ~/fvm/versions/3.47.5. Without --flutter
// it uses the Flutter whose Dart runs it, as CI does, which installs the
// floor and runs `dart tool/check_floor.dart`: no workspace resolves on the
// floor, so this script imports nothing outside the SDK.
//
// The copy is deleted when every step passes and kept, at the path printed,
// when one fails.

import 'dart:convert';
import 'dart:io';

const _package = 'packages/admin_ui';

Future<void> main(List<String> arguments) async {
  String? flutterRoot;
  for (final argument in arguments) {
    if (argument.startsWith('--flutter=')) {
      flutterRoot = argument.substring('--flutter='.length);
    } else {
      _fail(
        'Unknown argument "$argument".\n'
        'Usage: dart run tool/check_floor.dart [--flutter=<Flutter SDK root>]',
      );
    }
  }

  final pubspec = File('$_package/pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail('No $_package/pubspec.yaml: run this from the repository root.');
  }
  final floor = _floor(pubspec.readAsStringSync());

  final flutter = _flutterExecutable(flutterRoot);
  final version = _frameworkVersion(flutter);
  if (!version.startsWith('${floor.minor}.')) {
    _fail(
      'Flutter $version is not the floor: $_package admits Flutter '
      '${floor.constraint}, so the check needs a ${floor.minor} SDK. Pass '
      '--flutter=<its root>, such as ~/fvm/versions/${floor.minor}.<patch> '
      'after `fvm install`.',
    );
  }
  print('Flutter $version, the floor of $_package (${floor.constraint}).');

  final copy = _copyPackage();
  print('Resolving the kit alone in ${copy.path}.');

  Future<void> run(List<String> command) async {
    print('\n\$ flutter ${command.join(' ')}');
    final process = await Process.start(
      flutter,
      command,
      workingDirectory: copy.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0) {
      _fail(
        '`flutter ${command.join(' ')}` failed on Flutter $version (exit '
        '$code). The copy stays in ${copy.path}.',
        code: code,
      );
    }
  }

  await run(['pub', 'downgrade']);
  print('Lowest: ${_directVersions(copy)}');
  // Infos are the pinned job's: lints, and what the pinned Flutter
  // deprecates. An error or a warning here is the kit's on the floor.
  await run(['analyze', '--no-pub', '--no-fatal-infos', 'lib']);

  await run(['pub', 'upgrade']);
  print('Latest: ${_directVersions(copy)}');
  await run(['analyze', '--no-pub', '--no-fatal-infos', 'lib', 'test', 'tool']);
  await run(['test', '--no-pub']);

  copy.parent.deleteSync(recursive: true);
  print('\nThe kit builds and passes its tests on Flutter $version.');
}

/// The lower bound of the kit's `environment: flutter:`, such as `>=3.47.0`,
/// and its `major.minor`.
({String constraint, String minor}) _floor(String pubspec) {
  final lines = const LineSplitter().convert(pubspec);
  final start = lines.indexOf('environment:');
  if (start != -1) {
    for (final line in lines.skip(start + 1)) {
      // The block ends at the next key that is not indented.
      if (line.isNotEmpty && !line.startsWith(RegExp(r'[\s#]'))) break;
      final match = RegExp(
        r'''^\s+flutter:\s*['"]?(>=\s*(\d+)\.(\d+)\.\d+[^'"\s]*)''',
      ).firstMatch(line);
      if (match != null) {
        return (constraint: match[1]!, minor: '${match[2]}.${match[3]}');
      }
    }
  }
  _fail(
    '$_package/pubspec.yaml has no `environment: flutter: \'>=x.y.z\'`, so it '
    'names no floor to check.',
  );
}

/// The `flutter` of the SDK at [root], or else of the SDK whose Dart runs
/// this: `<root>/bin/cache/dart-sdk/bin/dart`.
String _flutterExecutable(String? root) {
  root ??= File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
  if (root.startsWith('~/')) {
    root = '${Platform.environment['HOME']}${root.substring(1)}';
  }
  final flutter = File(
    '$root/bin/${Platform.isWindows ? 'flutter.bat' : 'flutter'}',
  );
  if (!flutter.existsSync()) {
    _fail(
      'No Flutter SDK at $root. Pass --flutter=<the root of a Flutter SDK>, '
      'or run this with the dart of one.',
    );
  }
  return flutter.path;
}

String _frameworkVersion(String flutter) {
  final result = Process.runSync(flutter, ['--version', '--machine']);
  final output = result.stdout as String;
  // A first run can print a banner around the JSON.
  final start = output.indexOf('{');
  final end = output.lastIndexOf('}');
  if (result.exitCode != 0 || start == -1 || end < start) {
    _fail('`$flutter --version --machine` failed:\n$output${result.stderr}');
  }
  final json = jsonDecode(output.substring(start, end + 1)) as Map;
  return json['frameworkVersion'] as String;
}

/// A copy of the kit as an app's `git:` dependency has it: the files git
/// sees (tracked, or new and not ignored), with no `resolution: workspace`,
/// and without the example's pubspec, which would make the example a
/// package of its own that `flutter test` tries to resolve. The example's
/// files stay: the tests read its fonts and its sources.
Directory _copyPackage() {
  final listing = Process.runSync('git', [
    'ls-files',
    '-z',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    _package,
  ]);
  if (listing.exitCode != 0) {
    _fail('`git ls-files` failed:\n${listing.stderr}');
  }
  final root = Directory.systemTemp.createTempSync('admin_ui_floor_');
  final copy = Directory('${root.path}/admin_ui')..createSync();
  for (final path in (listing.stdout as String).split('\x00')) {
    if (path.isEmpty) continue;
    final relative = path.substring(_package.length + 1);
    if (relative == 'example/pubspec.yaml') continue;
    final source = File(path);
    // Listed by the index but deleted in the working tree.
    if (!source.existsSync()) continue;
    final target = File('${copy.path}/$relative');
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }
  final pubspec = File('${copy.path}/pubspec.yaml');
  pubspec.writeAsStringSync(
    pubspec.readAsStringSync().replaceFirst(
      RegExp(r'^resolution: workspace[ \t]*\r?\n', multiLine: true),
      '',
    ),
  );
  return copy;
}

/// The kit's direct dependencies as [copy]'s pubspec.lock resolved them.
String _directVersions(Directory copy) {
  final lock = File('${copy.path}/pubspec.lock').readAsStringSync();
  final entry = RegExp(
    r'^  (\w+):\n    dependency: "direct main"\n(?:    .*\n)*?    version: "([^"]+)"',
    multiLine: true,
  );
  return [
    for (final match in entry.allMatches(lock))
      if (match[1] != 'flutter') '${match[1]} ${match[2]}',
  ].join(', ');
}

Never _fail(String message, {int code = 1}) {
  stderr.writeln(message);
  exit(code);
}
