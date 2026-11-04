import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';
import 'sample.dart';

/// Demo — saved views, end to end: a [SavedViewsBar] over a real paged
/// [CollectionController], driven by a [SavedViewsController] + in-memory store.
/// It opens on "All", every row, as no view is marked default. Switch views
/// to apply filter/sort presets; tweak a filter or sort to go dirty (Save /
/// Reset appear); "+" names a new view and says who sees it, in the kit's
/// dialog; rename / duplicate / move / set-default / delete per view via the
/// tab menu (its caret, a right-click, or Shift+F10 on the focused tab).
/// Under 600 wide the bar is a menu under the active view's name instead.
/// The Store error knob makes the store fail, so the bar shows the error
/// with its retry.
class SavedViewsDemo extends StatefulWidget {
  @Preview(name: 'Full workflow', wrapper: adminUiPreview)
  const SavedViewsDemo({super.key});

  @override
  State<SavedViewsDemo> createState() => _SavedViewsDemoState();
}

class _SavedViewsDemoState extends State<SavedViewsDemo> {
  static final _products = productSource(sampleProducts(137));

  final _store = _FlakyStore(
    InMemorySavedViewsStore(seed: {'products': _seed}),
  );

  late final CollectionController<Product> _collection = CollectionController(
    fetcher: _fetch,
    rowKey: (p) => p.id,
    initialQuery: const CollectionQuery(sortKey: 'name', pageSize: 10),
  );

  late final SavedViewsController<Product> _views = SavedViewsController(
    store: _store,
    collectionKey: 'products',
    collection: _collection,
    nameForCopy: (name) => context.adminL10n.collection.copyOf(name),
  );

  static final List<SavedView> _seed = [
    SavedView(
      id: 'published',
      name: 'Published',
      state: ViewState(
        filters: [
          OptionsFilter('status', const {'Published'}, label: 'Status'),
        ],
        sortKey: 'name',
      ),
    ),
    SavedView(
      id: 'review',
      name: 'Needs review',
      scope: SavedViewScope.shared,
      state: ViewState(
        filters: [
          OptionsFilter('status', const {'Needs review'}, label: 'Status'),
        ],
        sortKey: 'name',
      ),
    ),
    SavedView(
      id: 'premium',
      name: r'Premium ($50+)',
      state: ViewState(
        filters: [NumberRangeFilter('price', min: 50, label: 'Price')],
        sortKey: 'price',
        ascending: false,
      ),
    ),
  ];

  Future<CollectionPage<Product>> _fetch(CollectionQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _products.fetch(q);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );

  @override
  void dispose() {
    _views.dispose();
    _collection.dispose();
    super.dispose();
  }

  /// Follows the Store error knob: turning it on fails a reload at once.
  void _syncFailing(bool failing) {
    if (failing == _store.failing) return;
    _store.failing = failing;
    if (!failing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _views.load(applyDefault: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncFailing(context.knobs.bool('Store error', false));
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
                    builder: (context, _) => _header(),
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
                          selectable: true,
                          onRowTap: (p) => _toast('Open ${p.name}'),
                          columns: _columns,
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
      layout: SavedViewsLayout.auto,
      onSelect: _views.select,
      onSelectAll: _views.clearView,
      onSaveChanges: _views.saveChanges,
      onDiscardChanges: _views.discardChanges,
      onCreate: (view) => _views.saveAsNew(view.name, scope: view.scope),
      onRenamed: _views.rename,
      onDuplicate: _views.duplicate,
      onSetDefault: _views.setDefault,
      onReorder: _views.reorder,
      error: _views.lastError,
      onRetry: _views.retry,
      onDismissError: _views.clearError,
      onDelete: (v) async {
        final ok = await showConfirmDialog(
          context,
          title: 'Delete view',
          message: 'Delete "${v.name}"? This can\'t be undone.',
          confirmLabel: 'Delete',
          danger: true,
        );
        if (ok) await _views.delete(v);
      },
    );
  }

  Widget _header() {
    return CollectionHeader<Product>(
      controller: _collection,
      bulkActions: [
        BulkAction(
          'Publish',
          icon: Icons.publish_outlined,
          onPressed: () {
            _toast('Published ${_collection.selected.length}');
            _collection.clearSelection();
          },
        ),
        BulkAction(
          'Delete',
          icon: Icons.delete_outline,
          danger: true,
          onPressed: () {
            _toast('Deleted ${_collection.selected.length}');
            _collection.clearSelection();
          },
        ),
      ],
      toolbar: CollectionToolbar(
        searchHint: 'Search products…',
        searchValue: _collection.query.search,
        onSearch: _collection.setSearch,
        filterBar: FilterBar(
          fields: const [
            OptionsFilterField('status', 'Status', [
              FilterOption('Published', 'Published'),
              FilterOption('Draft', 'Draft'),
              FilterOption('Needs review', 'Needs review'),
              FilterOption('Archived', 'Archived'),
            ]),
            NumberRangeFilterField('price', 'Price'),
          ],
          active: _collection.query.filters,
          onChanged: _collection.setFilters,
        ),
        trailing: [
          Button.primary('New product', icon: Icons.add, onPressed: () {}),
        ],
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
      align: AlignmentDirectional.centerEnd,
      sortKey: 'price',
      cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
    ),
  ];
}

/// Demo — the bar's compact form with its menu pinned open, at a phone's
/// width: "All", then every view with the active one checked and the
/// default one captioned, then the active view's own actions. Save and
/// Reset show beside it, as the active view has unsaved changes.
class SavedViewsMenuDemo extends StatelessWidget {
  @Preview(name: 'Saved views menu (open)', wrapper: adminUiPreview)
  const SavedViewsMenuDemo({super.key});

  static const _views = [
    SavedView(id: 'published', name: 'Published', isDefault: true),
    SavedView(
      id: 'review',
      name: 'Needs review',
      scope: SavedViewScope.shared,
      position: 1,
    ),
    SavedView(id: 'premium', name: r'Premium ($50+)', position: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: 360,
          child: PinnedOpen(
            reserve: 400,
            child: SavedViewsBar(
              views: _views,
              activeId: 'review',
              dirty: true,
              onSelect: (_) {},
              onSelectAll: () {},
              onSaveChanges: () {},
              onDiscardChanges: () {},
              onCreate: (_) {},
              onRenamed: (_, _) {},
              onDuplicate: (_, _) {},
              onSetDefault: (_) {},
              onReorder: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
  }
}

/// A store that fails every call while [failing] is set, as a flaky network
/// would — except the first load, so the views still show.
class _FlakyStore implements SavedViewsStore {
  final SavedViewsStore inner;
  bool failing = false;
  bool _listed = false;

  _FlakyStore(this.inner);

  Future<R> _call<R>(Future<R> Function() body) async {
    if (failing) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      throw Exception('Request failed with status 503');
    }
    return body();
  }

  @override
  Future<List<SavedView>> list(String collectionKey) {
    if (!_listed) {
      _listed = true;
      return inner.list(collectionKey);
    }
    return _call(() => inner.list(collectionKey));
  }

  @override
  Future<SavedView> create(String collectionKey, SavedView view) =>
      _call(() => inner.create(collectionKey, view));

  @override
  Future<void> update(String collectionKey, SavedView view) =>
      _call(() => inner.update(collectionKey, view));

  @override
  Future<void> delete(String collectionKey, String id) =>
      _call(() => inner.delete(collectionKey, id));

  @override
  Future<void> setDefault(String collectionKey, String id) =>
      _call(() => inner.setDefault(collectionKey, id));

  @override
  Future<void> reorder(String collectionKey, List<String> ids) =>
      _call(() => inner.reorder(collectionKey, ids));
}
