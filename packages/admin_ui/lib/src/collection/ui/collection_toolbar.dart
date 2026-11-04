/// @docImport 'bulk_action_bar.dart';
/// @docImport 'filter_bar.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/search_field.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// The standard collection header: an optional [leading] (title / count), a
/// search field, the [filterBar], and a right cluster of [trailing] actions
/// (view toggle, column chooser, "New …").
///
/// Pure composition — no controller. Every run is the theme's medium control
/// height, so a search field, filter pills and medium buttons share one line,
/// and a one-line toolbar is [heightOf] tall — the height a [BulkActionBar]
/// takes when it swaps in. The search box flexes between [searchMinWidth] and
/// [searchMaxWidth]: it gives up width to keep the filters beside it, and when
/// they still don't fit they wrap onto the lines below. [trailing] stays at
/// the end of the first line, and the lines under it run the full width.
/// Pass [searchController] (typically
/// `CollectionController.searchController`) so the box stays in sync with the
/// query across rebuilds and route changes; the legacy [searchValue]/[onSearch]
/// pair still works for callers without a controller. Pass the existing
/// [FilterBar] as [filterBar] in the Screen.
class CollectionToolbar extends StatelessWidget {
  final Widget? leading;

  /// The durable search binding — preferred over [searchValue]/[onSearch].
  final TextEditingController? searchController;
  final String? searchValue;
  final ValueChanged<String>? onSearch;

  /// The search box's placeholder; Material's "Search" by default.
  final String? searchHint;

  /// A fixed search width instead of the flexing one.
  final double? searchWidth;

  /// The narrowest the search box gets before the filters wrap under it.
  final double searchMinWidth;

  /// The widest the search box grows.
  final double searchMaxWidth;

  /// Slot for a [FilterBar] (itself a wrap of filter pills).
  final Widget? filterBar;

  /// Right-aligned actions, gap-separated, level with the first line.
  final List<Widget> trailing;

  const CollectionToolbar({
    super.key,
    this.leading,
    this.searchController,
    this.searchValue,
    this.onSearch,
    this.searchHint,
    this.searchWidth,
    this.searchMinWidth = 200,
    this.searchMaxWidth = 320,
    this.filterBar,
    this.trailing = const [],
  });

  /// The height of a one-line toolbar and of the [BulkActionBar] that takes
  /// its place: the theme's medium control height and an inset above and
  /// below, taller by as much as a button's label, or the bar's count, grows
  /// at a large text size.
  static double heightOf(BuildContext context) =>
      context.sizes.medium +
      math.max(
        textGrowthOf(context, context.type.button),
        textGrowthOf(context, context.type.bodyStrong),
      ) +
      2 * _inset;

  static const _inset = AdminSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final line = context.sizes.medium;
    final hasSearch = searchController != null || onSearch != null;
    final searchHint =
        this.searchHint ?? MaterialLocalizations.of(context).searchFieldLabel;
    final left = <Widget>[
      ?leading,
      if (hasSearch)
        searchController != null
            ? SearchField(controller: searchController, hint: searchHint)
            : SearchField(
                value: searchValue ?? '',
                hint: searchHint,
                onChanged: onSearch,
              ),
      ?filterBar,
    ];
    final fixed = searchWidth;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _inset),
      child: _ToolbarFlow(
        flexIndex: hasSearch ? (leading == null ? 0 : 1) : -1,
        flexMin: fixed ?? searchMinWidth,
        flexMax: fixed ?? searchMaxWidth,
        spacing: AdminSpacing.sm,
        runSpacing: AdminSpacing.sm,
        lineHeight: line,
        hasTrailing: trailing.isNotEmpty,
        trailingGap: AdminSpacing.md,
        textDirection: Directionality.of(context),
        children: [
          ...left,
          if (trailing.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, w) in trailing.indexed) ...[
                  if (i > 0) const Gap(AdminSpacing.sm),
                  w,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// A wrap whose child at [flexIndex] takes a width between [flexMin] and
/// [flexMax] instead of its own: as much as it can while leaving the next
/// child room beside it, or the whole of its line (up to [flexMax]) when the
/// next one has to wrap anyway. Each line is at least [lineHeight] tall, with
/// its children centred on it.
///
/// With [hasTrailing], the last child sits at the end of the first line,
/// [trailingGap] clear of the rest: only the first line gives up its width,
/// and every line after it runs the full width.
class _ToolbarFlow extends MultiChildRenderObjectWidget {
  final int flexIndex;
  final double flexMin;
  final double flexMax;
  final double spacing;
  final double runSpacing;
  final double lineHeight;
  final bool hasTrailing;
  final double trailingGap;
  final TextDirection textDirection;

  const _ToolbarFlow({
    required this.flexIndex,
    required this.flexMin,
    required this.flexMax,
    required this.spacing,
    required this.runSpacing,
    required this.lineHeight,
    required this.hasTrailing,
    required this.trailingGap,
    required this.textDirection,
    required super.children,
  });

  @override
  _RenderToolbarFlow createRenderObject(BuildContext context) =>
      _RenderToolbarFlow(textDirection)
        ..flexIndex = flexIndex
        ..flexMin = flexMin
        ..flexMax = flexMax
        ..spacing = spacing
        ..runSpacing = runSpacing
        ..lineHeight = lineHeight
        ..hasTrailing = hasTrailing
        ..trailingGap = trailingGap;

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderToolbarFlow renderObject,
  ) {
    renderObject
      ..flexIndex = flexIndex
      ..flexMin = flexMin
      ..flexMax = flexMax
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..lineHeight = lineHeight
      ..hasTrailing = hasTrailing
      ..trailingGap = trailingGap
      ..textDirection = textDirection;
  }
}

class _FlowParentData extends ContainerBoxParentData<RenderBox> {}

/// Where [_RenderToolbarFlow] puts its children: a size and a start-edge
/// offset each, and its own size.
typedef _Placement = ({List<Size> sizes, List<Offset> offsets, Size size});

class _RenderToolbarFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FlowParentData> {
  _RenderToolbarFlow(this._textDirection);

  int _flexIndex = -1;
  set flexIndex(int value) {
    if (value == _flexIndex) return;
    _flexIndex = value;
    markNeedsLayout();
  }

  double _flexMin = 0;
  set flexMin(double value) {
    if (value == _flexMin) return;
    _flexMin = value;
    markNeedsLayout();
  }

  double _flexMax = 0;
  set flexMax(double value) {
    if (value == _flexMax) return;
    _flexMax = value;
    markNeedsLayout();
  }

  double _spacing = 0;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing = 0;
  set runSpacing(double value) {
    if (value == _runSpacing) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  double _lineHeight = 0;
  set lineHeight(double value) {
    if (value == _lineHeight) return;
    _lineHeight = value;
    markNeedsLayout();
  }

  bool _hasTrailing = false;
  set hasTrailing(bool value) {
    if (value == _hasTrailing) return;
    _hasTrailing = value;
    markNeedsLayout();
  }

  double _trailingGap = 0;
  set trailingGap(double value) {
    if (value == _trailingGap) return;
    _trailingGap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FlowParentData) {
      child.parentData = _FlowParentData();
    }
  }

  List<RenderBox> get _children {
    final result = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      result.add(child);
      child = childAfter(child);
    }
    return result;
  }

  _Placement _place(BoxConstraints constraints, ChildLayouter layoutChild) {
    final children = _children;
    final maxWidth = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: maxWidth);
    final trailing = _hasTrailing && children.isNotEmpty;
    final count = trailing ? children.length - 1 : children.length;
    final sizes = [
      for (final (i, child) in children.indexed)
        i == _flexIndex && i < count ? Size.zero : layoutChild(child, loose),
    ];
    // The first line gives up the trailing cluster's width; the rest don't.
    final reserve = trailing ? sizes.last.width + _trailingGap : 0.0;

    final offsets = List<Offset>.filled(children.length, Offset.zero);
    final runs = <(int, int, double)>[]; // first, end, height
    var runStart = 0;
    var x = 0.0;
    var widest = 0.0;
    var firstLineWidth = 0.0;
    double limit() =>
        runs.isEmpty ? math.max(0.0, maxWidth - reserve) : maxWidth;
    void closeRun(int end) {
      var height = _lineHeight;
      if (runs.isEmpty && trailing) {
        height = math.max(height, sizes.last.height);
        firstLineWidth = x;
      }
      for (var j = runStart; j < end; j++) {
        height = math.max(height, sizes[j].height);
      }
      runs.add((runStart, end, height));
      widest = math.max(widest, x);
      runStart = end;
      x = 0;
    }

    for (var i = 0; i < count; i++) {
      var first = i == runStart;
      if (i == _flexIndex) {
        var room = limit() - (first ? 0 : x + _spacing);
        final next = i + 1 < count ? sizes[i + 1].width : null;
        final double width;
        if (room >= _flexMin) {
          final beside = next == null ? room : room - _spacing - next;
          width = math.min(_flexMax, beside >= _flexMin ? beside : room);
        } else {
          // Onto a line of its own — below the trailing cluster when even
          // the first line is too short for it.
          if (!first || (runs.isEmpty && reserve > 0)) closeRun(i);
          first = true;
          room = limit();
          width = math.min(_flexMax, room);
        }
        sizes[i] = layoutChild(
          children[i],
          BoxConstraints.tightFor(width: width),
        );
      }
      final w = sizes[i].width;
      if (x + (first ? 0 : _spacing) + w > limit() + precisionErrorTolerance &&
          (!first || (runs.isEmpty && reserve > 0 && w <= maxWidth))) {
        closeRun(i);
        first = true;
      }
      final start = first ? 0.0 : x + _spacing;
      offsets[i] = Offset(start, 0);
      x = start + w;
    }
    if (count > 0 || trailing) closeRun(count);

    var y = 0.0;
    for (final (i, (first, end, height)) in runs.indexed) {
      if (i > 0) y += _runSpacing;
      for (var j = first; j < end; j++) {
        offsets[j] = Offset(offsets[j].dx, y + (height - sizes[j].height) / 2);
      }
      y += height;
    }
    final width = constraints.hasBoundedWidth
        ? maxWidth
        : math.max(widest, firstLineWidth + reserve);
    if (trailing) {
      final size = sizes.last;
      offsets.last = Offset(width - size.width, (runs[0].$3 - size.height) / 2);
    }
    return (
      sizes: sizes,
      offsets: offsets,
      size: constraints.constrain(Size(width, y)),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _place(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final placement = _place(constraints, ChildLayoutHelper.layoutChild);
    size = placement.size;
    final rtl = _textDirection == TextDirection.rtl;
    for (final (i, child) in _children.indexed) {
      final at = placement.offsets[i];
      (child.parentData! as _FlowParentData).offset = Offset(
        rtl ? size.width - at.dx - placement.sizes[i].width : at.dx,
        at.dy,
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var width = 0.0;
    for (final (i, child) in _children.indexed) {
      width = math.max(
        width,
        i == _flexIndex ? _flexMin : child.getMinIntrinsicWidth(height),
      );
    }
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = _children;
    final count = _hasTrailing ? children.length - 1 : children.length;
    var width = 0.0;
    for (final (i, child) in children.indexed) {
      if (i > 0) width += i < count ? _spacing : _trailingGap;
      width += i == _flexIndex && i < count
          ? _flexMax
          : child.getMaxIntrinsicWidth(height);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
