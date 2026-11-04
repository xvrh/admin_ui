import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/field_feedback_scope.dart';
import '../../common/ui/field_presence.dart';
import '../../common/ui/field_registry.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/labeled_field.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/tabs.dart';
import '../../common/ui/tappable.dart';
import '../../history/diff_model.dart' show DiffFieldKind;
import '../../history/ui/quick_diff.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/contrast.dart';
import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'change_scope.dart';
import 'history_button.dart';

/// Shared chrome for a single field: the label row with its trailing capability
/// cluster (help / language / comments / history) and the draft-override tint.
/// Each field type supplies its own [child] body — a text input, a media grid…
///
/// The label turns primary when the body is live: the shell observes focus on
/// any descendant of [child], so bodies need not report it. [active] forces it
/// on for bodies with no focusable control.
///
/// The body is built under a [FieldStateScope] of [enabled], [readOnly] and
/// the [errorText], so every kit body inside turns disabled, read-only or red
/// with the field; see [FieldState] for how read-only and disabled differ.
///
/// Layout, on the 4px grid: the label row is the 24px inline slot — the
/// label, its [FieldRequiredMarker] and every capability centred in it, so a
/// field with capabilities lines up with one without — then the
/// [description] 4 below, the body 8 below that and the [errorText] or
/// [warning] 8 below the body — or, with [reserveErrorLine], the room for one
/// line of it while there is none. While the ambient [FieldFeedbackScope]
/// has the field's value being checked, that line says so (see
/// [FieldMessage.pending]), unless there is an error.
/// A field too narrow to keep its label beside the language, comments and
/// history capabilities wraps them onto a line of their own under it.
///
/// For assistive technology the body is named by the label, marked required
/// when [required], and carries the error (or else the description) as its
/// hint; see [mergeSemantics].
class FieldShell extends StatefulWidget {
  final String label;

  /// Stable id (a [Cell.id]) this field registers under for ⌘K "jump to
  /// field", reports focus and presence with, and looks up its pending check
  /// by. Without one the field still registers, under a key of its own, but
  /// neither reports focus nor shows presence. No registry in scope ⇒ no-op.
  final String? fieldId;

  /// Forces the live, primary label on, OR-ed with observed descendant focus.
  /// For bodies that carry no focusable control (e.g. a media grid).
  final bool active;

  /// Capability shown right beside the label (e.g. a [HelpButton]).
  final Widget? help;

  /// Capability shown at the far end of the label row (e.g. a language pill).
  final Widget? language;

  /// Capability shown in the trailing cluster (e.g. a comments button).
  final Widget? comments;

  /// Capability shown in the trailing cluster (e.g. a history/draft button).
  final Widget? history;

  /// The draft differs from the baseline — shows a quiet "Edited" marker in
  /// the label row, unless a [HistoryButton] in [history] already shows it.
  final bool modified;

  /// Optional detail appended to the marker, e.g. the changed locale codes
  /// ("FR, NL"). Null shows just "Edited".
  final String? modifiedDetail;

  /// Marks the field required: the body is announced as required, and the
  /// label carries the theme's [FieldRequiredMarker].
  final bool required;

  /// A caption line under the label explaining what to enter.
  final String? description;

  /// False disables the body (through the [FieldStateScope]) and dims the
  /// label.
  final bool enabled;

  /// Shows the body's value without letting it change; see [FieldState].
  final bool readOnly;

  /// Whether the label and the body are merged into one node: right only for
  /// a body that is one control announcing itself as a button — a select
  /// trigger, a toggle — which then reads "Status, In review, button".
  ///
  /// Off by default, which leaves the body's nodes as they are: the label
  /// names a lone text input directly, and around several controls (a radio
  /// set, a list with remove buttons, per-language lanes) it names a group in
  /// which each control stays a node of its own that can be reached and
  /// pressed.
  final bool mergeSemantics;

  final Widget child;

  /// Validation line under the body. [errorText] (red) wins over [warning]
  /// (amber); an error also turns the body's outline red.
  final String? errorText;
  final String? warning;

  /// Keeps the room of a one-line message under the body while there is
  /// none, so a message appearing on validation does not push the rest of
  /// the form down. A message that wraps still grows the field.
  ///
  /// Null follows the ambient [FieldFeedbackScope] (a form engine's), and
  /// reserves nothing outside one.
  final bool? reserveErrorLine;

  const FieldShell({
    super.key,
    required this.label,
    required this.child,
    this.fieldId,
    this.active = false,
    this.help,
    this.language,
    this.comments,
    this.history,
    this.modified = false,
    this.modifiedDetail,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.mergeSemantics = false,
    this.errorText,
    this.warning,
    this.reserveErrorLine,
  });

  @override
  State<FieldShell> createState() => _FieldShellState();
}

class _FieldShellState extends State<FieldShell> {
  static var _shells = 0;

  bool _focused = false;

  /// Parents the body's focus subtree so tapping the label can focus the body's
  /// first focusable control (a no-op when the body has none).
  final FocusNode _bodyFocus = FocusNode();

  /// The registry key of a field without a [FieldShell.fieldId]: this
  /// field's own, so two fields with one label stay apart.
  final _ownKey = 'shell#${_shells++}';

  FormFieldRegistry? _registry;
  FormFieldEntry? _entry;
  TextDirection? _direction;
  PresenceChannel? _presence;
  bool _inTree = true;

  bool get _active => widget.active || _focused;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presence = FieldPresenceScope.maybeOf(context);
    final registry = FormFieldScope.maybeOf(context);
    final direction = Directionality.of(context);
    if (registry == _registry && direction == _direction) return;
    _unregister();
    _registry = registry;
    _direction = direction;
    _register();
  }

  @override
  void didUpdateWidget(FieldShell old) {
    super.didUpdateWidget(old);
    if (old.fieldId == widget.fieldId && old.label == widget.label) return;
    _unregister();
    _register();
  }

  void _register() {
    final registry = _registry;
    if (registry == null) return;
    final entry = FormFieldEntry(
      id: widget.fieldId ?? _ownKey,
      label: widget.label,
      focus: _jumpHere,
      bounds: _bounds,
      textDirection: _direction,
    );
    _entry = entry;
    registry.register(entry);
  }

  void _unregister() {
    final entry = _entry;
    if (entry != null) _registry?.unregister(entry.id, entry);
    _entry = null;
  }

  @override
  void activate() {
    super.activate();
    _inTree = true;
  }

  @override
  void deactivate() {
    _inTree = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _unregister();
    _bodyFocus.dispose();
    super.dispose();
  }

  /// Where this field is on screen, for the registry's reading order; null
  /// while it is out of the tree, on a tab in the background or not laid out.
  Rect? _bounds() {
    if (!mounted || !_inTree) return null;
    if (TabScope.maybeOf(context)?.isActive == false) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _focusBody() {
    var focusable = _bodyFocus.traversalDescendants;
    if (focusable.isNotEmpty) focusable.first.requestFocus();
  }

  /// Frame the body with a remote peer's ring + name badge while they edit this
  /// field. No-op (returns [body] untouched) when presence is off or the
  /// field has no id to be found by.
  Widget _withPresence(Widget body) {
    final channel = _presence;
    final fieldId = widget.fieldId;
    if (channel == null || fieldId == null) return body;
    return FieldPresenceRing(channel: channel, fieldId: fieldId, child: body);
  }

  /// Report focus to the ambient [FieldFocusScope] (the preview highlight), keyed
  /// by the field id. Only on *gaining* focus — the highlight persists on the
  /// last-focused field until another takes over, so clicking into the preview
  /// or elsewhere doesn't clear it.
  void _reportFocus(bool focused) {
    final fieldId = widget.fieldId;
    if (!focused || fieldId == null) return;
    FieldFocusScope.maybeOf(context)?.onFocus(fieldId);
    // Publish which field we're in so peers can frame it. One field at a time
    // (last focus wins); it lingers on the last field like the preview
    // highlight, so clicking outside all fields doesn't clear the ring.
    _presence?.setLocalField(fieldId);
  }

  /// "Jump to field" (⌘K, a comment anchor, search): if this field sits on a
  /// hidden tab, switch to it first, then scroll into view and focus the body.
  /// Switching remounts nothing (tabs stay in an IndexedStack), but the target
  /// scroll view must be on screen before [Scrollable.ensureVisible] can move
  /// it, so we wait a frame after activating.
  void _jumpHere() {
    if (!mounted) return;
    final tab = TabScope.maybeOf(context);
    if (tab != null && !tab.isActive) {
      tab.activate();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollIntoView());
    } else {
      _scrollIntoView();
    }
  }

  void _scrollIntoView() {
    if (!mounted) return;
    _focusBody();
    // A zero duration (reduced motion) jumps.
    Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: context.motion.slow,
      curve: context.motion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    final warning = widget.warning;
    final description = widget.description;
    final merge = widget.mergeSemantics;
    final fieldId = widget.fieldId;
    final pending =
        fieldId != null && FieldFeedbackScope.isPending(context, fieldId);
    final reserve =
        widget.reserveErrorLine ??
        FieldFeedbackScope.reserveErrorLineOf(context);
    Widget body = Semantics(
      label: widget.label,
      hint: error ?? description,
      isRequired: widget.required ? true : null,
      validationResult: error != null
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: _withPresence(
        Focus(
          focusNode: _bodyFocus,
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (f) {
            setState(() => _focused = f);
            _reportFocus(f);
          },
          child: widget.child,
        ),
      ),
    );
    if (merge) body = MergeSemantics(child: body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        if (description != null) ...[
          const Gap(AdminSpacing.xs),
          // Read as the body's hint.
          ExcludeSemantics(child: FieldDescription(description)),
        ],
        const Gap(AdminSpacing.md),
        FieldStateScope(
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          invalid: error != null,
          child: body,
        ),
        if (error != null || warning != null || pending) ...[
          const Gap(AdminSpacing.md),
          FieldMessage(error: error, warning: warning, pending: pending),
        ] else if (reserve) ...[
          const Gap(AdminSpacing.md),
          SizedBox(height: lineHeightOf(context, context.type.fieldMessage)),
        ],
      ],
    );
  }

  /// The quiet field-level draft cue in the label row: an amber dot + a word,
  /// with optional [FieldShell.modifiedDetail] (e.g. the changed locales).
  /// When the ambient [ChangeScope] can resolve this field's diff, the marker
  /// opens a [FieldQuickDiff] popover.
  Widget _draftMarker() {
    final detail = widget.modifiedDetail;
    final marker = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: context.colors.warning,
            shape: BoxShape.circle,
          ),
        ),
        const Gap(AdminSpacing.sm),
        Flexible(
          child: Text(
            detail == null
                ? context.adminL10n.edited
                : context.adminL10n.fields.editedDetail(detail),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type
                .weighted(context.type.caption, FontWeight.w600)
                .copyWith(color: context.colors.warningText),
          ),
        ),
      ],
    );

    final scope = ChangeScope.readOf(context);
    final fieldId = widget.fieldId;
    if (scope == null || fieldId == null) return marker;
    return Popover(
      autofocus: false,
      // Kept to the label's line height: a taller target would push the
      // body down the moment a field turns modified.
      anchor: (context, controller) => Tappable(
        onTap: controller.toggle,
        expanded: controller.isOpen,
        focusRadius: context.radii.radiusSmall,
        child: marker,
      ),
      content: (context, controller) {
        final diff = scope.current.diffOf(fieldId);
        if (diff == null) return const SizedBox.shrink();
        // Rich fields revert per block (the gutter bars — undoable); the
        // whole-field hammer stays off them.
        final revert = diff.kind == DiffFieldKind.richText
            ? null
            : scope.onRevertField;
        return FieldQuickDiff(
          diff,
          onRevert: revert == null
              ? null
              : () {
                  controller.close();
                  revert(fieldId);
                },
        );
      },
    );
  }

  /// A capability in the label row, held to the 24px inline slot so the row
  /// is the same height with or without it; one with text grows past it with
  /// its text at a large text size.
  Widget _slot(Widget capability) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: IconActionSize.inline.box),
    child: Center(widthFactor: 1, heightFactor: 1, child: capability),
  );

  Widget _header() {
    final colors = context.colors;
    final enabled = widget.enabled && FieldStateScope.of(context).enabled;
    final labelColor = !enabled
        ? colors.foregroundSubtle
        : _active
        ? colors.primaryText
        : _labelColor(colors);
    final history = widget.history;
    final historyShowsEdit = history is HistoryButton && history.modified;
    final capabilities = [
      if (widget.language case final language?) _slot(language),
      if (widget.comments case final comments?) _slot(comments),
      if (history != null) _slot(history),
    ];
    final markLeads = FieldRequiredMarker.leadsLabel(context);
    final mark = FieldRequiredMarker(
      required: widget.required,
      fieldId: widget.fieldId,
    );
    return _LabelRow(
      textDirection: Directionality.of(context),
      label: Row(
        children: [
          // Pointer-only, like an HTML label: the text is read with the
          // body below, and the body is the Tab stop.
          Flexible(
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _focusBody,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (markLeads) mark,
                    Flexible(
                      child: Text(
                        context.type.fieldLabelText(widget.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.fieldLabel.copyWith(
                          color: labelColor,
                        ),
                      ),
                    ),
                    if (!markLeads) mark,
                  ],
                ),
              ),
            ),
          ),
          if (widget.help case final help?) ...[
            // 7px to the dot, which sits 3px into its hit box.
            const Gap(AdminSpacing.xs),
            _slot(help),
          ],
          if (widget.modified && !historyShowsEdit) ...[
            const Gap(AdminSpacing.md),
            Flexible(child: _draftMarker()),
          ],
        ],
      ),
      capabilities: capabilities.isEmpty
          ? null
          : Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AdminSpacing.xs,
              runSpacing: AdminSpacing.xs,
              children: capabilities,
            ),
    );
  }
}

enum _LabelRowSlot { label, capabilities }

/// A field's label row: the [label] block at the start and the
/// [capabilities] cluster at the end, each centred on a line at least the
/// 24px inline slot tall. They share the line while the label keeps
/// [_RenderLabelRow.labelRoom] beside the cluster (or its whole width, when
/// shorter), the label ellipsising first; on a field narrower than that the
/// cluster moves onto a line of its own under the label, still at the end,
/// rather than overflow.
class _LabelRow
    extends SlottedMultiChildRenderObjectWidget<_LabelRowSlot, RenderBox> {
  final Widget label;
  final Widget? capabilities;
  final TextDirection textDirection;

  const _LabelRow({
    required this.label,
    required this.capabilities,
    required this.textDirection,
  });

  @override
  Iterable<_LabelRowSlot> get slots => _LabelRowSlot.values;

  @override
  Widget? childForSlot(_LabelRowSlot slot) => switch (slot) {
    _LabelRowSlot.label => label,
    _LabelRowSlot.capabilities => capabilities,
  };

  @override
  _RenderLabelRow createRenderObject(BuildContext context) =>
      _RenderLabelRow(textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderLabelRow renderObject) {
    renderObject.textDirection = textDirection;
  }
}

class _RenderLabelRow extends RenderBox
    with SlottedContainerRenderObjectMixin<_LabelRowSlot, RenderBox> {
  _RenderLabelRow({required this._textDirection});

  /// What the label block keeps before the capabilities give way: a dozen
  /// characters of label and its help dot.
  static const labelRoom = 96.0;

  /// Between the label block and the capabilities beside it.
  static const _gap = AdminSpacing.md;

  /// Between the label's line and the capabilities wrapped under it.
  static const _runGap = AdminSpacing.xs;

  static final _line = IconActionSize.inline.box;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _label => childForSlot(_LabelRowSlot.label)!;
  RenderBox? get _capabilities => childForSlot(_LabelRowSlot.capabilities);

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _label.getMinIntrinsicWidth(height),
    _capabilities?.getMinIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final capabilities = _capabilities?.getMaxIntrinsicWidth(height);
    return _label.getMaxIntrinsicWidth(height) +
        (capabilities == null ? 0 : _gap + capabilities);
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
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final rtl = _textDirection == TextDirection.rtl;
    double x(double start, double w) => rtl ? width - start - w : start;

    final capabilities = _capabilities;
    final capabilitiesSize = capabilities == null
        ? Size.zero
        : layoutChild(capabilities, BoxConstraints(maxWidth: width));
    final beside = width - capabilitiesSize.width - _gap;
    final wanted = math.min(
      labelRoom,
      _label.getMaxIntrinsicWidth(double.infinity),
    );
    final inline = capabilities == null || beside >= wanted;

    final labelSize = layoutChild(
      _label,
      BoxConstraints(
        maxWidth: math.max(0, capabilities != null && inline ? beside : width),
      ),
    );
    final labelLine = math.max(
      _line,
      inline
          ? math.max(labelSize.height, capabilitiesSize.height)
          : labelSize.height,
    );
    final offsets = <(RenderBox, Offset)>[
      (
        _label,
        Offset(x(0, labelSize.width), (labelLine - labelSize.height) / 2),
      ),
    ];
    var height = labelLine;
    if (capabilities != null) {
      final start = width - capabilitiesSize.width;
      if (inline) {
        offsets.add((
          capabilities,
          Offset(
            x(start, capabilitiesSize.width),
            (labelLine - capabilitiesSize.height) / 2,
          ),
        ));
      } else {
        final line = math.max(_line, capabilitiesSize.height);
        offsets.add((
          capabilities,
          Offset(
            x(start, capabilitiesSize.width),
            labelLine + _runGap + (line - capabilitiesSize.height) / 2,
          ),
        ));
        height += _runGap + line;
      }
    }
    return (size: constraints.constrain(Size(width, height)), offsets: offsets);
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

/// The resting label colour: [AdminPalette.foregroundMuted] where it reads at
/// 4.5:1 on both the page and a boxed group, otherwise the stronger
/// [AdminPalette.foregroundSecondary].
Color _labelColor(AdminPalette c) =>
    contrastRatio(c.foregroundMuted, c.surface) >= 4.5 &&
        contrastRatio(c.foregroundMuted, c.background) >= 4.5
    ? c.foregroundMuted
    : c.foregroundSecondary;
