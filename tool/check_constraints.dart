// Fails when a dependency constraint of the kit excludes that dependency's
// latest release, unless [_heldBack] says why. An app resolves the kit's
// constraints with its own, so one that stops short of a release holds
// every app on the kit below it too, along with whatever that release pins
// (a plugin's `win32`, say).
//
//   dart run tool/check_constraints.dart
//
// It needs the network: pub.dev answers the lookups. When pub.dev cannot be
// reached it says so and passes.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

const _package = 'packages/admin_ui';

/// Dependencies allowed to exclude their latest release, each with the
/// reason.
const _heldBack = <String, String>{
  'desktop_drop':
      '0.9 needs cross_file ^0.4, and file_picker 13.1.0, the latest, still '
      'pins cross_file ^0.3.5. Widen once a file_picker release takes 0.4.',
};

Future<void> main() async {
  final pubspec =
      loadYaml(File('$_package/pubspec.yaml').readAsStringSync()) as YamlMap;
  final dependencies = pubspec['dependencies'] as YamlMap? ?? YamlMap();
  final constraints = <String, VersionConstraint>{
    for (final MapEntry(:key, :value) in dependencies.entries)
      // An SDK, path or git dependency has no release to fall behind.
      if (value is String?)
        key as String: VersionConstraint.parse(value ?? 'any'),
  };

  final client = http.Client();
  final Map<String, Version> latest;
  try {
    latest = Map.fromIterables(
      constraints.keys,
      await Future.wait([
        for (final name in constraints.keys) _latest(client, name),
      ]),
    );
  } on _Unreachable catch (e) {
    print('pub.dev is unreachable, nothing checked: ${e.cause}');
    return;
  } finally {
    client.close();
  }

  final behind = <String>[];
  final stale = <String>[];
  for (final MapEntry(key: name, value: constraint) in constraints.entries) {
    final version = latest[name]!;
    final excluded = !constraint.allows(version);
    if (excluded && !_heldBack.containsKey(name)) {
      behind.add('$name: $constraint excludes $version');
    } else if (!excluded && _heldBack.containsKey(name)) {
      stale.add('$name: $constraint now allows $version');
    }
  }
  for (final name in _heldBack.keys) {
    if (!constraints.containsKey(name)) stale.add('$name: not a dependency');
  }

  if (behind.isNotEmpty) {
    print(
      'Widen these to the latest release, or list them in _heldBack with '
      'the reason:\n  ${behind.join('\n  ')}',
    );
  }
  if (stale.isNotEmpty) {
    print('Remove these from _heldBack:\n  ${stale.join('\n  ')}');
  }
  if (behind.isNotEmpty || stale.isNotEmpty) exitCode = 1;
}

/// The latest stable release of [package] on pub.dev.
Future<Version> _latest(http.Client client, String package) async {
  final http.Response response;
  try {
    response = await client
        .get(
          Uri.https('pub.dev', '/api/packages/$package'),
          headers: {'accept': 'application/vnd.pub.v2+json'},
        )
        .timeout(const Duration(seconds: 20));
  } on SocketException catch (e) {
    throw _Unreachable(e);
  } on http.ClientException catch (e) {
    throw _Unreachable(e);
  } on TimeoutException catch (e) {
    throw _Unreachable(e);
  }
  if (response.statusCode >= 500) {
    throw _Unreachable('HTTP ${response.statusCode} for $package');
  }
  if (response.statusCode != 200) {
    throw StateError('pub.dev answered ${response.statusCode} for $package');
  }
  final json = jsonDecode(response.body) as Map<String, Object?>;
  final latest = json['latest']! as Map<String, Object?>;
  return Version.parse(latest['version']! as String);
}

final class _Unreachable implements Exception {
  _Unreachable(this.cause);

  final Object cause;
}
