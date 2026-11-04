import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import '../sample.dart';

/// Demo — the table's interaction states, one per knob value and pinned the
/// way a person would reach them: the keyboard's focused cell and its ring,
/// an open inline editor, an open header menu (sorted, so "Clear sort" is
/// live), the row hover over a stripe and over a selection, the pointer on
/// a column boundary, and the pinned edge's rule and shadow once the columns
/// scroll under it. The table keeps these states to itself, so the demo
/// sends the keys, the hover or the scroll after its first frame.
///
/// The named constructors pin one state each without the knob, so a render
/// that cannot turn knobs (a golden) still shows every state.
class DataTableInteractionDemo extends StatelessWidget {
  /// The state shown, or null to take it from the State knob.
  final _Pin? _pin;

  @Preview(name: 'Interaction states', wrapper: adminUiPreview)
  const DataTableInteractionDemo({super.key}) : _pin = null;

  @Preview(name: 'Interaction · editing a cell', wrapper: adminUiPreview)
  const DataTableInteractionDemo.editing({super.key}) : _pin = _Pin.editing;

  @Preview(name: 'Interaction · header menu open', wrapper: adminUiPreview)
  const DataTableInteractionDemo.headerMenu({super.key})
    : _pin = _Pin.headerMenu;

  @Preview(name: 'Interaction · row hover on a stripe', wrapper: adminUiPreview)
  const DataTableInteractionDemo.hoverStripe({super.key})
    : _pin = _Pin.hoverStripe;

  @Preview(
    name: 'Interaction · row hover on a selection',
    wrapper: adminUiPreview,
  )
  const DataTableInteractionDemo.hoverSelected({super.key})
    : _pin = _Pin.hoverSelected;

  @Preview(
    name: 'Interaction · pointer on a column edge',
    wrapper: adminUiPreview,
  )
  const DataTableInteractionDemo.resizeEdge({super.key})
    : _pin = _Pin.resizeEdge;

  @Preview(
    name: 'Interaction · scrolled past the pinned column',
    wrapper: adminUiPreview,
  )
  const DataTableInteractionDemo.scrolled({super.key}) : _pin = _Pin.scrolled;

  @override
  Widget build(BuildContext context) {
    final state =
        _pin ??
        context.knobs.picker<_Pin>('State', const {
          'Focused cell': _Pin.focusedCell,
          'Editing a cell': _Pin.editing,
          'Header menu open': _Pin.headerMenu,
          'Row hover on a stripe': _Pin.hoverStripe,
          'Row hover on a selection': _Pin.hoverSelected,
          'Pointer on a column edge': _Pin.resizeEdge,
          'Scrolled past the pinned column': _Pin.scrolled,
        }, _Pin.focusedCell);
    final table = _PinnedTable(key: ValueKey(state), pin: state);
    if (state != _Pin.scrolled) return collectionFrame(context, table: table);
    return ColoredBox(
      color: context.colors.background,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: 560,
          child: collectionFrame(context, table: table),
        ),
      ),
    );
  }
}

enum _Pin {
  focusedCell,
  editing,
  headerMenu,
  hoverStripe,
  hoverSelected,
  resizeEdge,
  scrolled,
}

class _PinnedTable extends StatefulWidget {
  final _Pin pin;

  const _PinnedTable({super.key, required this.pin});

  @override
  State<_PinnedTable> createState() => _PinnedTableState();
}

class _PinnedTableState extends State<_PinnedTable> {
  final _rows = sampleProducts(12);
  final _renamed = <int, String>{};
  late Set<Product> _selected = widget.pin == _Pin.hoverSelected
      ? {_rows[1], _rows[2]}
      : {};
  TableSort? _sort = const TableSort('name');
  final _widths = <String, double>{};

  @override
  void initState() {
    super.initState();
    if (widget.pin == _Pin.headerMenu) _sort = const TableSort('price');
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  Future<void> _apply() async {
    if (!mounted) return;
    // The arrow toward the next column, and the side columns end on: both
    // mirror right to left.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    switch (widget.pin) {
      case _Pin.focusedCell:
        await _focusGrid();
        await _press(LogicalKeyboardKey.arrowDown);
        for (var i = 0; i < 4; i++) {
          await _press(forward);
        }
      case _Pin.editing:
        await _focusGrid();
        await _press(LogicalKeyboardKey.arrowDown);
        await _press(forward);
        await _press(LogicalKeyboardKey.f2);
      case _Pin.headerMenu:
        final name = context.adminL10n.collection.columnOptionsFor('Price');
        final trigger = _find((w) => w is IconAction && w.label == name);
        if (trigger != null) _tap(_centre(trigger));
      case _Pin.hoverStripe || _Pin.hoverSelected:
        final name = _find(
          (w) => w is TableIdentity && w.title == _rows[1].name,
        );
        if (name != null) _hover(_centre(name));
      case _Pin.resizeEdge:
        final label = _find((w) => w is Text && w.data == 'Category');
        if (label == null) return;
        final box = label.renderObject! as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        final padX = context.tableMetrics.cellPaddingX;
        // Just inside the 150px column's trailing edge.
        final x = rtl
            ? rect.right + padX - 150 + 2
            : rect.left - padX + 150 - 2;
        _hover(Offset(x, rect.center.dy));
      case _Pin.scrolled:
        final table = _find((w) => w is CollectionTable);
        if (table == null) return;
        GestureBinding.instance.handlePointerEvent(
          PointerScrollEvent(
            position: _centre(table),
            scrollDelta: Offset(rtl ? -120 : 120, 0),
          ),
        );
    }
    if (mounted) setState(() {});
  }

  /// The first element under this demo whose widget passes [test].
  Element? _find(bool Function(Widget widget) test) {
    Element? found;
    void visit(Element element) {
      if (found != null) return;
      if (test(element.widget)) {
        found = element;
        return;
      }
      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return found;
  }

  Offset _centre(Element element) {
    final box = element.renderObject! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// Focuses the table as Tab would, so its focused cell shows a ring.
  Future<void> _focusGrid() async {
    final grid = _find((w) => w is Focus && w.focusNode != null);
    (grid?.widget as Focus?)?.focusNode?.requestFocus();
    await _focusLanded();
  }

  /// Waits out the microtask the focus manager applies a focus change in,
  /// and no frame: the whole pin lands within the frame it starts after, so
  /// a render shows it however many frames it pumps.
  Future<void> _focusLanded() => Future<void>.microtask(() {});

  /// [key] going down, handed along the focus chain as the keyboard would.
  Future<void> _press(LogicalKeyboardKey key) async {
    final physical = switch (key) {
      LogicalKeyboardKey.arrowDown => PhysicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft => PhysicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight => PhysicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.f2 => PhysicalKeyboardKey.f2,
      _ => PhysicalKeyboardKey.space,
    };
    final event = KeyDownEvent(
      physicalKey: physical,
      logicalKey: key,
      timeStamp: Duration.zero,
    );
    for (
      FocusNode? node = FocusManager.instance.primaryFocus;
      node != null;
      node = node.parent
    ) {
      final result = node.onKeyEvent?.call(node, event);
      if (result == KeyEventResult.handled) break;
    }
    await _focusLanded();
  }

  void _hover(Offset position) => GestureBinding.instance.handlePointerEvent(
    PointerHoverEvent(
      position: position,
      device: 7,
      kind: PointerDeviceKind.mouse,
    ),
  );

  void _tap(Offset position) {
    GestureBinding.instance
      ..handlePointerEvent(
        PointerDownEvent(
          position: position,
          pointer: 70,
          kind: PointerDeviceKind.touch,
        ),
      )
      ..handlePointerEvent(
        PointerUpEvent(
          position: position,
          pointer: 70,
          kind: PointerDeviceKind.touch,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final sort = _sort;
    final rows = [..._rows];
    if (sort != null) {
      int cmp(Product a, Product b) => sort.key == 'price'
          ? a.price.compareTo(b.price)
          : a.name.compareTo(b.name);
      rows.sort((a, b) => sort.ascending ? cmp(a, b) : cmp(b, a));
    }
    return KeyboardHighlight(
      child: CollectionTable<Product>(
        rows: widget.pin == _Pin.hoverStripe || widget.pin == _Pin.hoverSelected
            ? _rows
            : rows,
        rowKey: (p) => p.id,
        striped: widget.pin == _Pin.hoverStripe,
        selected: _selected,
        onSelectionChanged: (s) => setState(() => _selected = s),
        sort: sort,
        onSort: (key, ascending) =>
            setState(() => _sort = TableSort(key, ascending: ascending)),
        onClearSort: () => setState(() => _sort = null),
        columnWidths: _widths,
        onColumnResize: (key, width) => setState(() => _widths[key] = width),
        onHideColumn: (_) {},
        columns: [
          TableColumn(
            id: 'name',
            label: 'Name',
            flex: 2,
            minWidth: 200,
            pinned: true,
            sortKey: 'name',
            cell: (p) => TableIdentity(
              leading: TableThumb(color: p.swatch),
              title: _renamed[p.id] ?? p.name,
              subtitle: p.sku,
            ),
            editBuilder: (p, session) => TableTextEditor(
              session: session,
              value: _renamed[p.id] ?? p.name,
              onCommit: (v) => setState(() => _renamed[p.id] = v),
            ),
          ),
          TableColumn(
            id: 'category',
            label: 'Category',
            fixed: 150,
            cellBuilder: (context, p) =>
                Text(p.category, style: tableMutedStyle(context)),
          ),
          TableColumn(
            id: 'status',
            label: 'Status',
            fixed: 150,
            cell: (p) => Tag(p.status, severity: p.tone, dot: true),
          ),
          TableColumn(
            id: 'price',
            label: 'Price',
            fixed: 110,
            numeric: true,
            sortKey: 'price',
            cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
          ),
          TableColumn(
            id: 'stock',
            label: 'Stock',
            fixed: 90,
            numeric: true,
            cellBuilder: (context, p) => Text(
              p.stock?.toString() ?? '—',
              style: tableMutedStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
