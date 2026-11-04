import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'sample.dart';

/// Demo — the column chooser, end to end. Open **Columns** in the toolbar to
/// toggle visibility and reorder (drag a handle, or Alt+↑ / Alt+↓ on a focused
/// row); the table reflows live. The choices come from the table's own columns
/// ([ColumnChoice.fromColumns]), so the anchor column is locked by being
/// declared not hideable. Column layout
/// is wired into the saved views (via the controller's `readColumns` /
/// `writeColumns` bridge): each seed view pins its own set of columns, so
/// switching views restores their layout, and editing columns flags the view
/// dirty (Save / Reset appear).
class ColumnChooserDemo extends StatefulWidget {
  @Preview(name: 'Column chooser', wrapper: adminUiPreview)
  const ColumnChooserDemo({super.key});

  @override
  State<ColumnChooserDemo> createState() => _ColumnChooserDemoState();
}

class _ColumnChooserDemoState extends State<ColumnChooserDemo> {
  static final _products = productSource(sampleProducts(86));

  late final ColumnLayout _default = ColumnLayout.of(_allColumns);
  late ColumnLayout _layout = _default;

  final _store = InMemorySavedViewsStore(seed: {'products': _seed});

  late final CollectionController<Product> _collection = CollectionController(
    fetcher: _fetch,
    rowKey: (p) => p.id,
    initialQuery: const CollectionQuery(sortKey: 'name', pageSize: 10),
  );

  late final SavedViewsController<Product> _views = SavedViewsController(
    store: _store,
    collectionKey: 'products',
    collection: _collection,
    readColumns: () => _layout,
    writeColumns: (l) => setState(() => _layout = l ?? _default),
    nameForCopy: (name) => context.adminL10n.collection.copyOf(name),
  );

  static final List<SavedView> _seed = [
    SavedView(
      id: 'overview',
      name: 'Overview',
      isDefault: true,
      state: const ViewState(
        sortKey: 'name',
        columns: ColumnLayout(order: ['name', 'status', 'category', 'price']),
      ),
    ),
    SavedView(
      id: 'inventory',
      name: 'Inventory',
      state: const ViewState(
        sortKey: 'name',
        columns: ColumnLayout(
          order: ['name', 'sku', 'stock', 'category', 'updated'],
          hidden: {'status', 'price', 'author'},
        ),
      ),
    ),
    SavedView(
      id: 'editorial',
      name: 'Editorial',
      scope: SavedViewScope.shared,
      state: const ViewState(
        sortKey: 'name',
        columns: ColumnLayout(
          order: ['name', 'author', 'updated', 'status'],
          hidden: {'sku', 'category', 'price', 'stock'},
        ),
      ),
    ),
  ];

  Future<CollectionPage<Product>> _fetch(CollectionQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _products.fetch(q);
  }

  @override
  void dispose() {
    _views.dispose();
    _collection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: _views,
            builder: (context, _) => _bar(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListenableBuilder(
                    listenable: _collection,
                    builder: (context, _) => _toolbar(),
                  ),
                  const Gap(AdminSpacing.lg),
                  Expanded(
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
                          controller: _collection,
                          columns: _layout.apply(_allColumns),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar() {
    return SavedViewsBar(
      views: _views.views,
      activeId: _views.activeId,
      dirty: _views.dirty,
      onSelect: _views.select,
      onSaveChanges: _views.saveChanges,
      onDiscardChanges: _views.discardChanges,
      onCreate: (view) => _views.saveAsNew(view.name, scope: view.scope),
      onRenamed: _views.rename,
      onDuplicate: _views.duplicate,
      onSetDefault: _views.setDefault,
      onDelete: _views.delete,
      onReorder: _views.reorder,
      error: _views.lastError,
      onRetry: _views.retry,
      onDismissError: _views.clearError,
    );
  }

  Widget _toolbar() {
    return CollectionToolbar(
      searchHint: 'Search products…',
      searchValue: _collection.query.search,
      onSearch: _collection.setSearch,
      trailing: [
        ColumnChooserButton(
          columns: ColumnChoice.fromColumns(_allColumns),
          layout: _layout,
          onChanged: (l) => setState(() => _layout = l),
          onReset: _layout == _default
              ? null
              : () => setState(() => _layout = _default),
        ),
        Button.primary('New product', icon: Icons.add, onPressed: () {}),
      ],
    );
  }

  List<TableColumn<Product>> get _allColumns => [
    TableColumn(
      id: 'name',
      label: 'Product',
      flex: 2,
      minWidth: 220,
      pinned: true,
      hideable: false,
      sortKey: 'name',
      cell: productIdentity,
    ),
    TableColumn(
      id: 'sku',
      label: 'SKU',
      fixed: 120,
      cell: (p) => Text(
        p.sku,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      ),
    ),
    TableColumn(
      id: 'status',
      label: 'Status',
      fixed: 150,
      cell: (p) => Tag(p.status, severity: p.tone, dot: true),
    ),
    TableColumn(
      id: 'category',
      label: 'Category',
      flex: 1,
      minWidth: 120,
      cell: (p) =>
          Text(p.category, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    TableColumn(
      id: 'stock',
      label: 'Stock',
      fixed: 90,
      align: AlignmentDirectional.centerEnd,
      sortKey: 'stock',
      cell: (p) => Text(p.stock?.toString() ?? '—'),
    ),
    TableColumn(
      id: 'price',
      label: 'Price',
      fixed: 100,
      align: AlignmentDirectional.centerEnd,
      sortKey: 'price',
      cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
    ),
    TableColumn(
      id: 'author',
      label: 'Author',
      flex: 1,
      minWidth: 120,
      cell: (p) => Text(p.author, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    TableColumn(
      id: 'updated',
      label: 'Updated',
      fixed: 120,
      cellBuilder: (context, p) => Text(
        p.updated,
        style: TextStyle(color: context.colors.foregroundMuted),
      ),
    ),
  ];
}

/// Demo — the column chooser's panel and its two triggers, pinned open: ten
/// columns, so the search and Show all / Hide all head the list; two hidden,
/// which the full trigger counts and the small one marks with a dot; the
/// anchor column locked.
class ColumnChooserPanelDemo extends StatefulWidget {
  @Preview(name: 'Column chooser panel', wrapper: adminUiPreview)
  const ColumnChooserPanelDemo({super.key});

  @override
  State<ColumnChooserPanelDemo> createState() => _ColumnChooserPanelDemoState();
}

class _ColumnChooserPanelDemoState extends State<ColumnChooserPanelDemo> {
  static const _choices = [
    ColumnChoice(key: 'name', label: 'Product', locked: true),
    ColumnChoice(key: 'sku', label: 'SKU'),
    ColumnChoice(key: 'status', label: 'Status'),
    ColumnChoice(key: 'category', label: 'Category'),
    ColumnChoice(key: 'stock', label: 'Stock'),
    ColumnChoice(key: 'price', label: 'Price'),
    ColumnChoice(key: 'author', label: 'Author'),
    ColumnChoice(key: 'updated', label: 'Updated'),
    ColumnChoice(key: 'tags', label: 'Tags'),
    ColumnChoice(key: 'featured', label: 'Featured'),
  ];

  late ColumnLayout _layout = ColumnLayout(
    order: [for (final c in _choices) c.key],
    hidden: const {'author', 'tags'},
  );

  void _set(ColumnLayout layout) => setState(() => _layout = layout);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopoverMenuSurface(
              width: 268,
              maxHeight: 480,
              child: ColumnChooser(
                columns: _choices,
                layout: _layout,
                onChanged: _set,
                onReset: () => _set(
                  ColumnLayout(order: [for (final c in _choices) c.key]),
                ),
              ),
            ),
            const Gap(AdminSpacing.xxl),
            ColumnChooserButton(
              columns: _choices,
              layout: _layout,
              onChanged: _set,
            ),
            const Gap(AdminSpacing.md),
            ColumnChooserButton(
              columns: _choices,
              layout: _layout,
              onChanged: _set,
              size: ControlSize.small,
            ),
          ],
        ),
      ),
    );
  }
}
