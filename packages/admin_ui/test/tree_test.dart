import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/tree.dart'
    show excludeSubtree, flattenTree, projectTreeDrop;
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

void main() {
  group('flattenTree', () {
    test('depth-first with depths and parents', () {
      final flat = flattenTree(_tree);
      expect(flat.map((f) => f.id), ['m1', 'm2', 'm2a', 'm2b', 'm3']);
      expect(flat.map((f) => f.depth), [0, 0, 1, 1, 0]);
      expect(flat.firstWhere((f) => f.id == 'm2a').parentId, 'm2');
      expect(flat.firstWhere((f) => f.id == 'm2').hasChildren, isTrue);
    });

    test('collapsed nodes hide their children', () {
      final flat = flattenTree(_tree, collapsed: {'m2'});
      expect(flat.map((f) => f.id), ['m1', 'm2', 'm3']);
      expect(flat.firstWhere((f) => f.id == 'm2').expanded, isFalse);
    });
  });

  test('excludeSubtree drops the node and its descendants', () {
    final flat = flattenTree(_tree);
    expect(excludeSubtree(flat, 'm2').map((f) => f.id), ['m1', 'm3']);
    expect(excludeSubtree(flat, 'm1').map((f) => f.id), [
      'm2',
      'm2a',
      'm2b',
      'm3',
    ]);
  });

  group('projectTreeDrop', () {
    // working = tree minus the dragged node m1.
    final working = excludeSubtree(flattenTree(_tree), 'm1');

    test('nests as a sibling between two children', () {
      final drop = projectTreeDrop(
        working,
        2,
        1,
      ); // between m2a and m2b, depth 1
      expect(drop.parentId, 'm2');
      expect(drop.childIndex, 1);
      expect(drop.depth, 1);
    });

    test('appends at root when dropped past the last row at depth 0', () {
      final drop = projectTreeDrop(working, working.length, 0);
      expect(drop.parentId, isNull);
      expect(drop.childIndex, 2); // after m2 and m3
    });

    test('nests as first child when depth exceeds the previous row', () {
      final drop = projectTreeDrop(working, working.length, 1);
      expect(drop.parentId, 'm3');
      expect(drop.childIndex, 0);
    });

    test('clamps projected depth to the neighbours', () {
      // Past m3 (depth 0), asking for depth 5 — only one level of nesting is
      // reachable under m3, so it clamps to depth 1.
      final drop = projectTreeDrop(working, working.length, 5);
      expect(drop.depth, 1);
    });

    test('honours maxDepth', () {
      final drop = projectTreeDrop(working, working.length, 5, maxDepth: 0);
      expect(drop.depth, 0);
      expect(drop.parentId, isNull);
    });
  });

  group('Tree widget', () {
    Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 420, height: 600, child: child)),
    );

    testWidgets('renders a row per visible node; caret collapses children', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(Tree(roots: _tree, itemBuilder: (_, id, _) => Text(id))),
      );
      expect(find.text('m2a'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('m2a'), findsNothing);
      expect(find.text('m2'), findsOneWidget);
    });

    testWidgets('a drag gesture survives the pickup and fires onMove', (
      tester,
    ) async {
      String? movedId;
      await tester.pumpWidget(
        host(
          Tree(
            roots: _tree,
            rowHeight: 44,
            onMove: (id, parent, index) => movedId = id,
            itemBuilder: (_, id, _) => Text(id),
          ),
        ),
      );

      // Grab m1's handle and drag it down past a couple of rows.
      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, 10)); // cross the pan slop
      await tester.pump();
      await gesture.moveBy(const Offset(0, 110));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(movedId, 'm1');
    });

    testWidgets('renders placeholder when there are no roots', (tester) async {
      await tester.pumpWidget(
        host(
          Tree(
            roots: const [],
            empty: const Text('Nothing here'),
            itemBuilder: (_, id, _) => Text(id),
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('dragging a parent shows a carried-count badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Tree(
            roots: _tree, // m2 has two children
            rowHeight: 44,
            onMove: (_, _, _) {},
            itemBuilder: (_, id, _) => Text(id),
          ),
        ),
      );

      // m2 is the second row; grab its handle.
      final handle = find.byIcon(Icons.drag_indicator_rounded).at(1);
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();

      expect(find.text('+2'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the lifted row casts a palette shadow, not an ink glow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: irisDarkPalette)),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 600,
              child: Tree(
                roots: _tree,
                rowHeight: 44,
                onMove: (_, _, _) {},
                itemBuilder: (_, id, _) => Text(id),
              ),
            ),
          ),
        ),
      );

      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();

      final lifted = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.elevation > 0);
      expect(lifted, hasLength(1));
      expect(
        lifted.single.shadowColor,
        irisDarkPalette.shadow.withValues(alpha: 0.2),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('dwelling over a collapsed parent auto-expands it mid-drag', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Tree(
            roots: _tree,
            rowHeight: 44,
            initiallyCollapsed: const {'m2'},
            onMove: (_, _, _) {},
            itemBuilder: (_, id, _) => Text(id),
          ),
        ),
      );
      expect(find.text('m2a'), findsNothing);

      // Lift m1; the working list (drag excluded) puts collapsed m2 at row 0.
      // Hover there and hold past the dwell delay.
      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(
        const Offset(0, 10),
      ); // cross pan slop, stay on row 0
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 700),
      ); // past the dwell delay

      expect(find.text('m2a'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('auto-scrolls when a drag is parked against the bottom edge', (
      tester,
    ) async {
      // A tall tree capped well below its content height so it must scroll.
      // Align gives loose constraints so maxHeight actually caps the viewport.
      final tall = [for (var i = 0; i < 30; i++) TreeNode(id: 'r$i')];
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topLeft,
            child: Tree(
              roots: tall,
              rowHeight: 44,
              maxHeight: 220, // ~5 rows visible of 30
              onMove: (_, _, _) {},
              itemBuilder: (_, id, _) => Text(id),
            ),
          ),
        ),
      );

      final controller = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      expect(controller.offset, 0);

      // Grab the first row and walk the pointer down into the bottom edge band.
      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();
      }
      // Let the periodic ticker run a few frames with the pointer parked.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(controller.offset, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'auto-scrolls the enclosing scrollable when uncapped (shrink-wrap mode)',
      (tester) async {
        final tall = [for (var i = 0; i < 30; i++) TreeNode(id: 'r$i')];
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          host(
            ListView(
              controller: outer,
              children: [
                Tree(
                  roots: tall, // no maxHeight: shrink-wraps inside the ListView
                  rowHeight: 44,
                  onMove: (_, _, _) {},
                  itemBuilder: (_, id, _) => Text(id),
                ),
              ],
            ),
          ),
        );
        expect(outer.offset, 0);

        final handle = find.byIcon(Icons.drag_indicator_rounded).first;
        final gesture = await tester.startGesture(tester.getCenter(handle));
        for (var i = 0; i < 12; i++) {
          await gesture.moveBy(
            const Offset(0, 48),
          ); // walk toward the bottom edge
          await tester.pump();
        }
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(outer.offset, greaterThan(0));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'expands a variable-height panel beneath one row, pushing rows down',
      (tester) async {
        await tester.pumpWidget(
          host(
            Tree(
              roots: _tree,
              rowHeight: 44,
              expandedId: 'm1',
              expansionBuilder: (_, id) =>
                  SizedBox(height: 120, child: Text('panel $id')),
              itemBuilder: (_, id, _) => Text(id),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('panel m1'), findsOneWidget);

        // m1 is the first row (top 0); the next root m2 is pushed below the
        // measured 120px panel (well past its un-expanded 44px slot).
        final m2Top = tester.getTopLeft(find.text('m2')).dy;
        expect(m2Top, greaterThan(44 + 100));

        // Collapsing (no expandedId) removes the panel and restores the offset.
        await tester.pumpWidget(
          host(
            Tree(
              roots: _tree,
              rowHeight: 44,
              expansionBuilder: (_, id) =>
                  SizedBox(height: 120, child: Text('panel $id')),
              itemBuilder: (_, id, _) => Text(id),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('panel m1'), findsNothing);
      },
    );

    testWidgets('drag handles appear only when onMove is set', (tester) async {
      await tester.pumpWidget(
        host(Tree(roots: _tree, itemBuilder: (_, id, _) => Text(id))),
      );
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);

      await tester.pumpWidget(
        host(
          Tree(
            roots: _tree,
            onMove: (_, _, _) {},
            itemBuilder: (_, id, _) => Text(id),
          ),
        ),
      );
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(5));
    });
  });
}
