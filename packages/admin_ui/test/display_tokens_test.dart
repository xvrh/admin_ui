import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s light tokens with its geometry, in the platform's font.
AdminTokens _tokens(AdminTheme theme) {
  final source = theme.tokens;
  final spec = source.typography.spec;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    type: AdminTypeSpec(
      ramp: spec.ramp,
      scale: spec.scale,
      heading: spec.heading,
      strong: spec.strong,
      body: spec.body,
      tracking: spec.tracking,
      uppercaseLabels: spec.uppercaseLabels,
    ),
    sizes: source.sizes,
    table: source.table,
    motion: source.motion,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
  );
}

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 480, child: child),
    ),
  ),
);

/// Every rounded rect [T]'s painter drew.
List<RRect> _rrects<T extends Widget>() {
  final rrects = <RRect>[];
  expect(
    find.descendant(of: find.byType(T), matching: find.byType(CustomPaint)),
    paints..everything((method, args) {
      if (method == #drawRRect) rrects.add(args[0] as RRect);
      return true;
    }),
  );
  return rrects;
}

BorderRadius? _radiusOf(WidgetTester tester, Finder box) {
  final decoration = tester.widget<Container>(box).decoration;
  return (decoration as BoxDecoration?)?.borderRadius as BorderRadius?;
}

void main() {
  const bars = BarChart(
    series: [
      ChartSeries('Desktop', [120, 190, 140]),
      ChartSeries('Mobile', [90, 130, 170]),
    ],
    labels: ['Q1', 'Q2', 'Q3'],
  );

  testWidgets('Carbon: bars and legend swatches are square', (tester) async {
    await tester.pumpWidget(_host(_tokens(carbonTheme), bars));
    final rrects = _rrects<BarChart>();
    expect(rrects, isNotEmpty);
    for (final bar in rrects) {
      expect(bar.tlRadiusX, 0);
      expect(bar.trRadiusX, 0);
    }
    final swatch = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxWidth == 8,
    );
    expect(swatch, findsNWidgets(2));
    expect(_radiusOf(tester, swatch.first), BorderRadius.zero);
  });

  for (final theme in [irisTheme, materialTheme, antTheme]) {
    testWidgets('${theme.name}: a bar top takes the small radius, within '
        'half its width', (tester) async {
      final tokens = _tokens(theme);
      await tester.pumpWidget(_host(tokens, bars));
      for (final bar in _rrects<BarChart>()) {
        final expected = [
          tokens.radii.radiusSmall,
          bar.width / 2,
          bar.height,
        ].reduce((a, b) => a < b ? a : b);
        expect(bar.tlRadiusX, expected);
        expect(bar.blRadiusX, 0);
      }
    });
  }

  for (final theme in [irisTheme, antTheme, carbonTheme]) {
    testWidgets('${theme.name}: the StatCard delta chip is a radiusPill, its '
        'glyph an xs icon', (tester) async {
      final tokens = _tokens(theme);
      await tester.pumpWidget(
        _host(
          tokens,
          const StatCard(
            label: 'Revenue',
            value: r'$48.2k',
            icon: Icons.payments_outlined,
            delta: StatDelta('12%', direction: TrendDirection.up),
          ),
        ),
      );
      final chip = find.ancestor(
        of: find.text('12%'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      expect(
        _radiusOf(tester, chip.first),
        BorderRadius.circular(tokens.radii.radiusPill),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.arrow_upward_rounded)).size,
        tokens.iconSizes.xs,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.payments_outlined)).size,
        tokens.iconSizes.md,
      );
    });
  }

  testWidgets('Carbon: a bar sparkline is square', (tester) async {
    await tester.pumpWidget(
      _host(_tokens(carbonTheme), const BarSparkline([3, 5, 2, 6])),
    );
    for (final bar in _rrects<BarSparkline>()) {
      expect(bar.tlRadiusX, 0);
    }
  });

  group('motion follows the theme, and reduced motion lands at once', () {
    // One theme for every pump: a new one would cross-fade the app's theme,
    // which restarts the rail's animation on every frame.
    final theme = buildAppTheme(defaultTokens);

    Widget rail({required bool collapsed, required bool reduced}) =>
        MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 400,
                  child: Sidebar(
                    collapsed: collapsed,
                    entries: const [
                      NavItem('Pages', icon: Icons.article_outlined),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    double width(WidgetTester tester) =>
        tester.getSize(find.byType(Sidebar)).width;

    testWidgets('the sidebar rail takes the medium duration', (tester) async {
      await tester.pumpWidget(rail(collapsed: false, reduced: false));
      await tester.pumpWidget(rail(collapsed: true, reduced: false));
      final medium = defaultTokens.motion.medium;
      // The first frame starts the animation's clock.
      await tester.pump();
      await tester.pump(medium ~/ 2);
      expect(width(tester), greaterThan(Sidebar.collapsedWidth));
      expect(width(tester), lessThan(Sidebar.expandedWidth));
      await tester.pump(medium ~/ 2);
      expect(width(tester), Sidebar.collapsedWidth);
    });

    testWidgets('reduced, the rail folds in the next frame', (tester) async {
      await tester.pumpWidget(rail(collapsed: false, reduced: true));
      await tester.pumpWidget(rail(collapsed: true, reduced: true));
      await tester.pump();
      expect(width(tester), Sidebar.collapsedWidth);
    });

    testWidgets('reduced, a tree caret turns in the next frame', (
      tester,
    ) async {
      Widget tree({required bool reduced}) => MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: SizedBox(
              width: 400,
              child: Tree(
                roots: const [
                  TreeNode(
                    id: 'a',
                    children: [TreeNode(id: 'b')],
                  ),
                ],
                itemBuilder: (context, id, info) => Text(id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(tree(reduced: true));
      final caret = find.byType(AnimatedRotation);
      expect(tester.widget<AnimatedRotation>(caret).duration, Duration.zero);
      await tester.pumpWidget(tree(reduced: false));
      expect(
        tester.widget<AnimatedRotation>(caret).duration,
        defaultTokens.motion.fast,
      );
    });
  });
}
