import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A card's content can ask how much of its top-start corner the selection
// check takes, and start its first line past it.

const _rows = ['Alpha', 'Bravo', 'Cherry'];

/// What each card's content read, by row.
final _read = <String, Size>{};

/// A card's content: it records the room it is told, and is keyed so its
/// box can be found.
Widget _content(BuildContext context, String row) {
  _read[row] = CollectionCards.checkRoomOf(context);
  return SizedBox(key: ValueKey('content $row'), height: 80, child: Text(row));
}

Future<void> _pump(
  WidgetTester tester, {
  Set<String>? selected,
  ValueChanged<Set<String>>? onSelectionChanged,
  TextDirection direction = TextDirection.ltr,
  AdminTokens? tokens,
}) async {
  _read.clear();
  tester.view
    ..physicalSize = const Size(900, 600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? irisTheme.tokens),
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
          child: CollectionCards<String>(
            rows: _rows,
            cardBuilder: _content,
            selected: selected,
            onSelectionChanged: onSelectionChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Rect _box(WidgetTester tester, String row) =>
    tester.getRect(find.byKey(ValueKey('content $row')));

/// The chip the check of [row]'s card stands on.
Rect _chip(WidgetTester tester, String row) => tester
    .getRect(
      find.descendant(
        of: find
            .ancestor(
              of: find.byKey(ValueKey('content $row')),
              matching: find.byType(Stack),
            )
            .first,
        matching: find.byType(Check),
      ),
    )
    .inflate(3);

/// What [_Probe] read, each time it was built.
final _probed = <Size>[];

/// Content that reads its room and nothing else.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    _probed.add(CollectionCards.checkRoomOf(context));
    return const SizedBox(height: 80);
  }
}

/// How many cards show their check: each is drawn at full opacity or none.
int _checksUp(WidgetTester tester) {
  final checks = find.byType(Check);
  return [
    for (var i = 0; i < checks.evaluate().length; i++)
      tester.widget<Opacity>(
        find.ancestor(of: checks.at(i), matching: find.byType(Opacity)).first,
      ),
  ].where((reveal) => reveal.opacity == 1).length;
}

void main() {
  testWidgets('a card that can be selected tells its content the corner its '
      'check takes', (tester) async {
    await _pump(tester, selected: {'Alpha'}, onSelectionChanged: (_) {});
    // 8 from the card's edges, a 24px chip, and 8 after it.
    expect(_read, {for (final row in _rows) row: const Size(40, 40)});
  });

  testWidgets('the check stands in that corner, the space after it kept', (
    tester,
  ) async {
    await _pump(tester, selected: {'Alpha'}, onSelectionChanged: (_) {});
    final content = _box(tester, 'Alpha');
    final chip = _chip(tester, 'Alpha');
    final room = _read['Alpha']!;
    expect(chip.left - content.left, 8);
    expect(chip.top - content.top, 8);
    expect(content.left + room.width - chip.right, 8);
    expect(content.top + room.height - chip.bottom, 8);
  });

  testWidgets('right to left, the corner is the top-right one', (tester) async {
    await _pump(
      tester,
      selected: {'Alpha'},
      onSelectionChanged: (_) {},
      direction: TextDirection.rtl,
    );
    final content = _box(tester, 'Alpha');
    final chip = _chip(tester, 'Alpha');
    final room = _read['Alpha']!;
    expect(room, const Size(40, 40));
    expect(content.right - chip.right, 8);
    expect(chip.left - (content.right - room.width), 8);
  });

  testWidgets('it is the same whether the check shows or not', (tester) async {
    // Under a mouse, nothing selected and no pointer over a card: no check
    // is up.
    await _pump(tester, selected: const {}, onSelectionChanged: (_) {});
    expect(_checksUp(tester), 0);
    expect(_read['Bravo'], const Size(40, 40));

    // One selected: every card's check is up.
    await _pump(tester, selected: {'Alpha'}, onSelectionChanged: (_) {});
    expect(_checksUp(tester), 3);
    expect(_read['Bravo'], const Size(40, 40));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('a card that cannot be selected has no corner to keep clear', (
    tester,
  ) async {
    await _pump(tester);
    expect(_read, {for (final row in _rows) row: Size.zero});

    // With a selection to show and no way to change it, too.
    await _pump(tester, selected: {'Alpha'});
    expect(_read, {for (final row in _rows) row: Size.zero});
  });

  testWidgets('a card told it can be selected after all is built again', (
    tester,
  ) async {
    await _pump(tester);
    expect(_read['Alpha'], Size.zero);
    await _pump(tester, selected: const {}, onSelectionChanged: (_) {});
    expect(_read['Alpha'], const Size(40, 40));
    await _pump(tester);
    expect(_read['Alpha'], Size.zero);
  });

  testWidgets('content that nothing else changes is built again for it', (
    tester,
  ) async {
    final tokens = irisTheme.tokens;
    Future<void> pump({required double checkSize}) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          tokens.copyWith(
            selection: tokens.selection.copyWith(checkSize: checkSize),
          ),
        ),
        home: Scaffold(
          body: CollectionCards<String>(
            rows: const ['Alpha'],
            // The same widget each time: only what it depends on rebuilds it.
            cardBuilder: (_, _) => const _Probe(),
            selected: const {},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

    _probed.clear();
    await pump(checkSize: 18);
    await tester.pumpAndSettle();
    expect(_probed, [const Size(40, 40)]);
    // The theme eases from one to the other, and the content with it.
    await pump(checkSize: 22);
    await tester.pumpAndSettle();
    expect(_probed.first, const Size(40, 40));
    expect(_probed.last, const Size(44, 44));
    final built = _probed.length;
    await pump(checkSize: 22);
    await tester.pumpAndSettle();
    expect(_probed, hasLength(built), reason: 'and not when it is the same');
  });

  testWidgets("it follows the theme's check size", (tester) async {
    final tokens = irisTheme.tokens;
    await _pump(
      tester,
      selected: {'Alpha'},
      onSelectionChanged: (_) {},
      tokens: tokens.copyWith(
        selection: tokens.selection.copyWith(checkSize: 22),
      ),
    );
    // 8, a chip 6 wider than its 22px box, and 8.
    expect(_read['Alpha'], const Size(44, 44));
    final content = _box(tester, 'Alpha');
    final chip = _chip(tester, 'Alpha');
    expect(chip.width, 28);
    expect(content.left + 44 - chip.right, 8);
  });

  testWidgets('outside a card there is none', (tester) async {
    late Size read;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            read = CollectionCards.checkRoomOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, Size.zero);
  });

  testWidgets('a Collection shown as cards tells its cards too', (
    tester,
  ) async {
    final controller = CollectionController<String>(
      rowKey: (r) => r,
      searchDebounce: Duration.zero,
      initialQuery: const CollectionQuery(pageSize: 10),
      fetcher: (q) async => const CollectionPage(items: _rows, total: 3),
    );
    addTearDown(controller.dispose);
    _read.clear();
    Future<void> pump({required bool selectable}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: Scaffold(
            body: Collection<String>(
              controller: controller,
              columns: [
                TableColumn(id: 'name', label: 'Name', cell: (r) => Text(r)),
              ],
              viewMode: CollectionViewMode.cards,
              selectable: selectable,
              cardBuilder: _content,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(selectable: true);
    expect(_read['Alpha'], const Size(40, 40));
    await pump(selectable: false);
    expect(_read['Alpha'], Size.zero);
  });
}
