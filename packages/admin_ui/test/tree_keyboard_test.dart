// A Tree operates its rows without a pointer: one Tab stop, the arrow keys
// between rows, and with onMove the Alt+arrow moves and a ⋯ menu on each
// row, so a move never needs a drag.

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/tree.dart' show flattenTree;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _tree = [
  TreeNode(id: 'm1'),
  TreeNode(
    id: 'm2',
    children: [
      TreeNode(id: 'm2a'),
      TreeNode(id: 'm2b'),
    ],
  ),
  TreeNode(id: 'm3'),
];

/// A tree the test can reorder: [move] applies [Tree.onMove] as a host
/// does, so the rows rebuild in their new places.
class _Model {
  _Model([this.roots = _tree]);

  List<TreeNode> roots;
  final moves = <(String, String?, int)>[];

  void move(String id, String? parent, int index) {
    moves.add((id, parent, index));
    late TreeNode moved;
    List<TreeNode> without(List<TreeNode> nodes) => [
      for (final node in nodes)
        if (node.id == id)
          ...() {
            moved = node;
            return const <TreeNode>[];
          }()
        else
          TreeNode(id: node.id, children: without(node.children)),
    ];
    List<TreeNode> placed(List<TreeNode> nodes, String? under) => [
      if (under == parent)
        ...[
          ...nodes.take(index),
          moved,
          ...nodes.skip(index),
        ].map((n) => TreeNode(id: n.id, children: placed(n.children, n.id)))
      else
        for (final node in nodes)
          TreeNode(id: node.id, children: placed(node.children, node.id)),
    ];
    roots = placed(without(roots), null);
  }

  /// The ids in order, each after its depth: "0 m1, 0 m2, 1 m2a".
  String get outline =>
      [for (final row in flattenTree(roots)) '${row.depth} ${row.id}']
          .join(', ');
}

Future<void> _pump(
  WidgetTester tester, {
  _Model? model,
  bool movable = true,
  int? maxDepth,
  double? maxHeight,
  Set<String> collapsed = const {},
  TextDirection direction = TextDirection.ltr,
}) async {
  final tree = model ?? _Model();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Button('Before', onPressed: _noop),
                  StatefulBuilder(
                    builder: (context, setState) => Tree(
                      roots: tree.roots,
                      maxDepth: maxDepth,
                      maxHeight: maxHeight,
                      initiallyCollapsed: collapsed,
                      onMove: movable
                          ? (id, parent, index) =>
                                setState(() => tree.move(id, parent, index))
                          : null,
                      itemBuilder: (_, id, _) => Text(id),
                    ),
                  ),
                  const Button('After', onPressed: _noop),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop() {}

/// What holds focus: a row's id, or a control's accessible name.
String _focused(WidgetTester tester) {
  final node = FocusManager.instance.primaryFocus!;
  final here = find.byElementPredicate((e) => e == node.context);
  if (node.debugLabel == 'tree row') {
    final text = find.descendant(of: here, matching: find.byType(Text));
    return 'row ${tester.widget<Text>(text.first).data}';
  }
  return tester.getSemantics(here).label;
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool alt = false,
  bool shift = false,
}) async {
  if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pumpAndSettle();
}

/// Tabs from the top of the page onto the tree's row.
Future<void> _enter(WidgetTester tester) async {
  await _press(tester, LogicalKeyboardKey.tab);
  await _press(tester, LogicalKeyboardKey.tab);
}

/// The ⋯ menu of the row [id].
Finder _menuOf(String id) => find.descendant(
  of: find.byKey(ValueKey('tree-row-$id')),
  matching: find.byIcon(Icons.more_horiz_rounded),
);

/// What the app tells a screen reader, as it says it.
List<String> _announcements(WidgetTester tester) {
  final announced = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      final data = (message! as Map)['data'] as Map;
      announced.add(data['message'] as String);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return announced;
}

void main() {
  group('focus', () {
    testWidgets('the tree is one Tab stop, then the focused row\'s menu', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      final seen = <String>[];
      for (var i = 0; i < 4; i++) {
        await _press(tester, LogicalKeyboardKey.tab);
        seen.add(_focused(tester));
      }
      expect(seen, ['Before', 'row m1', 'More actions', 'After']);

      seen.clear();
      for (var i = 0; i < 3; i++) {
        await _press(tester, LogicalKeyboardKey.tab, shift: true);
        seen.add(_focused(tester));
      }
      expect(seen, ['More actions', 'row m1', 'Before']);
      handle.dispose();
    });

    testWidgets('a read-only tree is the one stop, with no menu', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, movable: false);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
      await _enter(tester);
      expect(_focused(tester), 'row m1');
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'After');
      handle.dispose();
    });

    testWidgets('Tab comes back to the row that held focus last', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, movable: false);
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'row m2a');

      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'After');
      await _press(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_focused(tester), 'row m2a');
      handle.dispose();
    });

    testWidgets('a caret clicked on another row leaves the Tab stop on the '
        'row that holds focus', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _enter(tester);
      expect(_focused(tester), 'row m1');

      // The mouse closes m2 while the keyboard is on m1.
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('m2a'), findsNothing);
      expect(_focused(tester), 'row m1');

      // m1 is the Tab stop still: Tab goes on to its own menu.
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'More actions');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tree-row-m1')),
          matching: find.byElementPredicate(
            (e) => e == FocusManager.instance.primaryFocus!.context,
          ),
        ),
        findsOneWidget,
      );
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'After');
      await _press(tester, LogicalKeyboardKey.tab, shift: true);
      await _press(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_focused(tester), 'row m1');
      handle.dispose();
    });

    testWidgets('a parent closed over the Tab stop, with focus out of the '
        'tree, is the stop', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, movable: false);
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'After');

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('m2a'), findsNothing);
      expect(_focused(tester), 'After');
      await _press(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_focused(tester), 'row m2');
      handle.dispose();
    });

    testWidgets('the focused row shows the ring inside its edge, on '
        'keyboard focus', (tester) async {
      Finder ring() => find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border is Border &&
            ((w.decoration as BoxDecoration).border! as Border).top.color ==
                defaultTokens.palette.focusRing,
      );
      await _pump(tester);
      expect(ring(), findsNothing);
      await _enter(tester);
      expect(
        tester.getRect(ring()),
        tester.getRect(find.byKey(const ValueKey('tree-row-m1'))),
      );
      // The menu inside the row rings itself, not the row.
      await _press(tester, LogicalKeyboardKey.tab);
      expect(
        tester.getRect(ring()),
        isNot(tester.getRect(find.byKey(const ValueKey('tree-row-m1')))),
      );
    });

    testWidgets('a row the arrows reach scrolls into view', (tester) async {
      final model = _Model([for (var i = 0; i < 20; i++) TreeNode(id: 'n$i')]);
      await _pump(tester, model: model, movable: false, maxHeight: 132);
      await _enter(tester);
      expect(find.text('n19').hitTestable(), findsNothing);

      await _press(tester, LogicalKeyboardKey.end);
      expect(_focused(tester), 'row n19');
      expect(find.text('n19').hitTestable(), findsOneWidget);
      await _press(tester, LogicalKeyboardKey.home);
      expect(_focused(tester), 'row n0');
      expect(find.text('n0').hitTestable(), findsOneWidget);
    });
  });

  group('arrow keys', () {
    testWidgets('↑ and ↓ move between the rows on screen, Home and End go '
        'to the ends', (tester) async {
      await _pump(tester, collapsed: const {'m2'});
      await _enter(tester);

      final seen = <String>[];
      for (final key in [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
        LogicalKeyboardKey.arrowUp,
      ]) {
        await _press(tester, key);
        seen.add(_focused(tester));
      }
      // The children of the closed m2 are not rows to stop on.
      expect(seen, [
        'row m1',
        'row m2',
        'row m3',
        'row m3',
        'row m1',
        'row m3',
        'row m2',
      ]);
    });

    for (final direction in TextDirection.values) {
      final rtl = direction == TextDirection.rtl;
      final inward = rtl
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight;
      final outward = rtl
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft;
      testWidgets('${rtl ? '←' : '→'} opens a parent, then goes to its first '
          'child; ${rtl ? '→' : '←'} goes to the parent, then closes it '
          '($direction)', (tester) async {
        await _pump(tester, collapsed: const {'m2'}, direction: direction);
        await _enter(tester);
        await _press(tester, LogicalKeyboardKey.arrowDown);

        await _press(tester, inward);
        expect(find.text('m2a'), findsOneWidget);
        expect(_focused(tester), 'row m2');
        await _press(tester, inward);
        expect(_focused(tester), 'row m2a');
        // A leaf has nothing to open.
        await _press(tester, inward);
        expect(_focused(tester), 'row m2a');

        await _press(tester, outward);
        expect(_focused(tester), 'row m2');
        await _press(tester, outward);
        expect(find.text('m2a'), findsNothing);
        expect(_focused(tester), 'row m2');
        // A root has no parent to go to.
        await _press(tester, outward);
        expect(_focused(tester), 'row m2');
      });
    }

    testWidgets('Enter and Space open and close a parent', (tester) async {
      await _pump(tester);
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.arrowDown);

      await _press(tester, LogicalKeyboardKey.enter);
      expect(find.text('m2a'), findsNothing);
      await _press(tester, LogicalKeyboardKey.space);
      expect(find.text('m2a'), findsOneWidget);
      expect(_focused(tester), 'row m2');
    });

    testWidgets('a parent closed over the focused row takes the focus', (
      tester,
    ) async {
      await _pump(tester);
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'row m2a');

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('m2a'), findsNothing);
      expect(_focused(tester), 'row m2');
    });
  });

  group('moves without a drag', () {
    testWidgets('Alt+↑ and Alt+↓ move the row among its siblings; focus '
        'stays on it and a screen reader hears it', (tester) async {
      final announced = _announcements(tester);
      final model = _Model();
      await _pump(tester, model: model);
      await _enter(tester);

      await _press(tester, LogicalKeyboardKey.arrowDown, alt: true);
      expect(model.moves, [('m1', null, 1)]);
      expect(model.outline, '0 m2, 1 m2a, 1 m2b, 0 m1, 0 m3');
      expect(_focused(tester), 'row m1');

      await _press(tester, LogicalKeyboardKey.arrowUp, alt: true);
      expect(model.outline, '0 m1, 0 m2, 1 m2a, 1 m2b, 0 m3');
      expect(_focused(tester), 'row m1');
      expect(announced, ['Moved down', 'Moved up']);

      // The first row has no place above it: the key is the tree's still.
      await _press(tester, LogicalKeyboardKey.arrowUp, alt: true);
      expect(model.moves, hasLength(2));
      expect(announced, hasLength(2));
    });

    for (final direction in TextDirection.values) {
      final rtl = direction == TextDirection.rtl;
      final inward = rtl
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight;
      final outward = rtl
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft;
      testWidgets('Alt+${rtl ? '←' : '→'} nests the row under the sibling '
          'above, Alt+${rtl ? '→' : '←'} takes it out ($direction)', (
        tester,
      ) async {
        final announced = _announcements(tester);
        final model = _Model();
        await _pump(tester, model: model, direction: direction);
        await _enter(tester);
        await _press(tester, LogicalKeyboardKey.end);

        await _press(tester, inward, alt: true);
        expect(model.moves.last, ('m3', 'm2', 2));
        expect(model.outline, '0 m1, 0 m2, 1 m2a, 1 m2b, 1 m3');
        expect(_focused(tester), 'row m3');

        await _press(tester, outward, alt: true);
        expect(model.moves.last, ('m3', null, 2));
        expect(model.outline, '0 m1, 0 m2, 1 m2a, 1 m2b, 0 m3');
        expect(_focused(tester), 'row m3');
        expect(announced, ['Indented', 'Outdented']);
      });
    }

    testWidgets('a row nested under a closed parent opens it', (tester) async {
      final model = _Model();
      await _pump(tester, model: model, collapsed: const {'m2'});
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.end);
      await _press(tester, LogicalKeyboardKey.arrowRight, alt: true);
      expect(model.outline, '0 m1, 0 m2, 1 m2a, 1 m2b, 1 m3');
      expect(find.text('m2a'), findsOneWidget);
      expect(_focused(tester), 'row m3');
    });

    testWidgets('maxDepth stops a nesting that would pass it', (tester) async {
      final model = _Model();
      await _pump(tester, model: model, maxDepth: 1);
      await _enter(tester);
      // m2 would take its children to a third level.
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowRight, alt: true);
      expect(model.moves, isEmpty);
      // m3, a leaf, nests.
      await _press(tester, LogicalKeyboardKey.end);
      await _press(tester, LogicalKeyboardKey.arrowRight, alt: true);
      expect(model.moves, [('m3', 'm2', 2)]);
      // And goes no deeper.
      await _press(tester, LogicalKeyboardKey.arrowRight, alt: true);
      expect(model.moves, hasLength(1));
    });

    testWidgets('a host that reorders its own list in place gets the next '
        'move from the list as it is', (tester) async {
      final roots = [
        const TreeNode(id: 'a'),
        const TreeNode(id: 'b'),
        const TreeNode(id: 'c'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, setState) => Tree(
                  roots: roots,
                  onMove: (id, parent, index) => setState(() {
                    final node = roots.removeAt(
                      roots.indexWhere((n) => n.id == id),
                    );
                    roots.insert(index, node);
                  }),
                  itemBuilder: (_, id, _) => Text(id),
                ),
              ),
            ),
          ),
        ),
      );
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'row a');

      await _press(tester, LogicalKeyboardKey.arrowDown, alt: true);
      expect([for (final node in roots) node.id], ['b', 'a', 'c']);
      await _press(tester, LogicalKeyboardKey.arrowDown, alt: true);
      expect([for (final node in roots) node.id], ['b', 'c', 'a']);
      // The last row has no place below it.
      await _press(tester, LogicalKeyboardKey.arrowDown, alt: true);
      expect([for (final node in roots) node.id], ['b', 'c', 'a']);
      await _press(tester, LogicalKeyboardKey.arrowUp, alt: true);
      expect([for (final node in roots) node.id], ['b', 'a', 'c']);
    });

    testWidgets('each row ends in a menu of the moves, each beside its key', (
      tester,
    ) async {
      final announced = _announcements(tester);
      final model = _Model();
      await _pump(tester, model: model);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(5));

      await tester.tap(_menuOf('m3'));
      await tester.pumpAndSettle();
      for (final item in ['Move up', 'Move down', 'Indent', 'Outdent']) {
        expect(find.text(item), findsOneWidget);
      }
      expect(find.textContaining('↑'), findsOneWidget);
      expect(find.textContaining('→'), findsOneWidget);

      await tester.tap(find.text('Indent'));
      await tester.pumpAndSettle();
      expect(model.moves, [('m3', 'm2', 2)]);
      expect(announced, ['Indented']);

      await tester.tap(_menuOf('m3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move up'));
      await tester.pumpAndSettle();
      expect(model.outline, '0 m1, 0 m2, 1 m2a, 1 m3, 1 m2b');

      // The last root has no place below it, and no parent to leave.
      await tester.tap(_menuOf('m2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move down'));
      await tester.tap(find.text('Outdent'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(model.moves, hasLength(2));
    });

    testWidgets('without onMove the move keys are not the tree\'s', (
      tester,
    ) async {
      final model = _Model();
      await _pump(tester, model: model, movable: false);
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.arrowDown, alt: true);
      expect(model.moves, isEmpty);
      expect(_focused(tester), 'row m1');
    });
  });

  group('semantics', () {
    testWidgets('a caret is a button named for its press, with its row\'s '
        'expanded state', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, movable: false);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Collapse')),
        isSemantics(
          label: 'Collapse',
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Collapse'));
      await tester.pumpAndSettle();
      expect(find.text('m2a'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Expand')),
        isSemantics(
          label: 'Expand',
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the focused row says it is focused, and a parent whether '
        'it is open', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, movable: false);
      await _enter(tester);
      await _press(tester, LogicalKeyboardKey.arrowDown);

      SemanticsNode row(String id) {
        final focus = find.descendant(
          of: find.byKey(ValueKey('tree-row-$id')),
          matching: find.byType(Focus),
        );
        return tester.getSemantics(
          find
              .descendant(of: focus.first, matching: find.byType(Semantics))
              .first,
        );
      }

      expect(
        row('m2'),
        isSemantics(
          isFocusable: true,
          isFocused: true,
          hasExpandedState: true,
          isExpanded: true,
          hasFocusAction: true,
        ),
      );
      expect(row('m1'), isSemantics(isFocusable: true, hasFocusAction: true));
      handle.dispose();
    });
  });

  testWidgets('rows that are controls of their own keep the keyboard: the '
      'tree adds no stop, key or menu, and its carets are Tab stops', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final moves = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: Tree(
              roots: _tree,
              rowControls: false,
              onMove: (id, _, _) => moves.add(id),
              itemBuilder: (_, id, info) =>
                  Button(id, onPressed: info.moves?.down),
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);

    final seen = <String>[];
    for (var i = 0; i < 4; i++) {
      await _press(tester, LogicalKeyboardKey.tab);
      seen.add(_focused(tester));
    }
    expect(seen, ['m1', 'Collapse', 'm2', 'm2a']);

    // The row offers the tree's moves itself.
    await _press(tester, LogicalKeyboardKey.arrowDown, alt: true);
    expect(moves, isEmpty);
    await tester.tap(find.text('m1'));
    expect(moves, ['m1']);
    handle.dispose();
  });
}
