import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

Widget _host(
  Widget child, {
  AdminPalette palette = irisPalette,
  double width = 800,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

/// Four weekly cohorts over three later weeks, the newest not reached yet
/// past its first, and one week in which nobody came back.
const _table = HeatTable(
  labels: [HeatTableLabel('Week of'), HeatTableLabel('People', numeric: true)],
  columns: ['+1', '+2', '+3'],
  rows: [
    HeatTableRow(
      ['Jan 5', '400'],
      [HeatTableCell(0.57), HeatTableCell(0.41), HeatTableCell(0.33)],
    ),
    HeatTableRow(
      ['Jan 12', '20'],
      [HeatTableCell(0.25), HeatTableCell(0), null],
    ),
    HeatTableRow(['Jan 19', '310'], [HeatTableCell(0.6, text: '186')]),
    HeatTableRow(['Jan 26', '298'], []),
  ],
);

/// The fill of the value cell showing [text].
Color? _fillOf(WidgetTester tester, String text) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  group('AdminPalette.heatFill', () {
    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      test('$name: foreground reads at 4.5:1 on its strongest fill', () {
        final fill = palette.heatFill(1);
        for (final surface in [palette.surface, palette.background]) {
          expect(
            contrastRatio(palette.foreground, Color.alphaBlend(fill, surface)),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }

    test('rises with the share, from a faint wash at 0', () {
      final alphas = [
        for (final share in [0.0, 0.25, 0.5, 0.75, 1.0])
          irisPalette.heatFill(share).a,
      ];
      expect(alphas.first, greaterThan(0));
      for (var i = 1; i < alphas.length; i++) {
        expect(alphas[i], greaterThan(alphas[i - 1]));
      }
    });

    test('a share outside 0..1, or none, is held to the ends', () {
      final p = irisPalette;
      expect(p.heatFill(-1), p.heatFill(0));
      expect(p.heatFill(2), p.heatFill(1));
      expect(p.heatFill(double.nan), p.heatFill(0));
    });

    test('takes its hue from the first chart colour, or the one given', () {
      final p = irisPalette;
      expect(p.heatFill(1).withValues(alpha: 1), p.chart.first);
      final accent = p.success;
      expect(p.heatFill(1, accent: accent).withValues(alpha: 1), accent);
    });
  });

  group('HeatTable', () {
    testWidgets('shows each value as text on a fill that follows its share', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table));
      expect(find.text('57%'), findsOneWidget);
      expect(find.text('186'), findsOneWidget, reason: 'its own text');
      final p = irisPalette;
      expect(_fillOf(tester, '57%'), p.heatFill(0.57));
      expect(_fillOf(tester, '25%'), p.heatFill(0.25));
      expect(_fillOf(tester, '186'), p.heatFill(0.6));
    });

    testWidgets('a cell with no value is blank, apart from a 0%', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table));
      // 0% is a cell: its text, on the faint wash.
      expect(find.text('0%'), findsOneWidget);
      expect(_fillOf(tester, '0%'), irisPalette.heatFill(0));
      // The rest draw nothing: 4 rows × 3 weeks, of which 6 have a value.
      final fills = find.descendant(
        of: find.byType(HeatTable),
        matching: find.byWidgetPredicate(
          (w) => w is DecoratedBox && w.decoration is BoxDecoration,
        ),
      );
      expect(fills, findsNWidgets(6));
    });

    testWidgets('wide, fills the width without scrolling', (tester) async {
      await tester.pumpWidget(_host(_table, width: 800));
      expect(find.byType(Scrollbar), findsNothing);
      expect(tester.getSize(find.byType(HeatTable)).width, 800);
      // The value columns share what the labels leave, alike.
      final w1 = tester.getSize(
        find
            .ancestor(of: find.text('57%'), matching: find.byType(Padding))
            .first,
      );
      final w2 = tester.getSize(
        find
            .ancestor(of: find.text('41%'), matching: find.byType(Padding))
            .first,
      );
      expect(w1.width, w2.width);
    });

    testWidgets('narrow, the values scroll under the pinned labels', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table, width: 360));
      expect(find.byType(Scrollbar), findsOneWidget);
      final table = tester.getRect(find.byType(HeatTable));
      final label = tester.getTopLeft(find.text('Jan 5'));
      final value = tester.getTopLeft(find.text('41%'));
      expect(value.dx, lessThan(table.right), reason: 'a week shows');

      await tester.dragFrom(
        Offset(table.right - 8, tester.getCenter(find.text('Jan 5')).dy),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Jan 5')), label);
      expect(tester.getTopLeft(find.text('41%')).dx, lessThan(value.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('right to left, the labels lead from the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_table, width: 800, direction: TextDirection.rtl),
      );
      final week = tester.getCenter(find.text('Week of'));
      final people = tester.getCenter(find.text('People'));
      final first = tester.getCenter(find.text('+1'));
      expect(week.dx, greaterThan(people.dx));
      expect(people.dx, greaterThan(first.dx));
    });

    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      testWidgets('$name: lays out without overflow', (tester) async {
        await tester.pumpWidget(_host(_table, palette: palette, width: 260));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
