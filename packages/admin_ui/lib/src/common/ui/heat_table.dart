import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/table_metrics.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';

/// A leading column of a [HeatTable]: its [header], and whether its cells
/// are figures ([numeric]), which sit at the end of the column in tabular
/// figures.
class HeatTableLabel {
  final String header;
  final bool numeric;

  const HeatTableLabel(this.header, {this.numeric = false});
}

/// A value of a [HeatTable]: its [share], 0 to 1 (of a cohort, still
/// active), which sets how strongly the cell is tinted, and the [text] it
/// shows, by default [share] as a percentage in the app's locale. A share
/// outside 0 to 1 is tinted as the nearer end.
class HeatTableCell {
  final double share;
  final String? text;

  const HeatTableCell(this.share, {this.text});
}

/// A row of a [HeatTable]: a text for each of its leading columns, and a
/// cell for each of its value columns. A null cell, or one past the end of
/// [cells], has no value (a week not reached yet) and is left blank.
class HeatTableRow {
  final List<String> labels;
  final List<HeatTableCell?> cells;

  const HeatTableRow(this.labels, this.cells);
}

/// A table of values tinted by their share, for cohort retention and other
/// matrices read by intensity: a header row over [rows], a few leading
/// [labels] columns ("Week of", "People"), then a column of values for each
/// of [columns] ("+1", "+2", …).
///
/// A value cell shows its text on [AdminPalette.heatFill] of its share in
/// [color], by default the theme's first chart colour, so the strongest
/// cell still holds its figure at 4.5:1 in every theme and mode. A cell
/// with no value is left blank, apart from a 0%, which is a faint wash.
///
/// The columns are as wide as their text, the value columns sharing the
/// width left over. Narrower than that, the value columns keep their width
/// and scroll sideways under the leading ones, which stay put when they
/// leave a value column room. The table is as tall as its rows, and
/// mirrors right to left.
class HeatTable extends StatefulWidget {
  final List<HeatTableLabel> labels;
  final List<String> columns;
  final List<HeatTableRow> rows;

  /// The hue of the tint; the theme's first chart colour when null.
  final Color? color;

  const HeatTable({
    super.key,
    this.labels = const [],
    required this.columns,
    required this.rows,
    this.color,
  });

  @override
  State<HeatTable> createState() => _HeatTableState();
}

class _HeatTableState extends State<HeatTable> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final metrics = context.tableMetrics;
    final formats = context.adminFormats;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final header = switch (metrics.headerText) {
      TableHeaderText.caption => type.weighted(type.caption, FontWeight.w600),
      TableHeaderText.label => type.bodyStrong,
    }.copyWith(color: colors.foregroundMuted);
    final body = type.body.copyWith(color: colors.foreground);
    final figures = body.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Bold text draws every label bold: measured so, the columns hold it.
    final bold = MediaQuery.boldTextOf(context);
    double widthOf(String text, TextStyle style) => textWidthOf(
      context,
      text,
      bold ? type.weighted(style, FontWeight.bold) : style,
    );

    String textOf(HeatTableCell cell) =>
        cell.text ?? formats.percent(cell.share);
    HeatTableCell? cellAt(HeatTableRow row, int column) =>
        column < row.cells.length ? row.cells[column] : null;

    final labels = widget.labels;
    final columns = widget.columns;
    final rows = widget.rows;
    final padX = metrics.cellPaddingX;
    final rowHeight = metrics.rowCompact + textGrowthOf(context, body);
    final headerHeight = metrics.rowCompact + textGrowthOf(context, header);

    final labelWidths = [
      for (final (i, label) in labels.indexed)
        2 * padX +
            rows.fold(
              widthOf(label.header, header),
              (w, row) => i < row.labels.length
                  ? math.max(
                      w,
                      widthOf(row.labels[i], label.numeric ? figures : body),
                    )
                  : w,
            ),
    ];
    final labelsWidth = labelWidths.fold(0.0, (sum, w) => sum + w);
    // Every value column as wide as the widest value or header, and never
    // narrower than a row is tall.
    var valueWidth = rowHeight;
    for (final (i, column) in columns.indexed) {
      valueWidth = math.max(valueWidth, 2 * padX + widthOf(column, header));
      for (final row in rows) {
        if (cellAt(row, i) case final cell?) {
          valueWidth = math.max(
            valueWidth,
            2 * padX + widthOf(textOf(cell), figures),
          );
        }
      }
    }

    final gap = AdminSpacing.xxs / 2;
    final radius = BorderRadius.circular(context.radii.radiusSmall / 2);
    Widget valueCell(HeatTableRow row, int column) {
      final cell = cellAt(row, column);
      if (cell == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.all(gap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.heatFill(cell.share, accent: widget.color),
            borderRadius: radius,
          ),
          child: Center(
            child: Text(
              textOf(cell),
              style: figures,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      );
    }

    Widget labelCell(String text, HeatTableLabel label, TextStyle style) =>
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padX),
          child: Align(
            alignment: label.numeric
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Text(text, style: style, maxLines: 1, softWrap: false),
          ),
        );

    TableViewCell cell(BuildContext context, TableVicinity v) {
      final Widget child;
      if (v.row == 0) {
        child = v.column < labels.length
            ? labelCell(labels[v.column].header, labels[v.column], header)
            : Center(
                child: Text(
                  columns[v.column - labels.length],
                  style: header,
                  maxLines: 1,
                  softWrap: false,
                ),
              );
      } else {
        final row = rows[v.row - 1];
        if (v.column < labels.length) {
          final label = labels[v.column];
          child = labelCell(
            v.column < row.labels.length ? row.labels[v.column] : '',
            label,
            label.numeric ? figures : body,
          );
        } else {
          child = valueCell(row, v.column - labels.length);
        }
      }
      return TableViewCell(child: child);
    }

    final height = headerHeight + rows.length * rowHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final needed = labelsWidth + columns.length * valueWidth;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : needed;
        final scrolls = available < needed;
        // Wide enough, the value columns share what the labels leave.
        final width = scrolls || columns.isEmpty
            ? valueWidth
            : (available - labelsWidth) / columns.length;
        // Pinned only while a value column still shows beside them.
        final pinned = labelsWidth + valueWidth <= available
            ? labels.length
            : 0;

        Widget table = TableView.builder(
          verticalDetails: const ScrollableDetails.vertical(
            physics: NeverScrollableScrollPhysics(),
          ),
          // Reversed right to left, so the labels sit on the right and the
          // values scroll in from the left.
          horizontalDetails: ScrollableDetails.horizontal(
            controller: _horizontal,
            reverse: rtl,
          ),
          pinnedRowCount: 1,
          pinnedColumnCount: pinned,
          columnCount: labels.length + columns.length,
          rowCount: rows.length + 1,
          columnBuilder: (i) => TableSpan(
            extent: FixedTableSpanExtent(
              i < labels.length ? labelWidths[i] : width,
            ),
            // While the values scroll, a rule where they pass under the
            // labels, so a value cut there is not read as the label's.
            foregroundDecoration: scrolls && i == pinned - 1
                ? TableSpanDecoration(
                    border: TableSpanBorder(
                      trailing: BorderSide(color: colors.border),
                    ),
                  )
                : null,
          ),
          rowBuilder: (i) => i == 0
              ? TableSpan(
                  extent: FixedTableSpanExtent(headerHeight),
                  backgroundDecoration: TableSpanDecoration(
                    border: TableSpanBorder(
                      trailing: BorderSide(color: colors.border),
                    ),
                  ),
                )
              : TableSpan(extent: FixedTableSpanExtent(rowHeight)),
          cellBuilder: cell,
        );
        if (scrolls) {
          // Shown while idle too, where a platform hides it, as the one
          // sign that more weeks lie to the side; in a strip of its own
          // under the last row, so it never covers a value.
          // Without the screen's insets, which would lift it off the strip
          // and into the rows over a phone's home indicator.
          table = MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeTop: true,
            removeRight: true,
            removeBottom: true,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
                child: table,
              ),
            ),
          );
        }
        return SizedBox(
          width: scrolls ? available : labelsWidth + columns.length * width,
          height: height + (scrolls ? AdminSpacing.lg : 0),
          child: table,
        );
      },
    );
  }
}
