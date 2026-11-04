import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../sample.dart';

/// Demo 5 — sorting + pagination wired like the real server contract: a single
/// sort column (ascending, descending, then unsorted), offset pages,
/// page-size selector. Sorting/​paging happen on the
/// "backend" here (sort then slice) and feed the controlled [CollectionTable] +
/// [Pager], mirroring how a Screen drives a SliceRequest.
class DataTablePagedDemo extends StatefulWidget {
  @Preview(name: 'Sorting + pagination', wrapper: adminUiPreview)
  const DataTablePagedDemo({super.key});

  @override
  State<DataTablePagedDemo> createState() => _DataTablePagedDemoState();
}

class _DataTablePagedDemoState extends State<DataTablePagedDemo> {
  static final _all = sampleProducts(137);

  TableSort? _sort = const TableSort('name');
  int _pageSize = 10;
  int _page = 0; // zero-based

  List<Product> get _sorted {
    final sort = _sort;
    if (sort == null) return _all;
    int cmp(Product a, Product b) => switch (sort.key) {
      'price' => a.price.compareTo(b.price),
      'stock' => (a.stock ?? -1).compareTo(b.stock ?? -1),
      'updated' => a.updated.compareTo(b.updated),
      _ => a.name.compareTo(b.name),
    };
    final list = [..._all]
      ..sort((a, b) => sort.ascending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final total = _all.length;
    final sorted = _sorted;
    final start = _page * _pageSize;
    final page = sorted.skip(start).take(_pageSize).toList();

    return collectionFrame(
      context,
      table: CollectionTable<Product>(
        rows: page,
        rowKey: (p) => p.id,
        sort: _sort,
        onSort: (key, asc) => setState(() {
          _sort = TableSort(key, ascending: asc);
          _page = 0;
        }),
        onClearSort: () => setState(() {
          _sort = null;
          _page = 0;
        }),
        onRowTap: (_) {},
        columns: [
          TableColumn(
            label: 'Product',
            flex: 2,
            minWidth: 220,
            pinned: true,
            sortKey: 'name',
            cell: productIdentity,
          ),
          TableColumn(
            label: 'Status',
            fixed: 140,
            cell: (p) => Tag(p.status, severity: p.tone, dot: true),
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
            label: 'Price',
            fixed: 100,
            numeric: true,
            sortKey: 'price',
            cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
          ),
          TableColumn(
            label: 'Updated',
            fixed: 130,
            sortKey: 'updated',
            cellBuilder: (context, p) =>
                Text(p.updated, style: tableMutedStyle(context)),
          ),
        ],
      ),
      footer: Pager(
        from: total == 0 ? 0 : start + 1,
        to: start + page.length,
        total: total,
        hasPrev: _page > 0,
        hasNext: start + _pageSize < total,
        onPrev: () => setState(() => _page--),
        onNext: () => setState(() => _page++),
        page: _page + 1,
        onPage: (p) => setState(() => _page = p - 1),
        pageSize: _pageSize,
        onPageSize: (s) => setState(() {
          _pageSize = s;
          _page = 0;
        }),
      ),
    );
  }
}
