import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/focus_ring.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/tag.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../theme/sizes.dart';
import '../../theme/tokens.dart';

// The field bodies' tap target moved to the common layer so non-field widgets
// can share it; re-exported here for the bodies that still import it by name.
export '../../common/ui/tappable.dart';

/// Shared low-level pieces used across the field bodies, kept in one place so
/// they can't drift between field types.

/// The add action of a collection body — a key–value row, a repeater item, a
/// linked reference, a file: a small ghost [Button] with a leading [icon], so
/// every body adds the same way. One Tab stop that Enter and Space press,
/// named by [label] ("Add row", "Link…"). It keeps its own width at the start
/// of its column, flush with it: its glyph lines up with the rows above (see
/// `Button.flush`). A null [onPressed] disables it.
class AddRowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  /// Whether the popover the button opens is showing, announced as its
  /// expanded state; null for a button that adds in place.
  final bool? expanded;

  final FocusNode? focusNode;

  const AddRowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.expanded,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Button.ghost(
      label,
      icon: icon,
      size: ControlSize.small,
      flush: true,
      focusNode: focusNode,
      onPressed: onPressed,
    );
    if (expanded != null) {
      button = Semantics(expanded: expanded, child: button);
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: button,
    );
  }
}

/// A value in a field's box of tokens — a free tag, a chosen option: the
/// kit's [Tag] in the primary tone, muted under a disabled
/// [FieldStateScope], with an optional [leading] glyph and a × that calls
/// [onRemove]. The tags and multi-select bodies both draw it, so their chips
/// match in every theme.
class FieldToken extends StatelessWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onRemove;

  const FieldToken(this.label, {super.key, this.leading, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = FieldStateScope.of(context).enabled;
    return Tag(
      label,
      color: enabled ? colors.primary : colors.foregroundMuted,
      leading: leading,
      onRemove: onRemove,
    );
  }
}

/// Small circular icon button (remove / retry) overlaid on tiles and rows: a
/// 22px bordered disc in a 24px hit box. [label] is its accessible name and
/// tooltip.
class CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
  });

  static const _disc = 22.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tip(
      message: label,
      excludeFromSemantics: true,
      child: Tappable.states(
        onTap: onTap,
        semanticLabel: label,
        excludeSemantics: true,
        showFocusRing: false,
        builder: (context, states) {
          final active =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed);
          final overlay = states.contains(WidgetState.pressed)
              ? colors.pressedOverlay
              : (active ? colors.hoverOverlay : null);
          return SizedBox.square(
            dimension: IconActionSize.inline.box,
            child: Center(
              child: FocusRing(
                focused: states.contains(WidgetState.focused),
                radius: _disc / 2,
                child: Container(
                  width: _disc,
                  height: _disc,
                  decoration: BoxDecoration(
                    color: overlay == null
                        ? colors.surface
                        : Color.alphaBlend(overlay, colors.surface),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    icon,
                    size: context.iconSizes.sm,
                    color: active
                        ? colors.foregroundSecondary
                        : colors.foregroundMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Builds a field body under the ambient [FieldStateScope] with the body's
/// own flags folded in — a false [enabled] disables, a true [readOnly] or
/// [invalid] adds — so the chrome, `fieldInputDecoration`, `fieldTextStyle`
/// and a [ClearButton] or [FieldChevron] inside all draw the same state. An
/// enclosing scope's validation error carries through.
///
/// The scope is always there, so a flag that flips while the user types (a
/// value going out of range) never rebuilds the control underneath it.
class FieldBodyScope extends StatelessWidget {
  final bool enabled;
  final bool readOnly;
  final bool invalid;
  final WidgetBuilder builder;

  const FieldBodyScope({
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FieldStateScope(
      enabled: enabled,
      readOnly: readOnly,
      invalid: invalid || FieldStateScope.of(context).invalid,
      child: Builder(builder: builder),
    );
  }
}

/// What a collection body (tags, key–value pairs, references, media) shows
/// when it holds nothing and cannot be edited: its field box, read-only, with
/// [label] — a neutral "No tags", never an instruction like "Add a tag…" — in
/// the muted text colour. Under a disabled [FieldStateScope] it takes the
/// disabled fill.
Widget readOnlyEmpty(BuildContext context, String label) {
  return FieldChrome(
    readOnly: true,
    child: Builder(
      builder: (context) {
        final colors = context.colors;
        final enabled = FieldStateScope.of(context).enabled;
        return Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.type.fieldText.copyWith(
            color: enabled ? colors.foregroundMuted : colors.foregroundSubtle,
          ),
        );
      },
    ),
  );
}
