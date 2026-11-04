import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'sample.dart';

/// Demo — the collection header: a [CollectionToolbar] (search + filter bar +
/// "New") that a [CollectionHeader] swaps for a [BulkActionBar] once rows are
/// selected, with select-all-across-pages. Bound to a real paged
/// [CollectionController] over an in-memory fetcher, and opened with a status
/// filter applied so the active filter pill shows. The Selection knob opens it
/// with rows already selected; turn Table off to see the header alone. The
/// page scrolls, so a frame as short as the header renders it cleanly.
class CollectionToolbarDemo extends StatefulWidget {
  @Preview(name: 'Toolbar + bulk actions', wrapper: adminUiPreview)
  const CollectionToolbarDemo({super.key});

  @override
  State<CollectionToolbarDemo> createState() => _CollectionToolbarDemoState();
}

class _CollectionToolbarDemoState extends State<CollectionToolbarDemo> {
  static final _products = productSource(sampleProducts(137));

  late final CollectionController<Product> _controller = CollectionController(
    fetcher: _fetch,
    rowKey: (p) => p.id,
    initialQuery: const CollectionQuery(
      sortKey: 'name',
      pageSize: 10,
      filters: [
        OptionsFilter('status', {'Published'}, label: 'Status'),
      ],
    ),
  );

  /// The Selection knob's value the selection was last seeded from.
  String? _seeded;

  Future<CollectionPage<Product>> _fetch(CollectionQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _products.fetch(q);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );

  /// Applies the Selection knob once per value, so clicking rows afterwards
  /// still works.
  void _seed(String selection) {
    if (selection == _seeded) return;
    _seeded = selection;
    final matching = _products.matching(_controller.query).toList();
    final rows = switch (selection) {
      'Three rows' => matching.take(3).toSet(),
      'All matching' => matching.toSet(),
      _ => <Product>{},
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.setSelected(rows);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final knobs = context.knobs;
    final selection = knobs.picker('Selection', const {
      'None': 'None',
      'Three rows': 'Three rows',
      'All matching': 'All matching',
    }, 'None');
    final table = knobs.bool('Table', true);
    _seed(selection);

    final header = Padding(
      padding: const EdgeInsets.all(24),
      child: CollectionHeader<Product>(
        controller: _controller,
        onSelectAllMatching: () => _controller.setSelected(
          _products.matching(_controller.query).toSet(),
        ),
        bulkActions: [
          BulkAction(
            'Publish',
            icon: Icons.publish_outlined,
            onPressed: () {
              _toast('Published ${_controller.selected.length}');
              _controller.clearSelection();
            },
          ),
          BulkAction(
            'Delete',
            icon: Icons.delete_outline,
            danger: true,
            onPressed: () {
              _toast('Deleted ${_controller.selected.length}');
              _controller.clearSelection();
            },
          ),
        ],
        toolbar: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _toolbar(),
        ),
      ),
    );

    // A scrolling page with a fixed-height table, so any frame — down to the
    // header alone — renders without overflowing.
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (table)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  height: 440,
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
                      child: Collection<Product>(
                        controller: _controller,
                        selectable: true,
                        onRowTap: (p) => _toast('Open ${p.name}'),
                        columns: _columns,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    return CollectionToolbar(
      searchHint: 'Search products…',
      searchValue: _controller.query.search,
      onSearch: _controller.setSearch,
      filterBar: FilterBar(
        fields: _statusField,
        active: _controller.query.filters,
        onChanged: _controller.setFilters,
      ),
      trailing: [
        Button.primary('New product', icon: Icons.add, onPressed: () {}),
      ],
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
      align: AlignmentDirectional.centerEnd,
      sortKey: 'price',
      cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
    ),
  ];
}

const _statusField = [
  OptionsFilterField('status', 'Status', [
    FilterOption('Published', 'Published'),
    FilterOption('Draft', 'Draft'),
    FilterOption('Needs review', 'Needs review'),
    FilterOption('Archived', 'Archived'),
  ]),
];

const _fields = [
  ..._statusField,
  TextFilterField('name', 'Name'),
  NumberRangeFilterField('price', 'Price'),
];

/// Demo — the collection header's states side by side, each pinned: a
/// toolbar with active filters (three statuses collapse to "A +2", a long
/// text filter ellipsizes), the bulk bar offering select-all and after it,
/// and both again in narrow columns, where the filters wrap under the search
/// with "New" level with the first line, and the bar folds its actions into
/// "More actions".
class CollectionToolbarStatesDemo extends StatelessWidget {
  @Preview(name: 'Toolbar states', wrapper: adminUiPreview)
  const CollectionToolbarStatesDemo({super.key});

  static const _active = <FilterCondition>[
    OptionsFilter('status', {
      'Published',
      'Draft',
      'Needs review',
    }, label: 'Status'),
    TextFilter(
      'name',
      'a rather long product name somebody pasted into the filter',
      label: 'Name',
    ),
  ];

  static final _actions = [
    BulkAction('Publish', icon: Icons.publish_outlined, onPressed: () {}),
    BulkAction(
      'Delete',
      icon: Icons.delete_outline,
      danger: true,
      onPressed: () {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Widget toolbar() => CollectionToolbar(
      searchHint: 'Search products…',
      onSearch: (_) {},
      filterBar: FilterBar(fields: _fields, active: _active, onChanged: (_) {}),
      trailing: [
        Button.primary('New product', icon: Icons.add, onPressed: () {}),
      ],
    );
    Widget bar({bool all = false}) => BulkActionBar(
      count: all ? 137 : 10,
      onClear: () {},
      actions: _actions,
      matchingTotal: 137,
      allMatchingSelected: all,
      onSelectAllMatching: () {},
      selectedLabel: (n) => '$n products selected',
      allSelectedLabel: (n) => 'All $n products selected',
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Exhibit('Toolbar', child: toolbar()),
            _Exhibit('Bulk bar', child: bar()),
            _Exhibit('Bulk bar, all matching', child: bar(all: true)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 420,
                  child: _Exhibit('Toolbar at 420', child: toolbar()),
                ),
                const Gap(AdminSpacing.xxl),
                SizedBox(
                  width: 320,
                  child: _Exhibit('Bulk bar at 320', child: bar()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Exhibit extends StatelessWidget {
  final String label;
  final Widget child;
  const _Exhibit(this.label, {required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: context.type.sectionLabel),
          const Gap(AdminSpacing.sm),
          child,
        ],
      ),
    );
  }
}
