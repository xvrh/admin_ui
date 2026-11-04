import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'shipped_palettes.dart';

const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

const _rows = ['Alpha', 'Bravo', 'Cherry', 'Delta'];

void main() {
  for (final MapEntry(key: name, value: base) in shippedPalettes.entries) {
    for (final MapEntry(key: brand, value: seed) in _brands.entries) {
      final colors = seed == null ? base : base.branded(seed);
      testWidgets('$name + $brand: row fills, hover and muted text', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(AdminTokens.from(palette: colors)),
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: Builder(
                  builder: (context) => CollectionTable<String>(
                    rows: _rows,
                    rowKey: (r) => r,
                    striped: true,
                    // A plain row, a stripe, and one selection of each.
                    selected: const {'Cherry', 'Delta'},
                    onSelectionChanged: (_) {},
                    columns: [
                      const TableColumn(label: 'Name', cell: Text.new),
                      TableColumn(
                        label: 'Note',
                        cell: (r) =>
                            Text('$r note', style: tableMutedStyle(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final table = tester.widget<TwoDimensionalScrollView>(
          find.byWidgetPredicate((w) => w is TwoDimensionalScrollView),
        );
        final delegate = table.delegate as TableCellBuilderDelegate;
        Color fill(int row) =>
            delegate.buildRow(row + 1)!.backgroundDecoration!.color!;

        expect(fill(0), colors.surface);
        expect(fill(1), colors.tableRowStripe);
        expect(fill(2), colors.tableRowSelected);
        expect(fill(3), colors.tableRowSelected, reason: 'over the stripe');
        expect(
          colors.tableRowStripe,
          base.tableRowStripe,
          reason: 'a brand never tints the stripe',
        );

        final muted = tester
            .renderObject<RenderParagraph>(find.text('Alpha note'))
            .text
            .style!
            .color!;
        final foreground = tester
            .renderObject<RenderParagraph>(find.text('Alpha'))
            .text
            .style!
            .color!;

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer();
        addTearDown(mouse.removePointer);
        for (final (i, row) in _rows.indexed) {
          await mouse.moveTo(tester.getCenter(find.text(row)));
          await tester.pump();
          final wash = tester
              .widgetList<ColoredBox>(find.byType(ColoredBox))
              .map((b) => b.color)
              .where(
                (c) =>
                    c == colors.tableRowHover ||
                    c == colors.tableRowSelectedHover,
              )
              .toSet();
          final selected = i >= 2;
          expect(wash, {
            selected ? colors.tableRowSelectedHover : colors.tableRowHover,
          }, reason: '$row under the pointer');
          final hovered = selected
              ? colors.tableRowSelectedHover
              : Color.alphaBlend(colors.tableRowHover, fill(i));
          for (final surface in [fill(i), hovered]) {
            for (final (text, what) in [
              (foreground, 'text'),
              (muted, 'muted'),
            ]) {
              final ratio = contrastRatio(text, surface);
              expect(
                ratio,
                greaterThanOrEqualTo(4.5),
                reason:
                    '$what on $row ${surface == hovered ? '(hovered)' : ''}: '
                    '${ratio.toStringAsFixed(2)}:1',
              );
            }
          }
        }
      });
    }
  }
}
