import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source] with its theme's ramp and geometry, in the platform's font.
AdminTokens _fontless(AdminTokens source) {
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
    elevation: source.elevation,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
    motion: source.motion,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
  );
}

Finder _circles(double side) => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
      w.constraints?.maxWidth == side,
);

void main() {
  for (final theme in [irisTheme, antTheme]) {
    final tokens = _fontless(theme.tokens);

    Future<void> pump(
      WidgetTester tester, {
      TextScaler scaler = TextScaler.noScaling,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(tokens),
        home: MediaQuery(
          data: MediaQueryData(textScaler: scaler),
          child: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: Timeline(
                  entries: [
                    TimelineEntry(title: 'Deployed', timestamp: '12:30'),
                    TimelineEntry(
                      titleWidget: Text('Rich'),
                      icon: Icons.edit_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('${theme.name}: the node centres on the title\'s first line', (
      tester,
    ) async {
      await pump(tester);
      final nodes = _circles(28);
      expect(nodes, findsNWidgets(2));
      for (final (i, title) in [(0, 'Deployed'), (1, 'Rich')]) {
        final node = tester.getRect(nodes.at(i));
        final text = tester.getRect(find.text(title));
        expect(
          text.center.dy,
          moreOrLessEquals(node.center.dy, epsilon: 0.5),
          reason: title,
        );
      }
    });

    testWidgets('${theme.name}: at twice the text size the node still centres '
        'on the first line', (tester) async {
      await pump(tester, scaler: const TextScaler.linear(2));
      final node = tester.getRect(_circles(28).first);
      final text = tester.getRect(find.text('Deployed'));
      expect(text.center.dy, moreOrLessEquals(node.center.dy, epsilon: 0.5));
    });

    testWidgets('${theme.name}: the dot is even and sits on whole pixels', (
      tester,
    ) async {
      await pump(tester);
      final dot = tester.getRect(_circles(8));
      expect(dot.size, const Size.square(8));
      expect(dot.left, dot.left.roundToDouble());
      expect(dot.top, dot.top.roundToDouble());
    });

    testWidgets('${theme.name}: a titleWidget reads the body style', (
      tester,
    ) async {
      await pump(tester);
      final style = DefaultTextStyle.of(tester.element(find.text('Rich')))
          .style;
      expect(style.fontSize, tokens.typography.body.fontSize);
      expect(style.height, tokens.typography.body.height);
      expect(style.color, tokens.palette.foreground);
    });
  }
}
