import 'dart:convert';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'sample.dart';

/// Demo — the serialization behind saved views: a live collection on the left,
/// and on the right the JSON that gets persisted. Filter / sort / switch views
/// and watch the `ViewState` payload update — proving the query round-trips with
/// no field registry now that keys are plain [FieldId]s. Split with the
/// resizable [SplitView].
class SavedViewsInspectorDemo extends StatefulWidget {
  @Preview(name: 'Serialization inspector', wrapper: adminUiPreview)
  const SavedViewsInspectorDemo({super.key});

  @override
  State<SavedViewsInspectorDemo> createState() =>
      _SavedViewsInspectorDemoState();
}

class _SavedViewsInspectorDemoState extends State<SavedViewsInspectorDemo> {
  static final _products = productSource(sampleProducts(80));
  static const _encoder = JsonEncoder.withIndent('  ');

  final _store = InMemorySavedViewsStore(
    seed: {
      'products': [
        SavedView(
          id: 'all',
          name: 'All',
          isDefault: true,
          state: ViewState(sortKey: 'name'),
        ),
        SavedView(
          id: 'published',
          name: 'Published',
          state: ViewState(
            filters: [
              OptionsFilter('status', const {'Published'}, label: 'Status'),
            ],
            sortKey: 'price',
            ascending: false,
          ),
        ),
      ],
    },
  );

  late final CollectionController<Product> _collection = CollectionController(
    fetcher: _fetch,
    rowKey: (p) => p.id,
    initialQuery: const CollectionQuery(sortKey: 'name', pageSize: 12),
  );

  late final SavedViewsController<Product> _views = SavedViewsController(
    store: _store,
    collectionKey: 'products',
    collection: _collection,
    nameForCopy: (name) => context.adminL10n.collection.copyOf(name),
  );

  Future<CollectionPage<Product>> _fetch(CollectionQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(context.radii.radiusLarge),
            border: Border.all(color: context.colors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.radiusLarge),
            child: ListenableBuilder(
              listenable: _views,
              builder: (context, _) => SplitView.two(
                initialWeight: 0.62,
                minSecond: 300,
                first: _collectionPane(),
                second: _inspectorPane(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _collectionPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SavedViewsBar(
          views: _views.views,
          activeId: _views.activeId,
          dirty: _views.dirty,
          onSelect: _views.select,
          onDiscardChanges: _views.discardChanges,
        ),
        Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: FilterBar(
            fields: const [
              OptionsFilterField('status', 'Status', [
                FilterOption('Published', 'Published'),
                FilterOption('Draft', 'Draft'),
                FilterOption('Needs review', 'Needs review'),
                FilterOption('Archived', 'Archived'),
              ]),
            ],
            active: _collection.query.filters,
            onChanged: _collection.setFilters,
          ),
        ),
        Expanded(
          child: Collection<Product>(
            controller: _collection,
            columns: _columns,
          ),
        ),
      ],
    );
  }

  Widget _inspectorPane() {
    final live = _encoder.convert(ViewState.from(_collection.query).toJson());
    final active = _views.active;
    final saved = active == null
        ? '—'
        : _encoder.convert(active.state.toJson());
    return Container(
      color: context.colors.background,
      child: ListView(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        children: [
          Row(
            children: [
              Text('Persisted payload', style: context.type.sectionLabel),
              const Spacer(),
              Tag(
                _views.dirty ? 'dirty' : 'in sync',
                severity: _views.dirty ? Severity.warning : Severity.success,
                dot: true,
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
          _JsonBlock(label: 'Live query (ViewState.from)', json: live),
          const Gap(AdminSpacing.lg),
          _JsonBlock(label: 'Active saved view', json: saved),
        ],
      ),
    );
  }

  List<TableColumn<Product>> get _columns => [
    TableColumn(
      label: 'Product',
      flex: 2,
      minWidth: 180,
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
      label: 'Price',
      fixed: 90,
      align: AlignmentDirectional.centerEnd,
      sortKey: 'price',
      cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
    ),
  ];
}

class _JsonBlock extends StatelessWidget {
  final String label;
  final String json;
  const _JsonBlock({required this.label, required this.json});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.type.caption),
        const Gap(AdminSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AdminSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(context.radii.radiusSmall),
            border: Border.all(color: context.colors.border),
          ),
          child: SelectableText(
            json,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
