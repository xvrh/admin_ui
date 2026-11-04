import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps [trail] at the start of a column [width] wide, 24 in from the
/// window's edge.
Future<void> _pump(WidgetTester tester, Widget trail, {double width = 640}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: trail),
          ),
        ),
      ),
    ),
  );
}

void _noop() {}

const _long = [
  Crumb('Home', onTap: _noop),
  Crumb('Workspace', onTap: _noop),
  Crumb('Marketing', onTap: _noop),
  Crumb('Campaigns', onTap: _noop),
  Crumb('Spring launch', onTap: _noop),
  Crumb('Landing page draft'),
];

final _overflow = find.widgetWithIcon(IconAction, Icons.more_horiz_rounded);

/// Right edge of the painted trail.
double _trailEnd(WidgetTester tester) => [
  for (final element
      in find
          .descendant(of: find.byType(Breadcrumbs), matching: find.byType(Row))
          .evaluate())
    (element.renderObject! as RenderBox).localToGlobal(Offset.zero).dx +
        (element.renderObject! as RenderBox).size.width,
].reduce((a, b) => a > b ? a : b);

void main() {
  group('collapse', () {
    for (final width in [340.0, 420.0, 640.0]) {
      testWidgets('fits $width by folding the middle, first and last kept', (
        tester,
      ) async {
        await _pump(
          tester,
          const Breadcrumbs(_long, maxItems: null),
          width: width,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Landing page draft'), findsOneWidget);
        expect(_trailEnd(tester), lessThanOrEqualTo(24 + width));
        if (width < 640) expect(_overflow, findsOneWidget);
      });
    }

    testWidgets('keeps the whole trail when it fits', (tester) async {
      await _pump(
        tester,
        const Breadcrumbs([
          Crumb('Home', onTap: _noop),
          Crumb('Articles', onTap: _noop),
          Crumb('Editing'),
        ]),
      );
      expect(_overflow, findsNothing);
    });

    testWidgets('collapses past four crumbs by default', (tester) async {
      await _pump(tester, const Breadcrumbs(_long), width: 2000);
      expect(_overflow, findsOneWidget);
      expect(find.text('Workspace'), findsNothing);
      await tester.tap(_overflow);
      await tester.pumpAndSettle();
      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('ellipsises the current crumb as a last resort', (
      tester,
    ) async {
      await _pump(
        tester,
        const Breadcrumbs([
          Crumb('Home', onTap: _noop),
          Crumb('Articles', onTap: _noop),
          Crumb('A very long article title that has to ellipsise'),
        ]),
        width: 240,
      );
      expect(tester.takeException(), isNull);
      final current = tester.renderObject<RenderParagraph>(
        find.text('A very long article title that has to ellipsise'),
      );
      expect(current.didExceedMaxLines, isTrue);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Tip &&
              w.message == 'A very long article title that has to ellipsise',
        ),
        findsOneWidget,
      );
    });

    testWidgets('squeezes every crumb in a sliver of width', (tester) async {
      await _pump(
        tester,
        const Breadcrumbs([
          Crumb('A long first section name', onTap: _noop),
          Crumb('The current page'),
        ]),
        width: 120,
      );
      expect(tester.takeException(), isNull);
      expect(_trailEnd(tester), lessThanOrEqualTo(24 + 120));
    });

    testWidgets('lays out in an unbounded row without collapsing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Breadcrumbs([
                  Crumb('Home', onTap: _noop),
                  Crumb('Blog', onTap: _noop),
                  Crumb('Hello world'),
                ]),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Hello world'), findsOneWidget);
    });
  });

  group('spacing', () {
    testWidgets('8px each side of a separator; the first label on the edge', (
      tester,
    ) async {
      await _pump(
        tester,
        const Breadcrumbs([
          Crumb('Home', onTap: _noop),
          Crumb('Articles', onTap: _noop),
          Crumb('Editing'),
        ]),
      );
      final chevrons = find.byIcon(Icons.chevron_right_rounded);
      final first = tester.getRect(chevrons.first);
      final second = tester.getRect(chevrons.last);
      final home = tester.getRect(find.text('Home'));
      final articles = tester.getRect(find.text('Articles'));
      final editing = tester.getRect(find.text('Editing'));

      expect(first.left - home.right, 8);
      expect(articles.left - first.right, 8);
      expect(second.left - articles.right, 8);
      expect(editing.left - second.right, 8);
      expect(home.left, 24);
      expect(first.width, 16);
    });

    testWidgets('icons share one size', (tester) async {
      await _pump(
        tester,
        const Breadcrumbs([
          Crumb('Home', icon: Icons.home_outlined, onTap: _noop),
          Crumb(
            'Blog',
            onTap: _noop,
            siblings: [Crumb('Pages', onTap: _noop)],
          ),
          Crumb('Hello'),
        ]),
      );
      for (final icon in [
        Icons.home_outlined,
        Icons.chevron_right_rounded,
        Icons.expand_more_rounded,
      ]) {
        expect(tester.getSize(find.byIcon(icon).first), const Size.square(16));
      }
    });
  });

  group('targets', () {
    testWidgets('links, the … and the sibling caret are at least 24px', (
      tester,
    ) async {
      await _pump(
        tester,
        const Breadcrumbs(maxItems: 3, itemsAfterCollapse: 2, [
          Crumb('Home', onTap: _noop),
          Crumb('Workspace', onTap: _noop),
          Crumb(
            'Blog',
            onTap: _noop,
            siblings: [Crumb('Pages', onTap: _noop)],
          ),
          Crumb('Hello'),
        ]),
      );
      final link = find.ancestor(
        of: find.text('Home'),
        matching: find.byType(Tappable),
      );
      expect(tester.getSize(link).height, greaterThanOrEqualTo(24));
      expect(tester.getSize(_overflow), const Size.square(24));
      expect(
        tester.getSize(
          find.widgetWithIcon(IconAction, Icons.expand_more_rounded),
        ),
        const Size.square(24),
      );
      expect(tester.widget<IconAction>(_overflow).label, 'Show 1 more');
    });
  });

  group('keyboard', () {
    testWidgets('Tab reaches the links and the …, never the current page', (
      tester,
    ) async {
      final visited = <String>[];
      await _pump(
        tester,
        Breadcrumbs(maxItems: 3, [
          Crumb('Home', onTap: () => visited.add('Home')),
          Crumb('Workspace', onTap: () => visited.add('Workspace')),
          Crumb('Blog', onTap: () => visited.add('Blog')),
          const Crumb('Hello'),
        ]),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(visited, ['Home']);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.widget<IconAction>(_overflow).expanded, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('each crumb reads once; the current page says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const Breadcrumbs([
          Crumb('Home', onTap: _noop),
          Crumb('Articles'),
          Crumb('Editing'),
        ]),
      );
      final trail = tester
          .getSemantics(find.byType(Breadcrumbs))
          .getSemanticsData();
      expect(trail.role, SemanticsRole.navigation);
      expect(trail.label, 'Breadcrumb');

      expect(
        tester.getSemantics(
          find.descendant(
            of: find.ancestor(
              of: find.text('Home'),
              matching: find.byType(Tappable),
            ),
            matching: find.byType(GestureDetector),
          ),
        ),
        isSemantics(
          label: 'Home',
          isLink: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(tester.getSemantics(find.text('Articles')).label, 'Articles');
      expect(find.bySemanticsLabel('Editing, current page'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Editing.*Editing')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Home.*Home')), findsNothing);
      handle.dispose();
    });
  });
}
