import 'dart:ui' show Color, FontWeight, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show TextStyle;

import 'palette.dart';
import 'typography.dart';

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

  /// Body size at the body's own weight: Fluent's header cells are regular.
  body,
}

/// What a table's header row is filled with; see
/// [AdminTableMetrics.headerFill].
enum TableHeaderFill {
  /// [AdminPalette.surfaceMuted], a quiet band: the kit's own, Material's,
  /// Ant's `headerBg`.
  muted,

  /// [AdminPalette.surface], as the rows are: shadcn's and Fluent's headers
  /// have no fill of their own.
  surface,

  /// [AdminPalette.border], the divider colour as a fill: Carbon's header is
  /// `$layer-accent`, the grey of its rules.
  strong,
}

/// What a table's column headers are written in; see
/// [AdminTableMetrics.headerInk].
enum TableHeaderInk {
  /// [AdminPalette.foregroundMuted], and [AdminPalette.foregroundSecondary]
  /// for the sorted column: the header is apart from the body.
  muted,

  /// [AdminPalette.foreground]: shadcn's `text-foreground`, Ant's
  /// `colorTextHeading`, Fluent's first neutral, Carbon's `$text-primary`.
  foreground,
}

/// The colour of a rule under a table's header or between its rows; see
/// [AdminTableMetrics.headerRule] and [AdminTableMetrics.rowRule].
enum TableRule {
  /// [AdminPalette.borderSubtle].
  subtle,

  /// [AdminPalette.border], a card's edge.
  border,
}

/// Data-table geometry and chrome for the admin UI: the row height at each
/// [TableDensity], the header and what it is filled and written with, the
/// rules, the cell insets and the fixed columns and affordances a table
/// draws. Provided via [AdminTokens]; read through `context.tableMetrics`.
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

  /// What the header row is filled with.
  final TableHeaderFill headerFill;

  /// What the column headers are written in.
  final TableHeaderInk headerInk;

  /// The rule under the header row.
  final TableRule headerRule;

  /// The rule under each body row.
  final TableRule rowRule;

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
    this.headerFill = TableHeaderFill.muted,
    this.headerInk = TableHeaderInk.muted,
    this.headerRule = TableRule.border,
    this.rowRule = TableRule.subtle,
  });

  /// The style of a column header in [type], before its colour: the caption
  /// at semibold, or the body at the strong or at its own weight.
  TextStyle headerStyleOf(AdminTypography type) => switch (headerText) {
    TableHeaderText.caption => type.weighted(type.caption, FontWeight.w600),
    TableHeaderText.label => type.bodyStrong,
    TableHeaderText.body => type.body,
  };

  /// The header row's fill in [colors].
  Color headerFillOf(AdminPalette colors) => switch (headerFill) {
    TableHeaderFill.muted => colors.surfaceMuted,
    TableHeaderFill.surface => colors.surface,
    TableHeaderFill.strong => colors.border,
  };

  /// A column header's ink in [colors], readable at 4.5:1 on
  /// [headerFillOf]: a muted ink is moved toward the foreground until it
  /// reads there. With [sorted], the sorted column's: a step stronger where
  /// the rest is muted.
  Color headerInkOf(AdminPalette colors, {bool sorted = false}) {
    final ink = switch (headerInk) {
      TableHeaderInk.muted =>
        sorted ? colors.foregroundSecondary : colors.foregroundMuted,
      TableHeaderInk.foreground => colors.foreground,
    };
    return colors.readableOn(ink, surfaces: [headerFillOf(colors)]);
  }

  /// The rule under the header row in [colors].
  Color headerRuleOf(AdminPalette colors) => _ruleOf(headerRule, colors);

  /// The rule under a body row in [colors].
  Color rowRuleOf(AdminPalette colors) => _ruleOf(rowRule, colors);

  static Color _ruleOf(TableRule rule, AdminPalette colors) => switch (rule) {
    TableRule.subtle => colors.borderSubtle,
    TableRule.border => colors.border,
  };

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
    TableHeaderFill? headerFill,
    TableHeaderInk? headerInk,
    TableRule? headerRule,
    TableRule? rowRule,
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
      headerFill: headerFill ?? this.headerFill,
      headerInk: headerInk ?? this.headerInk,
      headerRule: headerRule ?? this.headerRule,
      rowRule: rowRule ?? this.rowRule,
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
      headerFill: t < 0.5 ? a.headerFill : b.headerFill,
      headerInk: t < 0.5 ? a.headerInk : b.headerInk,
      headerRule: t < 0.5 ? a.headerRule : b.headerRule,
      rowRule: t < 0.5 ? a.rowRule : b.rowRule,
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
      other.headerText == headerText &&
      other.headerFill == headerFill &&
      other.headerInk == headerInk &&
      other.headerRule == headerRule &&
      other.rowRule == rowRule;

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
    headerFill,
    headerInk,
    headerRule,
    rowRule,
  );

  @override
  String toString() =>
      'AdminTableMetrics(rows $rowCompact/$rowStandard/$rowComfortable, '
      'header $headerHeight ${headerText.name} in ${headerInk.name} on '
      '${headerFill.name} over a ${headerRule.name} rule, '
      '${rowRule.name} row rules, padding $cellPaddingX, '
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
