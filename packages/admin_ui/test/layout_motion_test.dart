import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] under a MediaQuery that asks for reduced motion when [still].
Widget _host(Widget child, {required bool still}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: still),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 420, child: child),
        ),
      ),
    ),
  ),
);

const _sections = [
  AccordionSection(title: 'One', child: SizedBox(height: 120)),
  AccordionSection(title: 'Two', child: SizedBox(height: 120)),
];

const _tree = [
  TreeNode(id: 'a'),
  TreeNode(
    id: 'b',
    children: [
      TreeNode(id: 'b1'),
      TreeNode(id: 'b2'),
    ],
  ),
  TreeNode(id: 'c'),
];

/// A strip of [count] tabs, too many for the 420px it is given.
class _Strip extends StatefulWidget {
  final int count;
  const _Strip({required this.count});

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Tabs(
    tabs: [for (var i = 0; i < widget.count; i++) TabItem('Section $i')],
    selected: _selected,
    onChanged: (i) => setState(() => _selected = i),
  );
}

double _scrollOffset(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: find.byType(Tabs), matching: find.byType(Scrollable)),
    )
    .position
    .pixels;

void main() {
  for (final still in [true, false]) {
    final mode = still ? 'with reduced motion' : 'with motion';

    testWidgets('$mode, an Accordion section '
        '${still ? 'opens in one frame' : 'grows open'}', (tester) async {
      await tester.pumpWidget(
        _host(const Accordion(sections: _sections), still: still),
      );
      // How far the second header sits below the first: the first's body.
      double gap() =>
          tester.getTopLeft(find.text('Two')).dy -
          tester.getTopLeft(find.text('One')).dy;
      final closed = gap();

      await tester.tap(find.text('One'));
      await tester.pump();
      final first = gap();
      final caret = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation).first,
      );
      await tester.pumpAndSettle();
      final open = gap();

      expect(open, greaterThan(closed + 100));
      if (still) {
        expect(first, open);
        expect(caret.duration, Duration.zero);
      } else {
        expect(first, closed);
        expect(caret.duration, greaterThan(Duration.zero));
      }
    });

    testWidgets('$mode, arrowing to a tab past the edge '
        '${still ? 'jumps it into view' : 'scrolls it into view'}', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const _Strip(count: 12), still: still));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_scrollOffset(tester), 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      final first = _scrollOffset(tester);
      await tester.pumpAndSettle();
      final settled = _scrollOffset(tester);

      expect(settled, greaterThan(0));
      if (still) {
        expect(first, settled);
      } else {
        expect(first, lessThan(settled));
      }
    });

    testWidgets('$mode, expanding a Tree node '
        '${still ? 'moves the rows below in one frame' : 'slides them'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Tree(
            roots: _tree,
            initiallyCollapsed: const {'b'},
            itemBuilder: (_, id, _) => Text(id),
          ),
          still: still,
        ),
      );
      final collapsed = tester.getTopLeft(find.text('c')).dy;

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      final first = tester.getTopLeft(find.text('c')).dy;
      final caret = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      await tester.pumpAndSettle();
      final expanded = tester.getTopLeft(find.text('c')).dy;

      expect(expanded, collapsed + 2 * 44);
      expect(find.text('b1'), findsOneWidget);
      if (still) {
        expect(first, expanded);
        expect(caret.duration, Duration.zero);
      } else {
        expect(first, collapsed);
        expect(caret.duration, greaterThan(Duration.zero));
      }
    });
  }

  testWidgets('with reduced motion, a SplitView divider lights at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 200,
          child: SplitView.two(
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
        still: true,
      ),
    );
    final line = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(SplitView),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(line.duration, Duration.zero);
  });
}
