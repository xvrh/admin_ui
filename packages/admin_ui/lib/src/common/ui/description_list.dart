/// @docImport 'avatar.dart';
/// @docImport 'tag.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';

/// One label → value pair in a [DescriptionList]. Supply a plain [value] string
/// or an arbitrary [child] (a [Tag], an [Avatar] row, a link…). An empty value
/// renders the [DescriptionList.emptyText] dash.
class DescriptionItem {
  final String label;
  final String? value;
  final Widget? child;

  /// Take the full width of the list, ignoring the column count — for long text,
  /// a block of prose, or a wide embedded widget.
  final bool span;

  /// Let [child] stretch across the whole value slot instead of hugging its
  /// content — for a progress bar, a slider, an input.
  ///
  /// Off by default because the slot is as wide as its column, so a box-shaped
  /// child (a [Tag], a button) otherwise stretches across it while text does
  /// not. Independent of [span], which widens the slot itself.
  final bool fill;

  const DescriptionItem(
    this.label, {
    this.value,
    this.child,
    this.span = false,
    this.fill = false,
  }) : assert(value == null || child == null, 'Pass value or child, not both'),
       assert(!fill || child != null, 'fill only affects a child');
}

enum DescriptionLayout {
  /// Label on the left in a column sized to the labels, value to its right.
  /// The classic definition-list / record-detail look.
  inline,

  /// Muted label stacked above its value. Reads better in narrow columns and in
  /// multi-column grids.
  stacked,
}

/// A read-only record display: a list of label → value pairs. The "show" side of
/// a CRUD entity, the counterpart to the editable field stack.
///
/// Pack several pairs per row with [columns]; mark a wide one [DescriptionItem.span]
/// to break it onto its own full-width row. A grid drops columns as it narrows,
/// so no cell gets thinner than [minCellWidth].
class DescriptionList extends StatelessWidget {
  final List<DescriptionItem> items;

  /// Pairs per row, at most. 1 is a single stacked column of rows; 2+ packs
  /// pairs into a grid, with fewer columns where [minCellWidth] doesn't fit.
  final int columns;

  final DescriptionLayout layout;

  /// Width of the label column in [DescriptionLayout.inline]. Null sizes it to
  /// the widest label, capped at 160 and at 40% of a grid cell, and shared by
  /// every row and column so the values line up. Ignored when stacked.
  final double? labelWidth;

  /// The narrowest a grid cell gets before the grid drops a column: 240 for
  /// [DescriptionLayout.inline], 120 for [DescriptionLayout.stacked] when
  /// null.
  final double? minCellWidth;

  /// Hairline between rows. On by default for single-column inline lists, off for
  /// grids (where it tends to fight the column gutters).
  final bool? divided;

  /// Shown for an item whose value is null or blank; a dash, '—', unless
  /// set.
  final String emptyText;

  const DescriptionList({
    super.key,
    required this.items,
    this.columns = 1,
    this.layout = DescriptionLayout.inline,
    this.labelWidth,
    this.minCellWidth,
    this.divided,
    this.emptyText = '—',
  }) : assert(columns >= 1);

  static const _maxLabelWidth = 160.0;
  static const _gutter = AdminSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) return _list(context, columns: 1, cellWidth: null);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final minCell =
            minCellWidth ??
            (layout == DescriptionLayout.inline ? 240.0 : 120.0);
        final fit = width.isFinite
            ? ((width + _gutter) / (minCell + _gutter)).floor()
            : columns;
        final count = fit.clamp(1, columns);
        final cellWidth = width.isFinite
            ? (width - _gutter * (count - 1)) / count
            : null;
        return _list(context, columns: count, cellWidth: cellWidth);
      },
    );
  }

  Widget _list(
    BuildContext context, {
    required int columns,
    required double? cellWidth,
  }) {
    final rows = _rows(columns);
    final showDividers = divided ?? (this.columns == 1);
    final labelStyle = context.type
        .weighted(context.type.caption, FontWeight.w600)
        .copyWith(color: context.colors.foregroundMuted);
    final labelColumn = layout == DescriptionLayout.inline
        ? _labelColumn(context, labelStyle, cellWidth)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            showDividers
                ? Divider(height: 1, thickness: 1, color: context.colors.border)
                : const Gap(AdminSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: showDividers ? AdminSpacing.lg : 0,
            ),
            child: _Row(
              items: rows[i],
              columns: columns,
              layout: layout,
              labelStyle: labelStyle,
              labelWidth: labelColumn,
              emptyText: emptyText,
            ),
          ),
        ],
      ],
    );
  }

  /// [labelWidth], or the widest label measured in [style], within 160 and
  /// 40% of a grid cell.
  double _labelColumn(
    BuildContext context,
    TextStyle style,
    double? cellWidth,
  ) {
    if (labelWidth != null) return labelWidth!;
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    var widest = 0.0;
    for (final item in items) {
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: resolved),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    var cap = _maxLabelWidth;
    if (cellWidth != null) {
      cap = math.min(cap, (cellWidth * 0.4).floorToDouble());
    }
    return math.min(widest.ceilToDouble(), cap);
  }

  /// Groups items into rows, honouring [columns] and breaking out
  /// [DescriptionItem.span] items onto their own row.
  List<List<DescriptionItem>> _rows(int columns) {
    final rows = <List<DescriptionItem>>[];
    var current = <DescriptionItem>[];
    void flush() {
      if (current.isNotEmpty) {
        rows.add(current);
        current = [];
      }
    }

    for (final item in items) {
      if (item.span || columns == 1) {
        flush();
        rows.add([item]);
        continue;
      }
      current.add(item);
      if (current.length == columns) flush();
    }
    flush();
    return rows;
  }
}

class _Row extends StatelessWidget {
  final List<DescriptionItem> items;
  final int columns;
  final DescriptionLayout layout;
  final TextStyle labelStyle;
  final double labelWidth;
  final String emptyText;

  const _Row({
    required this.items,
    required this.columns,
    required this.layout,
    required this.labelStyle,
    required this.labelWidth,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    // A span item, or a single-column list, fills the row on its own.
    final full = items.length == 1 && (items.first.span || columns == 1);
    if (full) return _cell(items.first);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) const Gap(DescriptionList._gutter),
          Expanded(
            child: c < items.length ? _cell(items[c]) : const SizedBox(),
          ),
        ],
      ],
    );
  }

  Widget _cell(DescriptionItem item) => _Cell(
    item: item,
    layout: layout,
    labelStyle: labelStyle,
    labelWidth: labelWidth,
    emptyText: emptyText,
  );
}

class _Cell extends StatelessWidget {
  final DescriptionItem item;
  final DescriptionLayout layout;
  final TextStyle labelStyle;
  final double labelWidth;
  final String emptyText;

  const _Cell({
    required this.item,
    required this.layout,
    required this.labelStyle,
    required this.labelWidth,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(item.label, style: labelStyle);

    final blank =
        item.child == null && (item.value == null || item.value!.isEmpty);
    // A `child` inherits the value text style so a plain Text in it matches the
    // string-valued rows; it can still override.
    final value = item.child != null
        ? DefaultTextStyle.merge(
            style: context.type.body.copyWith(color: context.colors.foreground),
            child: item.child!,
          )
        : Text(
            blank ? emptyText : item.value!,
            style: context.type.body.copyWith(
              color: blank
                  ? context.colors.foregroundMuted
                  : context.colors.foreground,
            ),
          );

    // The slot is as wide as the column, so anything box-shaped fills it unless
    // told otherwise. `heightFactor: 1` keeps the row's height driven by the
    // child rather than by the tallest cell in the row.
    final slot = item.fill
        ? SizedBox(width: double.infinity, child: value)
        : Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: value,
          );

    return switch (layout) {
      DescriptionLayout.stacked => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [label, const Gap(AdminSpacing.xs), slot],
      ),
      DescriptionLayout.inline => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            // The label's line centred on the value's first line.
            child: Padding(
              padding: EdgeInsets.only(
                top: math.max(
                  0.0,
                  (lineHeightOf(context, context.type.body) -
                          lineHeightOf(context, labelStyle)) /
                      2,
                ),
              ),
              child: label,
            ),
          ),
          const Gap(AdminSpacing.lg),
          Expanded(child: slot),
        ],
      ),
    };
  }
}
