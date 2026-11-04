import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A child of a known height, found by its [label].
Widget box(String label, {double height = 40}) =>
    SizedBox(key: ValueKey(label), height: height);

Rect rectOf(WidgetTester tester, String label) =>
    tester.getRect(find.byKey(ValueKey(label)));

/// The grid, [width] wide, at the window's top-left corner.
Future<void> pumpGrid(
  WidgetTester tester,
  double width,
  List<Widget> children, {
  FormColumns columns = const FormColumns(compact: 1, medium: 2, expanded: 3),
  TextDirection textDirection = TextDirection.ltr,
  double? columnGap,
  double? rowGap,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: textDirection,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: FormGrid(
            columns: columns,
            columnGap: columnGap,
            rowGap: rowGap,
            children: children,
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('the width classes break at 600 and 840', () {
    const columns = FormColumns(compact: 1, medium: 2, expanded: 3);
    expect(columns.resolve(599), 1);
    expect(columns.resolve(600), 2);
    expect(columns.resolve(839), 2);
    expect(columns.resolve(840), 3);
    expect(const FormColumns(compact: 1, medium: 2).resolve(1200), 2);
    expect(const FormColumns(compact: 2).resolve(1200), 2);
    expect(const FormColumns.fixed(4).resolve(320), 4);
  });

  group('the column count follows the grid’s own width', () {
    final children = [box('a'), box('b'), box('c')];

    testWidgets('599 wide: one column', (tester) async {
      await pumpGrid(tester, 599, children);
      expect(rectOf(tester, 'a'), const Rect.fromLTWH(0, 0, 599, 40));
      expect(rectOf(tester, 'b'), const Rect.fromLTWH(0, 56, 599, 40));
      expect(rectOf(tester, 'c'), const Rect.fromLTWH(0, 112, 599, 40));
    });

    testWidgets('600 wide: two columns', (tester) async {
      await pumpGrid(tester, 600, children);
      // (600 - 16) / 2 = 292 a column.
      expect(rectOf(tester, 'a'), const Rect.fromLTWH(0, 0, 292, 40));
      expect(rectOf(tester, 'b'), const Rect.fromLTWH(308, 0, 292, 40));
      expect(rectOf(tester, 'c'), const Rect.fromLTWH(0, 56, 292, 40));
    });

    testWidgets('839 wide: still two columns', (tester) async {
      await pumpGrid(tester, 839, children);
      // 411.5 a column, its edges rounded to whole pixels.
      expect(rectOf(tester, 'a'), const Rect.fromLTWH(0, 0, 412, 40));
      expect(rectOf(tester, 'b'), const Rect.fromLTWH(428, 0, 411, 40));
      expect(rectOf(tester, 'c').top, 56);
    });

    testWidgets('840 wide: three columns', (tester) async {
      await pumpGrid(tester, 840, children);
      // (840 - 2 × 16) / 3 = 269.33 a column.
      expect(rectOf(tester, 'a'), const Rect.fromLTWH(0, 0, 269, 40));
      expect(rectOf(tester, 'b'), const Rect.fromLTWH(285, 0, 270, 40));
      expect(rectOf(tester, 'c'), const Rect.fromLTWH(571, 0, 269, 40));
    });
  });

  testWidgets('a span takes its columns and the gaps between them; a span '
      'that does not fit starts a row; fullWidth takes the row', (
    tester,
  ) async {
    await pumpGrid(tester, 900, columnGap: 24, rowGap: 16, [
      box('a'),
      FormGridItem(span: 2, child: box('wide')),
      box('b'),
      FormGridItem(span: 3, child: box('three')),
      box('c'),
      FormGridItem(fullWidth: true, child: box('full', height: 80)),
      FormGridItem(span: 9, child: box('clamped')),
    ]);
    // (900 - 2 × 24) / 3 = 284 a column.
    expect(rectOf(tester, 'a'), const Rect.fromLTWH(0, 0, 284, 40));
    expect(rectOf(tester, 'wide'), const Rect.fromLTWH(308, 0, 592, 40));
    expect(rectOf(tester, 'b'), const Rect.fromLTWH(0, 56, 284, 40));
    expect(rectOf(tester, 'three'), const Rect.fromLTWH(0, 112, 900, 40));
    expect(rectOf(tester, 'c'), const Rect.fromLTWH(0, 168, 284, 40));
    expect(rectOf(tester, 'full'), const Rect.fromLTWH(0, 224, 900, 80));
    expect(rectOf(tester, 'clamped'), const Rect.fromLTWH(0, 320, 900, 40));
    expect(tester.getSize(find.byType(FormGrid)), const Size(900, 360));
  });

  testWidgets('column edges land on whole pixels', (tester) async {
    await pumpGrid(tester, 970, [box('a'), box('b'), box('c')]);
    // (970 - 2 × 16) / 3 = 312.67 a column.
    expect(rectOf(tester, 'a'), const Rect.fromLTWH(0, 0, 313, 40));
    expect(rectOf(tester, 'b'), const Rect.fromLTWH(329, 0, 312, 40));
    expect(rectOf(tester, 'c'), const Rect.fromLTWH(657, 0, 313, 40));

    await pumpGrid(tester, 970, textDirection: TextDirection.rtl, [
      box('a'),
      FormGridItem(span: 2, child: box('wide')),
    ]);
    expect(rectOf(tester, 'a'), const Rect.fromLTWH(657, 0, 313, 40));
    expect(rectOf(tester, 'wide'), const Rect.fromLTWH(0, 0, 641, 40));
  });

  testWidgets('narrower than its gaps, it lays out without failing', (
    tester,
  ) async {
    await pumpGrid(tester, 10, columns: const FormColumns.fixed(3), [
      box('a'),
      box('b'),
      box('c'),
    ]);
    expect(tester.takeException(), isNull);
    expect(rectOf(tester, 'c').width, 0);
  });

  testWidgets('a row is as tall as its tallest child, each at its top', (
    tester,
  ) async {
    await pumpGrid(tester, 700, [
      box('short', height: 40),
      box('tall', height: 90),
      box('next'),
    ]);
    expect(rectOf(tester, 'short').top, 0);
    expect(rectOf(tester, 'short').height, 40);
    expect(rectOf(tester, 'tall').top, 0);
    expect(rectOf(tester, 'next').top, 90 + 16);
  });

  testWidgets('right to left, the first column is on the right', (
    tester,
  ) async {
    await pumpGrid(tester, 600, textDirection: TextDirection.rtl, [
      box('a'),
      box('b'),
      FormGridItem(fullWidth: true, child: box('full')),
    ]);
    expect(rectOf(tester, 'a'), const Rect.fromLTWH(308, 0, 292, 40));
    expect(rectOf(tester, 'b'), const Rect.fromLTWH(0, 0, 292, 40));
    expect(rectOf(tester, 'full'), const Rect.fromLTWH(0, 56, 600, 40));
  });

  group('a child that lays out zero tall', () {
    testWidgets('takes no gap in one column', (tester) async {
      await pumpGrid(tester, 400, [
        box('a'),
        box('hidden', height: 0),
        box('b'),
        box('hidden at the end', height: 0),
      ]);
      expect(rectOf(tester, 'b').top, 40 + 16);
      expect(tester.getSize(find.byType(FormGrid)).height, 96);
    });

    testWidgets('takes no column in two', (tester) async {
      await pumpGrid(tester, 700, [
        box('hidden first', height: 0),
        box('a'),
        box('hidden', height: 0),
        box('b'),
        box('c'),
      ]);
      expect(rectOf(tester, 'a').topLeft, Offset.zero);
      expect(rectOf(tester, 'b').topLeft, const Offset(358, 0));
      expect(rectOf(tester, 'c').topLeft, const Offset(0, 56));
    });

    testWidgets('leaves an empty grid zero tall', (tester) async {
      await pumpGrid(tester, 700, [box('hidden', height: 0)]);
      expect(tester.getSize(find.byType(FormGrid)), const Size(700, 0));
    });
  });

  testWidgets('measures dry and intrinsically as it lays out', (tester) async {
    await pumpGrid(tester, 700, [
      box('a'),
      box('hidden', height: 0),
      FormGridItem(fullWidth: true, child: box('full', height: 80)),
    ]);
    final grid = tester.renderObject<RenderBox>(
      find.descendant(
        of: find.byType(FormGrid),
        matching: find.byWidgetPredicate(
          (w) => w is MultiChildRenderObjectWidget,
        ),
      ),
    );
    expect(grid.size, const Size(700, 136));
    expect(
      grid.getDryLayout(const BoxConstraints(maxWidth: 700)),
      const Size(700, 136),
    );
    expect(grid.getMinIntrinsicHeight(700), 136);
    expect(grid.getMaxIntrinsicHeight(700), 136);
  });

  testWidgets('a keyed child keeps its state when the children reorder', (
    tester,
  ) async {
    Widget field(String id) => _Counter(key: ValueKey(id), label: id);
    await pumpGrid(tester, 700, [field('x'), field('y')]);
    await tester.tap(find.text('x 0'));
    await tester.pump();
    expect(find.text('x 1'), findsOneWidget);

    await pumpGrid(tester, 700, [field('y'), field('x')]);
    expect(find.text('x 1'), findsOneWidget);
    expect(tester.getTopLeft(find.text('x 1')).dx, greaterThan(300));
  });

  for (final direction in TextDirection.values) {
    testWidgets('Tab moves along a row, then down ($direction)', (
      tester,
    ) async {
      final nodes = [for (var i = 0; i < 4; i++) FocusNode(debugLabel: '$i')];
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
      });
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: FormGrid(
              children: [
                for (final node in nodes)
                  Focus(focusNode: node, child: const SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      );
      nodes.first.requestFocus();
      await tester.pump();
      for (final node in nodes.skip(1)) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(node.hasPrimaryFocus, isTrue, reason: node.debugLabel);
      }
    });
  }

  testWidgets('real fields in 320 wide stack without overflowing', (
    tester,
  ) async {
    final form = ValueFormController<String>(
      read: (s) => s.text('name').value,
      write: (s, v) => s.text('name').set(v),
      initial: 'Ada',
    );
    addTearDown(form.dispose);
    final s = form.scope;
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        supportedLocales: AdminLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueForm(
            controller: form,
            child: ListView(
              children: [
                FormGrid(
                  columns: const FormColumns(compact: 1, medium: 2),
                  children: [
                    Field(s.text('name'), label: 'Name', required: true),
                    Field(s.text('email'), label: 'Email address'),
                    FormGridItem(
                      fullWidth: true,
                      child: Field(
                        s.text('notes'),
                        label: 'Notes',
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 280,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Finder shell(String label) =>
        find.byWidgetPredicate((w) => w is FieldShell && w.label == label);
    final name = tester.getRect(shell('Name'));
    final email = tester.getRect(shell('Email address'));
    expect(name.width, 320);
    expect(email.left, name.left);
    expect(email.top, name.bottom + AdminSpacing.lg, reason: 'under a form');
  });
}

class _Counter extends StatefulWidget {
  final String label;

  const _Counter({super.key, required this.label});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _count++),
    child: Text('${widget.label} $_count'),
  );
}
