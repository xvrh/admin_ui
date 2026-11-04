import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui_example/src/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/entries.dart';
import 'support/harness/harness.dart';

/// The sweeps pump [demoEntries]: every catalog page and every
/// `@Preview` the catalog leaves out. This fails when a preview is in
/// neither, so a new demo cannot go untested unnoticed. It also holds the
/// harness's naming and hashing to their contracts.
void main() {
  entriesGuard(
    catalog: catalogEntries,
    previewOnly: previewOnly,
    entries: demoEntries,
    catalogFile: 'lib/src/catalog.dart',
    catalogStart: 'genericCatalog() =>',
    minPreviews: 100,
    knownPreview: 'ShellDemo.narrow',
  );

  test('Labs is the last group, apart from what the kit ships', () {
    expect(genericCatalog().keys.last, 'Labs');
    final labs = [
      for (final entry in demoEntries())
        if (entry.id.startsWith('Labs / ')) entry.id,
    ];
    expect(labs, isNotEmpty);
    expect(
      [
        for (final entry in demoEntries())
          if (RegExp(
                r'\b(lab|prototype|spike|slice \d+)\b',
                caseSensitive: false,
              ).hasMatch(entry.id) &&
              !labs.contains(entry.id))
            entry.id,
      ],
      isEmpty,
      reason: 'a demo outside Labs is labelled as a prototype',
    );
  });

  test('themeNames follows adminThemes', () {
    expect(themeNames, [for (final theme in adminThemes) theme.name]);
    expect(allCombos, hasLength(12));
  });

  test('stableIndex is FNV-1a, independent of the list', () {
    // Reference values of 32-bit FNV-1a.
    expect(stableIndex('', 1 << 32), 0x811c9dc5);
    expect(stableIndex('a', 1 << 32), 0xe40c292c);
    expect(stableIndex('foobar', 1 << 32), 0xbf9cf968);
    for (final entry in demoEntries()) {
      expect(stableIndex(entry.id, 12), inInclusiveRange(0, 11));
    }
    final spread = {for (final e in demoEntries()) stableIndex(e.id, 12)};
    expect(spread, hasLength(12), reason: 'every combination gets an entry');
  });
}
