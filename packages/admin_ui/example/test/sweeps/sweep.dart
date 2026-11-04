import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/entries.dart';
import '../support/harness/harness.dart';

/// The tallest page a sweep lays out. A page is a lazy list, so what lies
/// past the surface is never built: this is tall enough for every page at
/// twice the text size.
const sweepMaxHeight = 8000.0;

/// Registers one test per [demoEntries] entry under each of the passes
/// [passes] gives it, named by label: the entry is pumped as `pumpEntry` does, the test fails on any exception or
/// overflow, [check] (when given) looks at the settled tree, and the demo is
/// then unmounted and its timers drained, which must throw nothing either.
///
/// [skipped] maps an entry's id to why it is not pumped. Nothing is skipped
/// silently: an entry is either there or pumped in every pass, and an id
/// there that names no entry fails.
void sweep({
  required Map<String, RenderConfig> Function(DemoEntry entry) passes,
  required Map<String, String> skipped,
  Future<void> Function(WidgetTester tester, DemoEntry entry)? check,
}) {
  final entries = demoEntries();

  test('every skipped id names a demo', () {
    final ids = {for (final entry in entries) entry.id};
    expect([
      for (final id in skipped.keys)
        if (!ids.contains(id)) id,
    ], isEmpty);
  });

  for (final entry in entries) {
    for (final MapEntry(key: pass, value: config) in passes(entry).entries) {
      final reason = skipped[entry.id];
      testWidgets(
        '${entry.id} · $pass${reason == null ? '' : ' (skipped: $reason)'}',
        skip: reason != null,
        (tester) async {
          await pumpClean(tester, entry, config);
          await check?.call(tester, entry);
          await unmountAndDrain(tester);
        },
      );
    }
  }
}

/// Pumps [entry] as `pumpEntry` does, and fails with the first error it
/// reported in full: for an overflow, that names the widget that made the
/// flex and where it is, which the exception alone does not. The report is
/// written as the error happens, while the widget is still mounted.
Future<void> pumpClean(
  WidgetTester tester,
  DemoEntry entry,
  RenderConfig config,
) async {
  final reports = <String>[];
  final handler = FlutterError.onError;
  FlutterError.onError = (details) {
    reports.add(details.toString());
    handler?.call(details);
  };
  try {
    await pumpEntry(tester, entry, config, maxHeight: sweepMaxHeight);
  } finally {
    FlutterError.onError = handler;
  }
  final error = tester.takeException();
  if (error == null) return;
  fail(
    reports.isEmpty
        ? '$error'
        : '${reports.length} error(s); the first:\n${reports.first}',
  );
}
