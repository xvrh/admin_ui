import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'sample.dart';

/// The state a connected-collection demo is pinned in, picked with its
/// "State" knob so each one is a static preview.
enum DemoListState {
  live('Live'),
  selected('Selected rows'),
  reloading('Reloading'),
  firstLoad('First load'),
  empty('Empty'),
  noResults('No results'),
  error('Error');

  final String label;
  const DemoListState(this.label);

  static DemoListState knob(BuildContext context) => context.knobs.picker(
    'State',
    {for (final s in values) s.label: s},
    DemoListState.live,
  );
}

/// A [CollectionController] over the sample products, pinned in [state]:
/// a live fetch with latency (failing while [failNext] says so), a first page
/// with three rows selected, a reload that never lands, a first load that
/// never lands, an empty source, a search that matches nothing, or a failed
/// load.
CollectionController<Product> demoProductController(
  DemoListState state, {
  required int pageSize,
  bool Function()? failNext,
}) {
  final products = productSource(sampleProducts(137));
  final never = Completer<CollectionPage<Product>>();
  var loads = 0;
  Future<CollectionPage<Product>> fetch(CollectionQuery q) async {
    loads++;
    switch (state) {
      case DemoListState.firstLoad:
        return never.future;
      case DemoListState.reloading when loads > 1:
        return never.future;
      case DemoListState.empty:
        return const CollectionPage(items: [], total: 0);
      case DemoListState.error:
        throw Exception('Connection refused');
      case DemoListState.live:
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (failNext?.call() ?? false) {
          throw Exception('Connection refused');
        }
      default:
    }
    return products.fetch(q);
  }

  final controller = CollectionController<Product>(
    fetcher: fetch,
    rowKey: (p) => p.id,
    initialQuery: CollectionQuery(
      sortKey: 'name',
      pageSize: pageSize,
      search: state == DemoListState.noResults ? 'zzz' : '',
    ),
  );
  if (state == DemoListState.selected || state == DemoListState.reloading) {
    void pin() {
      if (controller.loading || controller.items.isEmpty) return;
      controller.removeListener(pin);
      final items = controller.items;
      if (state == DemoListState.selected) {
        controller.setSelected({items[0], items[2], items[3]});
      } else {
        scheduleMicrotask(controller.refresh);
      }
    }

    controller.addListener(pin);
  }
  return controller;
}

/// Demo — the connected [Collection]: a [CollectionController] driven by a fake
/// in-memory fetcher (sort + filter + slice + simulated latency), with a
/// sibling [CollectionToolbar] bound to the controller's search box and an
/// error-injection toggle. Exercises the real load/refresh/sort/page/search
/// loop without a server; the "State" knob pins selection, loading, empty,
/// no-results and error.
class CollectionConnectedDemo extends StatelessWidget {
  @Preview(name: 'Connected (controller + fetcher)', wrapper: adminUiPreview)
  const CollectionConnectedDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final state = DemoListState.knob(context);
    return _ConnectedDemo(key: ValueKey(state), state: state);
  }
}

class _ConnectedDemo extends StatefulWidget {
  final DemoListState state;
  const _ConnectedDemo({super.key, required this.state});

  @override
  State<_ConnectedDemo> createState() => _ConnectedDemoState();
}

class _ConnectedDemoState extends State<_ConnectedDemo> {
  bool _failNext = false;

  late final CollectionController<Product> _controller = demoProductController(
    widget.state,
    pageSize: 10,
    failNext: () => _failNext,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return collectionFrame(
      context,
      controls: CollectionToolbar(
        searchController: _controller.searchController,
        searchHint: 'Search products…',
        trailing: [
          Toggle(
            value: _failNext,
            onChanged: (v) => setState(() => _failNext = v),
            label: 'Fail next load',
          ),
          Button(
            'Refresh',
            icon: Icons.refresh,
            onPressed: _controller.refresh,
          ),
        ],
      ),
      table: Collection<Product>(
        controller: _controller,
        selectable: true,
        showPageSize: true,
        onRowTap: (p) => ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Open ${p.name}'),
              duration: const Duration(milliseconds: 900),
            ),
          ),
        columns: _columns,
      ),
    );
  }

  List<TableColumn<Product>> get _columns => [
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
      fixed: 150,
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
      cellBuilder: (context, p) => Text(
        p.stock?.toString() ?? '—',
        style: TextStyle(
          color: p.stock == null ? context.colors.foregroundMuted : null,
        ),
      ),
    ),
  ];
}
