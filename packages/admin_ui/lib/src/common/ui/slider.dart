import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// A token-styled single-value slider. Named to dodge Material's own [Slider].
/// A null [onChanged] is read-only.
///
/// Pass [divisions] for a stepped (snapping) slider, [format] to control the
/// trailing readout / drag bubble, and turn the readout off with `showValue:
/// false`. The track runs flush with the column's edges, the bubble shows the
/// value while dragging, and a screen reader hears the same text as the
/// readout.
class ValueSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  /// Snap to this many equal steps. Null is a continuous slider.
  final int? divisions;

  /// Formats [value] for the trailing readout, the drag bubble and screen
  /// readers. Defaults to the locale's number format: no decimals on a whole
  /// number, two otherwise.
  final String Function(double value)? format;

  /// Show the formatted value to the right of the track.
  final bool showValue;

  const ValueSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.format,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    final accent = enabled ? colors.controlAccent : colors.foregroundFaint;
    final fmt = format ?? _localeFormat(context);

    final slider = SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        // No horizontal inset: the track starts and ends at the column's
        // edges, like the labels and fields around it. Vertically the row
        // is a medium control tall, the thumb centred in it.
        padding: EdgeInsets.symmetric(
          vertical: context.sizes.medium / 2 - _thumbRadius,
        ),
        activeTrackColor: accent,
        inactiveTrackColor: colors.border,
        thumbColor: enabled ? colors.controlAccent : colors.foregroundSubtle,
        disabledThumbColor: colors.foregroundSubtle,
        disabledActiveTrackColor: colors.foregroundFaint,
        disabledInactiveTrackColor: colors.border,
        overlayColor: colors.controlAccent.withValues(
          alpha: colors.stateLayer.tintPressed,
        ),
        activeTickMarkColor: colors.onControlAccent,
        inactiveTickMarkColor: colors.foregroundSubtle,
        disabledActiveTickMarkColor: colors.surface,
        disabledInactiveTickMarkColor: colors.foregroundFaint,
        showValueIndicator: ShowValueIndicator.onDrag,
        valueIndicatorColor: colors.foreground,
        valueIndicatorTextStyle: context.type.caption.copyWith(
          color: colors.surface,
        ),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: _thumbRadius,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 2 * _thumbRadius,
        ),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: fmt(value),
        semanticFormatterCallback: fmt,
        onChanged: onChanged,
      ),
    );

    if (!showValue) return slider;

    final style = context.type.body.copyWith(
      color: enabled ? colors.foreground : colors.foregroundSubtle,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // At least 48 wide, so stacked sliders end in line, and otherwise as wide
    // as the widest of the value and the two ends, so the track never shifts
    // as the value changes.
    final readout = Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        const SizedBox(width: 48),
        for (final end in {fmt(min), fmt(max)})
          ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: Text(end, maxLines: 1, softWrap: false, style: style),
            ),
          ),
        // The slider already announces the value.
        ExcludeSemantics(
          child: Text(fmt(value), maxLines: 1, softWrap: false, style: style),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(child: slider),
        const Gap(AdminSpacing.lg),
        readout,
      ],
    );
  }

  static String Function(double) _localeFormat(BuildContext context) {
    final locale = Intl.verifiedLocale(
      Localizations.maybeLocaleOf(context)?.toString(),
      NumberFormat.localeExists,
      onFailure: (_) => 'en',
    );
    final whole = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 0,
    );
    final fraction = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    return (v) => (v == v.roundToDouble() ? whole : fraction).format(v);
  }
}

/// The thumb's radius: an 18px knob, the size of a checkbox.
const _thumbRadius = 9.0;
