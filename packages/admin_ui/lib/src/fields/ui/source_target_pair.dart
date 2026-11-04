import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../i18n/locale_status.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart' show fieldPaddingY;
import '../../theme/tokens.dart';
import 'field_shell.dart';

/// A read-only source beside the editable target it is compared with: a
/// translation next to its original, a proposed value next to the current
/// one. Side by side when the available width allows, stacked below
/// [stackBelow]. The source is a sunken reference on the `surfaceMuted` fill;
/// the target is the only lane with input chrome, and owns it — pass a
/// chrome-less editor.
///
/// Each lane wears its language code as a label notched into its top border
/// ([NotchedLabelBox]) and lays its content out in that language's direction
/// ([LaneLanguage]), while the labels stay in the direction of the admin
/// around them. Side by side, the two lanes are always the same height, and
/// the arrow between them sits on their first line. A lane holding one line
/// of field text is exactly the control height, and the default source line
/// uses the type of the kit's text bodies, so lengths compare at a glance.
///
/// Assistive technology reads the source as "French source", say, and the
/// target as the enclosing [FieldShell]'s label in its language.
class SourceTargetPair extends StatefulWidget {
  /// The code of the source's language, such as 'en'.
  final String sourceLocale;

  /// The code of the target's language, such as 'fr'.
  final String targetLocale;

  /// The directions the source and target languages are written in, where
  /// they should not derive from [sourceLocale] and [targetLocale] (see
  /// [LocaleInfo.textDirection]).
  final TextDirection? sourceTextDirection;
  final TextDirection? targetTextDirection;

  /// Read-only source content. Null renders [sourceText] as one muted line,
  /// or a dash when there is none.
  final Widget? source;

  /// The source as plain text, for the default [source] line.
  final String? sourceText;

  /// The style of the default [source] line. Defaults to `fieldTextStyle`,
  /// the style of the kit's text bodies.
  final TextStyle? sourceStyle;

  /// The target editor. The pair draws its border and focus ring, so the
  /// editor must not bring its own.
  final Widget target;

  /// A widget after [target] in its row, inside the lane: an action on the
  /// empty target, say. It is centred on the target's first line and may
  /// reach into the lane's padding above and below it, so a control up to
  /// the lane's inner height (a small [Button]) leaves a one-line lane the
  /// control height.
  final Widget? targetTrailing;

  /// Notched into the target lane's top edge at the end, opposite its
  /// language label: a status pill, typically.
  final Widget? targetBadge;

  /// Tints the target lane in a status colour (its fill and border) in place
  /// of the input chrome. Null keeps the chrome, whose ring follows focus.
  final Color? targetTint;

  /// Shown under the pair, full width: hints and actions about the target.
  final Widget? footer;

  /// Available width below which the lanes stack vertically.
  final double stackBelow;

  const SourceTargetPair({
    super.key,
    required this.sourceLocale,
    required this.targetLocale,
    required this.target,
    this.sourceTextDirection,
    this.targetTextDirection,
    this.source,
    this.sourceText,
    this.sourceStyle,
    this.targetTrailing,
    this.targetBadge,
    this.targetTint,
    this.footer,
    this.stackBelow = 520,
  });

  @override
  State<SourceTargetPair> createState() => _SourceTargetPairState();
}

class _SourceTargetPairState extends State<SourceTargetPair> {
  bool _targetFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Head-room for the lane labels, which overhang their top border.
        Padding(
          padding: const EdgeInsets.only(top: _notchOverhang),
          child: _pair(context),
        ),
        if (widget.footer case final f?) ...[const Gap(AdminSpacing.md), f],
      ],
    );
  }

  /// The padding inside a lane's resting border: the content `fieldPaddingX`
  /// from its edge, and one line of field text centred in the control height.
  EdgeInsets _lanePadding(BuildContext context) {
    final sizes = context.sizes;
    final border = context.stroke.control;
    return EdgeInsets.symmetric(
      horizontal: sizes.fieldPaddingX - border,
      vertical: fieldPaddingY(context.type, sizes.medium) - border,
    );
  }

  /// The height of one line of field text, at the platform's text size.
  double _line(BuildContext context) {
    final text = context.type.fieldText;
    return text.fontSize! * (text.height ?? 1) + textGrowthOf(context, text);
  }

  Widget _pair(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final src = _sourceLane(context);
        final tgt = _targetLane(context);
        if (box.maxWidth < widget.stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Room for the target's label, which overhangs its top edge.
            children: [src, const Gap(AdminSpacing.xl), tgt],
          );
        }
        final arrow = context.iconSizes.sm;
        final firstLine =
            context.stroke.control +
            _lanePadding(context).top +
            _line(context) / 2;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: src),
              SizedBox(
                width: 28,
                child: Padding(
                  padding: EdgeInsets.only(top: firstLine - arrow / 2),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: arrow,
                        color: context.colors.foregroundMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(flex: 7, child: tgt),
            ],
          ),
        );
      },
    );
  }

  Widget _sourceLane(BuildContext context) {
    final c = context.colors;
    final text = widget.sourceText;
    final style = widget.sourceStyle ?? fieldTextStyle(context);
    final content =
        widget.source ??
        Text(
          text == null || text.isEmpty ? '—' : text,
          style: text == null || text.isEmpty
              ? style.copyWith(color: c.foregroundMutedOnTint)
              : style,
        );
    return Semantics(
      container: true,
      label: context.adminL10n.fields.sourceIn(
        languageNameOf(context, widget.sourceLocale),
      ),
      child: NotchedLabelBox(
        label: widget.sourceLocale.toUpperCase(),
        labelColor: c.foregroundMutedOnTint,
        notchFill: c.surfaceMuted,
        child: Container(
          width: double.infinity,
          padding: _lanePadding(context),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            // The target's corner, so the pair reads as one.
            borderRadius: BorderRadius.circular(context.radii.radiusField),
            border: Border.all(color: c.border),
          ),
          child: LaneLanguage(
            code: widget.sourceLocale,
            textDirection: widget.sourceTextDirection,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _targetLane(BuildContext context) {
    final c = context.colors;
    final field = context.findAncestorWidgetOfExactType<FieldShell>()?.label;
    final language = languageNameOf(context, widget.targetLocale);
    // The row keeps the lane's vertical padding inside it, beside the target,
    // so the trailing can be centred on the first line across that padding.
    // The box keeps what a focus or error border thicker than the resting
    // one takes from it.
    final stroke = context.stroke;
    final ring =
        math.max(stroke.fieldFocus, stroke.fieldError) - stroke.control;
    final lanePad = _lanePadding(context);
    final rowPad = lanePad.top - ring;
    final pad = lanePad.copyWith(top: ring, bottom: ring);
    // The pair owns the target chrome — bodies inside drop their own box.
    // Stretched to a taller source, the lane keeps its content at the top.
    final content = ChromelessFieldScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: rowPad),
                  child: LaneLanguage(
                    code: widget.targetLocale,
                    textDirection: widget.targetTextDirection,
                    child: Semantics(
                      label: field == null
                          ? language
                          : context.adminL10n.fields.fieldInLanguage(
                              field,
                              language,
                            ),
                      child: widget.target,
                    ),
                  ),
                ),
              ),
              if (widget.targetTrailing case final t?) ...[
                const Gap(AdminSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: _line(context) + 2 * rowPad,
                  ),
                  child: Center(widthFactor: 1, heightFactor: 1, child: t),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    final tint = widget.targetTint;
    final tintFill = tint == null ? null : c.statusFill(tint);
    final box = tint != null
        ? Container(
            padding: pad,
            decoration: BoxDecoration(
              color: tintFill,
              borderRadius: BorderRadius.circular(context.radii.radiusField),
              border: Border.all(color: c.statusBorder(tint)),
            ),
            child: content,
          )
        : FieldChrome(active: _targetFocused, padding: pad, child: content);
    final notchFill = tintFill ?? c.fieldFill;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (f) => setState(() => _targetFocused = f),
      child: NotchedLabelBox(
        label: widget.targetLocale.toUpperCase(),
        labelColor: c.readableOn(c.primaryText, surfaces: [notchFill]),
        notchFill: notchFill,
        trailing: widget.targetBadge,
        child: box,
      ),
    );
  }
}

/// A box with a small [label] chip notched into its top border at the start,
/// and an optional [trailing] widget notched in at the end: the language code
/// on a [SourceTargetPair] lane, and its status pill.
///
/// Both notches overhang the top edge by 8 logical pixels, so leave that much
/// room above. The label is decoration — name the box through its semantics.
class NotchedLabelBox extends StatelessWidget {
  final String label;
  final Color labelColor;

  /// The fill behind both notches: the box's own fill at its top edge, so
  /// the border does not show through them.
  final Color notchFill;

  /// Notched into the top edge at the end, opposite [label].
  final Widget? trailing;

  final Widget child;

  const NotchedLabelBox({
    super.key,
    required this.label,
    required this.labelColor,
    required this.notchFill,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Passthrough: a pair stretched to its taller lane stretches the box too.
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          start: 10,
          top: -_notchOverhang,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.sm,
              vertical: AdminSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: notchFill,
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
              border: Border.all(color: context.colors.border),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: context.type.weighted(
                  context.type.micro.copyWith(
                    color: labelColor,
                    letterSpacing: 0.5,
                    height: 1,
                  ),
                  FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        if (trailing case final t?)
          PositionedDirectional(
            end: 10,
            top: -_notchOverhang,
            // Solid backing so the border doesn't show through a translucent
            // pill.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: notchFill,
                borderRadius: BorderRadius.circular(context.radii.radiusPill),
              ),
              child: t,
            ),
          ),
      ],
    );
  }
}

/// How far a [NotchedLabelBox]'s notches rise above its top edge.
const _notchOverhang = AdminSpacing.md;
