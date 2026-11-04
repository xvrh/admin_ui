import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'focus_ring.dart';
import 'tappable.dart';

/// One step in a [Steps] indicator.
class StepItem {
  final String title;
  final String? subtitle;

  const StepItem(this.title, {this.subtitle});
}

enum _NodeState { complete, active, upcoming, error }

/// A multi-step progress indicator — the reusable part of a wizard. It shows
/// where the flow is; the page body and the Back/Next buttons stay with the
/// screen that drives it.
///
/// Steps before [current] read as complete, [current] is active, the rest are
/// upcoming; mark any as errored with [errorSteps]. Pass [onChanged] to let
/// the user jump back to a completed step: those steps become buttons, reached
/// with Tab and activated with Enter or Space, announced as "Step 1 of 4:
/// Account, completed".
class Steps extends StatelessWidget {
  final List<StepItem> steps;
  final int current;
  final Axis direction;

  /// Indexes to render in the error state, overriding their derived state.
  final Set<int> errorSteps;

  /// Tapping a step ≤ [current] reports its index. Null is a static indicator.
  final ValueChanged<int>? onChanged;

  const Steps({
    super.key,
    required this.steps,
    required this.current,
    this.direction = Axis.horizontal,
    this.errorSteps = const {},
    this.onChanged,
  });

  _NodeState _stateOf(int i) {
    if (errorSteps.contains(i)) return _NodeState.error;
    if (i < current) return _NodeState.complete;
    if (i == current) return _NodeState.active;
    return _NodeState.upcoming;
  }

  VoidCallback? _tapFor(int i) {
    final onChanged = this.onChanged;
    if (onChanged == null || i > current) return null;
    return () => onChanged(i);
  }

  /// What a tappable step announces; its own glyph and text are dropped.
  String _labelFor(BuildContext context, int i) {
    final strings = context.adminL10n.display;
    final step = steps[i];
    final state = switch (_stateOf(i)) {
      _NodeState.complete => strings.stepCompleted,
      _NodeState.active => strings.stepCurrent,
      _NodeState.upcoming => strings.stepUpcoming,
      _NodeState.error => strings.stepError,
    };
    return strings.joinParts([
      strings.stepOf(i + 1, steps.length, step.title),
      ?step.subtitle,
      state,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return direction == Axis.horizontal
        ? _horizontal(context)
        : _vertical(context);
  }

  Widget _horizontal(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _HStep(
              item: steps[i],
              index: i,
              state: _stateOf(i),
              beforeFilled: i > 0 && i <= current,
              afterFilled: i < steps.length - 1 && i < current,
              showBefore: i > 0,
              showAfter: i < steps.length - 1,
              onTap: _tapFor(i),
              label: _labelFor(context, i),
            ),
          ),
      ],
    );
  }

  Widget _vertical(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _VStep(
            item: steps[i],
            index: i,
            state: _stateOf(i),
            connectorFilled: i < current,
            last: i == steps.length - 1,
            onTap: _tapFor(i),
            label: _labelFor(context, i),
          ),
      ],
    );
  }
}

/// A step's node: even, so its glyph and its connectors centre on whole
/// pixels.
const _nodeSize = 26.0;

/// A connector's thickness: even, like [_nodeSize].
const _connector = 2.0;

/// A step of a horizontal indicator: its node between the connector from the
/// step before, on the start side, and the one to the step after.
class _HStep extends StatelessWidget {
  final StepItem item;
  final int index;
  final _NodeState state;
  final bool beforeFilled;
  final bool afterFilled;
  final bool showBefore;
  final bool showAfter;
  final VoidCallback? onTap;
  final String label;

  const _HStep({
    required this.item,
    required this.index,
    required this.state,
    required this.beforeFilled,
    required this.afterFilled,
    required this.showBefore,
    required this.showAfter,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _StepTarget(
      onTap: onTap,
      label: label,
      builder: (focused) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: showBefore
                    ? _Connector(filled: beforeFilled)
                    : const SizedBox(),
              ),
              _Node(index: index, state: state),
              Expanded(
                child: showAfter
                    ? _Connector(filled: afterFilled)
                    : const SizedBox(),
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
            child: _Label(
              item: item,
              state: state,
              center: true,
              focused: focused,
            ),
          ),
        ],
      ),
    );
  }
}

class _VStep extends StatelessWidget {
  final StepItem item;
  final int index;
  final _NodeState state;
  final bool connectorFilled;
  final bool last;
  final VoidCallback? onTap;
  final String label;

  const _VStep({
    required this.item,
    required this.index,
    required this.state,
    required this.connectorFilled,
    required this.last,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // The node and the title's first line share a centre: whichever is
    // shorter is pushed down by half the difference.
    final line = lineHeightOf(context, context.type.body);
    final nodeTop = math.max(0.0, (line - _nodeSize) / 2);
    final titleTop = math.max(0.0, (_nodeSize - line) / 2);
    return IntrinsicHeight(
      child: _StepTarget(
        onTap: onTap,
        label: label,
        builder: (focused) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: nodeTop),
              child: Column(
                children: [
                  _Node(index: index, state: state),
                  if (!last)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AdminSpacing.xs,
                        ),
                        child: _Connector(
                          filled: connectorFilled,
                          vertical: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(AdminSpacing.lg),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: titleTop,
                  bottom: last ? 0 : AdminSpacing.xl,
                ),
                child: _Label(
                  item: item,
                  state: state,
                  center: false,
                  focused: focused,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final int index;
  final _NodeState state;

  const _Node({required this.index, required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, border, fg) = switch (state) {
      _NodeState.complete => (colors.primary, colors.primary, colors.onPrimary),
      _NodeState.active => (
        colors.primaryFaint,
        colors.primary,
        colors.readableOn(colors.primaryText, surfaces: [colors.primaryFaint]),
      ),
      _NodeState.upcoming => (
        colors.surface,
        colors.foregroundFaint,
        colors.foregroundMuted,
      ),
      _NodeState.error => (colors.danger, colors.danger, colors.onDanger),
    };

    Widget content;
    switch (state) {
      case _NodeState.complete:
        content = Icon(
          Icons.check_rounded,
          size: context.iconSizes.sm,
          color: fg,
        );
      case _NodeState.error:
        content = Icon(
          Icons.priority_high_rounded,
          size: context.iconSizes.sm,
          color: fg,
        );
      default:
        // A number on a node of fixed size, which keeps its size at any
        // text scale as the node's icons do.
        content = Text(
          '${index + 1}',
          textScaler: TextScaler.noScaling,
          style: context.type.weighted(
            context.type.caption.copyWith(color: fg),
            FontWeight.w700,
          ),
        );
    }

    return Container(
      width: _nodeSize,
      height: _nodeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: border,
          width: state == _NodeState.active
              ? context.stroke.controlStrong
              : context.stroke.hairline,
        ),
      ),
      child: content,
    );
  }
}

class _Connector extends StatelessWidget {
  final bool filled;
  final bool vertical;

  const _Connector({required this.filled, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final color = filled ? context.colors.primary : context.colors.border;
    return vertical
        ? Container(width: _connector, color: color)
        : Container(height: _connector, color: color);
  }
}

class _Label extends StatelessWidget {
  final StepItem item;
  final _NodeState state;
  final bool center;

  /// Draws the keyboard focus ring of a step the user can jump to, around its
  /// label — clear of the node and the connectors.
  final bool focused;

  const _Label({
    required this.item,
    required this.state,
    required this.center,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    final active = state == _NodeState.active || state == _NodeState.complete;
    final titleColor = state == _NodeState.error
        ? context.colors.dangerText
        : (active ? context.colors.foreground : context.colors.foregroundMuted);
    final text = Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: context.type.weighted(
            context.type.body.copyWith(color: titleColor),
            state == _NodeState.active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        if (item.subtitle != null) ...[
          const Gap(AdminSpacing.xxs),
          Text(
            item.subtitle!,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.type.caption.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
        ],
      ],
    );
    // The ring's box stands a little off the text without taking layout
    // space, further where the theme draws the ring inset, so it always clears
    // the glyphs.
    final inset = math.max(0.0, -context.focus.offset);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        text,
        Positioned(
          left: -AdminSpacing.xs - inset,
          right: -AdminSpacing.xs - inset,
          top: -AdminSpacing.xxs - inset,
          bottom: -AdminSpacing.xxs - inset,
          child: IgnorePointer(
            child: FocusRing(
              focused: focused,
              radius: context.radii.radiusSmall,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

/// A step the user can jump back to is a labelled button, its label ringed
/// while it holds keyboard focus; any other step is plain content.
class _StepTarget extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final Widget Function(bool focused) builder;

  const _StepTarget({
    required this.onTap,
    required this.label,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return builder(false);
    return Tappable.states(
      onTap: onTap,
      semanticLabel: label,
      excludeSemantics: true,
      showFocusRing: false,
      builder: (context, states) =>
          builder(states.contains(WidgetState.focused)),
    );
  }
}
