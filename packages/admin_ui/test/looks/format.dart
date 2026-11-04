import 'package:material_ui/material_ui.dart';

/// Adds [value] to [out] under [path], as one line of looks.txt: a list or
/// a map one entry per line, anything else on its own.
void describeValue(Object? value, String path, Map<String, String> out) {
  switch (value) {
    case List<BoxShadow>():
      out[path] = value.isEmpty ? '[]' : value.map(_shadow).join('; ');
    case List<String>():
      out[path] = '[${value.join(', ')}]';
    default:
      out[path] = formatValue(value);
  }
}

/// [value] as looks.txt writes it. Throws on a type it has no form for, so
/// no token leaves the dump as `Instance of …`.
String formatValue(Object? value) => switch (value) {
  null => 'null',
  Color() => _color(value),
  double() => _num(value),
  int() || bool() || String() => '$value',
  Enum() => value.name,
  FontWeight() => 'w${value.value}',
  Duration() => '${value.inMicroseconds / 1000}ms'.replaceAll('.0ms', 'ms'),
  Cubic() =>
    'cubic(${[value.a, value.b, value.c, value.d].map(_num).join(', ')})',
  ThreePointCubic() =>
    'cubic3(${[value.a1, value.b1, value.midpoint, value.a2, value.b2].map(_offset).join(', ')})',
  TextStyle() => _style(value),
  _ => throw ArgumentError(
    'looks.txt has no form for ${value.runtimeType}: add one to '
    'test/looks/format.dart',
  ),
};

String _color(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';

String _num(num value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  final fixed = value.toStringAsFixed(4);
  return fixed.replaceFirst(RegExp(r'0+$'), '');
}

String _offset(Offset offset) => '${_num(offset.dx)},${_num(offset.dy)}';

String _shadow(BoxShadow shadow) => [
  _color(shadow.color),
  _offset(shadow.offset),
  'blur ${_num(shadow.blurRadius)}',
  if (shadow.spreadRadius != 0) 'spread ${_num(shadow.spreadRadius)}',
].join(' ');

String _style(TextStyle style) => [
  ?style.fontFamily,
  if (style.fontFamilyFallback case final fallback? when fallback.isNotEmpty)
    'fallback [${fallback.join(', ')}]',
  if (style.fontSize case final size?) _num(size),
  if (style.fontWeight case final weight?) formatValue(weight),
  if (style.fontStyle case final fontStyle?) fontStyle.name,
  if (style.height case final height?) 'height ${_num(height)}',
  if (style.letterSpacing case final spacing?) 'spacing ${_num(spacing)}',
  if (style.wordSpacing case final spacing?) 'word ${_num(spacing)}',
  if (style.color case final color?) _color(color),
  if (style.decoration case final decoration?) '$decoration',
  if (style.fontFeatures case final features? when features.isNotEmpty)
    'features [${features.map((f) => '${f.feature}=${f.value}').join(', ')}]',
  if (style.leadingDistribution case final distribution?) distribution.name,
].join(' ');
