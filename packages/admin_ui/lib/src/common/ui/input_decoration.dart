/// @docImport '../../theme/radii.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'field_chrome.dart';
import 'icon_action.dart';

/// Shared input decoration for field controls — the theme's field chrome
/// ([buildInputDecorationTheme]: a [FieldBorder] in the theme's anatomy at
/// [AdminRadii.radiusField], a stronger edge under the pointer, the focus
/// indicator on focus), so fields read as editable whatever the ambient
/// input theme. Inside a [ChromelessFieldScope] the host draws the chrome,
/// so this collapses to a bare, border-less decoration with no padding that
/// keeps the hint style, [leadingIcon] and [suffix].
///
/// The state comes from the ambient [FieldStateScope], with [invalid] and
/// [readOnly] OR-ed in: invalid turns the border red so a failed validation
/// reads on the control itself; read-only drops the hover; a disabled scope
/// disables the decoration, and so a [TextField] that leaves its own
/// `enabled` unset. A body still passes `readOnly` to its [TextField] itself
/// (see [FieldState]), and styles its text with [fieldTextStyle].
///
/// The field is exactly the [size]'s control height (`context.sizes`) for any
/// single line of text, and grows only for more (a multi-line box, a large
/// text scale). Its text starts `fieldPaddingX` in, or after a
/// [leadingIcon] — a 16px glyph at `fieldPaddingX` — at `fieldIconInset`.
/// [suffix] (a [ClearButton], a [FieldChevron], a reveal [IconAction]) sits
/// in a 24px slot whose glyph lines up with `fieldPaddingX` at the end; the
/// text then stops `fieldIconInset` from the end. [trailing] is an action
/// just before it, in a 24px slot of its own — a clear before a chevron, as
/// [FieldTrigger] places them — and moves the text's end in by that slot.
/// The slots can never grow the field. [hovered] pins the hover edge (and a
/// filled field's hover fill), e.g. in a catalog.
InputDecoration fieldInputDecoration(
  BuildContext context, {
  String? hint,
  bool invalid = false,
  ControlSize size = ControlSize.medium,
  IconData? leadingIcon,
  Widget? suffix,
  Widget? trailing,
  bool readOnly = false,
  bool hovered = false,
}) {
  final tokens = context.adminTokens;
  final palette = tokens.palette;
  final sizes = tokens.sizes;
  final state = FieldStateScope.of(context)
      .merge(readOnly: readOnly, invalid: invalid);
  final hintStyle = tokens.typography.fieldText.copyWith(
    color: palette.placeholder,
  );
  // Material 3 keeps 4px between an icon slot and the text.
  final iconGap = Theme.of(context).useMaterial3 ? 4.0 : 0.0;
  final slot = IconActionSize.inline.box;
  final glyph = leadingIcon == null
      ? null
      : Icon(
          leadingIcon,
          size: sizes.fieldIcon,
          color: state.iconColor(palette),
        );
  // The slot is a semantics node of its own: without one, a tooltip inside
  // the decorator's suffix keeps its action in the tree as an invisible node
  // once a scroll view has clipped the action away but not the field.
  Widget? action(Widget? child) => child == null
      ? null
      : FieldStateScope(
          enabled: state.enabled,
          readOnly: state.readOnly,
          invalid: state.invalid,
          child: Semantics(container: true, child: child),
        );
  // [trailing] then [suffix], each centred in a 24px slot.
  final slots = suffix == null && trailing == null
      ? null
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final glyph in [?trailing, ?suffix])
              SizedBox.square(
                dimension: slot,
                child: Center(child: glyph),
              ),
          ],
        );
  final slotsWidth =
      (trailing == null ? 0.0 : slot) + (suffix == null ? 0.0 : slot);

  if (ChromelessFieldScope.of(context)) {
    // No box and no padding, but the glyph and the action stay.
    final lead = sizes.fieldIcon + sizes.fieldIconGap - iconGap;
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      enabled: state.enabled,
      isDense: true,
      filled: false,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      prefixIcon: glyph == null
          ? null
          : Align(alignment: AlignmentDirectional.centerStart, child: glyph),
      prefixIconConstraints: glyph == null
          ? null
          : BoxConstraints.tightFor(width: lead),
      suffixIcon: action(slots),
      suffixIconConstraints: slots == null
          ? null
          : BoxConstraints.tight(Size(slotsWidth, slot)),
    );
  }

  Set<WidgetState> resolved(Set<WidgetState> states) {
    final hover =
        (hovered || states.contains(WidgetState.hovered)) && !state.readOnly;
    return {
      ...states.where((s) => s != WidgetState.hovered),
      if (!state.enabled) WidgetState.disabled,
      if (state.invalid) WidgetState.error,
      if (hover) WidgetState.hovered,
    };
  }

  final radius = BorderRadius.circular(tokens.radii.radiusField);

  final height = sizes.height(size);
  final glyphInset = (slot - sizes.fieldIcon) / 2;
  // The prefix is always there: sized to the control height, it holds the
  // field at that height whatever the font's line box, and it replaces the
  // start padding, so the text starts at the same x with or without a glyph.
  final leadWidth =
      (leadingIcon == null ? sizes.fieldPaddingX : sizes.fieldIconInset) -
      iconGap;
  final trailWidth =
      sizes.fieldIconInset - iconGap + (slotsWidth > slot ? slot : 0);
  return InputDecoration(
    hintText: hint,
    hintStyle: hintStyle,
    enabled: state.enabled,
    isDense: true,
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => resolveFieldChrome(tokens, resolved(states)).fill,
    ),
    hoverColor: const Color(0x00000000),
    contentPadding: EdgeInsets.symmetric(
      horizontal: sizes.fieldPaddingX,
      vertical: fieldPaddingY(tokens.typography, height),
    ),
    border: FieldBorder.of(tokens, borderRadius: radius, mapStates: resolved),
    prefixIcon: SizedBox(
      width: leadWidth,
      height: height,
      child: glyph == null
          ? null
          : Padding(
              padding: EdgeInsetsDirectional.only(start: sizes.fieldPaddingX),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: glyph,
              ),
            ),
    ),
    prefixIconConstraints: BoxConstraints.tightFor(
      width: leadWidth,
      height: height,
    ),
    suffixIcon: action(
      slots == null
          ? null
          : SizedBox(
              width: trailWidth,
              height: height,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: sizes.fieldPaddingX - glyphInset,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: slots,
                ),
              ),
            ),
    ),
    suffixIconConstraints: slots == null
        ? null
        : BoxConstraints.tightFor(width: trailWidth, height: height),
  );
}

/// The text style of a field's value: [AdminTypography.fieldText] — body type
/// on the fixed line box the control heights are built around — in the
/// [FieldState.textColor] of the ambient [FieldStateScope], with [enabled]
/// folded in. Every body styles its [TextField] or value [Text] with it, so
/// none falls back to Material's 16px `bodyLarge`.
TextStyle fieldTextStyle(BuildContext context, {bool enabled = true}) {
  final state = FieldStateScope.of(context).merge(enabled: enabled);
  return context.type.fieldText.copyWith(
    color: state.textColor(context.colors),
  );
}
