import 'dart:ui' as ui;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {double width = 500}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// The colour of the pixel at [offset] inside the [RepaintBoundary] keyed
/// [key], rendered at a device pixel ratio of 1.
Future<Color> _pixel(WidgetTester tester, Key key, Offset offset) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (data!, width);
  });
  final (data, width) = bytes!;
  final i = (offset.dy.toInt() * width + offset.dx.toInt()) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

void main() {
  testWidgets('a flush Panel keeps its border above content that fills it', (
    tester,
  ) async {
    const key = Key('panel');
    const fill = Color(0xFFFF0000);
    await tester.pumpWidget(
      _host(
        const RepaintBoundary(
          key: key,
          child: Panel(
            child: SizedBox(height: 60, child: ColoredBox(color: fill)),
          ),
        ),
      ),
    );
    final line = defaultTokens.palette.border;

    // Every edge, away from the corners: the border, not the row fill.
    expect(await _pixel(tester, key, const Offset(0, 30)), line);
    expect(await _pixel(tester, key, const Offset(499, 30)), line);
    expect(await _pixel(tester, key, const Offset(250, 0)), line);
    expect(await _pixel(tester, key, const Offset(250, 59)), line);
    // Inside, the child still paints.
    expect(await _pixel(tester, key, const Offset(250, 30)), fill);
  });

  testWidgets('DashedBorder paints over its child, inside its edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const DashedBorder(
          color: Color(0xFF000000),
          radius: 8,
          child: SizedBox(height: 40),
        ),
      ),
    );
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DashedBorder),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.painter, isNull);
    expect(paint.foregroundPainter, isNotNull);

    // A whole-pixel stroke inset by half its width lands on the first row.
    const key = Key('dashed');
    const fill = Color(0xFFFFFFFF);
    await tester.pumpWidget(
      _host(
        const RepaintBoundary(
          key: key,
          child: DashedBorder(
            color: Color(0xFF000000),
            radius: 0,
            child: SizedBox(height: 40, child: ColoredBox(color: fill)),
          ),
        ),
      ),
    );
    final top = [
      for (var x = 20; x < 40; x++)
        await _pixel(tester, key, Offset(x.toDouble(), 0)),
    ];
    final below = [
      for (var x = 20; x < 40; x++)
        await _pixel(tester, key, Offset(x.toDouble(), 1)),
    ];
    expect(top, contains(const Color(0xFF000000)));
    expect(below, everyElement(fill));
  });

  testWidgets('two inline columns size labels to the list, not 160 each', (
    tester,
  ) async {
    // The width the list gets in the catalog's 760px render.
    await tester.pumpWidget(
      _host(
        const DescriptionList(
          columns: 2,
          items: [
            DescriptionItem('Email', value: 'a'),
            DescriptionItem('Phone', value: 'b'),
            DescriptionItem('Role', value: 'c'),
          ],
        ),
        width: 556,
      ),
    );
    final email = tester.getRect(find.text('Email'));
    final phone = tester.getRect(find.text('Phone'));
    // The label column hugs the widest label …
    expect(tester.getTopLeft(find.text('a')).dx - email.left, lessThan(100));
    // … so the value slot, up to the next column, keeps at least 160.
    final valueStart = tester.getTopLeft(find.text('a')).dx;
    expect(
      phone.left - AdminSpacing.xxl - valueStart,
      greaterThanOrEqualTo(160),
    );
    // Labels line up across columns and rows.
    expect(
      tester.getTopLeft(find.text('b')).dx - phone.left,
      valueStart - email.left,
    );
    expect(tester.getTopLeft(find.text('c')).dx, valueStart);
  });

  testWidgets('a grid drops columns rather than squeeze a cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const DescriptionList(
          columns: 2,
          items: [
            DescriptionItem('A', value: '1'),
            DescriptionItem('B', value: '2'),
          ],
        ),
        width: 320,
      ),
    );
    // 320 fits one 240px inline cell, so the pair stacks.
    expect(
      tester.getTopLeft(find.text('2')).dy,
      greaterThan(tester.getTopLeft(find.text('1')).dy),
    );
    expect(
      tester.getTopLeft(find.text('2')).dx,
      tester.getTopLeft(find.text('1')).dx,
    );
  });

  testWidgets('tiles in a StatGrid row share its height', (tester) async {
    await tester.pumpWidget(
      _host(
        const StatGrid(
          minTileWidth: 150,
          children: [
            StatCard(label: 'Posts', value: '312'),
            StatCard(
              label: 'Storage',
              value: '6.4 GB',
              delta: StatDelta('flat', direction: TrendDirection.flat),
            ),
            StatCard(label: 'Drafts', value: '18'),
          ],
        ),
      ),
    );
    final heights = [
      for (final label in ['Posts', 'Storage', 'Drafts'])
        tester
            .getSize(
              find.ancestor(of: find.text(label), matching: find.byType(Panel)),
            )
            .height,
    ];
    expect(heights[0], heights[1]);
    expect(heights[2], heights[1]);
  });
}
