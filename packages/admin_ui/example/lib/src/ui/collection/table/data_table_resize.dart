import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';

/// Demo — drag a column's edge to resize it, double-click the edge to reset
/// it, or Alt+←/→ on a focused header. Widths flow out through
/// `onColumnResize` into a [ColumnLayout] (the same object a saved view
/// persists), so the serialized state stays visible as you drag;
/// `onColumnResizeEnd` counts the writes a server would see — one per
/// gesture. The last column is marked non-resizable to show the opt-out.
class DataTableResizeDemo extends StatefulWidget {
  @Preview(name: 'Resizable columns', wrapper: adminUiPreview)
  const DataTableResizeDemo({super.key});

  @override
  State<DataTableResizeDemo> createState() => _DataTableResizeDemoState();
}

class _DataTableResizeDemoState extends State<DataTableResizeDemo> {
  ColumnLayout _layout = const ColumnLayout();
  TableSort _sort = const TableSort('name');
  int _saves = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _controls(),
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
                  child: CollectionTable<_Row>(
                    rows: _rows,
                    rowKey: (r) => r.id,
                    sort: _sort,
                    onSort: (key, asc) =>
                        setState(() => _sort = TableSort(key, ascending: asc)),
                    columnWidths: _layout.widths,
                    onColumnResize: (key, width) =>
                        setState(() => _layout = _layout.withWidth(key, width)),
                    onColumnResizeEnd: (_, _) => setState(() => _saves++),
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

  Widget _controls() {
    final widths = _layout.widths;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: AdminSpacing.lg,
        runSpacing: AdminSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Button(
            'Reset widths',
            onPressed: widths.isEmpty
                ? null
                : () => setState(() => _layout = const ColumnLayout()),
          ),
          Text(
            widths.isEmpty
                ? 'Drag or double-click a header edge · Alt+←/→ on a focused '
                      'header · the last column opts out'
                : 'layout.widths = {${[for (final e in widths.entries) '${e.key}: ${e.value.round()}'].join(', ')}} · '
                      '$_saves saved',
            style: context.type.caption,
          ),
        ],
      ),
    );
  }

  List<_Row> get _rows {
    final list = [..._seed];
    int cmp(_Row a, _Row b) => switch (_sort.key) {
      'name' => a.name.compareTo(b.name),
      'owner' => a.owner.compareTo(b.owner),
      _ => 0,
    };
    list.sort((a, b) => _sort.ascending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  List<TableColumn<_Row>> get _columns => [
    TableColumn(
      label: 'Name',
      flex: 2,
      minWidth: 140,
      pinned: true,
      sortKey: 'name',
      cell: (r) => Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    TableColumn(
      label: 'Owner',
      flex: 1,
      minWidth: 120,
      sortKey: 'owner',
      cell: (r) => Text(r.owner, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    TableColumn(
      label: 'Status',
      fixed: 160,
      cell: (r) => Tag(r.status, severity: r.tone, dot: true),
    ),
    TableColumn(
      label: 'Notes',
      flex: 2,
      minWidth: 140,
      cell: (r) => Text(r.notes, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    TableColumn(
      label: 'ID',
      fixed: 90,
      align: AlignmentDirectional.centerEnd,
      resizable: false,
      cellBuilder: (context, r) => Text(r.id, style: tableMutedStyle(context)),
    ),
  ];
}

class _Row {
  final String id;
  final String name;
  final String owner;
  final String status;
  final Severity tone;
  final String notes;
  const _Row(
    this.id,
    this.name,
    this.owner,
    this.status,
    this.tone,
    this.notes,
  );
}

const _seed = <_Row>[
  _Row(
    '#1042',
    'Spring campaign landing page',
    'Mira Patel',
    'Published',
    Severity.success,
    'Hero copy approved, awaiting localized variants',
  ),
  _Row(
    '#2210',
    'Pricing page rewrite',
    'Tom Beck',
    'Draft',
    Severity.info,
    'Blocked on legal sign-off for the enterprise tier',
  ),
  _Row(
    '#3318',
    'Help center migration',
    'Léa Moreau',
    'Needs review',
    Severity.warning,
    'Imported 240 articles, redirects pending',
  ),
  _Row(
    '#4401',
    'Holiday gift guide',
    'Sven Olsson',
    'Archived',
    Severity.danger,
    'Superseded by the 2026 edition',
  ),
  _Row(
    '#5567',
    'Product tour refresh',
    'Aisha Khan',
    'Published',
    Severity.success,
    'New screenshots shipped last week',
  ),
];
