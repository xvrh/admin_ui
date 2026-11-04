import 'package:admin_ui/src/common/ui/tree_editor.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _badge = TreeEntryBadge(icon: Icons.link_rounded, label: '/about');

/// A menu the test can reorder: [move] applies [TreeEditor.onMove] the way a
/// host does, so the rows rebuild in their new places.
class _Menu {
  final entries = <TreeEditorEntry>[
    const TreeEditorEntry(id: 'home', title: 'Home', badge: _badge),
    const TreeEditorEntry(id: 'shop', title: 'Shop', isHeader: true),
    const TreeEditorEntry(id: 'new', parentId: 'shop', title: 'New arrivals'),
    const TreeEditorEntry(id: 'sale', parentId: 'shop', title: 'On sale'),
    const TreeEditorEntry(
      id: 'about',
      title: 'About us, with a much longer title than the others',
      badge: _badge,
    ),
  ];
  final moves = <(String, String?, int)>[];
  final deleted = <String>[];

  void move(String id, String? parent, int index) {
    moves.add((id, parent, index));
    final e = entries.firstWhere((e) => e.id == id);
    entries.remove(e);
    final moved = TreeEditorEntry(
      id: e.id,
      parentId: parent,
      title: e.title,
      isHeader: e.isHeader,
      badge: e.badge,
    );
    final siblings = entries.where((x) => x.parentId == parent).toList();
    if (index >= siblings.length) {
      final at = siblings.isEmpty
          ? entries.length
          : entries.indexOf(siblings.last) + 1;
      entries.insert(at, moved);
    } else {
      entries.insert(entries.indexOf(siblings[index]), moved);
    }
  }

  List<String?> parentsOf(List<String> ids) => [
    for (final id in ids) entries.firstWhere((e) => e.id == id).parentId,
  ];

  List<String> order(String? parent) => [
    for (final e in entries)
      if (e.parentId == parent) e.id,
  ];
}

Future<void> _pump(
  WidgetTester tester,
  _Menu menu, {
  String? selectedId,
  double width = 560,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: StatefulBuilder(
              builder: (context, setState) => TreeEditor(
                maxDepth: 2,
                entries: List.of(menu.entries),
                selectedId: selectedId,
                onMove: (id, parent, index) =>
                    setState(() => menu.move(id, parent, index)),
                onSelect: (_) {},
                onToggleVisible: (_) {},
                onAddChild: (_) {},
                onDelete: menu.deleted.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The focusable row carrying [title].
Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Focus)).first;

Future<void> _focusRow(WidgetTester tester, String title) async {
  Focus.of(tester.element(find.text(title))).requestFocus();
  await tester.pump();
}

Future<void> _alt(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every row ends its actions at the same x', (tester) async {
    await _pump(tester, _Menu());

    final eyes = find.byIcon(Icons.visibility_outlined);
    final more = find.byIcon(Icons.more_horiz_rounded);
    expect(eyes, findsNWidgets(5));
    expect(more, findsNWidgets(5));
    final eyeX = {
      for (final e in eyes.evaluate())
        tester.getCenter(find.byWidget(e.widget)).dx,
    };
    final moreX = {
      for (final e in more.evaluate())
        tester.getCenter(find.byWidget(e.widget)).dx,
    };
    expect(eyeX, hasLength(1), reason: 'eye x per row: $eyeX');
    expect(moreX, hasLength(1), reason: '⋯ x per row: $moreX');
    expect(moreX.single, greaterThan(eyeX.single));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden row actions take no taps and fall through to the row', (
    tester,
  ) async {
    final menu = _Menu();
    await _pump(tester, menu);

    final glyph = find.byIcon(Icons.delete_outline_rounded).first;
    await tester.tap(glyph, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(menu.deleted, isEmpty);

    // Under the pointer the same spot is the real Delete.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(glyph));
    await tester.pumpAndSettle();
    await tester.tap(glyph);
    await tester.pumpAndSettle();
    expect(menu.deleted, ['home']);
    await gesture.removePointer();
  });

  testWidgets('a selected row shows its actions for touch', (tester) async {
    final menu = _Menu();
    await _pump(tester, menu, selectedId: 'shop');

    final shopDelete = find.descendant(
      of: _row('Shop'),
      matching: find.byIcon(Icons.delete_outline_rounded),
    );
    await tester.tap(shopDelete);
    expect(menu.deleted, ['shop']);
  });

  testWidgets('hidden actions stay in the Tab order and show on focus', (
    tester,
  ) async {
    await _pump(tester, _Menu());

    double shown(String title) => tester
        .widget<AnimatedOpacity>(
          find
              .descendant(
                of: _row(title),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;

    expect(shown('Home'), 0);
    await _focusRow(tester, 'Home');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(shown('Home'), 1);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(
        of: find.byWidget(focused.widget),
        matching: find.byIcon(Icons.subdirectory_arrow_right_rounded),
      ),
      findsOneWidget,
      reason: 'Tab lands on Add child, the first of the revealed actions',
    );
  });

  testWidgets('Alt+arrows move, indent and outdent the focused row', (
    tester,
  ) async {
    final menu = _Menu();
    await _pump(tester, menu);

    await _focusRow(tester, 'On sale');
    await _alt(tester, LogicalKeyboardKey.arrowUp);
    expect(menu.order('shop'), ['sale', 'new']);

    await _alt(tester, LogicalKeyboardKey.arrowDown);
    expect(menu.order('shop'), ['new', 'sale']);

    // Out of Shop, just after it.
    await _alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(menu.order(null), ['home', 'shop', 'sale', 'about']);

    // Back under the row above it, at the end.
    await _alt(tester, LogicalKeyboardKey.arrowRight);
    expect(menu.order('shop'), ['new', 'sale']);

    // Focus rode along the whole way.
    expect(Focus.of(tester.element(find.text('On sale'))).hasFocus, isTrue);
    expect(menu.moves, hasLength(4));
  });

  testWidgets('moves that break the tree are not offered', (tester) async {
    final menu = _Menu();
    await _pump(tester, menu);

    // First among its siblings: no move up.
    await _focusRow(tester, 'Home');
    await _alt(tester, LogicalKeyboardKey.arrowUp);
    // Shop has children, and maxDepth 2 leaves no level for them.
    await _focusRow(tester, 'Shop');
    await _alt(tester, LogicalKeyboardKey.arrowRight);
    // A root has nothing to leave.
    await _alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(menu.moves, isEmpty);
    expect(menu.parentsOf(['shop', 'new']), [null, 'shop']);
  });

  testWidgets('the ⋯ menu offers every move and action', (tester) async {
    final menu = _Menu();
    await _pump(tester, menu);

    Future<void> open(String title) async {
      await tester.tap(
        find.descendant(
          of: _row(title),
          matching: find.byIcon(Icons.more_horiz_rounded),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open('Home');
    for (final item in [
      'Move up',
      'Move down',
      'Indent',
      'Outdent',
      'Add child',
      'Delete',
    ]) {
      expect(find.text(item), findsOneWidget, reason: item);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // A second-level row can't take children under maxDepth 2.
    await open('New arrivals');
    expect(find.text('Add child'), findsNothing);
    await tester.tap(find.text('Move down'));
    await tester.pumpAndSettle();
    expect(menu.order('shop'), ['sale', 'new']);
  });

  testWidgets('the drag grip reads at 3:1 on every shipped surface', (
    tester,
  ) async {
    await _pump(tester, _Menu());
    final grip = tester.widget<Icon>(
      find.byIcon(Icons.drag_indicator_rounded).first,
    );
    expect(grip.color, defaultTokens.palette.foregroundMuted);
    for (final theme in adminThemes) {
      for (final p in [theme.palette, theme.darkPalette!]) {
        expect(
          contrastRatio(p.foregroundMuted, p.surface),
          greaterThanOrEqualTo(3),
          reason: '${theme.name} ${p.brightness}',
        );
      }
    }
  });
}
