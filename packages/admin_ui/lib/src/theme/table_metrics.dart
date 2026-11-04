import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// How tightly a table packs its rows; see [AdminTableMetrics.rowHeight].
enum TableDensity { compact, standard, comfortable }

/// The text a table's column headers are set in. The table resolves it
/// against `context.type`.
enum TableHeaderText {
  /// The kit's own header: `caption` at semibold — small, quiet, and
  /// visibly apart from the body.
  caption,

  /// Body size at the theme's strong weight (`bodyStrong`): shadcn, Material,
  /// Ant and Carbon set their headers as a label the size of the cells.
  label,
}

/// Data-table geometry for the admin UI: the row height at each
/// [TableDensity], the header, the cell insets and the fixed columns and
/// affordances a table draws. Provided via [AdminTokens]; read through
/// `context.tableMetrics`.
///
/// Each theme picks the sizes its design system ships, on the 4px grid; a
/// standard row leaves room for a medium control and its breathing space, so
/// an inline select or button never crowds the row rules.
@immutable
class AdminTableMetrics {
  /// A row at [TableDensity.compact].
  final double rowCompact;

  /// A row at [TableDensity.standard], the default.
  final double rowStandard;

  /// A row at [TableDensity.comfortable].
  final double rowComfortable;

  /// The header row, at every density.
  final double headerHeight;

  /// Horizontal inset of a cell's content from its column's edges, header
  /// included.
  final double cellPaddingX;

  /// The width of the checkbox column a selectable table leads with.
  final double selectionColumnWidth;

  /// The hit strip a resizable column's boundary answers to, centred on the
  /// boundary.
  final double resizeHandleWidth;

  /// The sort arrow beside a sortable header's label.
  final double sortIconSize;

  /// Between a header's label and its sort arrow.
  final double sortIconGap;

  /// The style the column headers are set in.
  final TableHeaderText headerText;

  const AdminTableMetrics({
    required this.rowCompact,
    required this.rowStandard,
    required this.rowComfortable,
    required this.headerHeight,
    required this.cellPaddingX,
    required this.selectionColumnWidth,
    this.resizeHandleWidth = 8,
    this.sortIconSize = 16,
    this.sortIconGap = 4,
    this.headerText = TableHeaderText.label,
  });

  /// The row height at [density].
  double rowHeight(TableDensity density) => switch (density) {
    TableDensity.compact => rowCompact,
    TableDensity.standard => rowStandard,
    TableDensity.comfortable => rowComfortable,
  };

  AdminTableMetrics copyWith({
    double? rowCompact,
    double? rowStandard,
    double? rowComfortable,
    double? headerHeight,
    double? cellPaddingX,
    double? selectionColumnWidth,
    double? resizeHandleWidth,
    double? sortIconSize,
    double? sortIconGap,
    TableHeaderText? headerText,
  }) {
    return AdminTableMetrics(
      rowCompact: rowCompact ?? this.rowCompact,
      rowStandard: rowStandard ?? this.rowStandard,
      rowComfortable: rowComfortable ?? this.rowComfortable,
      headerHeight: headerHeight ?? this.headerHeight,
      cellPaddingX: cellPaddingX ?? this.cellPaddingX,
      selectionColumnWidth: selectionColumnWidth ?? this.selectionColumnWidth,
      resizeHandleWidth: resizeHandleWidth ?? this.resizeHandleWidth,
      sortIconSize: sortIconSize ?? this.sortIconSize,
      sortIconGap: sortIconGap ?? this.sortIconGap,
      headerText: headerText ?? this.headerText,
    );
  }

  static AdminTableMetrics lerp(
    AdminTableMetrics a,
    AdminTableMetrics b,
    double t,
  ) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminTableMetrics(
      rowCompact: d(a.rowCompact, b.rowCompact),
      rowStandard: d(a.rowStandard, b.rowStandard),
      rowComfortable: d(a.rowComfortable, b.rowComfortable),
      headerHeight: d(a.headerHeight, b.headerHeight),
      cellPaddingX: d(a.cellPaddingX, b.cellPaddingX),
      selectionColumnWidth: d(a.selectionColumnWidth, b.selectionColumnWidth),
      resizeHandleWidth: d(a.resizeHandleWidth, b.resizeHandleWidth),
      sortIconSize: d(a.sortIconSize, b.sortIconSize),
      sortIconGap: d(a.sortIconGap, b.sortIconGap),
      headerText: t < 0.5 ? a.headerText : b.headerText,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminTableMetrics &&
      other.rowCompact == rowCompact &&
      other.rowStandard == rowStandard &&
      other.rowComfortable == rowComfortable &&
      other.headerHeight == headerHeight &&
      other.cellPaddingX == cellPaddingX &&
      other.selectionColumnWidth == selectionColumnWidth &&
      other.resizeHandleWidth == resizeHandleWidth &&
      other.sortIconSize == sortIconSize &&
      other.sortIconGap == sortIconGap &&
      other.headerText == headerText;

  @override
  int get hashCode => Object.hash(
    rowCompact,
    rowStandard,
    rowComfortable,
    headerHeight,
    cellPaddingX,
    selectionColumnWidth,
    resizeHandleWidth,
    sortIconSize,
    sortIconGap,
    headerText,
  );

  @override
  String toString() =>
      'AdminTableMetrics(rows $rowCompact/$rowStandard/$rowComfortable, '
      'header $headerHeight ${headerText.name}, padding $cellPaddingX, '
      'selection $selectionColumnWidth, resize $resizeHandleWidth, '
      'sort $sortIconSize + $sortIconGap)';
}

/// The kit's own table (Iris): rows 40 / 52 / 64 under a 44 header set in
/// the caption style.
const defaultTableMetrics = AdminTableMetrics(
  rowCompact: 40,
  rowStandard: 52,
  rowComfortable: 64,
  headerHeight: 44,
  cellPaddingX: 12,
  selectionColumnWidth: 44,
  headerText: TableHeaderText.caption,
);
