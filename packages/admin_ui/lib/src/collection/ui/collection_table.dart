import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../common/pointer.dart';
import '../../common/text_metrics.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/delayed_loading.dart';
import '../../common/ui/empty_state.dart';
import '../../common/ui/focus_ring.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/skeleton.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/sections/collection_messages.dart';
import '../../theme/spacing.dart';
import '../../theme/table_metrics.dart';
import '../../theme/tokens.dart';
import '../filter.dart';
import 'table_edit_session.dart';
import 'view_support.dart';

/// A column in a [CollectionTable].
///
/// Two kinds, distinguished by [sortKey]: an *accessor* column has a sort key
/// (it maps to a data field, so it can be sorted), a *display* column does not
/// (actions, derived widgets). The view derives sortability from this rather
/// than a separate flag.
///
/// Width is either [fixed] pixels or a [flex] share of the space left after the
/// fixed columns. Flex columns expand to fill the viewport; when the columns
/// outgrow it they clamp to [minWidth] and the table scrolls horizontally.
///
/// [pinned] columns freeze during horizontal scroll and must be the leading
/// columns of the list. Where together they would take more than half the
/// table's width, they scroll with the rest.
///
/// A cell comes from exactly one of [cell] and [cellBuilder].
class TableColumn<T> {
  /// Stable identifier, independent of the (localizable) [label] — the key a
  /// `ColumnLayout` and the column chooser persist. Defaults to [label].
  final String? id;
  final String label;

  /// Builds a row's cell from the row alone: the shorthand for a cell that
  /// needs nothing from its context, such as `Text(row.name)`.
  final Widget Function(T row)? cell;

  /// Builds a row's cell with the cell's context, for one that reads the
  /// theme or a scope: `context.colors`, `context.adminL10n`.
  final Widget Function(BuildContext context, T row)? cellBuilder;

  final double? fixed;
  final int flex;
  final double minWidth;

  /// Where the cells and the header sit in the column. Directional by
  /// default, so a right-to-left table puts them on the right; [numeric]
  /// overrides it.
  final AlignmentGeometry align;
  final FieldId? sortKey;
  final bool pinned;

  /// A column of numbers: its header and cells align to the end — the right
  /// in a left-to-right table, the left in a right-to-left one — and the
  /// default cell style sets tabular figures so decimals line up.
  final bool numeric;

  /// Whether the user can resize this column — drag its trailing edge, or
  /// Alt+←/→ on its header, the arrow past that edge widening it. A
  /// double-click on the edge, or "Reset width" in the header menu, returns it
  /// to its declared width: the table doesn't fit a column to its content, as
  /// cells are arbitrary widgets and only the rows on screen are built. Only
  /// honoured when the table has an [CollectionTable.onColumnResize] callback.
  final bool resizable;

  /// Whether the header menu may offer "Hide column" for this column. Off for an
  /// anchor/identity column that should always stay visible. Only relevant when
  /// the table has an [CollectionTable.onHideColumn] callback.
  final bool hideable;

  /// Opts this column into inline editing. Enter or F2 on the focused cell,
  /// or a double tap as [CollectionTable.editTrigger] allows, swaps the cell
  /// for `editBuilder(row, session)`. The editor keeps a draft and saves it
  /// through [EditSession.onCommit]: Enter, Tab and a tap outside commit,
  /// Escape cancels. [TableTextEditor] is the stock text and number editor.
  /// Display columns can edit too — sortability is independent.
  final Widget Function(T row, EditSession session)? editBuilder;

  const TableColumn({
    this.id,
    required this.label,
    this.cell,
    this.cellBuilder,
    this.fixed,
    this.flex = 1,
    this.minWidth = 80,
    this.align = AlignmentDirectional.centerStart,
    this.sortKey,
    this.pinned = false,
    this.numeric = false,
    this.resizable = true,
    this.hideable = true,
    this.editBuilder,
  }) : assert(
         (cell == null) != (cellBuilder == null),
         'Pass exactly one of cell or cellBuilder',
       );

  /// The persisted key — explicit [id] or the [label] as a fallback.
  String get key => id ?? label;

  /// The cell for [row], from [cellBuilder] or [cell]; [context] is the
  /// cell's.
  Widget buildCell(BuildContext context, T row) =>
      cellBuilder?.call(context, row) ?? cell!(row);

  /// This column, [pinned] or not — how a `ColumnLayout` applies the pins
  /// the user chose.
  TableColumn<T> withPinned(bool pinned) => pinned == this.pinned
      ? this
      : TableColumn<T>(
          id: id,
          label: label,
          cell: cell,
          cellBuilder: cellBuilder,
          fixed: fixed,
          flex: flex,
          minWidth: minWidth,
          align: align,
          sortKey: sortKey,
          pinned: pinned,
          numeric: numeric,
          resizable: resizable,
          hideable: hideable,
          editBuilder: editBuilder,
        );

  bool get sortable => sortKey != null;
  bool get editable => editBuilder != null;

  /// [align], or the end for a [numeric] column.
  AlignmentGeometry get _alignment =>
      numeric ? AlignmentDirectional.centerEnd : align;
}

/// How a pointer opens a [CollectionTable]'s inline editor
/// ([TableColumn.editBuilder]). Enter and F2 on the focused cell edit it
/// whatever the trigger.
///
/// A double tap rather than an edit affordance: a pencil shown on hover
/// reaches no touch screen and takes room from the value it sits beside,
/// while a double tap is how a spreadsheet opens a cell, by mouse or touch.
enum TableEditTrigger {
  /// A double tap edits while the table opens no rows
  /// ([CollectionTable.onRowTap] null). With a row tap only the keyboard
  /// edits, so a tap opens its row at once.
  auto,

  /// A double tap on an editable cell edits it, row tap or not. With
  /// [CollectionTable.onRowTap] set, a single tap on an editable cell waits
  /// out the double-tap window (`kDoubleTapTimeout`) before opening its row;
  /// a tap on any other cell opens it at once.
  doubleTap,
}

/// The active sort: which column [key] and direction. The view is controlled —
/// it renders this and reports changes through [CollectionTable.onSort]; it never
/// reorders [CollectionTable.rows] itself.
class TableSort {
  final FieldId key;
  final bool ascending;
  const TableSort(this.key, {this.ascending = true});
}

/// A presentational, virtualized data table built on `TableView`
/// (two_dimensional_scrollables): pinned header, optional pinned leading
/// columns, fixed + flex column widths, sortable headers, row hover and tap,
/// optional striping and row selection.
///
/// Pure View: plain [rows] in, intent out via callbacks. No fetching, no global
/// reads. Rows are one fixed height — the theme's `context.tableMetrics` at
/// [density], or [rowHeight], taller by as much as a line of text grows at a
/// large text size — so cells truncate rather than wrap.
///
/// Selection is controlled: pass [selected] + [onSelectionChanged] to turn on a
/// leading checkbox column with select-all-on-page. Rows are told apart by
/// [rowKey], so a refetch that returns fresh objects keeps its checks.
///
/// **States.** [error] takes precedence, then [loading], then [empty]. Loading
/// shows after 150ms: skeleton rows on a first load, and otherwise a top bar
/// over the current rows, dimmed and inert — taps, Enter, Space and F2 leave
/// them be, while the arrows still move. Empty and error bodies sit under
/// the real header, which keeps scrolling with its pinned columns. A
/// [filtered] table with no rows says so and offers [onClearFilters].
///
/// **Keyboard**, as a WAI-ARIA grid: the table is one Tab stop holding a
/// focused cell, header row included. Arrows move between cells, Home/End to
/// the ends of the row (with Ctrl, of the grid), PageUp/PageDown by a screen
/// of rows. On a row, Enter opens it ([onRowTap]) — or edits an editable cell,
/// or enters a cell holding a control, which keeps its own keys until Escape
/// or F2 leaves it — Space toggles its selection and F2 edits. On a header,
/// Enter or Space sorts, Alt+↓ or Shift+F10 opens the column menu and
/// Alt+←/→ resizes by 16px (8 with Shift).
///
/// **Right to left**, under an RTL [Directionality], the table mirrors: the
/// first column and the pinned ones sit on the right, a column resizes from
/// its left edge, and ←/→ move to the cell drawn on that side — so → goes
/// back a column, and Alt+← widens one. Home and End stay the first and the
/// last column.
///
/// Assistive technology reads it as a table — a row of column headers over
/// rows of cells — whose one focus target is the focused cell, so a move of
/// it is announced.
class CollectionTable<T> extends StatefulWidget {
  final List<T> rows;
  final List<TableColumn<T>> columns;
  final TableSort? sort;
  final void Function(FieldId key, bool ascending)? onSort;

  /// Opens a row. The tap is named for what the view draws: a table's
  /// `onRowTap`, a card view's or a board's `onCardTap`.
  final void Function(T row)? onRowTap;

  /// How a pointer starts an inline edit; see [TableEditTrigger]. With
  /// [onRowTap] set, [TableEditTrigger.doubleTap] lets a double tap edit a
  /// cell that a single tap still opens the row from.
  final TableEditTrigger editTrigger;

  final Set<T>? selected;
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Explicit per-column pixel widths, keyed by [TableColumn.key]. A key present
  /// here overrides the column's [TableColumn.fixed]/[TableColumn.flex] sizing;
  /// keys absent fall back to declared sizing. Pair with [onColumnResize] to let
  /// the user drag column edges; the view reports each new width through it.
  final Map<String, double>? columnWidths;

  /// Fires while the user drags a resizable column's trailing edge, with the
  /// column [TableColumn.key] and its new (clamped) width. Enables resize handles.
  final void Function(String key, double width)? onColumnResize;

  /// Hides the column with this [TableColumn.key]. Enables a "Hide column" entry
  /// in each hideable column's header menu. The parent applies it (typically
  /// `ColumnLayout.withVisible(key, false)`).
  final void Function(String key)? onHideColumn;

  /// Pins (`pinned` true) or unpins the column with this [TableColumn.key].
  /// Enables a "Pin column" / "Unpin column" entry in each header menu. The
  /// parent applies it (typically `ColumnLayout.withPinned(key, pinned)`),
  /// keeping pinned columns first.
  final void Function(String key, bool pinned)? onPinColumn;

  /// Opens the parent's column chooser. Enables a "Manage columns…" entry at
  /// the end of each header menu.
  final VoidCallback? onManageColumns;

  /// Dims the rows under a top progress bar, or shows skeleton rows when
  /// there are none yet.
  final bool loading;

  /// Shown in the body (under the header) when [rows] is empty and not
  /// [loading]/[error]; defaults to "Nothing here yet".
  final Widget? empty;

  /// Shown in the body (under the header) when set, taking precedence over
  /// [loading] and [empty].
  final Widget? error;

  /// Identifies a row across rebuilds — a record id, not the row object, so a
  /// refetch that returns fresh objects keeps its selection and an open
  /// editor. Selection and inline editing compare rows by it, and are
  /// required to have it.
  final Object Function(T row)? rowKey;

  /// How tightly rows pack; the height comes from `context.tableMetrics`
  /// unless [rowHeight] overrides it.
  final TableDensity density;

  /// Paints every other row with `tableRowStripe`.
  final bool striped;

  /// Whether a filter or search narrows [rows]: an empty result then reads
  /// "No results" with a "Clear filters" action ([onClearFilters]) rather
  /// than [empty].
  final bool filtered;
  final VoidCallback? onClearFilters;

  /// Clears the sort. With it, clicking a sorted descending header cycles
  /// back to unsorted and the header menu offers "Clear sort".
  final VoidCallback? onClearSort;

  /// Fires once when a resize ends — a drag released, a keyboard step, a
  /// width reset — with the column key and its final width. Persist here
  /// rather than in [onColumnResize], which fires on every drag update.
  final void Function(String key, double width)? onColumnResizeEnd;

  /// Overrides the theme's row height at [density]. It is the height at the
  /// normal text size: a larger platform text size adds as much as a line of
  /// body text grows, as it does to the theme's height. Cells keep to one
  /// line and ellipsize.
  final double? rowHeight;

  /// Overrides the theme's header height. It is the height at the normal
  /// text size, and grows with a line of the header's text as [rowHeight]
  /// grows with the body's.
  final double? headerHeight;

  const CollectionTable({
    super.key,
    required this.rows,
    required this.columns,
    this.sort,
    this.onSort,
    this.onRowTap,
    this.editTrigger = TableEditTrigger.auto,
    this.selected,
    this.onSelectionChanged,
    this.columnWidths,
    this.onColumnResize,
    this.onHideColumn,
    this.onPinColumn,
    this.onManageColumns,
    this.loading = false,
    this.empty,
    this.error,
    this.rowKey,
    this.density = TableDensity.standard,
    this.striped = false,
    this.filtered = false,
    this.onClearFilters,
    this.onClearSort,
    this.onColumnResizeEnd,
    this.rowHeight,
    this.headerHeight,
  });

  @override
  State<CollectionTable<T>> createState() => _CollectionTableState<T>();
}

/// A grid position: row 0 is the header, rows 1… the data rows.
typedef _Cell = ({int row, int col});

/// The table's live pointer and focus state, read by the cells that paint
/// it, so hover and the moving focus repaint two rows rather than the table.
class _Signals {
  /// The data row under the pointer, as a grid row.
  final hoveredRow = ValueNotifier<int?>(null);
  final cursor = ValueNotifier<_Cell?>(null);

  /// Whether the focused cell shows its ring: the grid holds focus and the
  /// keyboard put it there.
  final ring = ValueNotifier<bool>(false);

  /// The column whose trailing edge is under the pointer or being dragged.
  final resizing = ValueNotifier<int?>(null);

  /// Whether the grid itself holds focus, rather than a control in a cell.
  final active = ValueNotifier<bool>(false);

  /// The cell focus lands on until [cursor] is set.
  _Cell home = (row: 0, col: 0);

  /// Past the pinned columns, and short of the far edge: the horizontal
  /// scroll's two edge cues.
  final edges = ValueNotifier<({bool scrolled, bool more})>((
    scrolled: false,
    more: false,
  ));

  void dispose() {
    hoveredRow.dispose();
    cursor.dispose();
    ring.dispose();
    resizing.dispose();
    active.dispose();
    edges.dispose();
  }
}

class _CollectionTableState<T> extends State<CollectionTable<T>> {
  final _signals = _Signals();
  final _grid = FocusNode(
    debugLabel: 'CollectionTable',
    descendantsAreTraversable: false,
  );
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  /// Whether a pointer rather than a key last moved the focused cell: the
  /// ring then stays hidden, as `:focus-visible` would have it.
  bool _pointerFocus = false;

  /// Whether the last pointer on the table was a finger or a pen; null
  /// until one lands.
  bool? _touch;

  /// Whether the pointer is coarse — the last one was a finger or a pen, or
  /// none has landed on a touch-first platform. Nothing hovers there, so the
  /// column menus stay visible.
  bool get _coarse => _touch ?? coarsePointerByDefault;

  /// The open inline edit, by record and column.
  ({Object? row, String col})? _editing;
  EditSession? _session;

  /// The column menus, by column index, for Alt+↓.
  final _menus = <int, PopoverController>{};

  /// The body cells on screen, for entering one that holds a control.
  final _bodyCells = <_Cell, _BodyCellState>{};

  /// Live-drag width layer, keyed by column key. Sits over
  /// [CollectionTable.columnWidths]
  /// so a resize is responsive without requiring the parent to rebuild, and
  /// persists across unrelated rebuilds when the parent is uncontrolled.
  final Map<String, double> _resized = {};

  /// The unclamped width of the column being dragged, so a drag past
  /// [TableColumn.minWidth] keeps the pointer's offset.
  double _dragWidth = 0;

  // The last layout, for the keyboard.
  List<TableColumn<T>> _cols = const [];
  List<double> _widths = const [];
  double _available = 0;
  int _pinnedCount = 0;
  double _rowHeight = 0;
  double _headerHeight = 0;

  /// Whether the rows on show are dimmed under a reload.
  bool _stale = false;

  Map<Object?, int> _indexByKey = const {};
  Set<Object?> _selectedKeys = const {};

  bool get _selectable =>
      widget.selected != null && widget.onSelectionChanged != null;

  bool get _resizable => widget.onColumnResize != null;

  /// The data rows the grid shows: none while an error stands in.
  int get _rowCount => widget.error != null ? 0 : widget.rows.length;

  Object? _keyOf(T row) => widget.rowKey == null ? row : widget.rowKey!(row);

  @override
  void initState() {
    super.initState();
    _grid.addListener(_onGridFocus);
    _syncRows();
  }

  @override
  void didUpdateWidget(covariant CollectionTable<T> old) {
    super.didUpdateWidget(old);
    _syncRows();
    if (!identical(widget.columnWidths, old.columnWidths)) _resized.clear();
    final editing = _editing;
    if (editing != null &&
        (!_indexByKey.containsKey(editing.row) ||
            !widget.columns.any((c) => c.key == editing.col))) {
      // The record left the page, or its column went: nothing to edit.
      _session?.cancel();
    }
  }

  @override
  void dispose() {
    // An edit still open is dropped, so an editor that writes as the user
    // types gets to undo it.
    final session = _session;
    _session = null;
    session?.cancel();
    _grid.removeListener(_onGridFocus);
    _grid.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    _signals.dispose();
    super.dispose();
  }

  void _syncRows() {
    final rows = widget.rows;
    _indexByKey = {for (var i = 0; i < rows.length; i++) _keyOf(rows[i]): i};
    _selectedKeys = {...?widget.selected?.map(_keyOf)};
  }

  bool _isSelected(T row) => _selectedKeys.contains(_keyOf(row));

  // ── selection ──

  bool get _allSelected =>
      widget.rows.isNotEmpty && widget.rows.every(_isSelected);
  bool get _someSelected => widget.rows.any(_isSelected) && !_allSelected;

  void _toggleRow(T row) {
    final key = _keyOf(row);
    final next = {...widget.selected!};
    if (_selectedKeys.contains(key)) {
      next.removeWhere((s) => _keyOf(s) == key);
    } else {
      next.add(row);
    }
    widget.onSelectionChanged!(next);
  }

  void _toggleAll(bool select) {
    final next = {...widget.selected!};
    final page = {for (final row in widget.rows) _keyOf(row)};
    next.removeWhere((s) => page.contains(_keyOf(s)));
    if (select) next.addAll(widget.rows);
    widget.onSelectionChanged!(next);
  }

  // ── columns and widths ──

  /// Columns actually rendered: the synthetic checkbox column (when selectable)
  /// followed by the caller's columns.
  List<TableColumn<T>> _columnsFor(AdminTableMetrics metrics) => [
    if (_selectable)
      TableColumn<T>(
        id: '\u0000select',
        label: '',
        fixed: metrics.selectionColumnWidth,
        pinned: true,
        align: Alignment.center,
        resizable: false,
        hideable: false,
        cell: (_) => const SizedBox.shrink(),
      ),
    ...widget.columns,
  ];

  bool _isSelectionColumn(int col) => _selectable && col == 0;

  double? _overrideWidth(TableColumn<T> col) =>
      _resized[col.key] ?? widget.columnWidths?[col.key];

  /// A column is sized either by an explicit width (a resize override or its
  /// declared [TableColumn.fixed]) or by flex. An override turns a flex column
  /// into a fixed one for layout purposes.
  double? _explicitWidth(TableColumn<T> c) => _overrideWidth(c) ?? c.fixed;

  /// Whole-pixel widths, so no column boundary lands between pixels — a
  /// fractional one shows as a seam where the pinned and scrolling halves of
  /// a row meet. The leftover pixels go to the last flex column.
  List<double> _layoutWidths(
    List<TableColumn<T>> cols,
    double available, {
    String? ignoreOverride,
  }) {
    double? explicit(TableColumn<T> c) =>
        (c.key == ignoreOverride ? c.fixed : _explicitWidth(c))
            ?.roundToDouble();
    final widths = [for (final c in cols) explicit(c) ?? 0.0];
    final flexIndexes = [
      for (var i = 0; i < cols.length; i++)
        if (explicit(cols[i]) == null) i,
    ];
    if (flexIndexes.isEmpty) return widths;
    final fixedTotal = widths.fold(0.0, (a, w) => a + w);
    final flexTotal = flexIndexes.fold(0, (a, i) => a + cols[i].flex);
    final remaining = available.isFinite
        ? math.max(0.0, (available - fixedTotal).floorToDouble())
        : 0.0;
    var used = 0.0;
    for (final i in flexIndexes) {
      final share = flexTotal == 0
          ? 0.0
          : (remaining * cols[i].flex / flexTotal).floorToDouble();
      widths[i] = math.max(cols[i].minWidth.ceilToDouble(), share);
      used += widths[i];
    }
    if (used < remaining) widths[flexIndexes.last] += remaining - used;
    return widths;
  }

  void _dragStart(int index) {
    _dragWidth = _widths[index];
    _signals.resizing.value = index;
  }

  /// A drag of [index]'s trailing edge by [delta], positive toward the end.
  void _dragUpdate(int index, double delta) {
    _dragWidth += delta;
    final col = _cols[index];
    final next = math.max(col.minWidth, _dragWidth).roundToDouble();
    if (next == _widths[index]) return;
    setState(() => _resized[col.key] = next);
    widget.onColumnResize!(col.key, next);
  }

  void _dragEnd(int index) {
    if (_signals.resizing.value == index) _signals.resizing.value = null;
    final col = _cols[index];
    widget.onColumnResizeEnd?.call(
      col.key,
      _overrideWidth(col) ?? _widths[index],
    );
  }

  void _resizeBy(int index, double delta) {
    final col = _cols[index];
    final next = math.max(col.minWidth, _widths[index] + delta).roundToDouble();
    setState(() => _resized[col.key] = next);
    widget.onColumnResize!(col.key, next);
    widget.onColumnResizeEnd?.call(col.key, next);
  }

  /// Back to the declared width: [TableColumn.fixed], or a flex column's
  /// share of the table as it stands.
  void _resetWidth(int index) {
    final col = _cols[index];
    if (!_resizable || !col.resizable) return;
    final declared = _layoutWidths(
      _cols,
      _available,
      ignoreOverride: col.key,
    )[index];
    setState(() => _resized.remove(col.key));
    widget.onColumnResize!(col.key, declared);
    widget.onColumnResizeEnd?.call(col.key, declared);
  }

  // ── sort ──

  /// Ascending, then descending, then — with [CollectionTable.onClearSort] —
  /// unsorted.
  void _cycleSort(TableColumn<T> col) {
    final onSort = widget.onSort;
    if (!col.sortable || onSort == null) return;
    final current = widget.sort;
    if (current == null || current.key != col.sortKey) {
      onSort(col.sortKey!, true);
    } else if (current.ascending) {
      onSort(col.sortKey!, false);
    } else if (widget.onClearSort != null) {
      widget.onClearSort!();
    } else {
      onSort(col.sortKey!, true);
    }
  }

  // ── focus ──

  _Cell get _home => (row: _rowCount > 0 ? 1 : 0, col: 0);

  void _onGridFocus() {
    _signals.active.value = _grid.hasPrimaryFocus;
    if (!_grid.hasFocus) _pointerFocus = false;
    if (_grid.hasPrimaryFocus) {
      final cursor = _signals.cursor.value ??= _home;
      if (!_pointerFocus) _reveal(cursor);
    }
    _syncRing();
  }

  void _syncRing() =>
      _signals.ring.value = _grid.hasPrimaryFocus && !_pointerFocus;

  /// A pointer landed on [cell]: it becomes the focused cell, with no ring.
  void _pointAt(_Cell cell) {
    _pointerFocus = true;
    _signals.cursor.value = cell;
    if (!_grid.hasFocus) _grid.requestFocus();
    _syncRing();
  }

  void _onPointerDown(PointerDownEvent event) {
    final coarse = isCoarsePointer(event.kind);
    if (coarse != _coarse) setState(() => _touch = coarse);
  }

  /// [row], [col] kept inside the grid as it stands.
  _Cell _within(int row, int col) =>
      (row: row.clamp(0, _rowCount), col: col.clamp(0, _cols.length - 1));

  void _moveTo(int row, int col) {
    final cell = _within(row, col);
    _signals.cursor.value = cell;
    _reveal(cell);
  }

  /// Scrolls [cell] fully into view on both axes.
  void _reveal(_Cell cell) {
    if (cell.row > 0 && _vertical.hasClients) {
      final position = _vertical.position;
      final top = (cell.row - 1) * _rowHeight;
      final body = position.viewportDimension - _headerHeight;
      var offset = position.pixels;
      if (top < offset) {
        offset = top;
      } else if (top + _rowHeight > offset + body) {
        offset = top + _rowHeight - body;
      }
      offset = offset.clamp(position.minScrollExtent, position.maxScrollExtent);
      if (offset != position.pixels) _vertical.jumpTo(offset);
    }
    if (cell.col >= _pinnedCount &&
        cell.col < _widths.length &&
        _horizontal.hasClients) {
      // Offsets from the start edge, which the scroll position measures
      // from in either direction.
      final position = _horizontal.position;
      final pinned = _widths.take(_pinnedCount).fold(0.0, (a, w) => a + w);
      final start = _widths.take(cell.col).fold(0.0, (a, w) => a + w);
      final end = start + _widths[cell.col];
      var offset = position.pixels;
      if (start - pinned < offset) {
        offset = start - pinned;
      } else if (end - position.viewportDimension > offset) {
        offset = end - position.viewportDimension;
      }
      offset = offset.clamp(position.minScrollExtent, position.maxScrollExtent);
      if (offset != position.pixels) _horizontal.jumpTo(offset);
    }
  }

  /// The rows one screen of the body holds.
  int get _pageRows => _rowHeight <= 0 || !_vertical.hasClients
      ? 10
      : math.max(
          1,
          ((_vertical.position.viewportDimension - _headerHeight) / _rowHeight)
              .floor(),
        );

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_cols.isEmpty) return KeyEventResult.ignored;
    if (_session case final session?) {
      // An open editor answers its own keys: one reaching the grid means
      // the editor took no focus, and Escape still has to close it.
      if (event.logicalKey != LogicalKeyboardKey.escape) {
        return KeyEventResult.ignored;
      }
      _pointerFocus = false;
      session.cancel();
      return KeyEventResult.handled;
    }
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final alt = keyboard.isAltPressed;
    final shift = keyboard.isShiftPressed;
    final ctrl = keyboard.isControlPressed || keyboard.isMetaPressed;
    final repeat = event is KeyRepeatEvent;
    // The arrow that points at the next column: → in a left-to-right
    // table, ← in a right-to-left one.
    final forward = Directionality.of(context) == TextDirection.rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;

    if (!_grid.hasPrimaryFocus) {
      // A control inside a cell holds focus and keeps its own keys, arrows
      // included: Escape or F2 hands focus back to the cell, Tab leaves the
      // table.
      if (repeat) return KeyEventResult.ignored;
      if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.f2) {
        _focusGrid();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.tab) {
        _focusGrid();
        shift ? _grid.previousFocus() : _grid.nextFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // The rows or columns may have shrunk under the focused cell.
    final cursor = _signals.cursor.value ?? _home;
    final at = _within(cursor.row, cursor.col);
    final lastCol = _cols.length - 1;
    final header = at.row == 0;
    // A row about to be replaced is not to be opened, picked or edited.
    final inert = _stale && !header;
    var handled = true;
    switch (key) {
      case LogicalKeyboardKey.arrowUp when !alt:
        _moveTo(at.row - 1, at.col);
      case LogicalKeyboardKey.arrowDown when alt:
        handled = header && !repeat && _openMenu(at.col);
      case LogicalKeyboardKey.arrowDown:
        _moveTo(at.row + 1, at.col);
      case LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowRight
          when alt:
        // The arrow past the column's trailing edge widens it.
        final step = (shift ? 8 : 16) * (key == forward ? 1.0 : -1.0);
        handled = header && _resizable && _cols[at.col].resizable;
        if (handled) _resizeBy(at.col, step);
      case LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowRight:
        _moveTo(at.row, at.col + (key == forward ? 1 : -1));
      case LogicalKeyboardKey.home:
        ctrl ? _moveTo(0, 0) : _moveTo(at.row, 0);
      case LogicalKeyboardKey.end:
        ctrl ? _moveTo(_rowCount, lastCol) : _moveTo(at.row, lastCol);
      case LogicalKeyboardKey.pageDown:
        _moveTo(header ? math.min(1, _rowCount) : at.row + _pageRows, at.col);
      case LogicalKeyboardKey.pageUp:
        _moveTo(
          header ? 0 : math.max(math.min(1, _rowCount), at.row - _pageRows),
          at.col,
        );
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter
          when !repeat:
        if (!inert) _activate(at);
      case LogicalKeyboardKey.space when !repeat:
        handled = inert || _space(at);
      case LogicalKeyboardKey.f2 when !repeat:
        handled = !header && (inert || _startEdit(at.row - 1, at.col));
      case LogicalKeyboardKey.f10 when shift && !repeat:
        handled = header && _openMenu(at.col);
      default:
        handled = false;
    }
    if (!handled) return KeyEventResult.ignored;
    _pointerFocus = false;
    _syncRing();
    return KeyEventResult.handled;
  }

  void _focusGrid() {
    _pointerFocus = false;
    _grid.requestFocus();
  }

  /// Assistive technology moved its focus to [cell]: the grid takes focus
  /// there, as the keyboard would put it.
  void _focusCell(_Cell cell) {
    _signals.cursor.value = cell;
    _focusGrid();
  }

  bool _openMenu(int col) {
    final menu = _menus[col];
    if (menu == null) return false;
    menu.open();
    return true;
  }

  /// Enter on [at].
  void _activate(_Cell at) {
    if (at.row == 0) {
      _activateHeader(at.col);
      return;
    }
    final index = at.row - 1;
    if (index >= _rowCount) return;
    final row = widget.rows[index];
    if (_isSelectionColumn(at.col)) {
      _toggleRow(row);
    } else if (_startEdit(index, at.col)) {
      return;
    } else if (_bodyCells[at]?.enter() ?? false) {
      return;
    } else {
      widget.onRowTap?.call(row);
    }
  }

  void _activateHeader(int col) {
    if (_isSelectionColumn(col)) {
      if (widget.rows.isNotEmpty) _toggleAll(!_allSelected);
    } else {
      _cycleSort(_cols[col]);
    }
  }

  bool _space(_Cell at) {
    if (at.row == 0) {
      _activateHeader(at.col);
      return true;
    }
    if (!_selectable || at.row > _rowCount) return false;
    _toggleRow(widget.rows[at.row - 1]);
    return true;
  }

  // ── inline editing ──

  bool _isEditable(int index, int col) =>
      index >= 0 &&
      index < _rowCount &&
      col >= 0 &&
      col < _cols.length &&
      !_isSelectionColumn(col) &&
      _cols[col].editable;

  /// Opens the editor on data row [index], column [col]; false when that
  /// cell doesn't edit.
  bool _startEdit(int index, int col) {
    if (!_isEditable(index, col)) return false;
    _session?.cancel();
    final column = _cols[col];
    late final EditSession session;
    session = EditSession(
      label: column.label,
      onEnd: (_) => _onEditEnd(session),
    );
    setState(() {
      _session = session;
      _editing = (row: _keyOf(widget.rows[index]), col: column.key);
    });
    _moveTo(index + 1, col);
    return true;
  }

  void _onEditEnd(EditSession session) {
    if (!mounted || _session != session) return;
    setState(() {
      _session = null;
      _editing = null;
    });
    // The editor held focus: hand it back to its cell.
    if (_grid.hasFocus) _grid.requestFocus();
  }

  /// Tab in an editor: commit, then edit the next editable cell in reading
  /// order ([forward]) or the previous one.
  void _editTab(bool forward) {
    _pointerFocus = false;
    final at = _signals.cursor.value;
    final session = _session;
    if (at == null || session == null || !session.commit()) return;
    final width = _cols.length;
    final step = forward ? 1 : -1;
    final end = _rowCount * width;
    for (
      var i = (at.row - 1) * width + at.col + step;
      i >= 0 && i < end;
      i += step
    ) {
      if (_startEdit(i ~/ width, i % width)) return;
    }
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    assert(() {
      var unpinned = false;
      for (final c in widget.columns) {
        if (!c.pinned) {
          unpinned = true;
        } else if (unpinned) {
          return false;
        }
      }
      return true;
    }(), 'Pinned columns must lead: list every pinned TableColumn first.');
    assert(
      widget.rowKey != null ||
          (!_selectable && !widget.columns.any((c) => c.editable)),
      'Selection and inline editing need a rowKey (under a Collection, '
      'CollectionController(rowKey:)): without one, a refetch of fresh '
      'objects drops the checks and moves an open editor.',
    );

    final metrics = context.tableMetrics;
    _cols = _columnsFor(metrics);
    // Taller by as much as the text grows at a large text size.
    _rowHeight =
        (widget.rowHeight ?? metrics.rowHeight(widget.density)) +
        textGrowthOf(context, context.type.body);
    _headerHeight =
        (widget.headerHeight ?? metrics.headerHeight) +
        textGrowthOf(context, switch (metrics.headerText) {
          TableHeaderText.caption => context.type.caption,
          TableHeaderText.label => context.type.bodyStrong,
        });
    if (_cols.isEmpty) return const SizedBox.shrink();

    return Focus(
      focusNode: _grid,
      onKeyEvent: _onKey,
      includeSemantics: false,
      child: Listener(
        onPointerDown: _onPointerDown,
        child: LayoutBuilder(
          builder: (context, constraints) => DelayedLoading(
            loading: widget.loading,
            builder: (context, showLoading) =>
                _body(context, constraints, showLoading),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    BoxConstraints constraints,
    bool showLoading,
  ) {
    final colors = context.colors;
    final rows = widget.rows;
    _stale = showLoading && _rowCount > 0;
    _signals.home = _home;
    _available = constraints.maxWidth;
    _widths = _layoutWidths(_cols, constraints.maxWidth);
    final declaredPinned = _cols.takeWhile((c) => c.pinned).length;
    final pinnedWidth = _widths.take(declaredPinned).fold(0.0, (a, w) => a + w);
    // Frozen columns that would take most of a narrow viewport scroll away
    // with the rest instead.
    _pinnedCount = pinnedWidth > constraints.maxWidth / 2 ? 0 : declaredPinned;

    final Widget? overlay;
    if (widget.error != null) {
      overlay = widget.error!;
    } else if (rows.isEmpty && !widget.loading) {
      overlay = widget.filtered
          ? NoResultsState(onClearFilters: widget.onClearFilters)
          : (widget.empty ??
                EmptyState(title: context.adminL10n.collection.nothingHereYet));
    } else {
      overlay = null;
    }
    final skeleton =
        widget.error == null && rows.isEmpty && widget.loading && showLoading;
    final bodyRows = skeleton
        ? ((constraints.maxHeight - _headerHeight) / _rowHeight).ceil().clamp(
            1,
            50,
          )
        : _rowCount;
    final contentHeight = math.min(
      constraints.maxHeight,
      _headerHeight + bodyRows * _rowHeight,
    );

    Widget table = _table(context, bodyRows, skeleton: skeleton);
    if (skeleton) table = SkeletonGroup(child: table);

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<Notification>(
            onNotification: _onScrollNotification,
            child: table,
          ),
        ),
        if (overlay != null)
          Positioned(
            top: _headerHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: _BodyOverlay(child: overlay),
          ),
        if (showLoading && _rowCount > 0)
          // Dims the rows, not the header, and keeps them from taking taps
          // until the new ones land.
          Positioned(
            top: _headerHeight,
            left: 0,
            right: 0,
            bottom: 0,
            // token-literal: the veil over stale rows
            child: ColoredBox(color: colors.surface.withValues(alpha: 0.45)),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: contentHeight,
          child: _ScrollEdges(
            edges: _signals.edges,
            pinnedWidth: _pinnedCount == 0 ? 0 : pinnedWidth,
          ),
        ),
        if (showLoading)
          const Positioned(top: 0, left: 0, right: 0, child: TopProgressBar()),
      ],
    );
  }

  bool _onScrollNotification(Notification notification) {
    final metrics = switch (notification) {
      ScrollMetricsNotification(:final metrics) => metrics,
      ScrollNotification(:final metrics) => metrics,
      _ => null,
    };
    if (metrics == null || metrics.axis != Axis.horizontal) return false;
    final edges = (
      scrolled: metrics.pixels > metrics.minScrollExtent + 0.5,
      more: metrics.pixels < metrics.maxScrollExtent - 0.5,
    );
    if (edges == _signals.edges.value) return false;
    void apply() {
      if (mounted) _signals.edges.value = edges;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
    return false;
  }

  Widget _table(BuildContext context, int bodyRows, {required bool skeleton}) {
    final colors = context.colors;
    final rows = widget.rows;
    final widths = _widths;
    final metrics = context.tableMetrics;
    final strings = context.adminL10n.collection;

    Color fill(int index) {
      if (!skeleton && _selectable && _isSelected(rows[index])) {
        return colors.tableRowSelected;
      }
      return widget.striped && index.isOdd
          ? colors.tableRowStripe
          : colors.surface;
    }

    final editing = _editing;
    final session = _session;
    // The open editor is keyed by its session, so it keeps its state — the
    // draft, the focus — when a sort or a refresh moves its record.
    Key? keyOf(TableVicinity v) {
      if (session == null || editing == null || skeleton || v.row == 0) {
        return null;
      }
      final match =
          _keyOf(rows[v.row - 1]) == editing.row &&
          _cols[v.column].key == editing.col;
      return match ? ObjectKey(session) : null;
    }

    Widget cellContent(BuildContext context, TableVicinity v) {
      if (v.row == 0) return _headerCell(context, v.column);
      final col = _cols[v.column];
      final align = col._alignment;
      final padding = EdgeInsets.symmetric(horizontal: metrics.cellPaddingX);
      if (skeleton) {
        return _SkeletonCell(
          padding: padding,
          align: align,
          check: _isSelectionColumn(v.column),
          fraction: const [0.72, 0.5, 0.84, 0.6][(v.row + v.column) % 4],
        );
      }
      final index = v.row - 1;
      final row = rows[index];
      final key = _keyOf(row);
      if (session != null && keyOf(v) != null) {
        return _EditorCell(
          session: session,
          align: align,
          padding: EdgeInsets.symmetric(
            horizontal: math.max(
              AdminSpacing.xs,
              metrics.cellPaddingX - context.sizes.fieldPaddingX,
            ),
          ),
          onKeyboard: () => _pointerFocus = false,
          onTapOutside: () => _pointerFocus = true,
          onTab: _editTab,
          child: col.editBuilder!(row, session),
        );
      }

      final selectionColumn = _isSelectionColumn(v.column);
      final selected = _selectable && _selectedKeys.contains(key);
      final Widget content;
      if (selectionColumn) {
        content = Center(
          child: Check(
            value: selected,
            onChanged: (_) => _toggleRow(row),
            semanticLabel: strings.selectRow(v.row),
          ),
        );
      } else {
        final base = context.type.body;
        content = Padding(
          padding: padding,
          child: Align(
            alignment: align,
            // Cells default to the primary body style; the Material
            // textTheme's bodyColor is the muted grey, which reads too
            // light for row text. A cell can still override it.
            child: DefaultTextStyle.merge(
              style: col.numeric
                  ? base.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )
                  : base,
              // One line, as the row is: a long value ellipsizes rather
              // than wraps into a second line the row would clip.
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              child: col.cellBuilder == null
                  ? col.cell!(row)
                  : Builder(builder: (context) => col.buildCell(context, row)),
            ),
          ),
        );
      }
      // The whole selection cell toggles the row, not only its box; the
      // box itself stays the one checkbox assistive technology sees.
      final onTap = selectionColumn
          ? () => _toggleRow(row)
          : widget.onRowTap == null
          ? null
          : () => widget.onRowTap!(row);
      final cell = (row: v.row, col: v.column);
      return _BodyCell(
        signals: _signals,
        registry: _bodyCells,
        cell: cell,
        selected: selected,
        onPointerDown: () => _pointAt(cell),
        onTap: onTap,
        // With a row tap, only when asked for: the tap then waits out a
        // double.
        onDoubleTap:
            col.editable &&
                (widget.onRowTap == null ||
                    widget.editTrigger == TableEditTrigger.doubleTap)
            ? () => _startEdit(index, v.column)
            : null,
        // The row's open action is announced once, on its first cell.
        tapSemantics: v.column == (_selectable ? 1 : 0),
        child: content,
      );
    }

    return _GridView(
      verticalDetails: ScrollableDetails.vertical(controller: _vertical),
      // Reversed right to left, so the first and the pinned columns sit on
      // the right and the rest scroll in from the left.
      horizontalDetails: ScrollableDetails.horizontal(
        controller: _horizontal,
        reverse: Directionality.of(context) == TextDirection.rtl,
      ),
      delegate: _KeyedCellDelegate(
        keyOf: keyOf,
        pinnedRowCount: 1,
        pinnedColumnCount: _pinnedCount,
        columnCount: _cols.length,
        rowCount: bodyRows + 1,
        columnBuilder: (i) =>
            TableSpan(extent: FixedTableSpanExtent(widths[i])),
        rowBuilder: (i) {
          if (i == 0) {
            return TableSpan(
              extent: FixedTableSpanExtent(_headerHeight),
              backgroundDecoration: TableSpanDecoration(
                color: colors.surfaceMuted,
                border: TableSpanBorder(
                  trailing: BorderSide(color: colors.border),
                ),
              ),
            );
          }
          return TableSpan(
            extent: FixedTableSpanExtent(_rowHeight),
            // Guarded: the mouse tracker can deliver a hover callback in the
            // frame after this table is disposed (a row tap navigates away).
            onEnter: skeleton
                ? null
                : (_) {
                    if (mounted) _signals.hoveredRow.value = i;
                  },
            onExit: skeleton
                ? null
                : (_) {
                    if (mounted && _signals.hoveredRow.value == i) {
                      _signals.hoveredRow.value = null;
                    }
                  },
            backgroundDecoration: TableSpanDecoration(
              color: fill(i - 1),
              border: TableSpanBorder(
                trailing: BorderSide(color: colors.borderSubtle),
              ),
            ),
          );
        },
        cellBuilder: (context, v) => TableViewCell(
          child: _GridCell(
            signals: _signals,
            cell: (row: v.row, col: v.column),
            onFocus: _focusCell,
            child: cellContent(context, v),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(BuildContext context, int index) {
    final col = _cols[index];
    final metrics = context.tableMetrics;
    final strings = context.adminL10n.collection;
    void pointAt() => _pointAt((row: 0, col: index));

    if (_isSelectionColumn(index)) {
      // Partial or empty → select all; all → clear (Gmail-style).
      final toggleAll = widget.rows.isEmpty
          ? null
          : () => _toggleAll(!_allSelected);
      return _HeaderShell(
        signals: _signals,
        col: index,
        onPointerDown: pointAt,
        // The whole cell is the target; the box inside is the checkbox
        // assistive technology announces.
        child: CursorRegion(
          cursor: toggleAll == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: toggleAll,
            child: Center(
              child: Check(
                value: _allSelected,
                indeterminate: _someSelected,
                onChanged: toggleAll == null ? null : (_) => toggleAll(),
                semanticLabel: strings.selectAllOnPage,
              ),
            ),
          ),
        ),
      );
    }

    final resizable = _resizable && col.resizable;
    final canSort = col.sortable && widget.onSort != null;
    final active = col.sortable && widget.sort?.key == col.sortKey;
    final canHide = col.hideable && widget.onHideColumn != null;
    final onPin = widget.onPinColumn;
    final onManage = widget.onManageColumns;
    final columnEntries = resizable || canHide || onPin != null;
    final entries = <MenuEntry>[
      if (canSort) ...[
        MenuItem(
          strings.sortAscending,
          icon: Icons.arrow_upward,
          onSelect: () => widget.onSort!(col.sortKey!, true),
        ),
        MenuItem(
          strings.sortDescending,
          icon: Icons.arrow_downward,
          onSelect: () => widget.onSort!(col.sortKey!, false),
        ),
        if (widget.onClearSort != null)
          MenuItem(
            strings.clearSort,
            icon: Icons.close_rounded,
            onSelect: active ? widget.onClearSort : null,
          ),
      ],
      if (canSort && columnEntries) const MenuDivider(),
      if (onPin != null)
        MenuItem(
          col.pinned ? strings.unpinColumn : strings.pinColumn,
          icon: col.pinned ? Icons.push_pin : Icons.push_pin_outlined,
          onSelect: () => onPin(col.key, !col.pinned),
        ),
      if (resizable)
        MenuItem(
          strings.resetWidth,
          icon: Icons.width_normal_outlined,
          onSelect: _overrideWidth(col) == null
              ? null
              : () => _resetWidth(index),
        ),
      if (canHide)
        MenuItem(
          strings.hideColumn,
          icon: Icons.visibility_off_outlined,
          onSelect: () => widget.onHideColumn!(col.key),
        ),
      if (onManage != null) ...[
        if (canSort || columnEntries) const MenuDivider(),
        MenuItem(
          strings.manageColumns,
          icon: Icons.view_column_outlined,
          onSelect: onManage,
        ),
      ],
    ];

    _ResizeCallbacks grip(int column) => _ResizeCallbacks(
      column,
      onStart: _dragStart,
      onUpdate: _dragUpdate,
      onEnd: _dragEnd,
      onReset: _resetWidth,
    );
    // The previous column's boundary is shared with this cell, unless the
    // pinned edge parts the two.
    final previousResizable =
        _resizable &&
        index > 0 &&
        index != _pinnedCount &&
        _cols[index - 1].resizable &&
        !_isSelectionColumn(index - 1);

    return _HeaderShell(
      signals: _signals,
      col: index,
      onPointerDown: pointAt,
      trailingResize: resizable ? grip(index) : null,
      leadingResize: previousResizable ? grip(index - 1) : null,
      handleWidth: metrics.resizeHandleWidth,
      child: _HeaderCell(
        signals: _signals,
        col: index,
        label: col.label,
        align: col._alignment,
        sortable: col.sortable,
        active: active,
        ascending: widget.sort?.ascending ?? true,
        onSort: canSort ? () => _cycleSort(col) : null,
        menu: entries,
        coarse: _coarse,
        onMenu: (controller) {
          if (controller == null) {
            _menus.remove(index);
          } else {
            _menus[index] = controller;
          }
        },
      ),
    );
  }
}

/// Muted cell text — a date, a SKU, a secondary figure — in `foregroundMuted`
/// nudged to 4.5:1 on every fill a row can take: plain, striped and selected,
/// and each under the pointer. [style] defaults to `bodyMuted`.
TextStyle tableMutedStyle(BuildContext context, [TextStyle? style]) {
  final colors = context.colors;
  return (style ?? context.type.bodyMuted).copyWith(
    color: colors.readableOn(
      colors.foregroundMuted,
      surfaces: tableRowSurfaces(colors),
    ),
  );
}

/// The keyboard focus ring of a grid cell, drawn inside the cell so its
/// neighbours never cover it.
class _CellRing extends StatelessWidget {
  const _CellRing();

  @override
  Widget build(BuildContext context) {
    final spec = context.focus;
    final inset = spec.offset >= 0 ? spec.offset + spec.width : 0.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: const FocusRing(focused: true, child: SizedBox.expand()),
        ),
      ),
    );
  }
}

/// Tracks whether [cell] is the grid's focused cell with its ring showing.
mixin _CursorWatch<W extends StatefulWidget> on State<W> {
  _Signals get signals;
  _Cell get cell;

  bool focused = false;

  void watchCursor() {
    signals.cursor.addListener(_syncCursor);
    signals.ring.addListener(_syncCursor);
    focused = _isFocused;
  }

  void unwatchCursor() {
    signals.cursor.removeListener(_syncCursor);
    signals.ring.removeListener(_syncCursor);
  }

  bool get _isFocused => signals.ring.value && signals.cursor.value == cell;

  void _syncCursor() {
    final next = _isFocused;
    if (next != focused) setState(() => focused = next);
  }

  /// Re-reads the cursor after [cell] changed.
  void resyncCursor() => focused = _isFocused;
}

/// A data cell: its content over the row's hover wash, under the focus ring.
/// Hover and focus are read from [signals], so only the cells whose state
/// changed rebuild — never [child].
class _BodyCell extends StatefulWidget {
  final _Signals signals;
  final Map<_Cell, _BodyCellState> registry;
  final _Cell cell;
  final bool selected;
  final VoidCallback onPointerDown;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool tapSemantics;
  final Widget child;

  const _BodyCell({
    required this.signals,
    required this.registry,
    required this.cell,
    required this.selected,
    required this.onPointerDown,
    required this.onTap,
    required this.onDoubleTap,
    required this.tapSemantics,
    required this.child,
  });

  @override
  State<_BodyCell> createState() => _BodyCellState();
}

class _BodyCellState extends State<_BodyCell> with _CursorWatch<_BodyCell> {
  /// Holds the cell's own controls; [enter] reaches them.
  final _scope = FocusNode(
    debugLabel: 'CollectionTable cell',
    canRequestFocus: false,
    skipTraversal: true,
  );

  bool _hovered = false;

  @override
  _Signals get signals => widget.signals;

  @override
  _Cell get cell => widget.cell;

  @override
  void initState() {
    super.initState();
    widget.registry[cell] = this;
    signals.hoveredRow.addListener(_syncHover);
    _hovered = signals.hoveredRow.value == cell.row;
    watchCursor();
  }

  @override
  void didUpdateWidget(_BodyCell old) {
    super.didUpdateWidget(old);
    if (old.cell != cell) {
      if (identical(old.registry[old.cell], this)) {
        old.registry.remove(old.cell);
      }
      widget.registry[cell] = this;
      _hovered = signals.hoveredRow.value == cell.row;
      resyncCursor();
    }
  }

  @override
  void dispose() {
    if (identical(widget.registry[cell], this)) widget.registry.remove(cell);
    signals.hoveredRow.removeListener(_syncHover);
    unwatchCursor();
    _scope.dispose();
    super.dispose();
  }

  void _syncHover() {
    final next = signals.hoveredRow.value == cell.row;
    if (next != _hovered) setState(() => _hovered = next);
  }

  /// Moves focus to the first control in the cell; false when it has none.
  bool enter() {
    for (final node in _scope.descendants) {
      if (node.canRequestFocus && node.context != null) {
        node.requestFocus();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget child = Stack(
      fit: StackFit.expand,
      children: [
        if (_hovered)
          // Laid over the row's fill, short of its trailing rule.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 1,
            child: ColoredBox(
              color: widget.selected
                  ? colors.tableRowSelectedHover
                  : colors.tableRowHover,
            ),
          ),
        Focus(focusNode: _scope, includeSemantics: false, child: widget.child),
        if (focused) const _CellRing(),
      ],
    );
    if (widget.onTap != null || widget.onDoubleTap != null) {
      // A cell edited on a double tap takes no selection either (a double
      // click there would select a word instead), under the arrow, as a
      // spreadsheet's cells.
      child = CursorRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: !widget.tapSemantics,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: child,
        ),
      );
    }
    return Listener(onPointerDown: (_) => widget.onPointerDown(), child: child);
  }
}

/// The open editor of a cell: routes Escape to cancel, Enter to commit and
/// Tab to the next editable cell, commits on a tap outside, and focuses the
/// editor's first control as it opens.
class _EditorCell extends StatefulWidget {
  final EditSession session;
  final AlignmentGeometry align;
  final EdgeInsets padding;
  final VoidCallback onKeyboard;
  final VoidCallback onTapOutside;
  final ValueChanged<bool> onTab;
  final Widget child;

  const _EditorCell({
    required this.session,
    required this.align,
    required this.padding,
    required this.onKeyboard,
    required this.onTapOutside,
    required this.onTab,
    required this.child,
  });

  @override
  State<_EditorCell> createState() => _EditorCellState();
}

class _EditorCellState extends State<_EditorCell> {
  final _scope = FocusNode(
    debugLabel: 'CollectionTable editor',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final node in _scope.descendants) {
        if (node.canRequestFocus) {
          node.requestFocus();
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  /// Whether focus is in a popover the editor opened — a picker's list —
  /// which answers Enter itself.
  bool get _inNestedPopover {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused != null &&
        Popover.availableHeightOf(focused) != null &&
        Popover.availableHeightOf(context) == null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final session = widget.session;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onKeyboard();
        session.cancel();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter
          when !HardwareKeyboard.instance.isShiftPressed && !_inNestedPopover:
        widget.onKeyboard();
        session.commit();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.tab:
        widget.onTab(!HardwareKeyboard.instance.isShiftPressed);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) {
        // A tap in a picker the editor opened is the editor's own: the pick
        // lands on its tap-up, after this.
        if (Popover.isOpenWithin(context)) return;
        widget.onTapOutside();
        widget.session.commit();
      },
      child: Focus(
        focusNode: _scope,
        onKeyEvent: _onKey,
        includeSemantics: false,
        child: Padding(
          padding: widget.padding,
          child: Align(alignment: widget.align, child: widget.child),
        ),
      ),
    );
  }
}

/// A placeholder cell of a first load: a pulsing bar, or a box in the
/// checkbox column.
class _SkeletonCell extends StatelessWidget {
  final EdgeInsets padding;
  final AlignmentGeometry align;
  final bool check;
  final double fraction;

  const _SkeletonCell({
    required this.padding,
    required this.align,
    required this.check,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    if (check) {
      return Center(
        child: Skeleton(
          width: 18,
          height: 18,
          borderRadius: BorderRadius.circular(context.radii.radiusCheck),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, box) => Align(
          alignment: align,
          child: Skeleton(
            width: math.min(box.maxWidth * fraction, 160),
            height: 12,
          ),
        ),
      ),
    );
  }
}

/// An empty or error body under the header: centred in the body, and
/// scrolling when the body is shorter than it.
class _BodyOverlay extends StatelessWidget {
  final Widget child;

  const _BodyOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.maxHeight,
            maxWidth: box.maxWidth,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The horizontal scroll's edge cues: a rule and a soft shadow off the last
/// pinned column once content scrolls under it, and a shadow at the far edge
/// while more columns lie beyond it. Both follow the text direction, as the
/// columns do.
class _ScrollEdges extends StatelessWidget {
  final ValueListenable<({bool scrolled, bool more})> edges;
  final double pinnedWidth;

  const _ScrollEdges({required this.edges, required this.pinnedWidth});

  static const _shadowWidth = 8.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // token-literal: the pinned columns' scroll shadow
    final shade = colors.shadow.withValues(
      alpha: colors.brightness == Brightness.dark ? 0.4 : 0.1,
    );
    Widget shadow({required bool fromStart}) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fromStart
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          end: fromStart
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          colors: [shade, shade.withValues(alpha: 0)],
        ),
      ),
    );
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: edges,
        builder: (context, edges, _) => Stack(
          children: [
            if (edges.scrolled && pinnedWidth > 0) ...[
              PositionedDirectional(
                start: pinnedWidth - 1,
                top: 0,
                bottom: 0,
                width: 1,
                child: ColoredBox(color: colors.border),
              ),
              PositionedDirectional(
                start: pinnedWidth,
                top: 0,
                bottom: 0,
                width: _shadowWidth,
                child: shadow(fromStart: true),
              ),
            ],
            if (edges.more)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                width: _shadowWidth,
                child: shadow(fromStart: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// A column-edge drag, for the column at [index].
class _ResizeCallbacks {
  final int index;
  final ValueChanged<int> onStart;
  final void Function(int index, double delta) onUpdate;
  final ValueChanged<int> onEnd;
  final ValueChanged<int> onReset;

  const _ResizeCallbacks(
    this.index, {
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onReset,
  });
}

/// What every header cell shares: the pointer landing on it, the focus ring,
/// and the resize grips that straddle its edges — the trailing half of its
/// own boundary, and the leading half of the previous column's.
class _HeaderShell extends StatefulWidget {
  final _Signals signals;
  final int col;
  final VoidCallback onPointerDown;
  final _ResizeCallbacks? trailingResize;
  final _ResizeCallbacks? leadingResize;
  final double handleWidth;
  final Widget child;

  const _HeaderShell({
    required this.signals,
    required this.col,
    required this.onPointerDown,
    this.trailingResize,
    this.leadingResize,
    this.handleWidth = 8,
    required this.child,
  });

  @override
  State<_HeaderShell> createState() => _HeaderShellState();
}

class _HeaderShellState extends State<_HeaderShell>
    with _CursorWatch<_HeaderShell> {
  @override
  _Signals get signals => widget.signals;

  @override
  _Cell get cell => (row: 0, col: widget.col);

  @override
  void initState() {
    super.initState();
    watchCursor();
  }

  @override
  void didUpdateWidget(_HeaderShell old) {
    super.didUpdateWidget(old);
    if (old.col != widget.col) resyncCursor();
  }

  @override
  void dispose() {
    unwatchCursor();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final half = widget.handleWidth / 2;
    final trailing = widget.trailingResize;
    final leading = widget.leadingResize;
    return Listener(
      onPointerDown: (_) => widget.onPointerDown(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (trailing != null)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 0,
              width: half,
              child: _ResizeGrip(
                signals: signals,
                callbacks: trailing,
                drawsLine: true,
              ),
            ),
          if (leading != null)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: 0,
              width: half,
              child: _ResizeGrip(
                signals: signals,
                callbacks: leading,
                drawsLine: false,
              ),
            ),
          if (focused) const _CellRing(),
        ],
      ),
    );
  }
}

/// One half of a column boundary's hit strip: the resize cursor, drag to
/// resize, double-click to reset, and — while either half is hovered or
/// dragged — a 1px primary hairline on the boundary. A drag toward the
/// column's end widens it: rightward, or leftward right to left.
class _ResizeGrip extends StatefulWidget {
  final _Signals signals;
  final _ResizeCallbacks callbacks;

  /// Whether this half draws the boundary's hairline: the trailing one,
  /// on its column's last pixel — its rightmost, or leftmost right to left.
  final bool drawsLine;

  const _ResizeGrip({
    required this.signals,
    required this.callbacks,
    required this.drawsLine,
  });

  @override
  State<_ResizeGrip> createState() => _ResizeGripState();
}

class _ResizeGripState extends State<_ResizeGrip> {
  bool _inside = false;
  bool _dragging = false;

  ValueNotifier<int?> get _resizing => widget.signals.resizing;
  int get _index => widget.callbacks.index;

  void _release() {
    if (!_inside && !_dragging && _resizing.value == _index) {
      _resizing.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final callbacks = widget.callbacks;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) {
        _inside = true;
        _resizing.value = _index;
      },
      onExit: (_) {
        _inside = false;
        if (mounted) _release();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        // From the pointer's first move, so the edge tracks it exactly.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) {
          _dragging = true;
          callbacks.onStart(_index);
        },
        onHorizontalDragUpdate: (d) =>
            callbacks.onUpdate(_index, rtl ? -d.delta.dx : d.delta.dx),
        onHorizontalDragEnd: (_) {
          _dragging = false;
          callbacks.onEnd(_index);
          _release();
        },
        onHorizontalDragCancel: () {
          _dragging = false;
          _release();
        },
        onDoubleTap: () => callbacks.onReset(_index),
        child: !widget.drawsLine
            ? null
            : ValueListenableBuilder(
                valueListenable: _resizing,
                builder: (context, resizing, _) => Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: 1,
                    height: double.infinity,
                    child: resizing == _index
                        ? ColoredBox(color: context.colors.primary)
                        : null,
                  ),
                ),
              ),
      ),
    );
  }
}

/// A header cell: the whole cell sorts ([onSort]), and a discreet ⋮ opens
/// the column menu. The ⋮ floats over the cell rather than taking a slot —
/// on the start side of an end-aligned column, so its label still lines up
/// with its values — and shows on hover, while its cell has keyboard focus
/// and while open. Start and end follow the text direction.
///
/// Nothing hovers on touch ([coarse]), so there the ⋮ shows for good, in a
/// slot at the cell's trailing edge where it can't be read as the next
/// column's — as long as the whole label and a sort arrow leave room for it.
/// Where they don't, the label wins: the ⋮ floats as it would for a mouse,
/// and a long press, or the header's "Column options" action for assistive
/// technology, opens the menu. Touch shows no idle sort arrow either.
class _HeaderCell extends StatefulWidget {
  final _Signals signals;
  final int col;
  final String label;
  final AlignmentGeometry align;
  final bool sortable;
  final bool active;
  final bool ascending;
  final VoidCallback? onSort;
  final List<MenuEntry> menu;
  final bool coarse;
  final ValueChanged<PopoverController?> onMenu;

  const _HeaderCell({
    required this.signals,
    required this.col,
    required this.label,
    required this.align,
    required this.sortable,
    required this.active,
    required this.ascending,
    required this.onSort,
    required this.menu,
    required this.coarse,
    required this.onMenu,
  });

  @override
  State<_HeaderCell> createState() => _HeaderCellState();
}

class _HeaderCellState extends State<_HeaderCell>
    with _CursorWatch<_HeaderCell> {
  /// The pointers a long press on the header opens the menu for.
  static final _pressKinds = {
    ...PointerDeviceKind.values.where(isCoarsePointer),
  };

  bool _hover = false;

  /// The column menu, once built.
  PopoverController? _menu;

  @override
  _Signals get signals => widget.signals;

  @override
  _Cell get cell => (row: 0, col: widget.col);

  @override
  void initState() {
    super.initState();
    watchCursor();
    PaintingBinding.instance.systemFonts.addListener(_onFontsChanged);
  }

  /// The label is measured, so a font that loads late measures it again.
  void _onFontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_HeaderCell old) {
    super.didUpdateWidget(old);
    if (old.col != widget.col) {
      old.onMenu(null);
      resyncCursor();
    }
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    unwatchCursor();
    widget.onMenu(null);
    super.dispose();
  }

  void _openMenu() {
    final menu = _menu;
    if (menu != null && !menu.isOpen) menu.open();
  }

  /// The label with its sort state, as read aloud: "Price, sorted
  /// ascending".
  String _sortName(CollectionMessages strings) {
    final label = widget.label;
    if (!widget.sortable) return label;
    if (!widget.active) return strings.notSorted(label);
    return widget.ascending
        ? strings.sortedAscending(label)
        : strings.sortedDescending(label);
  }

  /// Whether the label sits at the cell's end, as a number column's does:
  /// its sort arrow then goes on its inside, before it.
  bool _endAligned(TextDirection direction) {
    final x = widget.align.resolve(direction).x;
    return direction == TextDirection.rtl ? x < 0 : x > 0;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext context, BoxConstraints box) {
    final colors = context.colors;
    final metrics = context.tableMetrics;
    final strings = context.adminL10n.collection;
    final direction = Directionality.of(context);
    final endAligned = _endAligned(direction);
    final padX = metrics.cellPaddingX;
    final hasMenu = widget.menu.isNotEmpty;
    const size = IconActionSize.inline;
    // The glyph lines up with the cell padding; its 24px box borrows the
    // rest from the padding.
    final inset = padX - (size.box - size.glyph) / 2;

    // The header strip is surfaceMuted, not the surface foregroundMuted is
    // tuned for; nudge it just enough to read on it.
    final idle = colors.readableOn(
      colors.foregroundMuted,
      surfaces: [colors.surfaceMuted],
    );
    final base = switch (metrics.headerText) {
      TableHeaderText.caption => context.type.weighted(
        context.type.caption,
        FontWeight.w600,
      ),
      TableHeaderText.label => context.type.bodyStrong,
    };
    // Bold text draws the label bold: in the font's own bold face, so the
    // measure below and the Text agree.
    final face = MediaQuery.boldTextOf(context)
        ? context.type.weighted(base, FontWeight.bold)
        : base;
    final style = face.copyWith(
      color: widget.active ? colors.foregroundSecondary : idle,
    );
    // Measured as the Text below will lay it out.
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final painter = TextPainter(
      text: TextSpan(text: widget.label, style: effective),
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final natural = painter.width;
    painter.dispose();

    final room = math.max(0.0, box.maxWidth - 2 * padX);
    final arrow = metrics.sortIconGap + metrics.sortIconSize;
    // The ⋮'s slot on touch: the box, less what it borrows from the
    // padding, and a gap before it. Taken only where the label, and the
    // arrow a sort would add, leave room for it, so sorting never moves it.
    final slot = size.box - (padX - inset) + metrics.sortIconGap;
    final slotted =
        hasMenu &&
        widget.coarse &&
        natural + (widget.sortable ? arrow : 0) + slot <= room;
    final reserve = slotted ? slot : 0.0;
    // A floating ⋮ sits on an end-aligned label's start side; a slotted
    // one on the trailing edge.
    final menuAtStart = !slotted && endAligned;
    final actions = hasMenu && widget.coarse && !slotted
        ? {CustomSemanticsAction(label: strings.columnOptions): _openMenu}
        : null;

    final labelRoom = room - reserve;
    final showArrow =
        widget.sortable &&
        (widget.active || !widget.coarse && natural + arrow <= labelRoom);
    final truncated = natural + (showArrow ? arrow : 0) > labelRoom + 0.5;
    // A long press on touch opens the menu, not a tooltip, so a cut-off
    // label is named in full atop the menu instead.
    final named = truncated && hasMenu && widget.coarse;

    final content = Padding(
      padding: EdgeInsetsDirectional.only(
        start: padX + (menuAtStart ? reserve : 0),
        end: padX + (menuAtStart ? 0 : reserve),
      ),
      child: Align(
        alignment: widget.align,
        child: _label(
          context,
          style,
          idle,
          showArrow: showArrow,
          arrowFirst: endAligned,
          tip: truncated && !named,
        ),
      ),
    );
    final Widget target = GestureDetector(
      supportedDevices: _pressKinds,
      excludeFromSemantics: true,
      onLongPress: hasMenu ? _openMenu : null,
      child: widget.onSort == null
          ? Semantics(
              label: _sortName(strings),
              excludeSemantics: true,
              customSemanticsActions: actions,
              // A header is chrome, not prose: no selection from above
              // reaches its label, under the arrow.
              child: CursorRegion(
                cursor: SystemMouseCursors.basic,
                child: content,
              ),
            )
          : Tappable(
              onTap: widget.onSort,
              focusable: false,
              showFocusRing: false,
              semanticLabel: _sortName(strings),
              excludeSemantics: true,
              customSemanticsActions: actions,
              child: content,
            ),
    );

    return MouseRegion(
      onEnter: (_) {
        if (!_hover) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover) setState(() => _hover = false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          target,
          if (hasMenu)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: menuAtStart ? inset : null,
              end: menuAtStart ? null : inset,
              child: Center(
                child: _trigger(context, menuAtStart, slotted, named),
              ),
            ),
        ],
      ),
    );
  }

  /// The label and, with [showArrow], its sort arrow: after it, or before
  /// it with [arrowFirst], so an end-aligned label keeps its arrow on the
  /// inside and its edge meets the values'. A mouse's idle arrow gives way
  /// before the label truncates, and touch shows none; a label that still
  /// doesn't fit ends in an ellipsis, and with [tip] shows in full in a
  /// tooltip.
  Widget _label(
    BuildContext context,
    TextStyle style,
    Color idle, {
    required bool showArrow,
    required bool arrowFirst,
    required bool tip,
  }) {
    final colors = context.colors;
    final metrics = context.tableMetrics;
    final active = widget.active;

    Widget label = Text(
      widget.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (tip) {
      label = Tip(
        message: widget.label,
        excludeFromSemantics: true,
        child: label,
      );
    }
    final icon = Icon(
      active
          ? (widget.ascending ? Icons.arrow_upward : Icons.arrow_downward)
          : Icons.unfold_more,
      size: metrics.sortIconSize,
      color: active ? colors.primaryText : idle,
    );
    final gap = SizedBox(width: metrics.sortIconGap);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showArrow && arrowFirst) ...[icon, gap],
        Flexible(child: label),
        if (showArrow && !arrowFirst) ...[gap, icon],
      ],
    );
  }

  Widget _trigger(
    BuildContext context,
    bool atStart,
    bool slotted,
    bool named,
  ) {
    return Menu(
      side: PopoverSide.bottom,
      align: atStart ? PopoverAlign.start : PopoverAlign.end,
      minWidth: 184,
      entries: [if (named) MenuHeader(widget.label), ...widget.menu],
      builder: (context, controller) {
        widget.onMenu(controller);
        _menu = controller;
        final visible = slotted || _hover || focused || controller.isOpen;
        return IgnorePointer(
          ignoring: !visible,
          child: Opacity(
            opacity: visible ? 1 : 0,
            // Out of sight on touch, the header's action stands in for it.
            alwaysIncludeSemantics: !widget.coarse,
            // Backed by the header fill, so a long label runs under it
            // rather than through it.
            child: ColoredBox(
              color: context.colors.surfaceMuted,
              child: IconAction(
                Icons.more_vert,
                label: context.adminL10n.collection.columnOptionsFor(
                  widget.label,
                ),
                size: IconActionSize.inline,
                expanded: controller.isOpen,
                onPressed: controller.toggle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A grid cell as assistive technology meets it: a cell, or a column header
/// on the header row, filed under its row by [_RenderGridViewport]. The
/// grid's focused cell — the one it starts on until it has had focus — is
/// its one focus target, so a move of the focus is announced, and focusing
/// it from a screen reader focuses the grid ([onFocus]).
class _GridCell extends StatefulWidget {
  final _Signals signals;
  final _Cell cell;
  final ValueChanged<_Cell> onFocus;
  final Widget child;

  const _GridCell({
    required this.signals,
    required this.cell,
    required this.onFocus,
    required this.child,
  });

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  /// Whether this is the grid's focused cell.
  bool _current = false;

  /// Whether it is, and the grid holds focus.
  bool _focused = false;

  _Signals get _signals => widget.signals;

  @override
  void initState() {
    super.initState();
    _signals.cursor.addListener(_sync);
    _signals.active.addListener(_sync);
    _read();
  }

  @override
  void didUpdateWidget(_GridCell old) {
    super.didUpdateWidget(old);
    _read();
  }

  @override
  void dispose() {
    _signals.cursor.removeListener(_sync);
    _signals.active.removeListener(_sync);
    super.dispose();
  }

  void _read() {
    _current = (_signals.cursor.value ?? _signals.home) == widget.cell;
    _focused = _current && _signals.active.value;
  }

  void _sync() {
    final current = _current;
    final focused = _focused;
    _read();
    if (current != _current || focused != _focused) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;
    return _CellTagger(
      tag: _CellTag(cell.row, cell.col),
      child: Semantics(
        container: true,
        role: cell.row == 0 ? SemanticsRole.columnHeader : SemanticsRole.cell,
        focusable: _current ? true : null,
        focused: _current ? _focused : null,
        onFocus: _current ? () => widget.onFocus(cell) : null,
        child: widget.child,
      ),
    );
  }
}

/// Where a grid cell sits, on its semantics node.
class _CellTag extends SemanticsTag {
  final int row;
  final int column;

  _CellTag(this.row, this.column) : super('grid cell $row,$column');

  @override
  bool operator ==(Object other) =>
      other is _CellTag && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

/// Tags the semantics node under it with [tag].
class _CellTagger extends SingleChildRenderObjectWidget {
  final _CellTag tag;

  const _CellTagger({required this.tag, required super.child});

  @override
  _RenderCellTagger createRenderObject(BuildContext context) =>
      _RenderCellTagger(tag);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCellTagger renderObject,
  ) {
    renderObject.tag = tag;
  }
}

class _RenderCellTagger extends RenderProxyBox {
  _RenderCellTagger(this._tag);

  _CellTag _tag;
  set tag(_CellTag value) {
    if (value == _tag) return;
    _tag = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.addTagForChildren(_tag);
  }
}

/// A [TableView] whose cells assistive technology reads as a table: rows of
/// cells under a row of column headers.
class _GridView extends TwoDimensionalScrollView {
  const _GridView({
    required super.verticalDetails,
    required super.horizontalDetails,
    required TableCellDelegateMixin super.delegate,
  });

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return _GridViewport(
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      delegate: delegate as TableCellDelegateMixin,
      mainAxis: mainAxis,
      clipBehavior: clipBehavior,
    );
  }
}

class _GridViewport extends TableViewport {
  const _GridViewport({
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    super.clipBehavior,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return _RenderGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      clipBehavior: clipBehavior,
      delegate: delegate as TableCellDelegateMixin,
      childManager: context as TwoDimensionalChildManager,
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
    );
  }
}

/// The table's viewport, announced as a table: the cells' nodes, which
/// [_CellTag] places, are filed under a node per row, since a row has no
/// render object of its own.
class _RenderGridViewport extends RenderTableViewport {
  _RenderGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required super.childManager,
    super.clipBehavior,
    super.alignment,
    super.textDirection,
  });

  final _rows = <int, SemanticsNode>{};

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..role = SemanticsRole.table
      ..isSemanticBoundary = true
      ..explicitChildNodes = true;
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _rows.clear();
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final byRow = <int, List<(int, SemanticsNode)>>{};
    for (final child in children) {
      final tag = child.tags?.whereType<_CellTag>().firstOrNull;
      assert(tag != null, 'Every grid cell is a _GridCell.');
      if (tag == null) continue;
      (byRow[tag.row] ??= []).add((tag.column, child));
    }
    _rows.removeWhere((row, _) => !byRow.containsKey(row));
    final rows = [
      for (final row in byRow.keys.toList()..sort())
        _row(row, byRow[row]!..sort((a, b) => a.$1.compareTo(b.$1))),
    ];
    node.updateWith(config: config, childrenInInversePaintOrder: rows);
  }

  /// The node of [row], around its [cells] — in the viewport's coordinates,
  /// so the cells keep theirs.
  SemanticsNode _row(int row, List<(int, SemanticsNode)> cells) {
    Rect? bounds;
    for (final (_, cell) in cells) {
      final transform = cell.transform;
      final rect = transform == null
          ? cell.rect
          : MatrixUtils.transformRect(transform, cell.rect);
      bounds = bounds?.expandToInclude(rect) ?? rect;
    }
    return (_rows[row] ??= SemanticsNode())
      ..rect = bounds!
      ..updateWith(
        config: SemanticsConfiguration()
          ..role = SemanticsRole.row
          ..indexInParent = row,
        childrenInInversePaintOrder: [for (final (_, cell) in cells) cell],
      );
  }
}

/// Builds the table's cells, wrapping each one [keyOf] names in a keyed
/// subtree: the stock delegate wraps cells in a keep-alive that hides their
/// own keys, so a keyed cell would otherwise never follow its record.
class _KeyedCellDelegate extends TableCellBuilderDelegate {
  final Key? Function(TableVicinity vicinity) keyOf;

  _KeyedCellDelegate({
    required this.keyOf,
    super.columnCount,
    super.rowCount,
    super.pinnedColumnCount,
    super.pinnedRowCount,
    required super.cellBuilder,
    required super.columnBuilder,
    required super.rowBuilder,
  });

  @override
  Widget? build(BuildContext context, ChildVicinity vicinity) {
    final child = super.build(context, vicinity);
    final key = keyOf(vicinity as TableVicinity);
    return child == null || key == null
        ? child
        : KeyedSubtree(key: key, child: child);
  }
}
