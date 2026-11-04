import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/entries.dart';
import '../support/harness/harness.dart';
import 'sweep.dart';

/// The demos pumped in every theme, light and dark, by id: the anatomy a
/// theme gives its controls, fields, overlays and frame.
const _everyTheme = [
  'Primitives / Button',
  'Preview / Control states',
  'Fields / Basic / Field heights',
  'Fields / Basic / Select / open',
  'Primitives / Tabs',
  'Primitives / Menu',
  'Primitives / Feedback / Modal',
  'Screens / Shell (app frame)',
];

/// Demos pumped in combinations besides their home one, by id: a layout one
/// theme's anatomy strains.
final _alsoIn = <String, List<RenderConfig>>{
  // M3's 360 drawer, the widest sidebar, which a narrow window narrows.
  'Preview / Shell (narrow window)': [
    RenderConfig.of('Material', ThemeMode.light),
  ],
};

/// Entries this sweep does not pump, by id, each with the reason and the line
/// a fix starts from.
const _skipped = <String, String>{};

/// Every demo in the themes the other sweeps leave out: each once in its
/// [homeCombo], so every theme and mode is pumped, and [_everyTheme] in all
/// 12. A demo must not throw or overflow in any of them.
void main() {
  sweep(
    passes: (entry) => {
      for (final config in [
        if (_everyTheme.contains(entry.id)) ...allCombos else homeCombo(entry),
        ...?_alsoIn[entry.id],
      ])
        '$config': config,
    },
    skipped: _skipped,
  );

  test('every theme and mode is the home of some demo', () {
    final used = {for (final entry in demoEntries()) homeCombo(entry)};
    expect([
      for (final combo in allCombos)
        if (!used.contains(combo)) '$combo',
    ], isEmpty);
  });

  test('every id this sweep names is a demo', () {
    final ids = {for (final entry in demoEntries()) entry.id};
    expect([
      for (final id in [..._everyTheme, ..._alsoIn.keys])
        if (!ids.contains(id)) id,
    ], isEmpty);
  });
}
