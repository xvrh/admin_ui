import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/input_decoration.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// The bare free-text tag control — a box of removable token chips with an
/// inline add input, no label or capability chrome. Like the other bodies it
/// sits inside a [FieldShell] or one lane of a translatable field. The value is
/// an ordered `List<String>`; duplicates are rejected.
///
/// Type and press enter to add; the × on a chip (or backspace on the empty
/// input) removes one. The chips are [FieldToken]s, the multi-select's
/// tokens. The box is the control height on one row: the chips and the input
/// are the 24px inline row, inset evenly from the border.
///
/// A null [onChanged] renders it read-only: the chips at full contrast, no
/// input and no removes; with no tags, the box shows [emptyLabel]. [enabled]
/// false, or a disabled [FieldStateScope], disables it.
///
/// For a tag picker constrained to a known set, use `MultiSelectBody` with
/// `creatable: true` instead — this body is the unconstrained, order-preserving
/// case.
class TagsBody extends StatefulWidget {
  final List<String> value;
  final ValueChanged<List<String>>? onChanged;

  /// The input's placeholder; null reads "Add a tag…" in the app's language.
  final String? hint;

  /// Shown in the box when read-only with no tags; null reads "No tags".
  final String? emptyLabel;

  final bool enabled;

  const TagsBody({
    super.key,
    this.value = const [],
    this.onChanged,
    this.hint,
    this.emptyLabel,
    this.enabled = true,
  });

  @override
  State<TagsBody> createState() => _TagsBodyState();
}

class _TagsBodyState extends State<TagsBody> {
  final _add = TextEditingController();
  final _focus = FocusNode();
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _add.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _submit(String raw) {
    final v = raw.trim();
    _add.clear();
    if (v.isEmpty || widget.value.contains(v)) return;
    widget.onChanged?.call([...widget.value, v]);
  }

  void _removeAt(int i) =>
      widget.onChanged?.call([...widget.value]..removeAt(i));

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _add.text.isEmpty &&
        widget.value.isNotEmpty) {
      _removeAt(widget.value.length - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: widget.onChanged == null,
      builder: _build,
    );
  }

  Widget _build(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    if (!editable && widget.value.isEmpty) {
      return readOnlyEmpty(
        context,
        state.readOnly ? _emptyLabel(context) : _hint(context),
      );
    }

    final row = IconActionSize.inline.box;
    // The chips sit as far in from the border as the row is from the top.
    final inset = math.max(
      0.0,
      (context.sizes.medium - 2 * context.stroke.control - row) / 2,
    );
    final gap = AdminSpacing.xs;

    // Pointer-only: a click on the box's free space lands in the input, which
    // is itself the Tab stop and the node assistive technology reads. An
    // input's chips and hint are no place for a selection from above; the
    // input selects its own text.
    return CursorRegion(
      cursor: editable ? SystemMouseCursors.text : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: editable ? _focus.requestFocus : null,
        child: FieldChrome(
          active: _focus.hasFocus,
          hovered: _hovered,
          padding: EdgeInsets.all(inset),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < widget.value.length; i++)
                FieldToken(
                  widget.value[i],
                  onRemove: editable ? () => _removeAt(i) : null,
                ),
              if (editable) _input(context, inset),
            ],
          ),
        ),
      ),
    );
  }

  String _hint(BuildContext context) =>
      widget.hint ?? context.adminL10n.fields.addTag;

  String _emptyLabel(BuildContext context) =>
      widget.emptyLabel ?? context.adminL10n.fields.noTags;

  Widget _input(BuildContext context, double inset) {
    // With no chips the hint starts where every field's text does.
    final start = widget.value.isEmpty
        ? math.max(
            0.0,
            context.sizes.fieldPaddingX - context.stroke.control - inset,
          )
        : AdminSpacing.xs;
    return ConstrainedBox(
      // Wide enough that the always-on hint isn't clipped; IntrinsicWidth grows
      // it further as a long tag is typed.
      constraints: const BoxConstraints(minWidth: 110),
      child: IntrinsicWidth(
        child: SizedBox(
          height:
              IconActionSize.inline.box +
              textGrowthOf(context, fieldTextStyle(context)),
          // The collapsed field is one text line tall, centred in the row
          // like the chips' labels.
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
                controller: _add,
                focusNode: _focus,
                onSubmitted: _submit,
                style: fieldTextStyle(context),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  filled: false,
                  hintText: _hint(context),
                  hintStyle: context.type.fieldText.copyWith(
                    color: context.colors.placeholder,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsetsDirectional.only(
                    start: start,
                    end: AdminSpacing.xs,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
