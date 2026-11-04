import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:material_ui/material_ui.dart';

import '../../theme/contrast.dart';
import '../../theme/palette.dart';
import '../../theme/tokens.dart';

// The label row and hover outline shared by the selection controls (Check,
// Toggle, Choice and the boolean field body). Internal: left out of the
// public barrels.

/// The outline of an unchecked box or radio under the pointer:
/// [AdminPalette.controlAccent] where it stands out from the surface at least
/// as much as the resting [AdminPalette.controlBorder], otherwise that border
/// deepened by the pressed overlay, so hovering never makes the control
/// fainter.
Color offHoverOutline(AdminPalette colors) =>
    contrastRatio(colors.controlAccent, colors.surface) >=
        contrastRatio(colors.controlBorder, colors.surface)
    ? colors.controlAccent
    : Color.alphaBlend(colors.pressedOverlay, colors.controlBorder);

/// [row] centred in a target at least 24px tall, whatever the label's line.
Widget minTarget(Widget row) => ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 24),
  child: Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: row,
  ),
);

/// [control] centred on the first line of [label] set in [style]: in a row
/// aligned on baselines it sits against that line, however many lines the
/// label wraps to. An invisible, zero-width line of the label itself gives the
/// slot the line's height and baseline, whatever font the label resolves to;
/// it is a [RichText], so a finder for the label's [Text] still finds one.
Widget onFirstLine(
  BuildContext context,
  Widget control,
  String label,
  TextStyle style,
) {
  final defaults = DefaultTextStyle.of(context);
  var effective = defaults.style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    effective = context.type.weighted(effective, FontWeight.bold);
  }
  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 0,
        child: OverflowBox(
          maxWidth: double.infinity,
          fit: OverflowBoxFit.deferToChild,
          alignment: AlignmentDirectional.centerStart,
          child: Opacity(
            opacity: 0,
            child: RichText(
              text: TextSpan(text: label, style: effective),
              maxLines: 1,
              softWrap: false,
              textScaler: MediaQuery.textScalerOf(context),
              textHeightBehavior:
                  defaults.textHeightBehavior ??
                  DefaultTextHeightBehavior.maybeOf(context),
            ),
          ),
        ),
      ),
      control,
    ],
  );
}
