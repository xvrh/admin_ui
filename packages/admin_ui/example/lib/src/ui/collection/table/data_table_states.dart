import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../sample.dart';

/// Demo 2 — CollectionTable body states, one per knob value: populated, a
/// first load (skeleton rows), a refetch (the rows dim under a top bar, the
/// header doesn't), empty, no results for a filter, error and a single row.
/// Empty, no-results and error sit under the real header, which still
/// scrolls sideways with its pinned column; the narrow entry shows that at
/// phone width.
class DataTableStatesDemo extends StatelessWidget {
  final double? width;

  @Preview(name: 'States', wrapper: adminUiPreview)
  const DataTableStatesDemo({super.key}) : width = null;

  @Preview(name: 'States (narrow)', wrapper: adminUiPreview)
  const DataTableStatesDemo.narrow({super.key}) : width = 360;

  @override
  Widget build(BuildContext context) {
    final state = context.knobs.picker('State', const {
      'Populated': _State.populated,
      'First load': _State.firstLoad,
      'Refetch': _State.refetch,
      'Empty': _State.empty,
      'No results': _State.noResults,
      'Error': _State.error,
      'Single row': _State.single,
    }, _State.populated);
    final table = _StatesTable(state: state);
    final width = this.width;
    if (width == null) return collectionFrame(context, table: table);
    return ColoredBox(
      color: context.colors.background,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: width,
          child: collectionFrame(context, table: table),
        ),
      ),
    );
  }
}

enum _State { populated, firstLoad, refetch, empty, noResults, error, single }

class _StatesTable extends StatefulWidget {
  final _State state;

  const _StatesTable({required this.state});

  @override
  State<_StatesTable> createState() => _StatesTableState();
}

class _StatesTableState extends State<_StatesTable> {
  static final _all = sampleProducts(20);

  /// Set by the empty states' actions, to show them working.
  _State? _override;

  @override
  void didUpdateWidget(_StatesTable old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _override = null;
  }

  _State get _state => _override ?? widget.state;

  List<Product> get _rows => switch (_state) {
    _State.firstLoad ||
    _State.empty ||
    _State.noResults ||
    _State.error => const [],
    _State.single => _all.take(1).toList(),
    _ => _all,
  };

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return CollectionTable<Product>(
      rows: _rows,
      rowKey: (p) => p.id,
      loading: state == _State.firstLoad || state == _State.refetch,
      error: state == _State.error
          ? ErrorState(
              title: "Couldn't load products",
              message: 'Check your connection and try again.',
              onRetry: () => setState(() => _override = _State.populated),
            )
          : null,
      filtered: state == _State.noResults,
      onClearFilters: () => setState(() => _override = _State.populated),
      empty: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Create your first product to get started.',
        action: Button.primary(
          'New product',
          icon: Icons.add,
          onPressed: () {},
        ),
      ),
      columns: _columns,
    );
  }

  List<TableColumn<Product>> get _columns => [
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
      label: 'Updated',
      fixed: 130,
      cellBuilder: (context, p) =>
          Text(p.updated, style: tableMutedStyle(context)),
    ),
  ];
}
