import 'package:material_ui/material_ui.dart';

import '../common/ui/error_state.dart';
import '../common/ui/error_text.dart';
import '../l10n/admin_ui_localizations.dart';
import '../theme/table_metrics.dart';
import 'collection_controller.dart';
import 'ui/collection_cards.dart';
import 'ui/collection_table.dart';
import 'ui/pager.dart';

/// How a [Collection] lays its rows out. The controller is layout-agnostic, so
/// the Screen flips this freely (typically from a sibling toolbar toggle).
enum CollectionViewMode { table, cards }

/// The connected collection: binds a [CollectionController] to the pure
/// [CollectionTable] or [CollectionCards] (per [viewMode]) plus a [Pager],
/// threading loading / error / empty and selection. The [controller] is
/// supplied by the Screen, which also owns any sibling toolbar (search,
/// filters, view switch) bound to the same controller.
///
/// Rows are identified by the controller's [CollectionController.rowKey].
/// While the query is filtered, an empty result offers "Clear filters",
/// which clears the search, the filters and the advanced query. A failed
/// load shows an [ErrorState] with the error put in words by
/// [ErrorTextScope.describe] and a Retry. The pager hides while there is
/// nothing to page through, and while a failed load shows its error: the
/// rows it would count are the ones from before the failure.
class Collection<T> extends StatelessWidget {
  final CollectionController<T> controller;
  final List<TableColumn<T>> columns;

  /// Opens a row: a table row or, in [CollectionViewMode.cards], its card
  /// ([CollectionCards.onCardTap]). The controller's items are rows in
  /// either view.
  final void Function(T row)? onRowTap;

  /// How a pointer starts an inline edit in [CollectionViewMode.table]; see
  /// [CollectionTable.editTrigger].
  final TableEditTrigger editTrigger;

  /// Routes selection through the controller — a leading checkbox column in
  /// [CollectionViewMode.table], a corner checkbox on cards.
  final bool selectable;

  final List<int> pageSizes;

  /// Shows the footer's page-size select. Off by default — most lists
  /// don't need it; opt a specific entity back in when there's a reason.
  final bool showPageSize;

  /// Which layout to render. [cardBuilder] is required for
  /// [CollectionViewMode.cards].
  final CollectionViewMode viewMode;

  /// Builds one card's content in [CollectionViewMode.cards]; see
  /// [CollectionCards.cardBuilder].
  final Widget Function(BuildContext context, T row)? cardBuilder;

  /// Body shown when an unfiltered load returns no rows.
  final Widget? empty;

  /// Builds the error body from the thrown error and a retry callback.
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;

  /// Hides the column with this key from a header menu entry (table view only).
  /// The Screen applies it to its `ColumnLayout`.
  final void Function(String key)? onHideColumn;

  /// Pins or unpins a column from its header menu (table view only); see
  /// [CollectionTable.onPinColumn]. The Screen applies it to its
  /// `ColumnLayout`.
  final void Function(String key, bool pinned)? onPinColumn;

  /// Opens the Screen's column chooser from a header menu's "Manage
  /// columns…" (table view only); see [CollectionTable.onManageColumns].
  final VoidCallback? onManageColumns;

  /// How tightly the table packs its rows.
  final TableDensity density;

  /// Overrides the theme's table row height at [density]; see
  /// [CollectionTable.rowHeight].
  final double? rowHeight;

  /// Overrides the theme's table header height; see
  /// [CollectionTable.headerHeight].
  final double? headerHeight;

  /// Paints every other table row with the stripe fill.
  final bool striped;

  /// Explicit column widths, keyed by [TableColumn.key] — typically a
  /// `ColumnLayout`'s; see [CollectionTable.columnWidths].
  final Map<String, double>? columnWidths;

  /// Enables column resizing; see [CollectionTable.onColumnResize].
  final void Function(String key, double width)? onColumnResize;

  /// Fires once a resize ends, to persist the width; see
  /// [CollectionTable.onColumnResizeEnd].
  final void Function(String key, double width)? onColumnResizeEnd;

  const Collection({
    super.key,
    required this.controller,
    required this.columns,
    this.onRowTap,
    this.editTrigger = TableEditTrigger.auto,
    this.selectable = false,
    this.pageSizes = const [10, 25, 50],
    this.showPageSize = false,
    this.viewMode = CollectionViewMode.table,
    this.cardBuilder,
    this.empty,
    this.errorBuilder,
    this.onHideColumn,
    this.onPinColumn,
    this.onManageColumns,
    this.density = TableDensity.standard,
    this.rowHeight,
    this.headerHeight,
    this.striped = false,
    this.columnWidths,
    this.onColumnResize,
    this.onColumnResizeEnd,
  }) : assert(
         viewMode != CollectionViewMode.cards || cardBuilder != null,
         'CollectionViewMode.cards requires a cardBuilder',
       );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final q = c.query;
        final error = c.error;
        final errorBody = error == null
            ? null
            : (errorBuilder?.call(error, c.refresh) ??
                  ErrorState(
                    title: context.adminL10n.couldNotLoad,
                    message: ErrorTextScope.describe(context, error),
                    onRetry: c.refresh,
                  ));
        final filtered = c.isFiltered;
        final onClearFilters = filtered ? c.clearSearchAndFilters : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: switch (viewMode) {
                CollectionViewMode.table => CollectionTable<T>(
                  rows: c.items,
                  columns: columns,
                  rowKey: c.rowKey,
                  sort: q.sortKey == null
                      ? null
                      : TableSort(q.sortKey!, ascending: q.ascending),
                  onSort: c.sortBy,
                  onClearSort: c.clearSort,
                  onRowTap: onRowTap,
                  editTrigger: editTrigger,
                  selected: selectable ? c.selected : null,
                  onSelectionChanged: selectable ? c.setSelected : null,
                  onHideColumn: onHideColumn,
                  onPinColumn: onPinColumn,
                  onManageColumns: onManageColumns,
                  density: density,
                  rowHeight: rowHeight,
                  headerHeight: headerHeight,
                  striped: striped,
                  columnWidths: columnWidths,
                  onColumnResize: onColumnResize,
                  onColumnResizeEnd: onColumnResizeEnd,
                  loading: c.loading,
                  empty: empty,
                  filtered: filtered,
                  onClearFilters: onClearFilters,
                  error: errorBody,
                ),
                CollectionViewMode.cards => CollectionCards<T>(
                  rows: c.items,
                  cardBuilder: cardBuilder!,
                  rowKey: c.rowKey,
                  onCardTap: onRowTap,
                  selected: selectable ? c.selected : null,
                  onSelectionChanged: selectable ? c.setSelected : null,
                  loading: c.loading,
                  empty: empty,
                  filtered: filtered,
                  onClearFilters: onClearFilters,
                  error: errorBody,
                ),
              },
            ),
            if (c.total > 0 && error == null)
              Pager(
                from: c.from,
                to: c.to,
                total: c.totalKnown ? c.total : null,
                hasPrev: c.hasPrev,
                hasNext: c.hasNext,
                onPrev: c.prevPage,
                onNext: c.nextPage,
                page: c.pageIndex + 1,
                pageCount: c.pageCount,
                onPage: (page) => c.goToPage(page - 1),
                pageSize: c.pageSize,
                pageSizes: pageSizes,
                onPageSize: showPageSize ? c.setPageSize : null,
              ),
          ],
        );
      },
    );
  }
}
