import 'dart:ui' as ui;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Hosts [child] at [width] in Arabic, which lays out right to left, or in
/// English with [rtl] false.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool rtl = true,
  double width = 400,
  double? height,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      locale: Locale(rtl ? 'ar' : 'en'),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _indent = 28.0;

/// The caret and drag-handle columns a tree row starts with.
const _gutter = 22.0 + 26.0;

const _roots = [
  TreeNode(
    id: 'a',
    children: [
      TreeNode(
        id: 'b',
        children: [TreeNode(id: 'c')],
      ),
    ],
  ),
];

Widget _tree({void Function(String, String?, int)? onMove}) => Tree(
  roots: _roots,
  onMove: onMove,
  itemBuilder: (context, id, info) => SizedBox.expand(key: ValueKey(id)),
);

void main() {
  group('Tree', () {
    testWidgets('indents from the right, right to left', (tester) async {
      await _pump(tester, _tree());
      final tree = tester.getRect(find.byType(Tree));
      final deep = tester.getRect(find.byKey(const ValueKey('c')));
      // The row starts 2 · indent in from the right; its content after the
      // caret and grip.
      expect(deep.right, tree.right - 2 * _indent - _gutter);
      expect(deep.left, tree.left);

      await _pump(tester, _tree(), rtl: false);
      final ltr = tester.getRect(find.byKey(const ValueKey('c')));
      expect(ltr.left, tree.left + 2 * _indent + _gutter);
    });

    testWidgets('draws its guide rails down the right-hand gutter', (
      tester,
    ) async {
      await _pump(tester, _tree());
      final width = tester.getSize(find.byType(Tree)).width;
      // Row 1 ('b', depth 1) is the first with a rail: depth 0's caret
      // column, 12px in from the start edge.
      expect(
        find
            .descendant(
              of: find.byType(Tree),
              matching: find.byType(CustomPaint),
            )
            .first,
        paints..line(p1: Offset(width - 12, 44), p2: Offset(width - 12, 88)),
      );
    });

    testWidgets('nests a row dragged toward the left, right to left', (
      tester,
    ) async {
      final moves = <(String, String?, int)>[];
      const flat = [TreeNode(id: 'x'), TreeNode(id: 'y')];
      Widget tree() => Tree(
        roots: flat,
        onMove: (id, parent, index) => moves.add((id, parent, index)),
        itemBuilder: (context, id, info) => const SizedBox.expand(),
      );
      await _pump(tester, tree());
      final grip = find.byIcon(Icons.drag_indicator_rounded).last;

      await tester.drag(grip, const Offset(30, 0));
      await tester.pumpAndSettle();
      expect(moves.last, ('y', null, 1));

      await tester.drag(grip, const Offset(-30, 0));
      await tester.pumpAndSettle();
      expect(moves.last, ('y', 'x', 0));
    });
  });

  testWidgets('TreeEditor indents with Alt+← right to left', (tester) async {
    final moves = <(String, String?, int)>[];
    await _pump(
      tester,
      TreeEditor(
        maxDepth: 2,
        entries: const [
          TreeEditorEntry(id: 'home', title: 'Home'),
          TreeEditorEntry(id: 'about', title: 'About'),
        ],
        onSelect: (_) {},
        onMove: (id, parent, index) => moves.add((id, parent, index)),
      ),
      width: 560,
    );
    Focus.of(tester.element(find.text('About'))).requestFocus();
    await tester.pump();

    Future<void> alt(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
    }

    await alt(LogicalKeyboardKey.arrowRight);
    expect(moves, isEmpty, reason: 'a root row has nowhere to outdent to');
    await alt(LogicalKeyboardKey.arrowLeft);
    expect(moves, [('about', 'home', 0)]);
  });

  testWidgets('SplitView grows the start pane as the divider goes left', (
    tester,
  ) async {
    await _pump(
      tester,
      SplitView.two(
        first: Container(key: const Key('first')),
        second: Container(key: const Key('second')),
      ),
      width: 600,
      height: 200,
    );
    final view = tester.getRect(find.byType(SplitView));
    final before = tester.getRect(find.byKey(const Key('first')));
    // Right to left, the first pane is the right-hand one.
    expect(before.right, view.right);
    expect(before.width, 295);

    await tester.drag(
      find.byType(SplitView).hitTestable(),
      const Offset(-60, 0),
    );
    await tester.pump();
    final after = tester.getRect(find.byKey(const Key('first')));
    expect(after.right, view.right);
    expect(after.width, closeTo(355, 1));
  });

  testWidgets('BlockDiff draws its gutter on the right, right to left', (
    tester,
  ) async {
    final boundary = GlobalKey();
    await _pump(
      tester,
      RepaintBoundary(
        key: boundary,
        child: const BlockDiff(
          blocks: [
            BlockChange(
              id: 'p',
              type: 'paragraph',
              op: DiffOp.added,
              after: 'Hello',
            ),
          ],
        ),
      ),
    );
    final box = tester.getRect(find.byType(BlockDiff));
    final icon = tester.getRect(find.byIcon(Icons.add_rounded));
    // The content is inset by the 3px gutter plus the padding on the right,
    // by the padding alone on the left.
    expect(box.right - icon.right, 3 + 12);

    final context = tester.element(find.byType(BlockDiff));
    final accent = DiffOpStyle.of(context, DiffOp.added).accent;
    final image = (await tester.runAsync(
      () =>
          (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(),
    ))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    Color pixel(int x, int y) {
      final i = (y * image.width + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(i + 3),
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
    }

    // Across the row, level with its header.
    final mid = (icon.center.dy - box.top).round();
    expect(pixel(image.width - 2, mid), accent);
    expect(pixel(1, mid), isNot(accent));
    image.dispose();
  });

  group('LineChart, right to left', () {
    Widget chart() => const LineChart(
      series: [
        ChartSeries('Views', [0, 10, 20]),
      ],
      labels: ['Jan', 'Feb', 'Mar'],
    );

    testWidgets('stands its value axis on the right', (tester) async {
      await _pump(tester, chart());
      final plot = tester.getRect(find.byType(LineChart));
      final top = tester.getRect(find.text('20'));
      final zero = tester.getRect(find.text('0'));
      expect(top.right, plot.right);
      expect(zero.left, greaterThan(plot.center.dx));

      await _pump(tester, chart(), rtl: false);
      expect(tester.getRect(find.text('20')).left, plot.left);
    });

    testWidgets('runs its categories from the right', (tester) async {
      await _pump(tester, chart());
      final jan = tester.getCenter(find.text('Jan'));
      final feb = tester.getCenter(find.text('Feb'));
      final mar = tester.getCenter(find.text('Mar'));
      expect(jan.dx, greaterThan(feb.dx));
      expect(feb.dx, greaterThan(mar.dx));
    });
  });

  testWidgets('LineChart.time runs its time from the right', (tester) async {
    await _pump(
      tester,
      width: 640,
      LineChart.time(
        series: [
          ChartTimeSeries('Views', [
            for (var m = 1; m <= 6; m++) (DateTime.utc(2026, m), m * 10.0),
          ]),
        ],
      ),
    );
    // January is named by its year, the others by their names.
    final ticks = [
      for (var m = 1; m <= 6; m++)
        m == 1
            ? DateFormat.y('ar').format(DateTime.utc(2026))
            : DateFormat.MMM('ar').format(DateTime.utc(2026, m)),
    ];
    final shown = [
      for (final tick in ticks)
        if (find.text(tick).evaluate().isNotEmpty)
          tester.getCenter(find.text(tick)).dx,
    ];
    expect(shown.length, greaterThanOrEqualTo(2));
    for (var i = 1; i < shown.length; i++) {
      expect(shown[i], lessThan(shown[i - 1]));
    }
  });

  testWidgets('BarList grows its bars from the right', (tester) async {
    await _pump(
      tester,
      const BarList(
        items: [BarListItem('/a', 10), BarListItem('/b', 5)],
        formatValue: _plain,
      ),
    );
    final half = find.byType(FractionallySizedBox).last;
    final bar = tester.getRect(
      find.descendant(of: half, matching: find.byType(Container)),
    );
    final track = tester.getRect(
      find.ancestor(of: half, matching: find.byType(Stack)).first,
    );
    expect(bar.right, track.right);
    expect(bar.width, closeTo(track.width / 2, 0.5));
  });

  testWidgets('JsonView keeps its code left to right', (tester) async {
    await _pump(tester, const JsonView(data: {'id': 1}), width: 500);
    final view = tester.getRect(find.byType(JsonView));
    final line = tester.getRect(find.textContaining('"id"'));
    expect(line.left - view.left, lessThan(60));
  });

  testWidgets('Breadcrumbs separate with the self-mirroring chevron', (
    tester,
  ) async {
    await _pump(tester, const Breadcrumbs([Crumb('Home'), Crumb('Page')]));
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(
      tester.getCenter(find.text('Home')).dx,
      greaterThan(tester.getCenter(find.text('Page')).dx),
    );
  });
}

String _plain(double v) => '$v';
