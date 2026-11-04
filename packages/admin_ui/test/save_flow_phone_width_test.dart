import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s light or dark tokens in the default type, so no font loads.
AdminTokens _tokens(AdminTheme theme, {bool dark = false}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
  );
}

/// [bar] alone in a window [width] wide, so the page gutter is the window's.
Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  required double width,
  AdminTokens? tokens,
  Locale locale = const Locale('en'),
}) {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? defaultTokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(body: Column(children: [bar])),
    ),
  );
}

/// Every slot of the bar filled: two icon actions, a widget of the caller's
/// own, an overflow menu, Discard, Save and a split Publish.
SaveBar _loaded({
  SaveState state = SaveState.unsaved,
  int invalidCount = 0,
  bool publishing = false,
  List<String>? log,
}) {
  void Function() record(String what) =>
      () => log?.add(what);
  return SaveBar(
    state: state,
    invalidCount: invalidCount,
    committing: publishing,
    leading: const Text('Edit page'),
    status: const Tag('Changed', severity: Severity.warning),
    actions: [
      IconAction(
        Icons.comment_outlined,
        label: 'Comments',
        onPressed: record('comments'),
      ),
      IconAction(
        Icons.history,
        label: 'Version history',
        danger: true,
        onPressed: record('history'),
      ),
    ],
    overflowActions: [
      SaveBarAction(label: 'Duplicate', onPressed: record('duplicate')),
      SaveBarAction(
        label: 'Delete page',
        danger: true,
        onPressed: record('delete'),
      ),
    ],
    onDiscard: record('discard'),
    onSave: record('save'),
    onCommit: record('publish'),
    commitMenu: [
      SaveBarAction(label: 'Schedule…', onPressed: record('schedule')),
    ],
  );
}

Future<void> _openMore(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz));
  await tester.pumpAndSettle();
}

/// The ⋯ menu's entries, top to bottom, with null for a divider.
List<String?> _moreEntries(WidgetTester tester) {
  final more = find.ancestor(
    of: find.byIcon(Icons.more_horiz),
    matching: find.byType(Menu),
  );
  return [
    for (final entry in tester.widget<Menu>(more.first).entries)
      entry is MenuItem ? entry.label : null,
  ];
}

MenuItem _moreItem(WidgetTester tester, String label) {
  final more = find.ancestor(
    of: find.byIcon(Icons.more_horiz),
    matching: find.byType(Menu),
  );
  return tester
      .widget<Menu>(more.first)
      .entries
      .whereType<MenuItem>()
      .firstWhere((item) => item.label == label);
}

void main() {
  group('a fully loaded bar never overflows at a phone’s width', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        final tokens = _tokens(theme, dark: dark);
        for (final locale in const [Locale('en'), Locale('fr')]) {
          final name =
              '${theme.name} ${dark ? 'dark' : 'light'} '
              '${locale.languageCode}';
          testWidgets('$name at 320, 360 and 400', (tester) async {
            for (final width in const [320.0, 360.0, 400.0]) {
              await _pump(
                tester,
                _loaded(),
                width: width,
                tokens: tokens,
                locale: locale,
              );
              expect(tester.takeException(), isNull, reason: '$width');
              final bar = tester.getRect(find.byType(SaveBar));
              final cluster = tester.getRect(find.byType(SaveCluster));
              expect(
                cluster.right,
                lessThanOrEqualTo(bar.right),
                reason: '$width',
              );
            }
          });
        }
      }
    }
  });

  group('below SaveBar.phoneWidth', () {
    testWidgets('the icon actions and Publish’s alternatives fold into ⋯, '
        'ahead of Discard and the overflow actions', (tester) async {
      await _pump(tester, _loaded(), width: 360);

      expect(find.byIcon(Icons.comment_outlined), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
      expect(find.byType(SplitButton), findsNothing);
      expect(find.widgetWithText(Button, 'Publish'), findsOneWidget);
      expect(find.widgetWithText(Button, 'Save'), findsOneWidget);

      expect(_moreEntries(tester), [
        'Comments',
        'Version history',
        null,
        'Discard',
        null,
        'Schedule…',
        null,
        'Duplicate',
        'Delete page',
      ]);
      await _openMore(tester);
      expect(find.text('Version history'), findsOneWidget);
      expect(find.text('Schedule…'), findsOneWidget);
    });

    for (final (label, callback) in const [
      ('Comments', 'comments'),
      ('Version history', 'history'),
      ('Schedule…', 'schedule'),
    ]) {
      testWidgets('a folded "$label" fires its callback', (tester) async {
        final log = <String>[];
        await _pump(tester, _loaded(log: log), width: 360);
        await _openMore(tester);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(log, [callback]);
      });
    }

    testWidgets('a folded icon action keeps its glyph and danger tint', (
      tester,
    ) async {
      await _pump(tester, _loaded(), width: 360);
      final item = _moreItem(tester, 'Version history');
      expect(item.danger, isTrue);
      expect(item.icon, Icons.history);
    });

    testWidgets('a widget of the caller’s own stays in the row', (
      tester,
    ) async {
      await _pump(
        tester,
        SaveBar(
          state: SaveState.unsaved,
          actions: [
            const Text('Mode'),
            IconAction(Icons.history, label: 'History', onPressed: () {}),
          ],
          onSave: () {},
        ),
        width: 360,
      );
      expect(find.text('Mode'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsNothing);
      await _openMore(tester);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('a toggle or a disclosure stays in the row', (tester) async {
      await _pump(
        tester,
        SaveBar(
          state: SaveState.unsaved,
          actions: [
            IconAction(
              Icons.comment_outlined,
              label: 'Comments',
              selected: true,
              onPressed: () {},
            ),
            IconAction(
              Icons.translate,
              label: 'Languages',
              expanded: false,
              onPressed: () {},
            ),
            IconAction(Icons.history, label: 'History', onPressed: () {}),
          ],
          onSave: () {},
        ),
        width: 360,
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.translate), findsOneWidget);
      expect(find.byIcon(Icons.history), findsNothing);
      expect(_moreEntries(tester), ['History']);
    });

    testWidgets('invalid edits disable Publish’s folded alternatives', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(tester, _loaded(invalidCount: 1, log: log), width: 360);
      expect(_moreItem(tester, 'Schedule…').onSelect, isNull);
      expect(_moreItem(tester, 'Discard').onSelect, isNotNull);
      await _openMore(tester);
      await tester.tap(find.text('Schedule…'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(log, isEmpty);
    });

    testWidgets('with room to spare, the labels keep their width', (
      tester,
    ) async {
      await _pump(tester, _loaded(), width: 400);
      final save = find.descendant(
        of: find.widgetWithText(Button, 'Save'),
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(save);
      expect(paragraph.didExceedMaxLines, isFalse);
    });
  });

  group('at 600 and wider nothing folds', () {
    for (final width in const [648.0, 900.0]) {
      testWidgets('a ${width.toInt()}-wide window', (tester) async {
        await _pump(tester, _loaded(), width: width);
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
        expect(find.byType(SplitButton), findsOneWidget);
        expect(find.widgetWithText(Button, 'Discard'), findsOneWidget);
        expect(find.text('Unsaved changes'), findsOneWidget);

        expect(_moreEntries(tester), ['Duplicate', 'Delete page']);
      });
    }

    testWidgets('the compact tier folds Discard alone', (tester) async {
      // 560 of bar inside the gutters: compact, not a phone's.
      await _pump(tester, _loaded(), width: 608);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byType(SplitButton), findsOneWidget);
      expect(_moreEntries(tester), [
        'Discard',
        null,
        'Duplicate',
        'Delete page',
      ]);
    });
  });
}
