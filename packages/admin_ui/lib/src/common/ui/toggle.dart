/// @docImport 'checkbox.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../theme/contrast.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'control_label.dart';
import 'focus_ring.dart';
import 'tappable.dart';

/// A token-styled switch (the Flutter `Switch` renamed to dodge the collision).
/// [value]/[onChanged]; with a [label] it's a tappable row that hugs the
/// label, otherwise just the control.
///
/// A Tab stop that Space and Enter flip, announced as a switch with its on/off
/// state. Keyboard focus rings the track.
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

  static const _width = 36.0;
  static const _height = 20.0;
  static const _knob = 16.0;

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
          radius: _height / 2,
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
    if (label == null) return toggle;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: toggle,
    );
  }

  Widget _track(
    BuildContext context, {
    required bool enabled,
    required bool hovered,
  }) {
    final colors = context.colors;
    final Color track;
    if (!enabled) {
      track = value
          ? colors.foregroundSubtle
          // token-literal: a disabled off track, fainter than the faint step
          : colors.foregroundFaint.withValues(alpha: 0.5);
    } else if (value) {
      track = hovered ? colors.controlAccentHover : colors.controlAccent;
    } else {
      track = hovered
          ? Color.alphaBlend(colors.pressedOverlay, colors.controlBorder)
          : colors.controlBorder;
    }
    // On, the accent's on-colour, as a checked Check's glyph: it holds its
    // contrast on the hover shade too, and it is Material's onPrimary handle
    // and shadcn's thumb (the page colour in light, primary-foreground in
    // dark). Off, the surface colour; but in a dark theme a surface-coloured
    // knob on a dim track reads as a hole, so there it takes whichever of the
    // surface and the foreground stands out more from the track. Disabled, the
    // surface colour on grey.
    final Color knob;
    if (!enabled) {
      knob = colors.surface;
    } else if (value) {
      knob = colors.onControlAccent;
    } else if (colors.brightness == Brightness.dark) {
      knob =
          contrastRatio(colors.foreground, track) >
              contrastRatio(colors.surface, track)
          ? colors.foreground
          : colors.surface;
    } else {
      knob = colors.surface;
    }

    final motion = context.motion;
    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      width: _width,
      height: _height,
      padding: const EdgeInsets.all((_height - _knob) / 2),
      decoration: BoxDecoration(
        color: track,
        // A pill in every theme, whatever its radii: no reference system
        // squares off a switch, Carbon included.
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: AnimatedAlign(
        duration: motion.fast,
        curve: motion.standard,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: _knob,
          height: _knob,
          decoration: BoxDecoration(
            color: knob,
            shape: BoxShape.circle,
            boxShadow: context.elevation.sm,
          ),
        ),
      ),
    );
  }
}
