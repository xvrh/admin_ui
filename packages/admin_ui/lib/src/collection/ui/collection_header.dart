import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../collection_controller.dart';
import 'bulk_action_bar.dart';
import 'collection_toolbar.dart';

/// The collection header that shows [toolbar] normally and swaps it for a
/// [BulkActionBar] the moment the [controller] has a selection — the drift-prone
/// `selection.isEmpty ? toolbar : bulkBar` glue every list otherwise re-rolls.
///
/// The toolbar stays laid out under the bar (hidden, out of the focus order
/// and the semantics tree), so it keeps its state. A one-line toolbar is the
/// bar's height ([CollectionToolbar.heightOf]), so the swap moves nothing; a
/// toolbar wrapped onto more lines, on a narrow screen, gives way to the
/// bar's one line rather than leaving an empty band under it.
///
/// Deliberately thin: it owns no state and assumes nothing about the toolbar's
/// contents or the [bulkActions] — those stay the Screen's to define, and every
/// primitive ([CollectionToolbar], [BulkActionBar]) is still usable directly
/// without this. It's a convenience over composition, never a gate.
class CollectionHeader<T> extends StatelessWidget {
  final CollectionController<T> controller;

  /// The no-selection header — typically a `CollectionToolbar`.
  final Widget toolbar;

  /// Actions offered while rows are selected.
  final List<BulkAction> bulkActions;

  /// Overrides the bulk bar's "{count} selected" label; see
  /// [BulkActionBar.selectedLabel].
  final String Function(int count)? selectedLabel;

  /// Overrides the bulk bar's "All {total} selected" label; see
  /// [BulkActionBar.allSelectedLabel].
  final String Function(int total)? allSelectedLabel;

  /// Selects every row matching the query, across pages. When set, the bar
  /// offers "Select all {total}" once the whole page is selected, and says
  /// so when all of them are.
  final VoidCallback? onSelectAllMatching;

  const CollectionHeader({
    super.key,
    required this.controller,
    required this.toolbar,
    this.bulkActions = const [],
    this.selectedLabel,
    this.allSelectedLabel,
    this.onSelectAllMatching,
  });

  @override
  Widget build(BuildContext context) {
    final line = CollectionToolbar.heightOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: line),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final selected = controller.selected;
          final total = controller.total;
          final everything = total > 0 && selected.length >= total;
          final selectAll = onSelectAllMatching;
          return Stack(
            children: [
              _HeightCap(
                extent: selected.isEmpty ? null : line,
                child: Visibility(
                  visible: selected.isEmpty,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: toolbar,
                ),
              ),
              if (selected.isNotEmpty)
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: BulkActionBar(
                    count: selected.length,
                    onClear: controller.clearSelection,
                    selectedLabel: selectedLabel,
                    allSelectedLabel: allSelectedLabel,
                    actions: bulkActions,
                    matchingTotal: selectAll == null ? null : total,
                    allMatchingSelected: selectAll != null && everything,
                    onSelectAllMatching:
                        selectAll != null &&
                            controller.allOnPageSelected &&
                            !everything
                        ? selectAll
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Lays [child] out at its own height, but takes no more than [extent] of
/// it when one is set: the hidden toolbar under the bar keeps its layout
/// without holding the page open.
class _HeightCap extends SingleChildRenderObjectWidget {
  final double? extent;

  const _HeightCap({required this.extent, required super.child});

  @override
  _RenderHeightCap createRenderObject(BuildContext context) =>
      _RenderHeightCap(extent);

  @override
  void updateRenderObject(BuildContext context, _RenderHeightCap renderObject) {
    renderObject.extent = extent;
  }
}

class _RenderHeightCap extends RenderProxyBox {
  _RenderHeightCap(this._extent);

  double? _extent;
  set extent(double? value) {
    if (value == _extent) return;
    _extent = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final extent = _extent;
    if (extent == null) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
      return;
    }
    child.layout(
      constraints.copyWith(minHeight: 0, maxHeight: double.infinity),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(child.size.width, math.min(child.size.height, extent)),
    );
  }

  double _capped(double height) =>
      _extent == null ? height : math.min(height, _extent!);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _capped(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _capped(super.computeMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final extent = _extent;
    if (extent == null) return child.getDryLayout(constraints);
    final natural = child.getDryLayout(
      constraints.copyWith(minHeight: 0, maxHeight: double.infinity),
    );
    return constraints.constrain(
      Size(natural.width, math.min(natural.height, extent)),
    );
  }
}
