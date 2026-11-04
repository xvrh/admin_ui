import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../sample.dart';

/// Demo 4 — selection + bulk + row actions: a leading checkbox column with
/// select-all-on-page, a bulk action bar that appears once a row is selected,
/// and a per-row kebab menu. Selection is controlled by the demo and keyed by
/// product id: it opens with two rows picked from a separate fetch — fresh
/// objects, as a refetch returns — one striped and one plain, so the
/// selected fill reads against the stripe. A tap anywhere in a checkbox's
/// cell toggles it, not only on the box.
class DataTableSelectionDemo extends StatefulWidget {
  @Preview(name: 'Selection + bulk', wrapper: adminUiPreview)
  const DataTableSelectionDemo({super.key});

  @override
  State<DataTableSelectionDemo> createState() => _DataTableSelectionDemoState();
}

class _DataTableSelectionDemoState extends State<DataTableSelectionDemo> {
  final _all = sampleProducts(14);

  /// Picked from another fetch: equal to rows 2 and 3 only by key.
  late Set<Product> _selected = {...sampleProducts(14).getRange(1, 3)};

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );

  @override
  Widget build(BuildContext context) {
    return collectionFrame(
      context,
      controls: _selected.isEmpty ? _idleBar() : _bulkBar(),
      table: CollectionTable<Product>(
        rows: _all,
        rowKey: (p) => p.id,
        striped: true,
        selected: _selected,
        onSelectionChanged: (s) => setState(() => _selected = s),
        onRowTap: (p) => _toast('Open ${p.name}'),
        columns: [
          TableColumn(
            label: 'Product',
            flex: 2,
            minWidth: 220,
            pinned: true,
            cell: productIdentity,
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
            cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
          ),
          TableColumn(
            label: '',
            fixed: 56,
            align: Alignment.center,
            cell: (p) => MenuButton(
              icon: Icons.more_horiz,
              entries: [
                MenuItem(
                  'Edit',
                  icon: Icons.edit_outlined,
                  onSelect: () => _toast('Edit ${p.name}'),
                ),
                MenuItem(
                  'Duplicate',
                  icon: Icons.copy_rounded,
                  onSelect: () => _toast('Duplicate ${p.name}'),
                ),
                const MenuDivider(),
                MenuItem(
                  'Delete',
                  icon: Icons.delete_outline,
                  danger: true,
                  onSelect: () => _toast('Delete ${p.name}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idleBar() {
    return CollectionToolbar(
      leading: Text('${_all.length} products', style: context.type.bodyStrong),
      trailing: [
        Button.primary('New product', icon: Icons.add, onPressed: () {}),
      ],
    );
  }

  Widget _bulkBar() {
    void clear() => setState(() => _selected = {});
    return BulkActionBar(
      count: _selected.length,
      onClear: clear,
      actions: [
        BulkAction(
          'Publish',
          icon: Icons.publish_outlined,
          onPressed: () {
            _toast('Published ${_selected.length}');
            clear();
          },
        ),
        BulkAction(
          'Delete',
          icon: Icons.delete_outline,
          danger: true,
          onPressed: () {
            _toast('Deleted ${_selected.length}');
            clear();
          },
        ),
      ],
    );
  }
}
