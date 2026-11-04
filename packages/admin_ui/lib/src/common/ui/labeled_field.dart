/// @docImport '../../theme/palette.dart';
/// @docImport '../../theme/typography.dart';
library;

import 'dart:ui' show SemanticsValidationResult;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/field_style.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'field_chrome.dart';
import 'field_feedback_scope.dart';
import 'icon_action.dart';
import 'spinner.dart';

/// A [label] (with an optional [trailing] affordance, a [FieldRequiredMarker]
/// and a muted [description]) above a control, and a validation [errorText]
/// under it.
///
/// The lightweight counterpart to `FieldShell`, without its capability cluster
/// (help / comments / history). Use it in a form, a dialog, a settings pane or
/// a one-off admin action, so the control doesn't fall back to raw Material
/// `labelText` chrome.
///
/// The control is built under a [FieldStateScope] of [enabled], [readOnly]
/// and the [errorText], so a kit control turns red, disabled or read-only with
/// the field. It is also named by the label, as required when [required],
/// with the error (or else the description) as its hint and a failed
/// validation while there is an error: a text field takes all of it as its
/// own; a control that is a node of its own (a trigger button) or several
/// controls (a radio set) sit in a group that carries it. The visible label
/// is not read again, and tapping it focuses the control, like an HTML
/// label.
///
/// Layout, on the 4px grid: the label row is at least 24 tall (the inline
/// [IconAction] box, so a trailing action never moves it) with the label, its
/// mark and [trailing] on one baseline; the description follows 4 below, the
/// control 8 below that, and the message 8 below the control — or, with
/// [reserveErrorLine], the room for one line of it while there is none.
/// With a [fieldId] the ambient [FieldFeedbackScope] knows the field by,
/// that line says while the value is checked (see [FieldMessage.pending]),
/// unless there is an error.
///
/// The label, the description and the message take the theme's
/// [AdminTypography.fieldLabel], [AdminTypography.fieldDescription] and
/// [AdminTypography.fieldMessage] as they are.
class LabeledField extends StatefulWidget {
  final String label;

  /// The id of the value the control edits (a `Cell.id`), by which a form
  /// engine's [FieldFeedbackScope] knows the field: whether its value is
  /// being checked, and whether it can be marked optional. Without one the
  /// field takes part in neither.
  final String? fieldId;

  /// Shown at the far end of the label row — a "forgot password?" link, a
  /// character counter, an optional-marker — in the caption style unless it
  /// sets its own.
  final Widget? trailing;

  /// Muted line between the label and the control, explaining what to enter.
  final String? description;

  /// Validation message shown under the control; also turns a kit control's
  /// border red through the [FieldStateScope].
  final String? errorText;

  /// Marks the field required: the control is announced as required, and
  /// the label carries the theme's [FieldRequiredMarker].
  final bool required;

  /// False disables the control (through the [FieldStateScope]) and dims the
  /// label.
  final bool enabled;

  /// Shows the control's value without letting it change; see [FieldState].
  final bool readOnly;

  /// Keeps the room of a one-line [errorText] under the control while there
  /// is none, so a message appearing on validation does not push the rest of
  /// the form down. A message that wraps still grows the field.
  ///
  /// Null follows the ambient [FieldFeedbackScope] (a form engine's), and
  /// reserves nothing outside one.
  final bool? reserveErrorLine;

  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    this.fieldId,
    this.trailing,
    this.description,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.reserveErrorLine,
    required this.child,
  });

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  /// Parents the control's focus subtree, so a tap on the label can focus it.
  final _controlFocus = FocusNode(
    debugLabel: 'LabeledField',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _controlFocus.dispose();
    super.dispose();
  }

  void _focusControl() {
    final focusable = _controlFocus.traversalDescendants;
    if (focusable.isNotEmpty) focusable.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final enabled = widget.enabled && FieldStateScope.of(context).enabled;
    final error = widget.errorText;
    final description = widget.description;
    final trailing = widget.trailing;
    final fieldId = widget.fieldId;
    final pending =
        fieldId != null && FieldFeedbackScope.isPending(context, fieldId);
    final reserve =
        widget.reserveErrorLine ??
        FieldFeedbackScope.reserveErrorLineOf(context);
    final markLeads = FieldRequiredMarker.leadsLabel(context);
    final mark = FieldRequiredMarker(
      required: widget.required,
      fieldId: fieldId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: IconActionSize.inline.box),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  // Pointer-only, like an HTML label: the control carries
                  // the name, and is the Tab stop.
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _focusControl,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (markLeads) mark,
                          Flexible(
                            child: Text(
                              type.fieldLabelText(widget.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: enabled
                                  ? type.fieldLabel
                                  : type.fieldLabel.copyWith(
                                      color: context.colors.foregroundSubtle,
                                    ),
                            ),
                          ),
                          if (!markLeads) mark,
                        ],
                      ),
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const Gap(AdminSpacing.md),
                  DefaultTextStyle.merge(style: type.caption, child: trailing),
                ],
              ],
            ),
          ),
        ),
        if (description != null) ...[
          const Gap(AdminSpacing.xs),
          FieldDescription(description),
        ],
        const Gap(AdminSpacing.md),
        FieldStateScope(
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          invalid: error != null,
          child: Semantics(
            label: widget.label,
            hint: error ?? description,
            isRequired: widget.required ? true : null,
            validationResult: error != null
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: Focus(
              focusNode: _controlFocus,
              includeSemantics: false,
              child: widget.child,
            ),
          ),
        ),
        if (error != null || pending) ...[
          const Gap(AdminSpacing.md),
          FieldMessage(error: error, pending: pending),
        ] else if (reserve) ...[
          const Gap(AdminSpacing.md),
          SizedBox(height: lineHeightOf(context, type.fieldMessage)),
        ],
      ],
    );
  }
}

/// How a field's label says whether the field is [required], in the theme's
/// [AdminFieldStyle.requiredMark]:
///
/// - [FieldRequiredMark.trailing]: a `*` in the danger text colour, 2 after
///   a required field's label;
/// - [FieldRequiredMark.leading]: the same `*`, 4 before it;
/// - [FieldRequiredMark.optionalText]: under a form that declares its
///   required fields ([FieldFeedbackScope.markOptionalOf]), "(optional)" 4
///   after the label of a field the form validates
///   ([FieldFeedbackScope.validates]) that is not required, in
///   [AdminTypography.fieldDescription], and nothing on any other field;
///   elsewhere the trailing `*`.
///
/// A label row puts it before the label when [leadsLabel], after it
/// otherwise, on the label's baseline. Where there is nothing to mark it
/// takes no room. Left out of the semantics tree: the control announces
/// itself as required, so the star would only be read as "star".
class FieldRequiredMarker extends StatelessWidget {
  /// Whether the field must be filled in.
  final bool required;

  /// The id of the field's value, by which a form that declares its
  /// required fields knows whether it validates the field; a field without
  /// one is never marked optional.
  final String? fieldId;

  const FieldRequiredMarker({super.key, this.required = true, this.fieldId});

  /// Whether the theme puts the mark before the label.
  static bool leadsLabel(BuildContext context) =>
      context.fieldStyle.requiredMark == FieldRequiredMark.leading;

  @override
  Widget build(BuildContext context) {
    final mark = context.fieldStyle.requiredMark;
    final markOptional =
        mark == FieldRequiredMark.optionalText &&
        FieldFeedbackScope.markOptionalOf(context);
    if (markOptional) {
      final fieldId = this.fieldId;
      // A field the form does not validate may be required or not: it
      // stays bare, as the form's required fields are.
      final optional =
          !required &&
          fieldId != null &&
          FieldFeedbackScope.validates(context, fieldId);
      if (!optional) return const SizedBox.shrink();
      return ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AdminSpacing.xs),
          child: Text(
            context.adminL10n.fields.optionalMarker,
            maxLines: 1,
            style: context.type.fieldDescription,
          ),
        ),
      );
    }
    if (!required) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: Padding(
        padding: mark == FieldRequiredMark.leading
            ? const EdgeInsetsDirectional.only(end: AdminSpacing.xs)
            : const EdgeInsetsDirectional.only(start: AdminSpacing.xxs),
        child: Text(
          '*',
          style: context.type.fieldLabel.copyWith(
            color: context.colors.dangerText,
          ),
        ),
      ),
    );
  }
}

/// The helper line under a field's label, explaining what to enter:
/// [AdminTypography.fieldDescription], in [AdminPalette.foregroundMuted].
class FieldDescription extends StatelessWidget {
  final String text;

  const FieldDescription(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.type.fieldDescription);
  }
}

/// A field's validation line under its control: [error] in the danger text
/// colour wins over [pending], which wins over [warning] in the warning
/// colour; with none of them it renders nothing.
///
/// A small glyph (`iconSizes.sm`) starts the line flush with the field's
/// edge, centred on the first line of text, and the text follows it 6 on; a
/// wrapped line keeps to the text's indent. Nothing paints outside the
/// widget, so a clipping card or a field at the page gutter keeps the glyph.
/// The type is [AdminTypography.fieldMessage] (weight 500). An error is a
/// live region, so a screen reader announces it as it appears.
///
/// While [pending], the line says the value is being checked: a [Spinner]
/// for the glyph and "Checking…", both in [AdminPalette.foregroundMuted]. It
/// is the height of a one-line message, so it fits the room a field keeps
/// for one, and is announced as it appears; with animations off the spinner
/// holds still.
class FieldMessage extends StatelessWidget {
  final String? error;
  final String? warning;

  /// The field's value is being checked (an async validator is running).
  final bool pending;

  const FieldMessage({
    super.key,
    this.error,
    this.warning,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = this.error;
    final message = error ?? (pending ? null : warning);
    if (message == null && !pending) return const SizedBox.shrink();
    final color = error != null
        ? colors.dangerText
        : message == null
        ? colors.foregroundMuted
        : colors.warningText;
    final style = context.type.fieldMessage.copyWith(color: color);
    final line = style.fontSize! * (style.height ?? 1);
    final glyph = context.iconSizes.sm;
    Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: line,
          child: message == null
              ? Center(
                  widthFactor: 1,
                  child: Spinner(size: glyph, color: color, announce: false),
                )
              : Icon(
                  error != null
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: glyph,
                  color: color,
                ),
        ),
        const Gap(AdminSpacing.sm),
        Expanded(
          child: Text(
            message ?? context.adminL10n.fields.checking,
            style: style,
          ),
        ),
      ],
    );
    if (error != null || message == null) {
      row = Semantics(container: true, liveRegion: true, child: row);
    }
    return row;
  }
}

/// A red validation message under a control, for inline validation outside
/// a [LabeledField] — a [FieldMessage] error 8 below the control.
class FieldErrorText extends StatelessWidget {
  final String message;

  const FieldErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.md),
      child: FieldMessage(error: message),
    );
  }
}
