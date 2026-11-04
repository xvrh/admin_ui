import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';

/// Demo — inline cell editing in a table whose rows also open on a tap.
/// Double-click a Name or Price cell, or focus it and press Enter or F2:
/// `editTrigger: TableEditTrigger.doubleTap` lets a double tap edit while a
/// single tap still opens the row, once the double-tap window has passed.
/// A tap on the read-only ID opens its row at once. The stock
/// [TableTextEditor] keeps a draft: Enter, Tab or a click away saves it,
/// Escape drops it, and Tab moves on to the next editable cell. Price
/// parses as a number and stays open while it doesn't.
class DataTableInlineEditDemo extends StatefulWidget {
  @Preview(name: 'Inline cell editing', wrapper: adminUiPreview)
  const DataTableInlineEditDemo({super.key});

  @override
  State<DataTableInlineEditDemo> createState() =>
      _DataTableInlineEditDemoState();
}

class _DataTableInlineEditDemoState extends State<DataTableInlineEditDemo> {
  late final List<_Row> _rows = [..._seed];

  void _open(_Row row) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('Open ${row.name}'),
        duration: const Duration(milliseconds: 900),
      ),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Double-click, Enter or F2 to edit · a click opens the row · '
              'Enter saves · Esc cancels · Tab to the next cell · ID is '
              'read-only',
              style: context.type.caption,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(
                    context.radii.radiusLarge,
                  ),
                  border: Border.all(color: context.colors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    context.radii.radiusLarge,
                  ),
                  child: CollectionTable<_Row>(
                    rows: _rows,
                    rowKey: (r) => r.id,
                    onRowTap: _open,
                    editTrigger: TableEditTrigger.doubleTap,
                    columns: _columns,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumn<_Row>> get _columns => [
    TableColumn(
      label: 'Name',
      flex: 2,
      minWidth: 200,
      pinned: true,
      cell: (r) => Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      editBuilder: (r, session) => TableTextEditor(
        session: session,
        value: r.name,
        onCommit: (v) => setState(() => r.name = v),
      ),
    ),
    TableColumn(
      label: 'Price',
      fixed: 140,
      numeric: true,
      cell: (r) => Text('\$${r.price.toStringAsFixed(2)}'),
      editBuilder: (r, session) => TableTextEditor.number(
        session: session,
        value: r.price,
        fractionDigits: 2,
        onCommit: (v) => setState(() => r.price = v.toDouble()),
      ),
    ),
    TableColumn(
      label: 'ID',
      fixed: 90,
      numeric: true,
      cellBuilder: (context, r) => Text(r.id, style: tableMutedStyle(context)),
    ),
  ];
}

class _Row {
  final String id;
  String name;
  double price;
  _Row(this.id, this.name, this.price);
}

final _seed = <_Row>[
  _Row('#1042', 'Aurora Wool Coat', 248.00),
  _Row('#2210', 'Trailhead Boots', 179.50),
  _Row('#3318', 'Leather Watch', 89.99),
  _Row('#4401', 'Cedar Throw Blanket', 64.00),
  _Row('#5567', 'Summit Daypack', 120.00),
];
