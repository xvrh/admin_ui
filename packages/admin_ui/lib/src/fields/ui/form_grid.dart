/// @docImport 'field_group.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_feedback_scope.dart';
import '../../theme/spacing.dart';

/// How many columns a [FormGrid] lays out at each width class of its own
/// container: [compact], [medium] and [expanded], a null one taking the
/// narrower class's.
@immutable
class FormColumns {
  final int compact;
  final int? medium;
  final int? expanded;

  const FormColumns({this.compact = 1, this.medium, this.expanded})
    : assert(compact >= 1),
      assert(medium == null || medium >= 1),
      assert(expanded == null || expanded >= 1);

  /// [n] columns at every width.
  const FormColumns.fixed(int n)
    : assert(n >= 1),
      compact = n,
      medium = n,
      expanded = n;

  /// The column count for a container [width] wide; see
  /// [FormGrid.compactMaxWidth] and [FormGrid.mediumMaxWidth].
  int resolve(double width) {
    final medium = this.medium ?? compact;
    if (width < FormGrid.compactMaxWidth) return compact;
    if (width < FormGrid.mediumMaxWidth) return medium;
    return expanded ?? medium;
  }

  @override
  bool operator ==(Object other) =>
      other is FormColumns &&
      other.compact == compact &&
      other.medium == medium &&
      other.expanded == expanded;

  @override
  int get hashCode => Object.hash(compact, medium, expanded);

  @override
  String toString() => 'FormColumns($compact, $medium, $expanded)';
}

/// Lays form fields out on a grid whose column count follows its own width
/// ([columns]); a [FormGridItem] spans several columns or the whole row.
///
/// The width class is the grid's, not the window's, so a grid in a dialog
/// or a side sheet stacks its fields the way it would on a phone.
///
/// Children fill the rows in order, each row as tall as its tallest child,
/// and every child sits at the top of its row, so the label rows of fields
/// side by side line up. The first column is on the reading side: the
/// right, right to left. A child that does not fit what is left of a row
/// starts the next one.
///
/// A child that lays out zero tall, as a field its rules hide does, takes
/// no column and no gap, so hiding one closes the space it held.
///
/// Under a form that keeps each field's message line
/// ([FieldFeedbackScope.reserveErrorLine]) the default row gap is
/// [AdminSpacing.lg] rather than [AdminSpacing.xl]: the space between a field
/// and its line comes out of it, so the fields keep one rhythm whether the
/// line shows a message or not.
///
/// The grid draws nothing of its own and never clips, so each field keeps
/// its theme's anatomy, a focus halo that spills past the field included.
class FormGrid extends StatelessWidget {
  /// Below this width the grid is compact, as a phone-sized window is in
  /// Material 3's window size classes.
  static const compactMaxWidth = 600.0;

  /// Below this width, and at least [compactMaxWidth], the grid is medium,
  /// as a tablet-sized window is in Material 3's window size classes; at
  /// this width and above it is expanded.
  static const mediumMaxWidth = 840.0;

  final List<Widget> children;
  final FormColumns columns;

  /// The gap between columns; [AdminSpacing.xl] when null, as between rows.
  final double? columnGap;

  /// The gap between rows; [AdminSpacing.xl] when null, or
  /// [AdminSpacing.lg] under a form that keeps each field's message line.
  final double? rowGap;

  const FormGrid({
    super.key,
    required this.children,
    this.columns = const FormColumns(compact: 1, medium: 2),
    this.columnGap,
    this.rowGap,
  }) : assert(columnGap == null || columnGap >= 0),
       assert(rowGap == null || rowGap >= 0);

  @override
  Widget build(BuildContext context) => _FormGridLayout(
    columns: columns,
    columnGap: columnGap ?? AdminSpacing.xl,
    rowGap:
        rowGap ??
        (FieldFeedbackScope.reserveErrorLineOf(context)
            ? AdminSpacing.lg
            : AdminSpacing.xl),
    textDirection: Directionality.of(context),
    children: [
      for (final child in children)
        _FormGridSlot(
          // A keyed child keeps its state when the children are reordered.
          key: switch (child.key) {
            final key? => ValueKey<Key>(key),
            null => null,
          },
          span: child is FormGridItem ? child.span : 1,
          fullWidth: child is FormGridItem && child.fullWidth,
          child: child,
        ),
    ],
  );
}

/// A [FormGrid] child that spans [span] columns, or the whole row when
/// [fullWidth]. A span wider than the grid's columns at its width takes
/// them all.
///
/// Give it to the grid directly, as one of its children: anywhere else it
/// is just its [child].
class FormGridItem extends StatelessWidget {
  final int span;
  final bool fullWidth;
  final Widget child;

  const FormGridItem({
    super.key,
    this.span = 1,
    this.fullWidth = false,
    required this.child,
  }) : assert(span >= 1);

  @override
  Widget build(BuildContext context) => child;
}

class _FormGridParentData extends ContainerBoxParentData<RenderBox> {
  int span = 1;
  bool fullWidth = false;
}

class _FormGridSlot extends ParentDataWidget<_FormGridParentData> {
  final int span;
  final bool fullWidth;

  const _FormGridSlot({
    super.key,
    required this.span,
    required this.fullWidth,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _FormGridParentData;
    if (data.span == span && data.fullWidth == fullWidth) return;
    data
      ..span = span
      ..fullWidth = fullWidth;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FormGrid;
}

class _FormGridLayout extends MultiChildRenderObjectWidget {
  final FormColumns columns;
  final double columnGap;
  final double rowGap;
  final TextDirection textDirection;

  const _FormGridLayout({
    required this.columns,
    required this.columnGap,
    required this.rowGap,
    required this.textDirection,
    super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFormGrid(
    columns: columns,
    columnGap: columnGap,
    rowGap: rowGap,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderFormGrid renderObject) {
    renderObject
      ..columns = columns
      ..columnGap = columnGap
      ..rowGap = rowGap
      ..textDirection = textDirection;
  }
}

/// A child's height at a width: laid out, dry or intrinsic.
typedef _Measure = double Function(RenderBox child, double width);

class _RenderFormGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FormGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FormGridParentData> {
  _RenderFormGrid({
    required this._columns,
    required this._columnGap,
    required this._rowGap,
    required this._textDirection,
  });

  FormColumns get columns => _columns;
  FormColumns _columns;
  set columns(FormColumns value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double get columnGap => _columnGap;
  double _columnGap;
  set columnGap(double value) {
    if (value == _columnGap) return;
    _columnGap = value;
    markNeedsLayout();
  }

  double get rowGap => _rowGap;
  double _rowGap;
  set rowGap(double value) {
    if (value == _rowGap) return;
    _rowGap = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FormGridParentData) {
      child.parentData = _FormGridParentData();
    }
  }

  int _spanOf(RenderBox child, int count) {
    final data = child.parentData! as _FormGridParentData;
    return data.fullWidth ? count : math.min(data.span, count);
  }

  /// Flows the children into rows across [width], measuring each with
  /// [measure] at the width its columns give it, hands each to [place] with
  /// its offset, and returns the height the rows take. A child measured
  /// zero tall takes no column and no gap.
  ///
  /// Column edges are rounded to whole pixels, so a field's border lands on
  /// one rather than blurring across two; a column or a gap may be a pixel
  /// off the others to make up the difference.
  double _flow(
    double width,
    _Measure measure, {
    void Function(RenderBox child, Offset offset)? place,
  }) {
    final count = columns.resolve(width);
    final column = math.max(0.0, (width - columnGap * (count - 1)) / count);
    final pitch = column + columnGap;
    double startOf(int c) => c == 0 ? 0 : (c * pitch).roundToDouble();
    double endOf(int c) =>
        c == count - 1 ? width : (c * pitch + column).roundToDouble();
    final rtl = textDirection == TextDirection.rtl;
    double? rowTop;
    var rowHeight = 0.0;
    var used = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final span = _spanOf(child, count);
      final first = used + span > count ? 0 : used;
      final start = startOf(first);
      final end = math.max(start, endOf(first + span - 1));
      final x = rtl ? width - end : start;
      final height = measure(child, end - start);
      if (height <= 0) {
        place?.call(child, Offset(x, (rowTop ?? 0) + rowHeight));
        continue;
      }
      if (rowTop == null) {
        rowTop = 0;
      } else if (first == 0) {
        rowTop += rowHeight + rowGap;
        rowHeight = 0;
      }
      place?.call(child, Offset(x, rowTop));
      used = first + span;
      rowHeight = math.max(rowHeight, height);
    }
    return rowTop == null ? 0 : rowTop + rowHeight;
  }

  /// The width [FormColumns.compact] columns take when each is as wide as
  /// the widest [childWidth] asks, per column it spans.
  double _intrinsicWidth(double Function(RenderBox child) childWidth) {
    final count = columns.compact;
    double? column;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final span = _spanOf(child, count);
      final perColumn = (childWidth(child) - columnGap * (span - 1)) / span;
      column = math.max(column ?? 0, perColumn);
    }
    if (column == null) return 0;
    return column * count + columnGap * (count - 1);
  }

  /// The constraints' width, or the children's widest when it is unbounded.
  double _widthFor(BoxConstraints constraints) {
    if (constraints.hasBoundedWidth) return constraints.maxWidth;
    return constraints.constrainWidth(
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(double.infinity)),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _flow(width, (child, width) => child.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _flow(width, (child, width) => child.getMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = _widthFor(constraints);
    final height = _flow(
      width,
      (child, width) => ChildLayoutHelper.dryLayoutChild(
        child,
        BoxConstraints.tightFor(width: width),
      ).height,
    );
    return constraints.constrain(Size(width, height));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    double? result;
    _flow(_widthFor(constraints), (child, width) {
      final childConstraints = BoxConstraints.tightFor(width: width);
      final height = child.getDryLayout(childConstraints).height;
      // The first child that takes room starts the first row, at the top.
      if (result == null && height > 0) {
        result = child.getDryBaseline(childConstraints, baseline);
      }
      return height;
    });
    return result;
  }

  @override
  void performLayout() {
    final width = _widthFor(constraints);
    final height = _flow(
      width,
      (child, width) => ChildLayoutHelper.layoutChild(
        child,
        BoxConstraints.tightFor(width: width),
      ).height,
      place: (child, offset) =>
          (child.parentData! as _FormGridParentData).offset = offset,
    );
    size = constraints.constrain(Size(width, height));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FormColumns>('columns', columns))
      ..add(DoubleProperty('columnGap', columnGap))
      ..add(DoubleProperty('rowGap', rowGap))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection));
  }
}
