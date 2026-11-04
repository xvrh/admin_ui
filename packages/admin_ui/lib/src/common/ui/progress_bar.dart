/// @docImport 'spinner.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../motion.dart';
import 'severity.dart';

/// The determinate counterpart to [Spinner]: a linear bar that fills [value]
/// (0..1) of its track. Pass `value: null` for an indeterminate sweep when the
/// total isn't known yet.
///
/// View-only — it draws whatever fraction it's handed. Optional [label] (leading)
/// and [showPercent] (trailing) wrap the bar in a captioned row; without either
/// it's just the bare track, sized to its parent's width.
///
/// The fill is the primary colour for work in flight; a [severity] tints it
/// with that status colour instead — success once it completes, danger when
/// it failed partway, warning when it is close to a limit. Whatever its
/// colour, the fill is what shows the value, so it takes the nearest shade of
/// it that clears 3:1 against the track and the page (WCAG 1.4.11): the
/// colour as it is where it already does.
class ProgressBar extends StatelessWidget {
  /// Completion in 0..1, clamped for display. `null` = indeterminate sweep.
  final double? value;

  /// Track thickness: 6 standalone, 4 tucked into a tile or a list row.
  final double thickness;

  /// The status the fill shows; null is the primary colour of work in flight.
  final Severity? severity;

  /// Leading caption, e.g. a file name or 'Uploading…'.
  final String? label;

  /// Trailing '62%' readout, derived from [value] in the app's locale ('62 %'
  /// in French). Ignored when indeterminate.
  final bool showPercent;

  const ProgressBar({
    super.key,
    required this.value,
    this.thickness = 6,
    this.severity,
    this.label,
    this.showPercent = false,
  });

  double? get _clamped => value?.clamp(0, 1).toDouble();

  /// The status accents are chosen for icons, dots and tints, and a yellow,
  /// a light green or a light blue all but vanishes on a grey track, as does
  /// a deep primary on a dark one. Each darkens, or lightens in a dark theme,
  /// to 3:1 against the track and the page. Where that departs from the meter
  /// of the system a theme follows, WCAG 1.4.11 is why:
  /// - Carbon's ProgressBar fills with `$support-success` and
  ///   `$support-error`; #24A148 on the #E0E0E0 track is 2.5:1, so success
  ///   takes #219242, and in the dark theme the #DA1E28 error takes #E64A52,
  ///   near g100's own `$support-error` #FA4D56, as the #0F62FE fill takes
  ///   #367CFE.
  /// - Ant's Progress fills with `colorSuccess` and `colorError`: #52C41A is
  ///   1.6:1 on the track, so success takes #3B8C13; in the dark theme the
  ///   primary #1668DC takes #488DED and the error #D44244 takes #DD696A.
  /// - Fluent's ProgressBar in the dark theme: the brand #115EA3 takes
  ///   #288DE9, near its own dark compound brand #479EF5.
  /// - M3's LinearProgressIndicator fills with the primary; the Material
  ///   theme's success and error already reach 3:1, so only a brand accent
  ///   moves.
  /// - shadcn's Progress has no status fills; its success #16A34A takes
  ///   #149644, and Iris's #2F9E63 takes #2D9860.
  Color _fill(BuildContext context) {
    final severity = this.severity;
    final c = context.colors;
    final accent = severity == null
        ? c.primary
        : severityStyleOf(context, severity).accent;
    return c.readableOn(
      accent,
      surfaces: [c.border, c.surface, c.background],
      minContrast: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    var bar = ClipRRect(
      // The theme's small radius: rounded ends in most themes, square in
      // Carbon.
      borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      child: _clamped == null && motionReduced(context)
          ? StillLinearProgress(
              minHeight: thickness,
              backgroundColor: context.colors.border,
              color: _fill(context),
            )
          : LinearProgressIndicator(
              value: _clamped,
              minHeight: thickness,
              backgroundColor: context.colors.border,
              valueColor: AlwaysStoppedAnimation(_fill(context)),
            ),
    );

    var percent = showPercent && _clamped != null;
    if (label == null && !percent) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
          child: Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.caption,
                  ),
                )
              else
                const Spacer(),
              if (percent)
                Text(
                  context.adminFormats.percent(_clamped!),
                  style: context.type.weighted(
                    context.type.caption.copyWith(
                      color: context.colors.foregroundMuted,
                    ),
                    FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        bar,
      ],
    );
  }
}
