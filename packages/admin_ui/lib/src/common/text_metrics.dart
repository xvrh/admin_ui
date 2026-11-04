import 'package:flutter/widgets.dart';

final _lineHeights = <(TextStyle, TextScaler), double>{};

/// Whether a font load empties [_lineHeights] yet: a line measured before its
/// font arrived was measured in a fallback.
var _clearsOnFontLoad = false;

/// The height of one line of [style] as a [Text] under [context] lays it out:
/// merged over the ambient [DefaultTextStyle], at the platform's text scale.
///
/// It measures in the fonts loaded at the time, so a box sized by it before
/// its font loads is off until it is built again: a widget that can be built
/// that early rebuilds on `PaintingBinding.instance.systemFonts`.
double lineHeightOf(BuildContext context, TextStyle style) => _lineHeight(
  DefaultTextStyle.of(context).style.merge(style),
  MediaQuery.textScalerOf(context),
);

/// How much taller one line of [style] is at the platform's text size than
/// at the normal size.
///
/// A box sized for a line of text grows by this much, keeping the room it
/// had around the text: it holds its text at a large text scale rather than
/// clipping it, and is unchanged at the normal size whatever the font.
double textGrowthOf(BuildContext context, TextStyle style) {
  final effective = DefaultTextStyle.of(context).style.merge(style);
  final scaler = MediaQuery.textScalerOf(context);
  if (scaler == TextScaler.noScaling) return 0;
  final growth =
      _lineHeight(effective, scaler) -
      _lineHeight(effective, TextScaler.noScaling);
  return growth > 0 ? growth.ceilToDouble() : 0;
}

double _lineHeight(TextStyle style, TextScaler scaler) {
  if (!_clearsOnFontLoad) {
    PaintingBinding.instance.systemFonts.addListener(_lineHeights.clear);
    _clearsOnFontLoad = true;
  }
  if (_lineHeights.length > 64) _lineHeights.clear();
  return _lineHeights.putIfAbsent((style, scaler), () {
    final painter = TextPainter(
      // Not user-facing: a probe for the line's ascent and descent.
      text: TextSpan(text: 'Hg', style: style),
      // Physical: the probe measures a height, the same either way.
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  });
}
