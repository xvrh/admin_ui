import 'package:material_ui/material_ui.dart';

import '../../common/motion.dart';
import '../../common/ui/panel.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'form_grid.dart';

/// A titled cluster of fields — the layout unit an edit screen is built from.
/// Stacks [children] [spacing] apart, or lays them out on a [FormGrid] of
/// [columns], under an optional [title] / [description] header that can
/// carry trailing [actions]. A child that lays out zero tall, as a field its
/// rules hide does, takes no gap.
///
/// Two looks: bare (a section header above the fields) or [boxed] (the header
/// and fields wrapped in a [Panel] card, split by a hairline). Set [collapsible]
/// to let the header toggle the body open and shut.
///
/// The [title] is heading type — a step above the field labels, announced as
/// a heading — with the [description] under it in muted body type.
class FieldGroup extends StatefulWidget {
  final String? title;
  final String? description;

  /// Trailing widgets in the header row — a button, a menu, a status tag.
  final List<Widget> actions;

  /// The fields, stacked vertically and separated by [spacing], or placed
  /// on the grid of [columns].
  final List<Widget> children;

  /// Lays [children] out on a [FormGrid] of these columns, [spacing] apart
  /// row from row; a [FormGridItem] child spans columns. Null stacks them.
  final FormColumns? columns;

  /// Wraps the header + body in a bordered [Panel] card.
  final bool boxed;

  /// Makes the header a toggle that expands/collapses the body.
  final bool collapsible;
  final bool initiallyExpanded;

  /// Vertical gap between [children], or between the grid's rows; the
  /// [FormGrid]'s row gap when null, which is closer under a form that
  /// keeps each field's message line.
  final double? spacing;

  const FieldGroup({
    super.key,
    this.title,
    this.description,
    this.actions = const [],
    required this.children,
    this.columns,
    this.boxed = false,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.spacing,
  });

  @override
  State<FieldGroup> createState() => _FieldGroupState();
}

class _FieldGroupState extends State<FieldGroup> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _hasHeader =>
      widget.title != null ||
      widget.description != null ||
      widget.actions.isNotEmpty;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return widget.boxed ? _boxed(context) : _bare(context);
  }

  Widget _bare(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasHeader) ...[_header(context), const Gap(AdminSpacing.lg)],
        _collapsible(_body(context)),
      ],
    );
  }

  Widget _boxed(BuildContext context) {
    return Panel(
      padding: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasHeader)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AdminSpacing.xl,
                AdminSpacing.lg,
                AdminSpacing.lg,
                AdminSpacing.lg,
              ),
              child: _header(context),
            ),
          _collapsible(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasHeader)
                  Container(height: 1, color: context.colors.border),
                Padding(
                  padding: const EdgeInsets.all(AdminSpacing.xl),
                  child: _body(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps [content] so it animates open/shut when [collapsible] — or, with
  /// reduced motion, just shows and hides; otherwise returns it untouched.
  Widget _collapsible(Widget content) {
    if (!widget.collapsible) return content;
    final body = _expanded
        ? content
        : const SizedBox(width: double.infinity, height: 0);
    if (motionReduced(context)) return body;
    final motion = context.motion;
    return ClipRect(
      child: AnimatedSize(
        alignment: Alignment.topCenter,
        duration: motion.medium,
        curve: motion.standard,
        child: body,
      ),
    );
  }

  /// A single-column grid stacks the children like a column, but closes the
  /// gap of a child that lays out zero tall.
  Widget _body(BuildContext context) => FormGrid(
    columns: widget.columns ?? const FormColumns.fixed(1),
    rowGap: widget.spacing,
    children: widget.children,
  );

  Widget _header(BuildContext context) {
    final labels = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title case final title?)
          Semantics(
            header: true,
            child: Text(title, style: context.type.heading),
          ),
        if (widget.description case final description?) ...[
          if (widget.title != null) const Gap(AdminSpacing.xs),
          Text(
            description,
            style: context.type.body.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
        ],
      ],
    );

    // Collapsed, the chevron points along the reading direction.
    final collapsedTurns = Directionality.of(context) == TextDirection.rtl
        ? 0.25
        : -0.25;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.collapsible) ...[
          AnimatedRotation(
            turns: _expanded ? 0 : collapsedTurns,
            duration: context.motion.fast,
            curve: context.motion.standard,
            child: Icon(
              Icons.expand_more_rounded,
              size: context.iconSizes.lg,
              color: context.colors.foregroundMuted,
            ),
          ),
          const Gap(AdminSpacing.xs),
        ],
        Expanded(child: labels),
        if (widget.actions.isNotEmpty) ...[
          const Gap(AdminSpacing.md),
          ...widget.actions,
        ],
      ],
    );

    if (!widget.collapsible) return row;
    return Semantics(
      button: true,
      expanded: _expanded,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        child: row,
      ),
    );
  }
}
