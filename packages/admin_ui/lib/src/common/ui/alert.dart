/// @docImport 'button.dart';
/// @docImport 'modal.dart';
/// @docImport 'toast.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'icon_action.dart';
import 'severity.dart';

/// An inline, in-flow message — the page/section-level banner (info, success,
/// warning, danger). For transient pop-ups use a [Toast]; for blocking choices a
/// [Modal].
///
/// A soft tinted surface with the severity icon, an optional bold [title] over
/// the [message], an optional trailing [action] (typically a [Button]) and an
/// optional dismiss affordance via [onDismiss].
///
/// Being a widget, it takes its action as a widget, which the caller builds
/// and sizes; a [Toast], which is data handed to a scope, takes an action
/// label and callback instead.
class Alert extends StatelessWidget {
  final Severity severity;
  final String message;
  final String? title;
  final Widget? action;
  final VoidCallback? onDismiss;

  /// Replaces the severity's leading glyph.
  final IconData? icon;

  /// Whether the leading glyph shows; false starts the text at the padding.
  final bool showIcon;

  /// Whether assistive technology reads the alert out when it appears or
  /// changes — for one shown in response to what the user did, such as an
  /// error under a form. Defaults to true for warning and danger.
  final bool? liveRegion;

  const Alert(
    this.message, {
    super.key,
    this.severity = Severity.info,
    this.title,
    this.action,
    this.onDismiss,
    this.icon,
    this.showIcon = true,
    this.liveRegion,
  });

  @override
  Widget build(BuildContext context) {
    final style = severityStyleOf(context, severity);
    final live =
        liveRegion ??
        (severity == Severity.warning || severity == Severity.danger);
    return Semantics(
      container: true,
      liveRegion: live,
      child: _surface(context, style),
    );
  }

  Widget _surface(BuildContext context, SeverityStyle style) {
    const close = IconActionSize.inline;
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: AdminSpacing.lg,
        // The close glyph, not its hit box, keeps the 12px inset.
        end: onDismiss == null
            ? AdminSpacing.lg
            : AdminSpacing.lg - (close.box - close.glyph) / 2,
      ),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(context.radii.radius),
        border: Border.all(color: style.border),
      ),
      child: firstLineRow(
        firstLine: firstLineHeight(
          context,
          TextSpan(
            text: title ?? message,
            style: title == null ? context.type.body : context.type.bodyStrong,
          ),
        ),
        trailingGap: action != null ? AdminSpacing.md : AdminSpacing.sm,
        textDirection: Directionality.of(context),
        icon: showIcon
            ? Icon(
                icon ?? style.icon,
                size: context.iconSizes.lg,
                color: style.foreground,
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: context.type.bodyStrong),
              const Gap(AdminSpacing.xxs),
            ],
            Text(
              message,
              style: context.type.body.copyWith(
                color: context.colors.foregroundSecondary,
              ),
            ),
          ],
        ),
        trailing: action == null && onDismiss == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?action,
                  if (action != null && onDismiss != null)
                    const Gap(AdminSpacing.sm),
                  if (onDismiss != null)
                    IconAction.close(
                      size: close,
                      label: MaterialLocalizations.of(context)
                          .modalBarrierDismissLabel,
                      onPressed: onDismiss,
                    ),
                ],
              ),
      ),
    );
  }
}

/// The height of [span]'s first line as a [Text] lays it out under
/// [context]: over the inherited style, at the text scale.
@internal
double firstLineHeight(BuildContext context, InlineSpan span) {
  final inherited = DefaultTextStyle.of(context);
  final painter = TextPainter(
    text: TextSpan(style: inherited.style, children: [span]),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior:
        inherited.textHeightBehavior ??
        DefaultTextHeightBehavior.maybeOf(context),
    maxLines: 1,
  )..layout();
  final height = painter.height;
  painter.dispose();
  return height;
}

/// A feedback row — an [Alert]'s or an `AnnouncementBar`'s: the [icon], the
/// [body] and the [trailing] action and close, in a row. The icon and the
/// trailing controls centre on the body's first line, [firstLine] tall, with
/// 12px above that line and below the body. Controls taller than the line
/// take the room they need out of that padding, down to 6px, so a
/// single-line row with a close or an action keeps the height of one
/// without.
///
/// [more] is a toggle that sits after the body, on its first line, while
/// [overflows] says the body runs past its lines at the width it is given;
/// otherwise it is neither painted, hit nor read out. [onMoreShown] hears
/// after the frame when it appears or goes, to take it out of the focus
/// order while hidden.
@internal
Widget firstLineRow({
  required Widget body,
  required double firstLine,
  required TextDirection textDirection,
  Widget? icon,
  Widget? more,
  Widget? trailing,
  double trailingGap = AdminSpacing.sm,
  bool Function(double width)? overflows,
  ValueChanged<bool>? onMoreShown,
}) => _FirstLineRow(
  icon: icon,
  body: body,
  more: more,
  trailing: trailing,
  firstLine: firstLine,
  trailingGap: trailingGap,
  overflows: overflows,
  onMoreShown: onMoreShown,
  textDirection: textDirection,
);

enum _Slot { icon, body, more, trailing }

class _FirstLineRow
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  final Widget? icon;
  final Widget body;
  final Widget? more;
  final Widget? trailing;
  final double firstLine;
  final double trailingGap;
  final bool Function(double width)? overflows;
  final ValueChanged<bool>? onMoreShown;
  final TextDirection textDirection;

  const _FirstLineRow({
    required this.icon,
    required this.body,
    required this.more,
    required this.trailing,
    required this.firstLine,
    required this.trailingGap,
    required this.overflows,
    required this.onMoreShown,
    required this.textDirection,
  });

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.icon => icon,
    _Slot.body => body,
    _Slot.more => more,
    _Slot.trailing => trailing,
  };

  @override
  _RenderFirstLineRow createRenderObject(BuildContext context) =>
      _RenderFirstLineRow(
        firstLine: firstLine,
        trailingGap: trailingGap,
        overflows: overflows,
        onMoreShown: onMoreShown,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFirstLineRow renderObject,
  ) {
    renderObject
      ..firstLine = firstLine
      ..trailingGap = trailingGap
      ..overflows = overflows
      ..onMoreShown = onMoreShown
      ..textDirection = textDirection;
  }
}

class _RenderFirstLineRow extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderFirstLineRow({
    required this._firstLine,
    required this._trailingGap,
    required this._overflows,
    required this.onMoreShown,
    required this._textDirection,
  });

  /// Above the first line and below the body: the 12px the row keeps.
  static const _padding = AdminSpacing.lg;

  /// The least left above and below a tall trailing control.
  static const _minPadding = AdminSpacing.sm;

  /// Between the icon and the body.
  static const _iconGap = AdminSpacing.md;

  /// Between the body and the [_more] toggle.
  static const _moreGap = AdminSpacing.lg;

  double _firstLine;
  set firstLine(double value) {
    if (value == _firstLine) return;
    _firstLine = value;
    markNeedsLayout();
  }

  double _trailingGap;
  set trailingGap(double value) {
    if (value == _trailingGap) return;
    _trailingGap = value;
    markNeedsLayout();
  }

  bool Function(double width)? _overflows;
  set overflows(bool Function(double width)? value) {
    if (value == _overflows) return;
    _overflows = value;
    markNeedsLayout();
  }

  ValueChanged<bool>? onMoreShown;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Whether the last layout showed [_more].
  bool _moreShown = false;

  /// What [onMoreShown] last heard, or is about to.
  bool _moreReported = false;

  RenderBox? get _icon => childForSlot(_Slot.icon);
  RenderBox get _body => childForSlot(_Slot.body)!;
  RenderBox? get _more => childForSlot(_Slot.more);
  RenderBox? get _trailing => childForSlot(_Slot.trailing);

  /// The children drawn, hit and read out: all but a hidden [_more].
  Iterable<RenderBox> get _shown =>
      children.where((child) => _moreShown || child != _more);

  double _besideBody(double Function(RenderBox child) width) {
    final icon = _icon;
    final trailing = _trailing;
    return (icon == null ? 0 : width(icon) + _iconGap) +
        (trailing == null ? 0 : _trailingGap + width(trailing));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _besideBody((c) => c.getMinIntrinsicWidth(height)) +
      _body.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _besideBody((c) => c.getMaxIntrinsicWidth(height)) +
      _body.getMaxIntrinsicWidth(height);

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
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final body = _body;
    final distance = body.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (body.parentData! as BoxParentData).offset.dy;
  }

  @override
  void performLayout() {
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    size = plan.size;
    for (final (child, offset) in plan.offsets) {
      (child.parentData! as BoxParentData).offset = offset;
    }
    _moreShown = plan.moreShown;
    if (_moreShown != _moreReported) {
      _moreReported = _moreShown;
      final shown = _moreShown;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached) onMoreShown?.call(shown);
      });
    }
  }

  ({Size size, List<(RenderBox, Offset)> offsets, bool moreShown}) _plan(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final rtl = _textDirection == TextDirection.rtl;
    double x(double start, double w) => rtl ? width - start - w : start;

    final icon = _icon;
    final iconSize = icon == null
        ? Size.zero
        : layoutChild(icon, const BoxConstraints());
    final trailing = _trailing;
    final trailingSize = trailing == null
        ? Size.zero
        : layoutChild(trailing, BoxConstraints(maxWidth: width));
    final bodyStart = icon == null ? 0.0 : iconSize.width + _iconGap;
    var bodyWidth = math.max(
      0.0,
      width -
          bodyStart -
          (trailing == null ? 0 : _trailingGap + trailingSize.width),
    );
    // Laid out even while hidden, so its focus node has a box to report.
    final more = _more;
    final moreSize = more == null
        ? Size.zero
        : layoutChild(more, BoxConstraints(maxWidth: width));
    // Narrowing the body never makes it fit, so the width without the
    // toggle decides.
    final moreShown = more != null && (_overflows?.call(bodyWidth) ?? false);
    if (moreShown) {
      bodyWidth = math.max(0.0, bodyWidth - _moreGap - moreSize.width);
    }
    final bodySize = layoutChild(
      _body,
      BoxConstraints.tightFor(width: bodyWidth),
    );

    // The first line and the icon share a line; the controls centre on it,
    // in a band that eats into the padding when they are taller.
    final line = math.max(_firstLine, iconSize.height);
    final band = math.max(
      line,
      math.max(trailingSize.height, moreShown ? moreSize.height : 0),
    );
    final bandTop = math.max(_minPadding, _padding - (band - line) / 2);
    final centre = bandTop + band / 2;
    final bodyTop = centre - _firstLine / 2;
    final height = math.max(
      bandTop + band + bandTop,
      bodyTop + bodySize.height + _padding,
    );

    final offsets = <(RenderBox, Offset)>[
      if (icon != null)
        (icon, Offset(x(0, iconSize.width), centre - iconSize.height / 2)),
      (_body, Offset(x(bodyStart, bodyWidth), bodyTop)),
      if (more != null)
        (
          more,
          Offset(
            x(bodyStart + bodyWidth + _moreGap, moreSize.width),
            centre - moreSize.height / 2,
          ),
        ),
      if (trailing != null)
        (
          trailing,
          Offset(
            x(width - trailingSize.width, trailingSize.width),
            centre - trailingSize.height / 2,
          ),
        ),
    ];
    return (
      size: constraints.constrain(Size(width, height)),
      offsets: offsets,
      moreShown: moreShown,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _shown) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _shown.toList().reversed) {
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

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      _shown.forEach(visitor);
}
