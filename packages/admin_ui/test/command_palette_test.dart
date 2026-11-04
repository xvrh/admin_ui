import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

PaletteItem _item(
  String title,
  String group,
  VoidCallback onSelect, {
  List<String> keywords = const [],
}) => PaletteItem(
  id: title,
  title: title,
  icon: Icons.circle_outlined,
  group: group,
  keywords: keywords,
  onSelect: onSelect,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 600,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: 480, child: child),
        ),
      ),
    ),
  );
  await tester.pump(); // settle autofocus
}

void main() {
  testWidgets('empty query shows the recents section', (tester) async {
    await _pump(
      tester,
      CommandPalette(
        items: const [],
        recent: [_item('About us', 'Pages', () {})],
      ),
    );
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('About us'), findsOneWidget);
  });

  testWidgets('typing fuzzy-filters the items', (tester) async {
    final items = [
      _item('New page', 'Commands', () {}),
      _item('Pricing', 'Pages', () {}),
      _item('Contact', 'Pages', () {}),
    ];
    await _pump(tester, CommandPalette(items: items));
    await tester.enterText(find.byType(TextField), 'pric');
    await tester.pumpAndSettle();
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('New page'), findsNothing);
    expect(find.text('Contact'), findsNothing);
  });

  testWidgets('Enter runs the top hit', (tester) async {
    String? ran;
    final items = [
      _item('New page', 'Commands', () => ran = 'New page'),
      _item('Pricing', 'Pages', () => ran = 'Pricing'),
    ];
    await _pump(tester, CommandPalette(items: items));
    await tester.enterText(find.byType(TextField), 'pric');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(ran, 'Pricing');
  });

  testWidgets('arrow keys move the selection before Enter', (tester) async {
    String? ran;
    await _pump(
      tester,
      CommandPalette(
        items: const [],
        recent: [
          _item('First', 'Recent', () => ran = 'first'),
          _item('Second', 'Recent', () => ran = 'second'),
        ],
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(ran, 'second');
  });

  testWidgets('matches keywords and groups under section headers', (
    tester,
  ) async {
    final items = [
      _item('Manage menus', 'Commands', () {}, keywords: ['navigation']),
      _item('Home', 'Pages', () {}),
    ];
    await _pump(
      tester,
      CommandPalette(items: items, groupOrder: const ['Commands', 'Pages']),
    );
    await tester.enterText(find.byType(TextField), 'navigation');
    await tester.pumpAndSettle();
    expect(find.text('Manage menus'), findsOneWidget); // matched via keyword
    expect(find.text('COMMANDS'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('shows a no-results message', (tester) async {
    await _pump(tester, CommandPalette(items: [_item('Home', 'Pages', () {})]));
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No results'), findsOneWidget);
  });

  PaletteItem contentHit() => PaletteItem(
    id: 'p1',
    title: 'Linen Blazer',
    icon: Icons.circle_outlined,
    group: 'Products',
    snippet: '…pure linen with a fringe…',
    snippetHighlights: const [6, 11],
    reason: 'Content',
    reasonIcon: Icons.notes_rounded,
    onSelect: () {},
  );

  testWidgets('a content hit shows its snippet and reason chip', (
    tester,
  ) async {
    await _pump(tester, CommandPalette(items: [contentHit()]));
    await tester.enterText(find.byType(TextField), 'linen');
    await tester.pumpAndSettle();
    expect(
      find.text('…pure linen with a fringe…', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('a name hit shows the chip but no snippet', (tester) async {
    final item = PaletteItem(
      id: 'p2',
      title: 'Linen Blazer',
      icon: Icons.circle_outlined,
      group: 'Products',
      subtitle: 'Matched in fr',
      reason: 'Name',
      onSelect: () {},
    );
    await _pump(tester, CommandPalette(items: [item]));
    await tester.enterText(find.byType(TextField), 'linen');
    await tester.pumpAndSettle();
    expect(find.text('Name'), findsOneWidget);
    expect(find.text(bidiIsolate('Matched in fr')), findsOneWidget);
  });

  testWidgets('preview pane shows the selected hit detail', (tester) async {
    await _pump(
      tester,
      CommandPalette(items: [contentHit()], preview: true),
      width: 760,
    );
    await tester.enterText(find.byType(TextField), 'linen');
    await tester.pumpAndSettle();
    expect(find.text('Matched in Content'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('showCommandPalette opens on the anchor; Enter activates and '
      'closes; Escape closes', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalAnchor(
            child: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showCommandPalette(
                    context,
                    items: [
                      _item('Manage pages', 'Commands', () => selected++),
                    ],
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pages');
    await tester.pumpAndSettle();
    expect(find.text('Manage pages'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.byType(CommandPalette), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsNothing);
  });

  testWidgets('section headers and the selected row read as text', (
    tester,
  ) async {
    const teal = Color(0xFF0D9488);
    final palette = irisDarkPalette.branded(teal);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: palette)),
        home: Scaffold(
          body: CommandPalette(
            items: [
              _item('Pricing', 'Pages', () {}),
              _item('Contact', 'Pages', () {}),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'pr');
    await tester.pumpAndSettle();

    final header = tester.widget<Text>(find.text('PAGES'));
    expect(header.style!.color, palette.foregroundMuted);

    // The top hit is selected: its glyph and matched letters use the
    // text-safe primary on the soft primary fill, the title stays foreground.
    final icon = tester.widget<Icon>(find.byIcon(Icons.circle_outlined).first);
    expect(icon.color, palette.primaryText);
    expect(
      contrastRatio(palette.primaryText, palette.primarySubtle),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(palette.foreground, palette.primarySubtle),
      greaterThanOrEqualTo(4.5),
    );
  });

  group('muted text on a selected or hovered row keeps 4.5:1', () {
    const brands = {
      'Default': null,
      'Crimson': Color(0xFFE11D48),
      'Violet': Color(0xFF7C3AED),
      'Teal': Color(0xFF0D9488),
      'Amber': Color(0xFFD97706),
    };
    final hits = [
      PaletteItem(
        id: 'pricing',
        title: 'Pricing',
        subtitle: '/pricing',
        icon: Icons.description_outlined,
        group: 'Pages',
        onSelect: () {},
      ),
      PaletteItem(
        id: 'returns',
        title: 'Returns',
        snippet: 'Items can be returned within 30 days.',
        snippetHighlights: const [13, 21],
        reason: 'Body',
        icon: Icons.description_outlined,
        group: 'Pages',
        onSelect: () {},
      ),
      PaletteItem(
        id: 'new',
        title: 'New page',
        shortcut: '⌘N',
        icon: Icons.note_add_outlined,
        group: 'Commands',
        onSelect: () {},
      ),
    ];
    for (final MapEntry(key: name, value: base) in shippedPalettes.entries) {
      for (final MapEntry(key: brand, value: seed) in brands.entries) {
        final p = seed == null ? base : base.branded(seed);
        testWidgets('$name · $brand', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(AdminTokens.from(palette: p)),
              home: Scaffold(
                body: SizedBox(
                  width: 600,
                  height: 480,
                  child: CommandPalette(items: const [], recent: hits),
                ),
              ),
            ),
          );
          await tester.pump();

          void expectReadable(Color color, String what) {
            for (final (fill, on) in [
              (p.primarySubtle, 'the selected row'),
              (p.listHighlight, 'the hovered row'),
            ]) {
              expect(
                contrastRatio(color, fill),
                greaterThanOrEqualTo(4.5),
                reason: '$what on $on',
              );
            }
          }

          // The page's path, on the selected first row.
          final subtitle = tester.widget<Text>(find.textContaining('/pricing'));
          expectReadable(subtitle.style!.color!, 'a subtitle');

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          final snippet = tester.widget<HighlightedText>(
            find.byType(HighlightedText),
          );
          expectReadable(snippet.style!.color!, 'a snippet');

          // The keycap and the reason chip carry their own background fill.
          for (final label in ['⌘N', 'Body']) {
            final chip = tester.widget<Text>(find.text(label));
            expect(
              contrastRatio(chip.style!.color!, p.background),
              greaterThanOrEqualTo(4.5),
              reason: label,
            );
          }
        });
      }
    }
  });

  testWidgets('CommandTrigger shows its hover on a Carbon light page', (
    tester,
  ) async {
    // Carbon's subtle border is the page colour: a hover drawn in it would
    // not show.
    const palette = carbonPalette;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: palette)),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 260, child: CommandTrigger(onTap: () {})),
          ),
        ),
      ),
    );
    Color? fill() =>
        (tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byType(CommandTrigger),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration)
            .color;
    expect(fill(), palette.background);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(
      location: tester.getCenter(find.byType(CommandTrigger)),
    );
    await tester.pump();
    expect(fill(), isNot(palette.background));
    expect(fill(), Color.alphaBlend(palette.hoverOverlay, palette.background));
  });

  testWidgets('the palette rounds like a menu, its rows like menu rows', (
    tester,
  ) async {
    // Material's radii tell the roles apart: 4dp menus, 28dp dialogs, 8dp
    // rows, 12dp controls.
    const radii = AdminRadii(
      radiusSmall: 8,
      radius: 12,
      radiusLarge: 16,
      radiusMenu: 4,
      radiusDialog: 28,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          AdminTokens.from(palette: materialPalette, radii: radii),
        ),
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 480,
            child: CommandPalette(
              items: const [],
              recent: [_item('Pricing', 'Pages', () {})],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final surface = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(CommandPalette),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      (surface.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(radii.radiusMenu),
    );
    final row = tester.widget<Container>(
      find
          .ancestor(of: find.text('Pricing'), matching: find.byType(Container))
          .first,
    );
    expect(
      (row.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(radii.radiusSmall),
    );
  });
}
