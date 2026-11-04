/// @docImport '../../common/ui/breadcrumbs.dart';
/// @docImport 'page_scaffold.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/skeleton.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// The header at the top of a page's content: an optional [breadcrumb] above the
/// [title] (with optional [subtitle] and [leading] back button), and
/// right-aligned [actions].
///
/// The actions sit beside the title while it keeps at least [minTitleWidth]
/// (or, when shorter, the one-line width of its title and subtitle);
/// otherwise they wrap below it, and wrap among themselves when even a line of
/// their own is too narrow. Wrapped onto one line of their own, a leading
/// [IconAction] moves back by its glyph's inset, so its glyph, not its hit
/// box, lines up with the title. The title runs to two lines at most, then
/// ellipsises; it is announced as the page's heading.
///
/// While [titleLoading] is true the title (and subtitle, if any) render as a
/// shimmer instead of text — for pages whose title arrives asynchronously, so
/// they never flash a placeholder label. Pair it with a [Crumb.loading] tail on
/// the [breadcrumb].
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Inline widget shown right of the title — e.g. a status pill.
  final Widget? titleTrailing;
  final Widget? breadcrumb;
  final bool titleLoading;
  final List<Widget> actions;

  const PageHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.leading,
    this.titleTrailing,
    this.breadcrumb,
    this.titleLoading = false,
    this.actions = const [],
  });

  /// The narrowest the title gets before the actions wrap below it.
  static const minTitleWidth = 240.0;

  static const _skeletonWidth = 240.0;

  /// The page's side gutter, shared by the header and the [PageScaffold]
  /// body: 24, or 16 in a compact window, narrower than the theme's medium
  /// breakpoint (`context.breakpoints.medium`) — the layout margins of a
  /// compact window.
  static double gutterOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width < context.breakpoints.medium
      ? AdminSpacing.xl
      : AdminSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    final titleStyle = context.type.pageTitle;
    final Widget titleLine;
    if (titleLoading) {
      // A bar the size of the type on a box the size of its line, so the
      // title takes the skeleton's place without moving what follows.
      titleLine = SizedBox(
        height: lineHeightOf(context, titleStyle),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Skeleton(
            width: _skeletonWidth,
            height: titleStyle.fontSize ?? AdminSpacing.xxl,
          ),
        ),
      );
    } else {
      final text = Semantics(
        container: true,
        header: true,
        child: Text(
          title,
          style: titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
      titleLine = titleTrailing == null
          ? text
          : Row(
              children: [
                Flexible(child: text),
                const Gap(AdminSpacing.md),
                titleTrailing!,
              ],
            );
    }

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleLine,
        if (subtitle != null) ...[
          const Gap(AdminSpacing.xs),
          if (titleLoading)
            SizedBox(
              height: lineHeightOf(context, context.type.body),
              child: const Align(
                alignment: AlignmentDirectional.centerStart,
                child: Skeleton(width: 160, height: 12),
              ),
            )
          else
            Text(
              subtitle!,
              style: context.type.body.copyWith(
                color: context.colors.foregroundMuted,
              ),
            ),
        ],
      ],
    );

    final first = actions.firstOrNull;
    final gutter = gutterOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (breadcrumb != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: breadcrumb,
              ),
            ),
            const Gap(AdminSpacing.md),
          ],
          _HeaderLayout(
            textDirection: Directionality.of(context),
            gutter: gutter,
            titleWidth: _wantedTitleWidth(context, titleStyle),
            wrappedInset: first is IconAction
                ? (first.size.boxOf(context) - first.size.glyph) / 2
                : 0,
            leading: leading,
            title: titleBlock,
            actions: actions.isEmpty
                ? null
                : Wrap(
                    spacing: AdminSpacing.sm,
                    runSpacing: AdminSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions,
                  ),
          ),
        ],
      ),
    );
  }

  /// The room the title asks for before the actions may sit beside it: the
  /// one-line width of its title and subtitle, up to [minTitleWidth]. A title
  /// with a trailing widget (whose width is unknown here) asks for the full
  /// [minTitleWidth].
  double _wantedTitleWidth(BuildContext context, TextStyle style) {
    if (titleTrailing != null) return minTitleWidth;
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width.ceilToDouble();
      painter.dispose();
      return width;
    }

    final subtitle = this.subtitle;
    final wanted = math.max(
      titleLoading ? _skeletonWidth : measure(title, style),
      subtitle == null || titleLoading
          ? 0.0
          : measure(subtitle, context.type.body),
    );
    return math.min(minTitleWidth, wanted);
  }
}

enum _HeaderSlot { leading, title, actions }

/// The leading widget, the title block and the actions. Side by side — the
/// actions at the end, all three centred on one another — while the title
/// keeps [titleWidth]; otherwise the actions wrap under the title, at the
/// start — pulled back by [wrappedInset] while they keep to one line. The
/// [gutter] is inside the box, so an action pulled back into it is still hit.
class _HeaderLayout
    extends SlottedMultiChildRenderObjectWidget<_HeaderSlot, RenderBox> {
  final Widget? leading;
  final Widget title;
  final Widget? actions;
  final double titleWidth;
  final double wrappedInset;
  final double gutter;
  final TextDirection textDirection;

  const _HeaderLayout({
    required this.leading,
    required this.title,
    required this.actions,
    required this.titleWidth,
    required this.wrappedInset,
    required this.gutter,
    required this.textDirection,
  });

  @override
  Iterable<_HeaderSlot> get slots => _HeaderSlot.values;

  @override
  Widget? childForSlot(_HeaderSlot slot) => switch (slot) {
    _HeaderSlot.leading => leading,
    _HeaderSlot.title => title,
    _HeaderSlot.actions => actions,
  };

  @override
  _RenderHeaderLayout createRenderObject(BuildContext context) =>
      _RenderHeaderLayout(
        titleWidth: titleWidth,
        wrappedInset: wrappedInset,
        gutter: gutter,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeaderLayout renderObject,
  ) {
    renderObject
      ..titleWidth = titleWidth
      ..wrappedInset = wrappedInset
      ..gutter = gutter
      ..textDirection = textDirection;
  }
}

class _RenderHeaderLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_HeaderSlot, RenderBox> {
  _RenderHeaderLayout({
    required this._titleWidth,
    required this._wrappedInset,
    required this._gutter,
    required this._textDirection,
  });

  /// Between the leading widget and the title. The leading widget takes half
  /// the width at most, so the title always keeps the other half.
  static const _leadingGap = AdminSpacing.md;

  /// Between the title and the actions beside it, or wrapped under it.
  static const _gap = AdminSpacing.lg;

  double _titleWidth;
  set titleWidth(double value) {
    if (value == _titleWidth) return;
    _titleWidth = value;
    markNeedsLayout();
  }

  double _wrappedInset;
  set wrappedInset(double value) {
    if (value == _wrappedInset) return;
    _wrappedInset = value;
    markNeedsLayout();
  }

  double _gutter;
  set gutter(double value) {
    if (value == _gutter) return;
    _gutter = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(_HeaderSlot.leading);
  RenderBox get _title => childForSlot(_HeaderSlot.title)!;
  RenderBox? get _actions => childForSlot(_HeaderSlot.actions);

  @override
  double computeMinIntrinsicWidth(double height) {
    final leading = _leading?.getMinIntrinsicWidth(height);
    return 2 * _gutter +
        math.max(
          (leading == null ? 0 : leading + _leadingGap) +
              _title.getMinIntrinsicWidth(height),
          _actions?.getMinIntrinsicWidth(height) ?? 0,
        );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final leading = _leading?.getMaxIntrinsicWidth(height);
    final actions = _actions?.getMaxIntrinsicWidth(height);
    return 2 * _gutter +
        (leading == null ? 0 : leading + _leadingGap) +
        _title.getMaxIntrinsicWidth(height) +
        (actions == null ? 0 : _gap + actions);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _plan(
    BoxConstraints(maxWidth: width),
    ChildLayoutHelper.dryLayoutChild,
  ).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _plan(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    size = plan.size;
    for (final (child, offset) in plan.offsets) {
      (child.parentData! as BoxParentData).offset = offset;
    }
  }

  ({Size size, List<(RenderBox, Offset)> offsets}) _plan(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final outer = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final width = math.max(0.0, outer - 2 * _gutter);
    final rtl = _textDirection == TextDirection.rtl;
    // The x of a box [w] wide starting [start] in from the leading edge of
    // the content, inside the gutters.
    double x(double start, double w) =>
        _gutter + (rtl ? width - start - w : start);

    final leading = _leading;
    final leadingSize = leading == null
        ? Size.zero
        : layoutChild(leading, BoxConstraints(maxWidth: width / 2));
    final titleStart = leading == null ? 0.0 : leadingSize.width + _leadingGap;

    final actions = _actions;
    final actionsSize = actions == null
        ? Size.zero
        : layoutChild(actions, BoxConstraints(maxWidth: width));
    final beside = width - titleStart - actionsSize.width - _gap;
    final inline = actions != null && beside >= _titleWidth;
    // Wrapped onto a single line of their own, the actions move back by the
    // leading glyph's inset. Over several lines they don't: every line
    // starts at the edge, and most start with a labelled button.
    final pullBack =
        actions != null &&
            !inline &&
            _wrappedInset > 0 &&
            actions.getMaxIntrinsicWidth(double.infinity) <= width
        ? _wrappedInset
        : 0.0;

    final titleSize = layoutChild(
      _title,
      BoxConstraints.tightFor(
        width: math.max(0, inline ? beside : width - titleStart),
      ),
    );
    final headHeight = math.max(leadingSize.height, titleSize.height);
    final rowHeight = inline
        ? math.max(headHeight, actionsSize.height)
        : headHeight;

    final offsets = <(RenderBox, Offset)>[
      if (leading != null)
        (
          leading,
          Offset(x(0, leadingSize.width), (rowHeight - leadingSize.height) / 2),
        ),
      (
        _title,
        Offset(
          x(titleStart, titleSize.width),
          (rowHeight - titleSize.height) / 2,
        ),
      ),
      if (actions != null)
        (
          actions,
          inline
              ? Offset(
                  x(width - actionsSize.width, actionsSize.width),
                  (rowHeight - actionsSize.height) / 2,
                )
              : Offset(x(-pullBack, actionsSize.width), rowHeight + _gap),
        ),
    ];
    final height = inline || actions == null
        ? rowHeight
        : rowHeight + _gap + actionsSize.height;
    return (size: constraints.constrain(Size(outer, height)), offsets: offsets);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
