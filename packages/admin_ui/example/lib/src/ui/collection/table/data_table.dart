import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';

/// Demo 1 — CollectionTable basics: populated, click-to-sort (controlled, with
/// a way back to unsorted), a pinned identity column, numeric columns in
/// tabular figures, a sticky header and deliberately awkward rows (overflow,
/// unicode/RTL, null cells). Knobs switch density, striping, loading and the
/// empty state.
class DataTableDemo extends StatefulWidget {
  @Preview(name: 'Basics', wrapper: adminUiPreview)
  const DataTableDemo({super.key});

  @override
  State<DataTableDemo> createState() => _DataTableDemoState();
}

class _DataTableDemoState extends State<DataTableDemo> {
  TableSort? _sort = const TableSort('name');

  List<_Product> _rows(bool empty) {
    if (empty) return const [];
    final list = [..._seed];
    final sort = _sort;
    if (sort == null) return list;
    int cmp(_Product a, _Product b) => switch (sort.key) {
      'name' => a.name.compareTo(b.name),
      'price' => a.price.compareTo(b.price),
      'stock' => (a.stock ?? -1).compareTo(b.stock ?? -1),
      'updated' => a.updated.compareTo(b.updated),
      _ => 0,
    };
    list.sort((a, b) => sort.ascending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final knobs = context.knobs;
    final density = knobs.picker('Density', const {
      'Compact': TableDensity.compact,
      'Standard': TableDensity.standard,
      'Comfortable': TableDensity.comfortable,
    }, TableDensity.standard);
    final striped = knobs.bool('Striped', false);
    final loading = knobs.bool('Loading', false);
    final empty = knobs.bool('Empty', false);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Click a header to sort · hover a row · scroll right for the '
              'pin · Tab in, then arrows, Enter and Space',
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
                  child: CollectionTable<_Product>(
                    rows: _rows(empty),
                    rowKey: (p) => p.sku,
                    density: density,
                    striped: striped,
                    sort: _sort,
                    loading: loading,
                    onSort: (key, asc) =>
                        setState(() => _sort = TableSort(key, ascending: asc)),
                    onClearSort: () => setState(() => _sort = null),
                    onRowTap: (p) => ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Tapped ${p.name}'),
                          duration: const Duration(milliseconds: 900),
                        ),
                      ),
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

  List<TableColumn<_Product>> get _columns => [
    TableColumn(
      label: 'Product',
      flex: 2,
      minWidth: 220,
      pinned: true,
      sortKey: 'name',
      cell: (p) => TableIdentity(
        leading: TableThumb(color: p.swatch),
        title: p.name,
        subtitle: p.sku,
      ),
    ),
    TableColumn(
      label: 'Status',
      fixed: 140,
      cell: (p) => Tag(p.status, severity: p.tone, dot: true),
    ),
    TableColumn(
      label: 'Category',
      flex: 1,
      minWidth: 120,
      cell: (p) =>
          Text(p.category, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    TableColumn(
      label: 'Price',
      fixed: 100,
      numeric: true,
      sortKey: 'price',
      cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
    ),
    TableColumn(
      label: 'Stock',
      fixed: 90,
      numeric: true,
      sortKey: 'stock',
      cellBuilder: (context, p) => p.stock == null
          ? Text('—', style: tableMutedStyle(context))
          : Text('${p.stock}'),
    ),
    TableColumn(
      label: 'Updated',
      fixed: 130,
      sortKey: 'updated',
      cellBuilder: (context, p) =>
          Text(p.updated, style: tableMutedStyle(context)),
    ),
  ];
}

class _Product {
  final String name;
  final String sku;
  final Color swatch;
  final String status;
  final Severity tone;
  final String category;
  final double price;
  final int? stock;
  final String updated;
  const _Product(
    this.name,
    this.sku,
    this.swatch,
    this.status,
    this.tone,
    this.category,
    this.price,
    this.stock,
    this.updated,
  );
}

const _seed = <_Product>[
  _Product(
    'Aurora Wool Coat',
    'SKU-1042',
    Color(0xFF5b5bd6),
    'Published',
    Severity.success,
    'Apparel',
    248.00,
    12,
    '2026-06-12',
  ),
  _Product(
    'Trailhead Boots — waterproof full-grain leather, lugged outsole',
    'SKU-2210',
    Color(0xFF2f9e63),
    'Draft',
    Severity.info,
    'Footwear',
    179.50,
    0,
    '2026-06-09',
  ),
  _Product(
    'برج الساعة الجلدية',
    'SKU-3318',
    Color(0xFFcf8a00),
    'Needs review',
    Severity.warning,
    'Accessories',
    89.99,
    240,
    '2026-05-30',
  ),
  _Product(
    'Cedar Throw Blanket',
    'SKU-4401',
    Color(0xFFd24b3e),
    'Archived',
    Severity.danger,
    'Home',
    64.00,
    null,
    '2026-05-21',
  ),
  _Product(
    'Summit Daypack',
    'SKU-5567',
    Color(0xFF4EABFB),
    'Published',
    Severity.success,
    'Outdoor',
    120.00,
    58,
    '2026-06-14',
  ),
  _Product(
    'Linen Camp Shirt',
    'SKU-6690',
    Color(0xFF5b5bd6),
    'Published',
    Severity.success,
    'Apparel',
    72.00,
    134,
    '2026-04-18',
  ),
  _Product(
    'Harbor Wool Socks',
    'SKU-7712',
    Color(0xFF2f9e63),
    'Draft',
    Severity.info,
    'Apparel',
    18.00,
    410,
    '2026-06-01',
  ),
];
