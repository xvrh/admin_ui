// Builds tree_shaking/, an app that ships the kit in English alone, for the
// web, and fails when its main.dart.js holds a language the app did not
// list: the kit's other languages, Material's other languages, or CLDR's
// names of languages in any language but English. It also fails on
// common_locale_data's canonicalization rules, which nothing in the kit
// reads.
//
//   fvm dart run tool/check_tree_shaking.dart [--keep]
//
// Run from packages/admin_ui. The Flutter that runs this script builds the
// app. --keep leaves the build in tree_shaking/build/web.
//
// Each check is a string only that language has, read from the sources: a
// language added under lib/src/l10n/languages is checked with no change
// here.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final app = Directory('tree_shaking');
  if (!app.existsSync()) {
    stderr.writeln('Run from packages/admin_ui.');
    exit(2);
  }
  final out = Directory('${app.path}/build/web');
  final flutter = _flutter();
  stdout.writeln('Building ${app.path} with $flutter …');
  final build = Process.runSync(flutter, [
    'build',
    'web',
    '--release',
    '-O4',
    '--no-pub',
    '--no-wasm-dry-run',
  ], workingDirectory: app.path);
  if (build.exitCode != 0) {
    stderr
      ..writeln(build.stdout)
      ..writeln(build.stderr);
    exit(build.exitCode);
  }
  final js = File('${out.path}/main.dart.js').readAsStringSync();
  final bytes = utf8.encode(js);
  stdout.writeln(
    'main.dart.js: ${_kb(bytes.length)} raw, '
    '${_kb(gzip.encode(bytes).length)} gzipped',
  );

  final packages = _packages();
  final codes = [
    for (final dir in Directory(
      'lib/src/l10n/languages',
    ).listSync().whereType<Directory>())
      dir.uri.pathSegments.where((s) => s.isNotEmpty).last,
  ]..sort();
  final material = '${packages['material_ui']}/src/l10n';
  final names = '${packages['common_locale_data']}/src/data';

  final failures = <String>[];
  void present(String what, String text) {
    if (!js.contains(_js(text))) {
      failures.add('$what ("$text") is missing: the app no longer uses it');
    }
  }

  void absent(String what, String text) {
    if (js.contains(_js(text))) failures.add('$what ("$text") is in the build');
  }

  // What English brings, so the checks below look where it would be.
  present("the kit's English", _kitString('en'));
  present("Material's English", _arb(material, 'en', 'pasteButtonLabel'));
  present("intl's English dates", _month('en'));
  present("CLDR's English names", _name(names, 'en'));

  for (final code in codes) {
    if (code == 'en') continue;
    if (!File(_kitFile(code)).existsSync()) {
      failures.add('$code has no strings: ${_kitFile(code)}');
      continue;
    }
    absent("the kit's $code", _kitString(code));
    final paste = _arb(material, code, 'pasteButtonLabel');
    if (paste != _arb(material, 'en', 'pasteButtonLabel')) {
      absent("Material's $code", paste);
    }
    absent("intl's $code dates", _month(code));
    absent("CLDR's $code names", _name(names, code));
  }
  // British English, which shares English's words but not its dates.
  absent("intl's en_GB dates", _pattern('en/date_data_en_gb.dart', 'yMd'));
  // A language the kit does not have: what Material's 82, intl's every
  // locale or common_locale_data_all.dart would bring.
  absent("Material's fi", _arb(material, 'fi', 'pasteButtonLabel'));
  absent("CLDR's fi names", _name(names, 'fi'));

  // common_locale_data's canonicalization rules, which the kit never needs:
  // it reads a language's names, and parses a code's subtags itself.
  absent("common_locale_data's LocaleData", 'zh-cmn');

  if (!args.contains('--keep')) {
    Directory('${app.path}/build').deleteSync(recursive: true);
  }
  if (failures.isEmpty) {
    stdout.writeln('Only English is in the build.');
    return;
  }
  stderr.writeln(failures.map((f) => '- $f').join('\n'));
  exit(1);
}

/// The flutter beside the Dart that runs this script, else the one on PATH.
String _flutter() {
  // <flutter>/bin/cache/dart-sdk/bin/dart
  final bin = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final flutter = File(
    '${bin.path}/flutter${Platform.isWindows ? '.bat' : ''}',
  );
  return flutter.existsSync() ? flutter.path : 'flutter';
}

/// Each package's lib directory, from the workspace's package config.
Map<String, String> _packages() {
  var dir = Directory.current.absolute;
  while (!File('${dir.path}/.dart_tool/package_config.json').existsSync()) {
    if (dir.parent.path == dir.path) throw StateError('No package config.');
    dir = dir.parent;
  }
  final config = File('${dir.path}/.dart_tool/package_config.json');
  final json = jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
  return {
    for (final p in (json['packages']! as List).cast<Map<String, Object?>>())
      p['name']! as String: config.parent.uri
          .resolve('${p['rootUri']}/')
          .resolve('${p['packageUri']}')
          .toFilePath()
          .replaceFirst(RegExp(r'/$'), ''),
  };
}

/// The kit's "Unsaved changes" in [code].
String _kitString(String code) {
  final file = _kitFile(code);
  final source = File(file).readAsStringSync();
  final match = RegExp(r"String get unsavedChanges =>\s*'((?:[^'\\]|\\.)*)';")
      .firstMatch(source);
  if (match == null) throw StateError('No unsavedChanges in $file.');
  return _unescape(match[1]!);
}

String _kitFile(String code) => code == 'en'
    ? 'lib/src/l10n/admin_ui_localizations.dart'
    : 'lib/src/l10n/languages/$code/admin_localizations_$code.dart';

/// The first month's name in [code]'s date data.
String _month(String code) {
  final source = File('lib/src/l10n/languages/$code/date_data.dart')
      .readAsStringSync();
  final match = RegExp(r"\n  MONTHS: const \[\s*'((?:[^'\\]|\\.)*)'")
      .firstMatch(source);
  if (match == null) throw StateError('No MONTHS in $code/date_data.dart.');
  return _unescape(match[1]!);
}

/// The date pattern for [skeleton] in the date data at [path], under
/// lib/src/l10n/languages.
String _pattern(String path, String skeleton) {
  final source = File('lib/src/l10n/languages/$path').readAsStringSync();
  final match = RegExp(
    "\n  '${RegExp.escape(skeleton)}': '((?:[^'\\\\]|\\\\.)*)',",
  ).firstMatch(source);
  if (match == null) throw StateError('No $skeleton in $path.');
  return _unescape(match[1]!);
}

/// Material's [key] in [code].
String _arb(String dir, String code, String key) =>
    (jsonDecode(File('$dir/material_$code.arb').readAsStringSync())
            as Map<String, Object?>)[key]!
        as String;

/// What CLDR calls Spanish in [code] ("Spanish", "espagnol"), or Spanish's
/// own name in Spanish.
String _name(String dir, String code) {
  final source = File('$dir/$code.dart').readAsStringSync();
  final match = RegExp(
    r"static const _es = Language\(\s*'es',\s*'((?:[^'\\]|\\.)*)'",
  ).firstMatch(source);
  if (match == null) throw StateError('No name for Spanish in $code.dart.');
  return _unescape(match[1]!);
}

String _unescape(String dart) =>
    dart.replaceAllMapped(RegExp(r'\\(.)'), (m) => m[1]!);

/// [text] as dart2js writes a string literal: in double quotes, with the
/// characters past ASCII escaped.
String _js(String text) {
  final b = StringBuffer('"');
  for (final rune in text.runes) {
    if (rune == 0x22 || rune == 0x5C) {
      b.write('\\${String.fromCharCode(rune)}');
    } else if (rune < 0x80) {
      b.writeCharCode(rune);
    } else if (rune < 0x100) {
      b.write('\\x${rune.toRadixString(16).padLeft(2, '0')}');
    } else if (rune < 0x10000) {
      b.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
    } else {
      final v = rune - 0x10000;
      b
        ..write('\\u${(0xD800 + (v >> 10)).toRadixString(16)}')
        ..write('\\u${(0xDC00 + (v & 0x3FF)).toRadixString(16)}');
    }
  }
  return (b..write('"')).toString();
}

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(0)} KB';
