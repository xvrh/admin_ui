// Sizes, radii, spacing, motion and state washes come from the tokens, not
// from literals: a literal is right in one theme only (a 999 pill under
// Carbon's square corners, a 13px label beside a 14px Ant body, a 6% hover
// beside Material's 8%) and never follows reduced motion. Outside
// lib/src/theme/, which defines the tokens, the kit reads context.type,
// context.radii, AdminSpacing, context.motion, colors.stateLayer, … instead.
//
// A literal that is not a token's job — a hairline nudge that keeps content
// still as a border thickens, a glyph's optical size — is allowed where the
// line it is on, or the line above, says why:
//
//   // token-literal: the 1px border the padding sits inside
//   padding: EdgeInsets.symmetric(horizontal: sizes.fieldPaddingX - 1),
//
// For a call over several lines, a marker on any of its lines, or on the line
// above it, allows it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `// token-literal: <reason>`, reason and all.
final _marker = RegExp(r'//\s*token-literal:(.*)$');

/// A number in code: not part of a name, a member access or a hex literal,
/// and not a divisor — `(box - glyph) / 2` centres, it picks no size.
final _number = RegExp(
  r'(?<![\w$.])(?<!/\s*)(\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)(?![\w.])',
);

void main() {
  final files = _sources();

  test('every token-literal marker says why', () {
    final bare = [
      for (final file in files)
        for (final (i, line) in file.lines.indexed)
          if (_marker.firstMatch(line) case final m?)
            if (m[1]!.trim().isEmpty) '${file.path}:${i + 1}: ${line.trim()}',
    ];
    expect(bare, isEmpty, reason: 'give each marker its reason');
  });

  test('every token-literal marker allows a literal', () {
    final stale = <String>[];
    for (final file in files) {
      final sites = _find(file);
      for (final (i, line) in file.lines.indexed) {
        if (!_marker.hasMatch(line)) continue;
        final used = sites.any((s) => _covers(s, i + 1));
        if (!used) stale.add('${file.path}:${i + 1}: ${line.trim()}');
      }
    }
    expect(
      stale,
      isEmpty,
      reason: 'these markers allow nothing the rules report: drop them',
    );
  });

  test('lib/src takes sizes, radii, spacing, motion and washes from the '
      'tokens', () {
    final offenders = <String, List<String>>{};
    final byRule = <String, int>{};
    for (final file in files) {
      for (final site in _find(file)) {
        if (_allowed(file, site)) continue;
        (offenders[file.path] ??= []).add(
          '  ${site.line} [${site.rule}]: ${site.code}',
        );
        byRule.update(site.rule, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final paths = offenders.keys.toList()..sort();
    final count = offenders.values.fold(0, (sum, s) => sum + s.length);
    final listing = [
      for (final path in paths) ...[path, ...offenders[path]!],
    ].join('\n');
    final rules = [
      for (final MapEntry(:key, :value) in byRule.entries) '$key $value',
    ].join(', ');
    expect(
      count,
      0,
      reason:
          'read the token instead of a literal — context.type.<role> for '
          'fontSize, context.radii for a radius, AdminSpacing for insets and '
          'gaps, context.motion for a duration or a curve, the state layer '
          '(colors.hoverOverlay, colors.stateLayer.selected, …) for a wash — '
          'or mark a literal that is not a token\'s job with `// '
          'token-literal: <reason>` on its line or the line above. $count '
          'sites ($rules) in ${paths.length} files:\n$listing',
    );
  });
}

/// A Dart file under lib/src, outside lib/src/theme/.
class _Source {
  final String path;
  final List<String> lines;

  /// The file with comments and the insides of strings blanked out, so
  /// offsets and line breaks stay where they were.
  final String code;
  final List<int> _lineStarts;

  _Source(this.path, String text)
    : lines = text.split('\n'),
      code = _blank(text),
      _lineStarts = [
        0,
        for (final (i, c) in text.codeUnits.indexed)
          if (c == 0x0A) i + 1,
      ];

  /// The 1-based line of [offset].
  int lineOf(int offset) {
    var lo = 0, hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }
}

List<_Source> _sources() => [
  for (final entity in Directory('lib/src').listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart'))
      if (entity.path.replaceAll(r'\', '/') case final path
          when !path.startsWith('lib/src/theme/'))
        _Source(path, entity.readAsStringSync()),
]..sort((a, b) => a.path.compareTo(b.path));

/// A literal found by the rules, spanning lines [from] to [to].
typedef _Found = ({int from, int to, int line, String rule, String code});

bool _covers(_Found site, int markerLine) =>
    markerLine >= site.from - 1 && markerLine <= site.to;

/// Whether a marker with a reason sits on [site]'s lines or the line above.
bool _allowed(_Source file, _Found site) {
  for (var line = site.from - 1; line <= site.to; line++) {
    if (line < 1 || line > file.lines.length) continue;
    final m = _marker.firstMatch(file.lines[line - 1]);
    if (m != null && m[1]!.trim().isNotEmpty) return true;
  }
  return false;
}

/// Every literal the rules report in [file].
List<_Found> _find(_Source file) {
  final code = file.code;
  final out = <_Found>[];

  void report(String rule, int start, int end, int at) {
    out.add((
      from: file.lineOf(start),
      to: file.lineOf(end),
      line: file.lineOf(at),
      rule: rule,
      code: file.lines[file.lineOf(at) - 1].trim(),
    ));
  }

  /// The first nonzero number in code[start, end), or null.
  int? firstNumber(int start, int end) {
    for (final m in _number.allMatches(code.substring(start, end))) {
      if (double.parse(m[1]!) != 0) return start + m.start;
    }
    return null;
  }

  // (a) a fontSize that holds a number.
  for (final m in RegExp(r'\bfontSize\s*:').allMatches(code)) {
    final end = _argumentEnd(code, m.end);
    if (firstNumber(m.end, end) case final at?) {
      report('fontSize', m.start, end, at);
    }
  }

  // (f) a Duration built for an animation: passed as a duration (to an
  // AnimationController, an implicit animation, a route), set as one or
  // defaulted to one, kept in a private `_…Duration`, or handed to
  // motionDuration. A timer — a debounce, a hover delay, a toast's dwell —
  // goes by another name.
  for (final m in RegExp(
    r'\b(?:duration|reverseDuration|transitionDuration)\s*(?::|=(?![=>]))|'
    r'\b_\w*Duration\s*=(?![=>])|\bmotionDuration\(',
  ).allMatches(code)) {
    final end = m[0]!.endsWith('(')
        ? _closing(code, m.end - 1)
        : _argumentEnd(code, m.end);
    final literal = RegExp(r'\bDuration\(')
        .firstMatch(code.substring(m.end, end));
    if (literal == null) continue;
    final at = m.end + literal.start;
    if (out.any((s) => s.rule == 'duration' && s.line == file.lineOf(at))) {
      continue;
    }
    report('duration', m.start, end, at);
  }

  // (b) radii, (c) insets, (d) gaps: a call whose arguments hold a number.
  for (final m in RegExp(
    r'\b(?:(?:BorderRadius|Radius)\.circular|'
    r'EdgeInsets\.(?:all|symmetric|only|fromLTRB|fromSTEB)|'
    r'EdgeInsetsDirectional\.\w+|Gap)\(',
  ).allMatches(code)) {
    final open = m.end - 1;
    final close = _closing(code, open);
    final at = firstNumber(open + 1, close);
    if (at == null) continue;
    final name = m[0]!;
    final rule = name.startsWith('Gap')
        ? 'gap'
        : name.contains('Radius')
        ? 'radius'
        : 'insets';
    // Radius.circular inside BorderRadius.circular is one site.
    if (rule == 'radius' &&
        out.any((s) => s.rule == 'radius' && s.line == file.lineOf(at))) {
      continue;
    }
    report(rule, m.start, close, at);
  }

  // (d) a SizedBox that is only a width or a height of 32 or less: a gap.
  for (final m in RegExp(r'\bSizedBox\(').allMatches(code)) {
    final open = m.end - 1;
    final close = _closing(code, open);
    final args = _namedArguments(code.substring(open + 1, close));
    final keys = args.keys.toSet()..remove('key');
    if (keys.length != 1 ||
        !(keys.contains('width') || keys.contains('height'))) {
      continue;
    }
    final value = double.tryParse(args[keys.single]!.trim());
    if (value == null || value == 0 || value > 32) continue;
    report('gap', m.start, close, m.start);
  }

  // (e) a curve.
  for (final m in RegExp(r'\bCurves\.\w+').allMatches(code)) {
    report('curve', m.start, m.end, m.start);
  }

  // (g) an opacity: a colour taken to a literal alpha, other than none or
  // all of it. A state's wash is the state layer's (colors.hoverOverlay,
  // colors.stateLayer.selected, …); a scrim, a shadow or a gradient's stop
  // says why it is its own.
  for (final m in RegExp(
    r'\.(?:withValues\(\s*alpha\s*:|withAlpha\(|withOpacity\()',
  ).allMatches(code)) {
    final open = code.lastIndexOf('(', m.end - 1);
    final end = _argumentEnd(code, m.end);
    final literal = _number.firstMatch(code.substring(m.end, end));
    if (literal == null) continue;
    final value = double.parse(literal[1]!);
    final full = m[0]!.contains('withAlpha') ? 255 : 1;
    if (value == 0 || value == full) continue;
    // Only a literal that is the whole argument: `alpha: 0.5` or
    // `alpha: dark ? 0.4 : 0.2`, not `alpha: layer.hover * 2`.
    report('alpha', open, end, m.end + literal.start);
  }

  out.sort((a, b) => a.line.compareTo(b.line));
  return out;
}

/// The offset of the bracket that closes the one at [open], or the end.
int _closing(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    switch (code[i]) {
      case '(' || '[' || '{':
        depth++;
      case ')' || ']' || '}':
        depth--;
        if (depth == 0) return i;
    }
  }
  return code.length;
}

/// Where the expression that starts at [start] ends: the first comma or
/// semicolon, or closing bracket, outside any brackets it opens.
int _argumentEnd(String code, int start) {
  var depth = 0;
  for (var i = start; i < code.length; i++) {
    final c = code[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return i;
      depth--;
    } else if (depth == 0 && (c == ',' || c == ';')) {
      return i;
    }
  }
  return code.length;
}

/// The named arguments of an argument list, name to expression; positional
/// ones are left out.
Map<String, String> _namedArguments(String args) {
  final out = <String, String>{};
  var start = 0;
  while (start < args.length) {
    final end = _argumentEnd(args, start);
    final arg = args.substring(start, end);
    if (RegExp(r'^\s*(\w+)\s*:(?!:)([\s\S]*)$').firstMatch(arg) case final m?) {
      out[m[1]!] = m[2]!;
    }
    start = end + 1;
  }
  return out;
}

/// [text] with every comment and the inside of every string replaced by
/// spaces, line breaks kept: what is left is code, at its own offsets.
String _blank(String text) {
  final out = StringBuffer();
  var i = 0;
  void blankTo(int stop) {
    for (; i < stop; i++) {
      out.write(text[i] == '\n' ? '\n' : ' ');
    }
  }

  while (i < text.length) {
    if (text.startsWith('//', i)) {
      final end = text.indexOf('\n', i);
      blankTo(end == -1 ? text.length : end);
    } else if (text.startsWith('/*', i)) {
      final end = text.indexOf('*/', i + 2);
      blankTo(end == -1 ? text.length : end + 2);
    } else if (text[i] == "'" || text[i] == '"') {
      final quote = text[i];
      final raw = i > 0 && text[i - 1] == 'r';
      final delimiter = text.startsWith(quote * 3, i) ? quote * 3 : quote;
      out.write(delimiter);
      i += delimiter.length;
      while (i < text.length && !text.startsWith(delimiter, i)) {
        if (delimiter.length == 1 && text[i] == '\n') break;
        if (!raw && text[i] == r'\' && i + 1 < text.length) {
          blankTo(i + 2);
        } else {
          blankTo(i + 1);
        }
      }
      if (text.startsWith(delimiter, i)) {
        out.write(delimiter);
        i += delimiter.length;
      }
    } else {
      out.write(text[i]);
      i++;
    }
  }
  return out.toString();
}
