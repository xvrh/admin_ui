import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'collection_connected.dart';
import 'sample.dart';

/// Demo — the connected [Collection] flipped between table and card layouts via
/// a [Segmented] toggle, driven by one [CollectionController]. The controller is
/// layout-agnostic, so search / loading / error / selection all carry across the
/// switch unchanged. The "State" knob pins selected cards, a reload, the first
/// load's skeleton, empty, no results and error.
class CollectionCardsDemo extends StatelessWidget {
  @Preview(name: 'Card / grid view', wrapper: adminUiPreview)
  const CollectionCardsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final state = DemoListState.knob(context);
    return _CardsDemo(key: ValueKey(state), state: state);
  }
}

class _CardsDemo extends StatefulWidget {
  final DemoListState state;
  const _CardsDemo({super.key, required this.state});

  @override
  State<_CardsDemo> createState() => _CardsDemoState();
}

class _CardsDemoState extends State<_CardsDemo> {
  bool _failNext = false;
  CollectionViewMode _mode = CollectionViewMode.cards;

  late final CollectionController<Product> _controller = demoProductController(
    widget.state,
    pageSize: 12,
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
        leading: Segmented<CollectionViewMode>(
          value: _mode,
          onChanged: (m) => setState(() => _mode = m),
          segments: const [
            SegmentOption(
              CollectionViewMode.table,
              'Table',
              icon: Icons.table_rows,
            ),
            SegmentOption(
              CollectionViewMode.cards,
              'Cards',
              icon: Icons.grid_view,
            ),
          ],
        ),
        searchController: _controller.searchController,
        searchHint: 'Search products…',
        searchWidth: 240,
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
        viewMode: _mode,
        cardBuilder: (_, p) => _ProductCard(product: p),
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
  ];
}

/// A product tile: a colour cover band over name / SKU / status / price.
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 96,
          color: p.swatch.withValues(alpha: 0.18),
          alignment: Alignment.center,
          child: Icon(Icons.inventory_2_outlined, color: p.swatch, size: 30),
        ),
        Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type.bodyStrong,
              ),
              const Gap(AdminSpacing.xxs),
              Text(
                p.sku,
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMutedOnTint,
                ),
              ),
              const Gap(AdminSpacing.lg),
              Row(
                children: [
                  // At a large text size the status gives way to the price.
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Tag(p.status, severity: p.tone, dot: true),
                    ),
                  ),
                  const Gap(AdminSpacing.sm),
                  Text(
                    '\$${p.price.toStringAsFixed(2)}',
                    style: context.type.bodyStrong.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
