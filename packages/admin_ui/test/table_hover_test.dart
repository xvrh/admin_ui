import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('hover repaints the rows it crosses, rebuilding no cell', (
    tester,
  ) async {
    final rows = [for (var i = 0; i < 6; i++) 'Row $i'];
    final built = <String, int>{};
    Widget cell(String row) {
      built.update(row, (n) => n + 1, ifAbsent: () => 1);
      return Text(row);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 400,
            child: CollectionTable<String>(
              rows: rows,
              rowKey: (r) => r,
              striped: true,
              selected: const {'Row 2'},
              onSelectionChanged: (_) {},
              onRowTap: (_) {},
              columns: [
                TableColumn(label: 'Name', cell: cell),
                TableColumn(label: 'Copy', cell: cell),
              ],
            ),
          ),
        ),
      ),
    );
    expect(built.values, everyElement(2), reason: 'two columns, one build');
    built.clear();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 10));
    addTearDown(mouse.removePointer);
    for (var y = 50.0; y < 360; y += 13) {
      await mouse.moveTo(Offset(400, y));
      await tester.pump();
    }
    await mouse.moveTo(const Offset(400, 330)); // Row 5
    await tester.pump();

    expect(built, isEmpty, reason: 'no TableColumn.cell ran on hover');
    final washes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((b) => b.color == irisPalette.tableRowHover);
    expect(washes, hasLength(3), reason: 'one row washed, in three cells');
  });
}
