// Gap takes its size along a Row's or a Column's main axis only, so it never
// makes a row taller or a column wider; anywhere else it is a square.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

// 100 by 20 each in the test font, whose glyphs are 1em squares.
const _label = Text('Label', style: TextStyle(fontSize: 20, height: 1));
const _value = Text('Value', style: TextStyle(fontSize: 20, height: 1));

void main() {
  testWidgets('in a Row it is 24 wide and the row keeps its text height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Row(
          key: Key('row'),
          mainAxisSize: MainAxisSize.min,
          children: [_label, Gap(24), _value],
        ),
      ),
    );
    expect(tester.getSize(find.byType(Gap)), const Size(24, 0));
    expect(tester.getSize(find.byKey(const Key('row'))), const Size(224, 20));
    expect(
      tester.getTopLeft(find.text('Value')).dx -
          tester.getTopRight(find.text('Label')).dx,
      24,
    );
  });

  testWidgets('in a Column it is 24 tall and the column keeps its width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          key: Key('column'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10, height: 10),
            Gap(24),
            SizedBox(width: 10, height: 10),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(Gap)), const Size(0, 24));
    expect(tester.getSize(find.byKey(const Key('column'))), const Size(10, 44));
  });

  testWidgets('a stretched Row still stretches it across', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 100,
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Gap(24)],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Gap)), const Size(24, 40));
  });

  testWidgets('it answers intrinsics along the flex axis only', (tester) async {
    await tester.pumpWidget(
      _host(
        const IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [_label, Gap(24), _value],
          ),
        ),
      ),
    );
    final row = tester.renderObject<RenderFlex>(find.byType(Row));
    expect(row.getMaxIntrinsicWidth(double.infinity), 224);
    expect(row.getMinIntrinsicHeight(double.infinity), 20);
    expect(tester.getSize(find.byType(Row)).height, 20);
  });

  testWidgets('it is a square outside a Flex: in a Wrap, a Stack, a Padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(children: [Gap(24, key: Key('wrap'))]),
            Stack(children: [Gap(24, key: Key('stack'))]),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: Gap(24, key: Key('padding')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    for (final key in ['wrap', 'stack', 'padding']) {
      expect(
        tester.getSize(find.byKey(Key(key))),
        const Size.square(24),
        reason: key,
      );
    }
  });

  testWidgets('keyed by the direction, it follows a Flex that turns', (
    tester,
  ) async {
    // Unbounded both ways, a Row and a Column hand a child the same
    // constraints, so only the new key lays the Gap out again.
    Widget flex(Axis direction) => _host(
      UnconstrainedBox(
        child: Flex(
          direction: direction,
          mainAxisSize: MainAxisSize.min,
          children: [
            _label,
            Gap(24, key: ValueKey(direction)),
            _value,
          ],
        ),
      ),
    );
    await tester.pumpWidget(flex(Axis.horizontal));
    expect(tester.getSize(find.byType(Gap)), const Size(24, 0));
    await tester.pumpWidget(flex(Axis.vertical));
    expect(tester.getSize(find.byType(Gap)), const Size(0, 24));
    expect(tester.getSize(find.byType(Flex)).height, 64);
    final flexBox = tester.renderObject<RenderFlex>(find.byType(Flex));
    expect(flexBox.getMaxIntrinsicHeight(double.infinity), 64);
    expect(flexBox.getMaxIntrinsicWidth(double.infinity), 100);
  });

  testWidgets('a new size lays it out again', (tester) async {
    Widget row(double gap) => _host(
      Row(mainAxisSize: MainAxisSize.min, children: [_label, Gap(gap), _value]),
    );
    await tester.pumpWidget(row(24));
    await tester.pumpWidget(row(8));
    expect(tester.getSize(find.byType(Gap)), const Size(8, 0));
    expect(tester.getSize(find.byType(Row)).width, 208);
  });
}
