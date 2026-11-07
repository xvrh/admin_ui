// Fails when the kit's version has no heading in its CHANGELOG or a heading
// above it is not newer, and, given the tag being released, when the tag is
// not v<version>. CI runs it on every pull request, and with --tag on a
// release tag, which the repository's rules keep from ever moving: a
// mistake there is for the next version to fix.
//
//   dart run tool/check_version.dart [--tag=v0.1.1]

import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

const _package = 'packages/admin_ui';

void main(List<String> args) {
  String? tag;
  for (final arg in args) {
    if (arg.startsWith('--tag=')) {
      tag = arg.substring('--tag='.length);
    } else {
      stderr.writeln(
        'Usage: dart run tool/check_version.dart [--tag=v<version>]',
      );
      exit(64);
    }
  }

  final pubspec =
      loadYaml(File('$_package/pubspec.yaml').readAsStringSync()) as YamlMap;
  final version = Version.parse(pubspec['version'] as String);

  final headings = [
    for (final line in File('$_package/CHANGELOG.md').readAsLinesSync())
      if (RegExp(r'^## (\S+)\s*$').firstMatch(line) case final match?)
        match[1]!,
  ];

  final problems = <String>[];
  final index = headings.indexOf('$version');
  if (index == -1) {
    problems.add(
      '$_package/CHANGELOG.md has no "## $version" heading for the version '
      'in its pubspec.',
    );
  } else {
    // Above the released version: the next one, its changes being recorded.
    for (final heading in headings.take(index)) {
      final Version next;
      try {
        next = Version.parse(heading);
      } on FormatException {
        problems.add(
          '$_package/CHANGELOG.md has "## $heading"; a heading is a version.',
        );
        continue;
      }
      if (next <= version) {
        problems.add(
          '$_package/CHANGELOG.md has "## $heading" above "## $version"; '
          'the headings go from the newest down.',
        );
      }
    }
  }
  if (tag != null && tag != 'v$version') {
    problems.add(
      'The tag is $tag, but $_package/pubspec.yaml says $version: a release '
      'is tagged v<its version>.',
    );
  }

  if (problems.isEmpty) {
    print(
      tag == null
          ? 'Version $version has its CHANGELOG heading.'
          : 'Tag $tag matches version $version and its CHANGELOG heading.',
    );
    return;
  }
  problems.forEach(stderr.writeln);
  exit(1);
}
