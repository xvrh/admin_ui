import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'sample.dart';

/// Demo — advanced filtering: a [CollectionToolbar] holding the global search
/// box and a structured [FilterBar] (status / category multi-select, price
/// range), both bound to the same [CollectionController], answered by a
/// [LocalCollectionSource].
class CollectionAdvancedDemo extends StatefulWidget {
  @Preview(name: 'Advanced filtering', wrapper: adminUiPreview)
  const CollectionAdvancedDemo({super.key});

  @override
  State<CollectionAdvancedDemo> createState() => _CollectionAdvancedDemoState();
}

class _CollectionAdvancedDemoState extends State<CollectionAdvancedDemo> {
  static final _products = productSource(sampleProducts(137));

  late final CollectionController<Product> _controller = CollectionController(
    fetcher: _fetch,
    rowKey: (p) => p.id,
    initialQuery: const CollectionQuery(sortKey: 'name', pageSize: 10),
  );

  Future<CollectionPage<Product>> _fetch(CollectionQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _products.fetch(q);
  }

  static const _fields = <FilterField>[
    OptionsFilterField('status', 'Status', [
      FilterOption('Published', 'Published'),
      FilterOption('Draft', 'Draft'),
      FilterOption('Needs review', 'Needs review'),
      FilterOption('Archived', 'Archived'),
    ]),
    OptionsFilterField('category', 'Category', [
      FilterOption('Apparel', 'Apparel'),
      FilterOption('Footwear', 'Footwear'),
      FilterOption('Accessories', 'Accessories'),
      FilterOption('Home', 'Home'),
      FilterOption('Outdoor', 'Outdoor'),
    ]),
    NumberRangeFilterField('price', 'Price'),
    DateRangeFilterField('updated', 'Updated'),
    BoolFilterField('featured', 'Featured'),
    TextFilterField('author', 'Author'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _toolbar(),
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
                  child: Collection<Product>(
                    controller: _controller,
                    onRowTap: (_) {},
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

  Widget _toolbar() {
    return CollectionToolbar(
      searchController: _controller.searchController,
      searchHint: 'Search products…',
      filterBar: FilterBar(
        fields: _fields,
        active: _controller.query.filters,
        onChanged: _controller.setFilters,
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
  ];
}
