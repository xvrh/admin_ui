// Regenerates the summary table at the top of FRICTION.md from its entries.
//
//   fvm dart run tool/friction_summary.dart [--check]
//
// test/unit/guards_test.dart reads the entries through [readFriction].

import 'dart:io';

/// One `### F-NNN · claim` (or `T-NNN`) entry of FRICTION.md.
class FrictionEntry {
  final String id;
  final String claim;
  final String kind;
  final String severity;

  /// The status as written, e.g. `open (verified in source)`.
  final String status;

  /// Where the claim shows: a scenario and shot, or a step address.
  final String evidence;

  const FrictionEntry({
    required this.id,
    required this.claim,
    required this.kind,
    required this.severity,
    required this.status,
    required this.evidence,
  });

  /// The status's first word: open, suspected, fixed, …: what the guards
  /// check.
  String get state => status.split(RegExp(r'[\s(]')).first.toLowerCase();

  /// The status as the summary table shows it: up to its parenthesis
  /// (`not reproduced`, `kit PR #12`), and a fix keeps its PR number
  /// (`fixed (#12)`).
  String get shownStatus {
    final head = status.split('(').first.trim();
    if (state != 'fixed') return head;
    final pr = RegExp(r'#\d+').firstMatch(status)?[0];
    return pr == null ? head : '$head ($pr)';
  }

  /// S1, S2 or S3.
  String get level => severity.split(RegExp(r'\s')).first;
}

final _heading = RegExp(r'^### ([FT]-\d{3}) · (.+)$');
final _field = RegExp(r'^- \*\*(Kind|Severity|Status|Evidence):\*\* (.+)$');

List<FrictionEntry> readFriction(String markdown) {
  final entries = <FrictionEntry>[];
  String? id;
  String? claim;
  final fields = <String, String>{};
  void flush() {
    if (id == null) return;
    entries.add(
      FrictionEntry(
        id: id!,
        claim: claim!,
        kind: fields['Kind'] ?? '',
        severity: fields['Severity'] ?? '',
        status: fields['Status'] ?? '',
        evidence: fields['Evidence'] ?? '',
      ),
    );
    id = null;
    fields.clear();
  }

  for (final line in markdown.split('\n')) {
    final heading = _heading.firstMatch(line);
    if (heading != null) {
      flush();
      id = heading[1];
      claim = heading[2];
      continue;
    }
    if (line.startsWith('## ')) flush();
    final field = _field.firstMatch(line);
    if (field != null && id != null) fields[field[1]!] = field[2]!;
  }
  flush();
  return entries;
}

String summaryTable(List<FrictionEntry> entries) {
  final sorted = [...entries]
    ..sort((a, b) {
      final byPrefix = a.id[0].compareTo(b.id[0]);
      return byPrefix != 0 ? byPrefix : a.id.compareTo(b.id);
    });
  return [
    '| Id | Claim | Kind | Severity | Status |',
    '|---|---|---|---|---|',
    for (final e in sorted)
      [
        '',
        e.id,
        e.claim.replaceAll('|', r'\|'),
        e.kind,
        e.level,
        e.shownStatus,
        '',
      ].join(' | ').trim(),
  ].join('\n');
}

const _start = '<!-- summary:start -->';
const _end = '<!-- summary:end -->';

/// [markdown] with its summary table rebuilt from its entries.
String withSummary(String markdown) {
  final start = markdown.indexOf(_start);
  final end = markdown.indexOf(_end);
  if (start < 0 || end < start) {
    throw const FormatException('FRICTION.md has no summary markers');
  }
  return '${markdown.substring(0, start + _start.length)}\n'
      '${summaryTable(readFriction(markdown))}\n'
      '${markdown.substring(end)}';
}

void main(List<String> args) {
  final file = File('FRICTION.md');
  final before = file.readAsStringSync();
  final after = withSummary(before);
  if (args.contains('--check')) {
    if (before != after) {
      stderr.writeln(
        'FRICTION.md summary is stale: run tool/friction_summary.dart',
      );
      exitCode = 1;
    }
    return;
  }
  file.writeAsStringSync(after);
  stdout.writeln('${readFriction(after).length} entries summarised');
}
