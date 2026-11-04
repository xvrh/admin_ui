import 'package:material_ui/material_ui.dart';

import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/stroke.dart';
import '../../theme/tokens.dart';
import 'control_label.dart';
import 'focus_ring.dart';
import 'tappable.dart';

/// A token-styled checkbox (the Flutter `Checkbox` renamed to dodge the
/// collision). [value]/[onChanged]; with a [label] it's a tappable row that
/// hugs the label, otherwise just the box.
///
/// A Tab stop that Space and Enter toggle, announced as a checkbox with its
/// checked (or mixed) state. Keyboard focus rings the box.
///
/// A null [onChanged] disables it: the box greys and it leaves the Tab
/// order. [readOnly] shows the value at full contrast without letting it
/// change — still a Tab stop, announced read-only, with no hover (see
/// `FieldState`).
class Check extends StatelessWidget {
  final bool value;

  /// Shows a dash instead of a tick — for a "some selected" select-all box.
  /// Treated as filled; tapping reports `true` (check) via [onChanged], as
  /// Radix's and Material's mixed checkboxes do, so a select-all box goes
  /// from some to all.
  final bool indeterminate;
  final ValueChanged<bool>? onChanged;
  final String? label;

  /// Names a box shown without a [label], e.g. "Select row 3" in a table.
  final String? semanticLabel;

  /// Reports, and can seed, the hovered, pressed and focused states — e.g. to
  /// pin a state in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  /// Shows [value] at full contrast, taking no input; see [Check].
  final bool readOnly;

  const Check({
    super.key,
    required this.value,
    this.indeterminate = false,
    this.onChanged,
    this.label,
    this.semanticLabel,
    this.statesController,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final editable = onChanged != null && !readOnly;
    // Read-only keeps the enabled look; only a missing onChanged dims it.
    final enabled = editable || readOnly;
    final check = Tappable.states(
      onTap: editable ? () => onChanged!(indeterminate || !value) : null,
      readOnly: readOnly,
      checked: value,
      mixed: indeterminate ? true : null,
      semanticLabel: semanticLabel,
      statesController: statesController,
      showFocusRing: false,
      builder: (context, states) {
        final box = FocusRing(
          focused: states.contains(WidgetState.focused),
          radius: context.radii.radiusCheck,
          child: _box(
            context,
            enabled: enabled,
            hovered: editable && states.contains(WidgetState.hovered),
          ),
        );
        if (label == null) return box;
        final style = context.type.body.copyWith(
          color: enabled
              ? context.colors.foreground
              : context.colors.foregroundSubtle,
        );
        return minTarget(
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              onFirstLine(context, box, label!, style),
              const Gap(AdminSpacing.md),
              Flexible(child: Text(label!, style: style)),
            ],
          ),
        );
      },
    );
    if (label == null) return check;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: check,
    );
  }

  /// Filled with [AdminPalette.controlAccent] and an
  /// [AdminPalette.onControlAccent] glyph when on, its hover shade under the
  /// pointer; an [AdminPalette.controlBorder] outline
  /// ([AdminStroke.controlStrong]) when off, which takes
  /// the [offHoverOutline] under the pointer. Disabled, the fill drops to the
  /// disabled grey with a knocked-out glyph.
  Widget _box(
    BuildContext context, {
    required bool enabled,
    required bool hovered,
  }) {
    final colors = context.colors;
    final on = value || indeterminate;
    final Color fill;
    final Color border;
    if (!enabled) {
      fill = on ? colors.foregroundSubtle : Colors.transparent;
      border = on ? colors.foregroundSubtle : colors.foregroundFaint;
    } else if (on) {
      fill = hovered ? colors.controlAccentHover : colors.controlAccent;
      border = fill;
    } else {
      fill = Colors.transparent;
      border = hovered ? offHoverOutline(colors) : colors.controlBorder;
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(context.radii.radiusCheck),
        border: Border.all(
          color: border,
          width: on ? 0 : context.stroke.controlStrong,
        ),
      ),
      child: on
          ? Icon(
              indeterminate ? Icons.remove_rounded : Icons.check_rounded,
              size: context.iconSizes.sm,
              color: enabled ? colors.onControlAccent : colors.surface,
            )
          : null,
    );
  }
}
