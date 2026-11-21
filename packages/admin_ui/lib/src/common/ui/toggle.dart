/// @docImport '../../theme/palette.dart';
/// @docImport '../../theme/stroke.dart';
/// @docImport 'checkbox.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/contrast.dart';
import '../../theme/selection_style.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'control_label.dart';
import 'focus_ring.dart';
import 'tappable.dart';

/// A token-styled switch (the Flutter `Switch` renamed to dodge the collision).
/// [value]/[onChanged]; with a [label] it's a tappable row that hugs the
/// label, otherwise just the control.
///
/// It keeps its own size. In a box that stretches it, a form's control slot
/// or a column that fills its width, it stands at the start, centred in the
/// height, and only the switch (and its label) takes the tap.
///
/// A Tab stop that Space and Enter flip, announced as a switch with its on/off
/// state. Keyboard focus rings the track.
///
/// The theme's [AdminSelectionStyle] draws it as its reference system does
/// (see `context.selectionStyle`): the track's and the knob's sizes, a knob
/// that grows as it turns on, an off track that is filled or outlined, and
/// an on track in the accent or in the success colour.
///
/// A null [onChanged] disables it: the track greys, as a disabled [Check]'s
/// box does, and it leaves the Tab order. [readOnly] shows the value at full
/// contrast without letting it change — still a Tab stop, announced
/// read-only, with no hover (see `FieldState`).
class Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  /// Names a switch shown without a [label], e.g. "Email notifications" in a
  /// settings row.
  final String? semanticLabel;

  /// Shows [value] at full contrast, taking no input; see [Toggle].
  final bool readOnly;

  /// Reports, and can seed, the hovered, pressed and focused states — e.g. to
  /// pin a state in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  const Toggle({
    super.key,
    required this.value,
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
    final toggle = Tappable.states(
      onTap: editable ? () => onChanged!(!value) : null,
      readOnly: readOnly,
      toggled: value,
      semanticLabel: semanticLabel,
      statesController: statesController,
      showFocusRing: false,
      builder: (context, states) {
        final track = FocusRing(
          focused: states.contains(WidgetState.focused),
          radius: context.selectionStyle.toggleHeight / 2,
          child: _track(
            context,
            enabled: enabled,
            hovered: editable && states.contains(WidgetState.hovered),
          ),
        );
        if (label == null) return track;
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
              onFirstLine(context, track, label!, style),
              const Gap(AdminSpacing.md),
              Flexible(child: Text(label!, style: style)),
            ],
          ),
        );
      },
    );
    // Aligned with or without a label: a bare control given a tight box
    // would fill it, its track or its box drawn that wide.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: toggle,
    );
  }

  /// Off, a [ToggleOffStyle.filled] track is [AdminPalette.controlBorder]
  /// under a knob in the surface colour; an outlined one is ringed in it,
  /// [AdminStroke.controlStrong] wide, around a knob in the same colour, over
  /// nothing or, [ToggleOffStyle.tonal], a wash of the foreground. On, the
  /// track is [AdminSelectionStyle.toggleOnOf] under
  /// [AdminSelectionStyle.toggleKnobOnOf]. Under the pointer the off colour
  /// deepens by the pressed overlay and the on track takes its hover shade.
  /// Disabled, the track greys.
  Widget _track(
    BuildContext context, {
    required bool enabled,
    required bool hovered,
  }) {
    final colors = context.colors;
    final style = context.selectionStyle;
    final filled = style.toggleOff == ToggleOffStyle.filled;
    const clear = Color(0x00000000);

    // The off colour: a filled track, or an outlined one's ring and knob.
    final Color off;
    if (!enabled) {
      off = filled
          // token-literal: a disabled off track, fainter than the faint step
          ? colors.foregroundFaint.withValues(alpha: 0.5)
          : colors.foregroundFaint;
    } else {
      off = hovered
          ? Color.alphaBlend(colors.pressedOverlay, colors.controlBorder)
          : colors.controlBorder;
    }

    final Color track;
    final Color ring;
    if (value) {
      track = enabled
          ? style.toggleOnOf(colors, hovered: hovered)
          : colors.foregroundSubtle;
      ring = track;
    } else if (filled) {
      track = off;
      ring = off;
    } else {
      track = style.toggleOff == ToggleOffStyle.tonal && enabled
          ? Color.alphaBlend(colors.pressedOverlay, colors.surface)
          : clear;
      ring = off;
    }

    // On, the track's on-colour, as a checked Check's glyph: it holds its
    // contrast on the hover shade too, and it is Material's onPrimary handle
    // and shadcn's thumb (the page colour in light, primary-foreground in
    // dark). Off on a filled track, the surface colour; but in a dark theme a
    // surface-coloured knob on a dim track reads as a hole, so there it takes
    // whichever of the surface and the foreground stands out more from the
    // track. Off in an outlined track, the ring's colour. Disabled, the
    // surface colour on grey.
    final Color knob;
    if (value) {
      knob = enabled ? style.toggleKnobOnOf(colors) : colors.surface;
    } else if (!filled) {
      knob = off;
    } else if (!enabled) {
      knob = colors.surface;
    } else if (colors.brightness == Brightness.dark) {
      knob =
          contrastRatio(colors.foreground, track) >
              contrastRatio(colors.surface, track)
          ? colors.foreground
          : colors.surface;
    } else {
      knob = colors.surface;
    }

    final height = style.toggleHeight;
    // The knob is laid out at the larger of its two sizes and drawn smaller
    // where it shrinks, so it grows about its own centre.
    final slot = style.toggleKnobSlot;
    final size = value
        ? style.toggleKnobOn ?? style.toggleKnob
        : style.toggleKnob;
    // An outlined track keeps its ring's width while on, in the track's own
    // colour, so the knob's margins never move.
    final ringWidth = filled ? 0.0 : context.stroke.controlStrong;
    final motion = context.motion;
    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      width: style.toggleWidth,
      height: height,
      // A Container adds its border's width to its padding. A ring wider
      // than the knob's margin leaves the knob that much less room.
      padding: EdgeInsets.all(math.max(0, (height - slot) / 2 - ringWidth)),
      decoration: BoxDecoration(
        color: track,
        // A pill in every theme, whatever its radii: no reference system
        // squares off a switch, Carbon included.
        borderRadius: BorderRadius.circular(height / 2),
        border: filled ? null : Border.all(color: ring, width: ringWidth),
      ),
      child: AnimatedAlign(
        duration: motion.fast,
        curve: motion.standard,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: AnimatedScale(
          duration: motion.fast,
          curve: motion.standard,
          scale: size / slot,
          child: Container(
            width: slot,
            height: slot,
            decoration: BoxDecoration(
              color: knob,
              shape: BoxShape.circle,
              // A knob on a filled track is lifted; an outlined track's is
              // flat, as M3's and Fluent's are.
              boxShadow: filled ? context.elevation.sm : null,
            ),
          ),
        ),
      ),
    );
  }
}
