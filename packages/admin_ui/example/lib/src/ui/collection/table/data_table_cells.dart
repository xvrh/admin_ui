import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../sample.dart';

/// Demo 3 — cell gallery: one table exercising every cell type an admin list
/// needs, on striped rows. Identity (thumb + title + subtitle), status pill,
/// locale roll-up, relation chip, thumbnail, boolean, tag list, price, link.
class DataTableCellsDemo extends StatelessWidget {
  @Preview(name: 'Cell gallery', wrapper: adminUiPreview)
  const DataTableCellsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = sampleProducts(12);
    return collectionFrame(
      context,
      table: CollectionTable<Product>(
        rows: rows,
        rowKey: (p) => p.id,
        striped: true,
        onRowTap: (_) {},
        columns: [
          TableColumn(
            label: 'Product',
            flex: 2,
            minWidth: 240,
            pinned: true,
            cell: productIdentity,
          ),
          TableColumn(
            label: 'Status',
            fixed: 150,
            cell: (p) => Tag(p.status, severity: p.tone, dot: true),
          ),
          TableColumn(
            label: 'Locales',
            fixed: 150,
            cell: (p) => LocaleRollup(locales: p.locales),
          ),
          TableColumn(
            label: 'Category',
            fixed: 140,
            cell: (p) => RelationChip(label: p.category, onTap: () {}),
          ),
          TableColumn(
            label: 'Tags',
            flex: 1,
            minWidth: 150,
            cell: (p) => _Tags(p.tags),
          ),
          TableColumn(
            label: 'Featured',
            fixed: 90,
            align: Alignment.center,
            cell: (p) => _Bool(p.featured),
          ),
          TableColumn(
            label: 'Price',
            fixed: 100,
            numeric: true,
            cellBuilder: (context, p) => Text(
              '\$${p.price.toStringAsFixed(2)}',
              style: context.type.bodyStrong,
            ),
          ),
          TableColumn(
            label: 'Author',
            fixed: 160,
            cell: (p) =>
                Text(p.author, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  final List<String> tags;
  const _Tags(this.tags);
  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Text('—', style: tableMutedStyle(context));
    }
    // Fixed row height: keep tags on one clipped line rather than wrapping.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          for (final t in tags)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AdminSpacing.xs),
              child: Tag(t),
            ),
        ],
      ),
    );
  }
}

class _Bool extends StatelessWidget {
  final bool value;
  const _Bool(this.value);
  @override
  Widget build(BuildContext context) {
    return Icon(
      value ? Icons.check_circle : Icons.remove_circle_outline,
      size: 18,
      color: value ? context.colors.success : tableMutedStyle(context).color,
    );
  }
}
