/// @docImport '../../theme/palette.dart';
library;

import 'dart:math' as math;

import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../theme/slider_style.dart';
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
///
/// The theme's [AdminSliderStyle] draws it as its reference system does (see
/// `context.sliderStyle`): the track's height, a thumb that is a disc, a
/// ringed or an inset disc, or M3's bar, the colour of the track past the
/// thumb, and whether the rest is in the accent or the foreground. The row
/// is a medium control tall, or the thumb where that is taller.
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
    final look = context.sliderStyle;
    final enabled = onChanged != null;
    final ink = look.inkOf(colors);
    final fmt = format ?? _localeFormat(context);
    final bar = look.thumb == SliderThumb.bar;
    final thumbSize = look.thumbSize;
    final thumbRadius = thumbSize / 2;
    // A medium control tall, the thumb centred in it; a thumb taller than
    // that sets the row's height.
    final rowHeight = math.max(context.sizes.medium, thumbSize);

    final sliderTheme = SliderTheme(
      data: SliderThemeData(
        trackHeight: look.trackHeight,
        // No horizontal inset: the track starts and ends at the column's
        // edges, like the labels and fields around it.
        padding: EdgeInsets.symmetric(vertical: rowHeight / 2 - thumbRadius),
        activeTrackColor: ink,
        inactiveTrackColor: look.railOf(colors),
        thumbColor: ink,
        disabledThumbColor: colors.foregroundSubtle,
        disabledActiveTrackColor: colors.foregroundFaint,
        disabledInactiveTrackColor: colors.border,
        overlayColor: ink.withValues(alpha: colors.stateLayer.tintPressed),
        activeTickMarkColor: look.onInkOf(colors),
        inactiveTickMarkColor: colors.foregroundSubtle,
        disabledActiveTickMarkColor: colors.surface,
        disabledInactiveTickMarkColor: colors.foregroundFaint,
        showValueIndicator: ShowValueIndicator.onDrag,
        valueIndicatorColor: colors.foreground,
        valueIndicatorTextStyle: context.type.caption.copyWith(
          color: colors.surface,
        ),
        thumbShape: switch (look.thumb) {
          SliderThumb.disc => RoundSliderThumbShape(
            enabledThumbRadius: thumbRadius,
          ),
          SliderThumb.ringed => _RingedThumb(
            radius: thumbRadius,
            ring: look.thumbRing,
            fill: colors.surface,
            shadows: context.elevation.sm,
          ),
          SliderThumb.inset => _InsetThumb(
            radius: thumbRadius,
            band: look.thumbRing,
            fill: colors.surface,
            edge: colors.border,
            edgeWidth: context.stroke.hairline,
          ),
          SliderThumb.bar => const HandleThumbShape(),
        },
        // A bar's own size, half as wide while pressed as M3's is, and the
        // gap it parts the track by.
        thumbSize: bar
            ? WidgetStateProperty.resolveWith(
                (states) => Size(
                  states.contains(WidgetState.pressed)
                      ? AdminSliderStyle.barWidth / 2
                      : AdminSliderStyle.barWidth,
                  thumbSize,
                ),
              )
            : null,
        trackGap: bar ? AdminSliderStyle.barGap : null,
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: bar ? thumbRadius : thumbSize,
        ),
        trackShape: bar
            ? const GappedSliderTrackShape()
            : const RoundedRectSliderTrackShape(),
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
    // The row's height is set here, not left to the slider: a slider sizes
    // itself once for its constraints, so on its own it would keep the last
    // theme's height when the theme changes under it.
    final slider = SizedBox(height: rowHeight, child: sliderTheme);

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

/// A thumb in the surface colour ringed in the slider's ink, lifted on the
/// theme's small shadow: shadcn's and Ant's. Disabled, the ring takes the
/// disabled thumb colour.
class _RingedThumb extends SliderComponentShape {
  final double radius;
  final double ring;
  final Color fill;
  final List<BoxShadow> shadows;

  const _RingedThumb({
    required this.radius,
    required this.ring,
    required this.fill,
    required this.shadows,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final ink = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;
    for (final shadow in shadows) {
      canvas.drawCircle(
        center + shadow.offset,
        radius + shadow.spreadRadius,
        shadow.toPaint(),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius - ring / 2,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring,
    );
  }
}

/// A thumb in the slider's ink inside a band in the surface colour, edged in
/// a hairline: Fluent's. Disabled, the disc takes the disabled thumb colour.
class _InsetThumb extends SliderComponentShape {
  final double radius;
  final double band;
  final Color fill;
  final Color edge;
  final double edgeWidth;

  const _InsetThumb({
    required this.radius,
    required this.band,
    required this.fill,
    required this.edge,
    required this.edgeWidth,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final ink = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(center, radius - band, Paint()..color = ink);
    canvas.drawCircle(
      center,
      radius - edgeWidth / 2,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth,
    );
  }
}
