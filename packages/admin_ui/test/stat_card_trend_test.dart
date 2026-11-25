import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

const _days = <double>[
  210, 214, 208, 221, 230, 226, 219, 232, 240, 236, 228, 241, 247, 239, 245, //
  251, 249, 238, 244, 256, 260, 253, 248, 259, 264, 258, 262, 270, 266, 268,
];

const _trendKey = ValueKey('trend');

/// A figure too wide to keep its width beside a trend on a card 300 wide.
const _long = '1,234,567 people';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 400,
  TextDirection direction = TextDirection.ltr,
  AdminTokens? tokens,
}) async {
  tester.view
    ..physicalSize = const Size(1200, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? irisTheme.tokens),
      supportedLocales: _kitLanguages.locales,
      localizationsDelegates: _kitLanguages.delegates,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// "Active, last 7 days: 268", with its change, and [trend] when given.
StatCard _active({
  Key? key,
  Widget? trend,
  String value = '268',
  bool delta = true,
  bool caption = true,
  bool loading = false,
}) => StatCard(
  key: key,
  label: 'Active, last 7 days',
  value: loading ? '' : value,
  icon: Icons.group_rounded,
  delta: delta ? StatDelta(loading ? '' : '12') : null,
  caption: caption ? (loading ? '' : 'vs the week before') : null,
  trend: trend,
  loading: loading,
);

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// The card's box inside its padding.
Rect _content(WidgetTester tester, [Finder? card]) =>
    _rect(tester, card ?? find.byType(StatCard)).deflate(AdminSpacing.xl);

void main() {
  testWidgets('stands beside the figure, at the end, as tall a card as '
      'without it', (tester) async {
    await _pump(tester, _active());
    final without = _rect(tester, find.byType(StatCard)).height;

    await _pump(tester, _active(trend: const Sparkline(_days, key: _trendKey)));
    final content = _content(tester);
    final trend = _rect(tester, find.byKey(_trendKey));
    final figure = _rect(tester, find.text('268'));
    expect(trend.size, const Size(88, 24));
    expect(trend.right, content.right);
    expect(trend.center.dy, figure.center.dy);
    expect(figure.left, content.left);
    expect(
      figure.right,
      lessThanOrEqualTo(trend.left - AdminSpacing.lg),
      reason: 'the figure keeps the room beside the trend',
    );
    expect(_rect(tester, find.byType(StatCard)).height, without);
  });

  testWidgets('goes under the delta and caption, across the card, when the '
      'figure would keep less than minValueWidth beside it', (tester) async {
    // 200 - 2 * 16 = 168 across; beside an 88 trend the figure would keep 68.
    await _pump(tester, _active(), width: 200);
    final without = _rect(tester, find.byType(StatCard)).height;

    await _pump(
      tester,
      _active(trend: const Sparkline(_days, key: _trendKey)),
      width: 200,
    );
    final content = _content(tester);
    final trend = _rect(tester, find.byKey(_trendKey));
    final caption = _rect(tester, find.text('vs the week before'));
    expect(trend.left, content.left);
    expect(trend.width, content.width);
    expect(trend.height, 24);
    expect(trend.bottom, content.bottom);
    expect(
      _rect(tester, find.byType(StatCard)).height,
      without + AdminSpacing.lg + 24,
    );
    expect(trend.top, greaterThanOrEqualTo(caption.bottom + AdminSpacing.lg));
  });

  testWidgets('goes under rather than clip a figure wider than minValueWidth', (
    tester,
  ) async {
    await _pump(
      tester,
      _active(
        value: _long,
        trend: const Sparkline(_days, key: _trendKey),
      ),
      width: 300,
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text(_long));
    final content = _content(tester);
    expect(
      paragraph.getMaxIntrinsicWidth(double.infinity),
      allOf(
        greaterThan(StatCard.minValueWidth),
        greaterThan(content.width - AdminSpacing.lg - 88),
      ),
      reason: 'the figure would not fit beside the trend',
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(_rect(tester, find.byKey(_trendKey)).width, content.width);
  });

  testWidgets('goes under when taller than the figure', (tester) async {
    await _pump(
      tester,
      _active(trend: const Sparkline(_days, key: _trendKey, height: 48)),
    );
    final trend = _rect(tester, find.byKey(_trendKey));
    expect(trend.width, _content(tester).width);
    expect(
      trend.top,
      greaterThan(_rect(tester, find.text('vs the week before')).bottom),
    );
  });

  testWidgets('a trend that fills its width goes under, across the card', (
    tester,
  ) async {
    await _pump(
      tester,
      _active(trend: const BarSparkline(_days, key: _trendKey, width: null)),
      width: 600,
    );
    final trend = _rect(tester, find.byKey(_trendKey));
    final content = _content(tester);
    expect(trend.width, content.width);
    expect(trend.bottom, content.bottom);
  });

  testWidgets('mirrors right to left', (tester) async {
    await _pump(
      tester,
      _active(trend: const Sparkline(_days, key: _trendKey)),
      direction: TextDirection.rtl,
    );
    var content = _content(tester);
    final trend = _rect(tester, find.byKey(_trendKey));
    expect(trend.left, content.left);
    expect(_rect(tester, find.text('268')).right, content.right);

    await _pump(
      tester,
      _active(trend: const Sparkline(_days, key: _trendKey)),
      direction: TextDirection.rtl,
      width: 200,
    );
    content = _content(tester);
    expect(_rect(tester, find.byKey(_trendKey)).width, content.width);
    expect(_rect(tester, find.byIcon(Icons.group_rounded)).left, content.left);
  });

  testWidgets('reads as the same sentence: the chart is not spoken', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _active(trend: const Sparkline(_days)));
    expect(
      find.bySemanticsLabel(
        'Active, last 7 days: 268, up 12, vs the week before',
      ),
      findsOneWidget,
    );
    final card = tester.getSemantics(find.byType(StatCard));
    var nodes = 0;
    card.visitChildren((_) {
      nodes++;
      return true;
    });
    expect(nodes, 0);
    semantics.dispose();
  });

  group('in a StatGrid', () {
    List<Widget> cards({required bool trends, bool loading = false}) => [
      _active(
        key: const ValueKey('a'),
        trend: trends ? const Sparkline(_days) : null,
        loading: loading,
      ),
      _active(key: const ValueKey('b'), loading: loading),
      _active(
        key: const ValueKey('c'),
        trend: trends ? const BarSparkline(_days, highlightLast: true) : null,
        caption: false,
        loading: loading,
      ),
      _active(key: const ValueKey('d'), delta: false, loading: loading),
    ];
    Finder card(String key) => find.byKey(ValueKey(key));

    testWidgets('wide, the trends beside: every card as tall, its label, '
        'figure and delta level with the next', (tester) async {
      // 1,000 wide: four tiles of 241, the figure keeps 109 beside a trend.
      await _pump(
        tester,
        StatGrid(children: cards(trends: false)),
        width: 1000,
      );
      final without = _rect(tester, find.byType(StatGrid)).height;
      await _pump(tester, StatGrid(children: cards(trends: true)), width: 1000);
      expect(_rect(tester, find.byType(StatGrid)).height, without);
      final first = _rect(tester, card('a'));
      for (final key in ['b', 'c', 'd']) {
        expect(_rect(tester, card(key)).top, first.top);
        expect(_rect(tester, card(key)).height, first.height);
        expect(
          _rect(
            tester,
            find.descendant(of: card(key), matching: find.text('268')),
          ).top,
          _rect(
            tester,
            find.descendant(of: card('a'), matching: find.text('268')),
          ).top,
        );
      }
      expect(
        _rect(
          tester,
          find.descendant(of: card('c'), matching: find.text('12')),
        ).top,
        _rect(
          tester,
          find.descendant(of: card('a'), matching: find.text('12')),
        ).top,
      );
    });

    testWidgets('narrow, the trends under: the figures and deltas level, the '
        'trends along the bottom', (tester) async {
      // 440 wide: two tiles of 214 a row, the figure would keep 82 beside.
      await _pump(tester, StatGrid(children: cards(trends: true)), width: 440);
      final a = _rect(tester, card('a'));
      final c = _rect(tester, card('c'));
      // a and b share the first row, c and d the second.
      expect(_rect(tester, card('b')).top, a.top);
      expect(_rect(tester, card('b')).height, a.height);
      expect(_rect(tester, card('d')).top, c.top);
      expect(_rect(tester, card('d')).height, c.height);
      for (final key in ['a', 'c']) {
        final trend = _rect(
          tester,
          find.descendant(
            of: card(key),
            matching: find.byWidgetPredicate(
              (w) => w is Sparkline || w is BarSparkline,
            ),
          ),
        );
        final content = _content(tester, card(key));
        expect(trend.width, content.width);
        expect(trend.bottom, content.bottom);
      }
    });

    testWidgets('loading, each row is as tall as the loaded row it becomes, '
        'the trends in their places', (tester) async {
      for (final width in [1000.0, 440.0]) {
        await _pump(
          tester,
          StatGrid(children: cards(trends: true)),
          width: width,
        );
        final loaded = _rect(tester, find.byType(StatGrid)).height;
        final trend = _rect(
          tester,
          find.descendant(of: card('a'), matching: find.byType(Sparkline)),
        ).shift(-_rect(tester, card('a')).topLeft);
        await _pump(
          tester,
          StatGrid(children: cards(trends: true, loading: true)),
          width: width,
        );
        expect(
          _rect(tester, find.byType(StatGrid)).height,
          loaded,
          reason: 'at $width',
        );
        final block = _rect(
          tester,
          find
              .descendant(
                of: find.ancestor(
                  of: find.descendant(
                    of: card('a'),
                    matching: find.byType(Sparkline),
                  ),
                  matching: find.byType(Stack),
                ),
                matching: find.byType(Skeleton),
              )
              .first,
        ).shift(-_rect(tester, card('a')).topLeft);
        expect(block, trend, reason: 'at $width');
      }
    });
  });

  testWidgets('a loading card shows a pulsing block for its trend', (
    tester,
  ) async {
    await _pump(
      tester,
      _active(loading: true, trend: const Sparkline([], key: _trendKey)),
    );
    // The figure, the delta, the caption and the trend.
    expect(find.byType(Skeleton), findsNWidgets(4));
    expect(find.byType(SkeletonGroup), findsNothing);
    final hidden = find.ancestor(
      of: find.byKey(_trendKey),
      matching: find.byType(Visibility),
    );
    expect(tester.widget<Visibility>(hidden).visible, isFalse);
  });

  testWidgets('a loading card given its figure places the trend as the '
      'loaded card does', (tester) async {
    await _pump(
      tester,
      _active(
        value: _long,
        trend: const Sparkline(_days, key: _trendKey),
      ),
      width: 300,
    );
    final loaded = _rect(tester, find.byType(StatCard)).height;
    await _pump(
      tester,
      width: 300,
      const StatCard(
        label: 'Active, last 7 days',
        value: _long,
        icon: Icons.group_rounded,
        delta: StatDelta(''),
        caption: '',
        trend: Sparkline([], key: _trendKey),
        loading: true,
      ),
    );
    expect(_rect(tester, find.byType(StatCard)).height, loaded);
    expect(_rect(tester, find.byKey(_trendKey)).width, _content(tester).width);
  });
}
