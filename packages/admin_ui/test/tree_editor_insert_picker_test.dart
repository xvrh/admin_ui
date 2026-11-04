// The tree editor's badges, and the wording of the insert picker and the
// tree editor: neutral, unless the host names its own.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

Widget _host(Widget child, {AdminTokens? tokens}) => MaterialApp(
  theme: buildAppTheme(tokens ?? defaultTokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 520, child: child)),
  ),
);

const _entries = [
  InsertPickerEntry(id: 'hero', label: 'Hero', icon: Icons.view_day_outlined),
  InsertPickerEntry(id: 'quote', label: 'Quote', icon: Icons.format_quote),
];

/// The [Tag] each of [_badges] paints as: its severity's, or the primary
/// text colour for the emphasised one.
const _tags = <String, ({Severity? severity, bool primary})>{
  'entity': (severity: null, primary: true),
  'external': (severity: Severity.success, primary: false),
  'path': (severity: null, primary: false),
  'unpublished': (severity: Severity.warning, primary: false),
  'missing': (severity: Severity.danger, primary: false),
};

/// One badge per kind of link a menu editor shows.
const _badges = <String, TreeEntryBadge>{
  'entity': TreeEntryBadge(
    icon: Icons.description_outlined,
    label: 'entity',
    emphasised: true,
  ),
  'external': TreeEntryBadge(
    icon: Icons.open_in_new_rounded,
    label: 'external',
    tone: Severity.success,
  ),
  'path': TreeEntryBadge(icon: Icons.link_rounded, label: 'path'),
  'unpublished': TreeEntryBadge(
    icon: Icons.schedule_outlined,
    label: 'unpublished',
    tone: Severity.warning,
  ),
  'missing': TreeEntryBadge(
    icon: Icons.error_outline_rounded,
    label: 'missing',
    tone: Severity.danger,
  ),
};

/// The fill, label colour and icon colour of the [Tag] whose label is
/// [label].
(Color?, Color?, Color?) _paint(WidgetTester tester, Finder label) {
  final tag = find.ancestor(of: label, matching: find.byType(Tag));
  final box = tester.widget<Container>(
    find.descendant(of: tag, matching: find.byType(Container)).first,
  );
  final text = tester.widget<Text>(label);
  final icon = tester.widget<Icon>(
    find.descendant(of: tag, matching: find.byType(Icon)),
  );
  return (
    (box.decoration as BoxDecoration?)?.color,
    text.style?.color,
    icon.color,
  );
}

void main() {
  group('TreeEntryBadge paints as the Tag of its severity', () {
    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      testWidgets(name, (tester) async {
        final tokens = AdminTokens.from(palette: palette);
        await tester.pumpWidget(
          _host(
            tokens: tokens,
            Column(
              children: [
                TreeEditor(
                  entries: [
                    for (final MapEntry(key: id, value: badge)
                        in _badges.entries)
                      TreeEditorEntry(id: id, title: 'Row $id', badge: badge),
                  ],
                ),
                for (final MapEntry(key: id, value: tag) in _tags.entries)
                  Builder(
                    builder: (context) => Tag(
                      'tag $id',
                      icon: Icons.link_rounded,
                      severity: tag.severity,
                      color: tag.primary ? context.colors.primaryText : null,
                      variant: TagVariant.soft,
                    ),
                  ),
              ],
            ),
          ),
        );
        for (final id in _tags.keys) {
          // The badge isolates its label for right-to-left text.
          expect(
            _paint(tester, find.text('\u2068$id\u2069')),
            _paint(tester, find.text('tag $id')),
            reason: id,
          );
        }
      });
    }
  });

  testWidgets('InsertPicker.onSelect fires with the picked entry', (
    tester,
  ) async {
    InsertPickerEntry? picked;
    await tester.pumpWidget(
      _host(InsertPicker(entries: _entries, onSelect: (e) => picked = e)),
    );
    await tester.tap(find.text('Quote'));
    expect(picked?.id, 'quote');
  });

  testWidgets('InsertPicker words itself neutrally unless told otherwise', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(InsertPicker(entries: _entries, onSelect: (_) {})),
    );
    expect(find.text('Search…'), findsOneWidget);
    expect(find.bySemanticsLabel('Choices'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Nothing matches “zzz”'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        InsertPicker(
          key: const ValueKey('blocks'),
          entries: _entries,
          hint: 'Search blocks…',
          semanticLabel: 'Blocks',
          onSelect: (_) {},
        ),
      ),
    );
    expect(find.text('Search blocks…'), findsOneWidget);
    expect(find.bySemanticsLabel('Blocks'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('TreeEditor reads "Add item" and "Group" by default', (
    tester,
  ) async {
    const entries = [
      TreeEditorEntry(id: 'shop', title: 'Shop', isHeader: true),
    ];
    await tester.pumpWidget(
      _host(TreeEditor(entries: entries, onAddRoot: () {})),
    );
    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('Group'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        TreeEditor(
          entries: entries,
          onAddRoot: () {},
          addLabel: 'Add menu item',
          headerLabel: 'Section',
        ),
      ),
    );
    expect(find.text('Add menu item'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Add item'), findsNothing);
    expect(find.text('Group'), findsNothing);
  });

  test('the new strings are translated', () {
    const en = AdminLocalizationsEn();
    const fr = AdminLocalizationsFr();
    const ar = AdminLocalizationsAr();
    for (final (name, read) in <(String, String Function(DisplayMessages))>[
      ('addItem', (m) => m.addItem),
      ('treeHeader', (m) => m.treeHeader),
      ('nothingMatches', (m) => m.nothingMatches('hero')),
      ('choices', (m) => m.choices),
    ]) {
      final [e, f, a] = [
        for (final l in [en, fr, ar]) read(l.display),
      ];
      expect(e, isNotEmpty, reason: name);
      expect(f, isNot(e), reason: '$name in French');
      expect(a, isNot(e), reason: '$name in Arabic');
    }
    expect(en.display.nothingMatches('hero'), contains('hero'));
    expect(fr.display.nothingMatches('hero'), contains('hero'));
    expect(ar.display.nothingMatches('hero'), contains('hero'));
  });
}
