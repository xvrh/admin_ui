import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// The opacities an interaction state lays over a control, as Material 3
/// names them: a wash of the content colour ([AdminPalette.foreground], or a
/// saturated colour for a link or a destructive row) over whatever the
/// control sits on. Carried by [AdminPalette.stateLayer], which turns them
/// into its `*Overlay` colours; read those rather than an alpha literal.
///
/// The defaults are the kit's own: a light 5% hover and 10% press, and a
/// stronger tint wash, since a saturated tint reads fainter. The Material
/// theme sets M3's 8 / 10 / 10 / 16%.
@immutable
class AdminStateLayer {
  /// Under the pointer: [AdminPalette.hoverOverlay].
  final double hover;

  /// Keyboard focus, where a control shows it with a wash rather than a
  /// ring: [AdminPalette.focusOverlay].
  final double focus;

  /// Pressed: [AdminPalette.pressedOverlay].
  final double pressed;

  /// A selected item that marks its selection with a wash of the primary
  /// rather than a fill.
  final double selected;

  /// Being dragged: [AdminPalette.draggedOverlay].
  final double dragged;

  /// A saturated colour under the pointer — the primary of a link
  /// ([AdminPalette.primaryHoverOverlay]), the danger of a destructive menu
  /// row, a column's accent under a dragged card.
  final double tintHover;

  /// A saturated colour pressed: [AdminPalette.primaryPressedOverlay], a
  /// slider's pressed thumb.
  final double tintPressed;

  /// A disabled control's content (label, glyph, a checked box's fill).
  final double disabledContent;

  const AdminStateLayer({
    this.hover = 0.05,
    this.focus = 0.05,
    this.pressed = 0.10,
    this.selected = 0.08,
    this.dragged = 0.10,
    this.tintHover = 0.08,
    this.tintPressed = 0.14,
    this.disabledContent = 0.38,
  });

  /// A copy with the given opacities replaced.
  AdminStateLayer copyWith({
    double? hover,
    double? focus,
    double? pressed,
    double? selected,
    double? dragged,
    double? tintHover,
    double? tintPressed,
    double? disabledContent,
  }) => AdminStateLayer(
    hover: hover ?? this.hover,
    focus: focus ?? this.focus,
    pressed: pressed ?? this.pressed,
    selected: selected ?? this.selected,
    dragged: dragged ?? this.dragged,
    tintHover: tintHover ?? this.tintHover,
    tintPressed: tintPressed ?? this.tintPressed,
    disabledContent: disabledContent ?? this.disabledContent,
  );

  static AdminStateLayer lerp(AdminStateLayer a, AdminStateLayer b, double t) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminStateLayer(
      hover: d(a.hover, b.hover),
      focus: d(a.focus, b.focus),
      pressed: d(a.pressed, b.pressed),
      selected: d(a.selected, b.selected),
      dragged: d(a.dragged, b.dragged),
      tintHover: d(a.tintHover, b.tintHover),
      tintPressed: d(a.tintPressed, b.tintPressed),
      disabledContent: d(a.disabledContent, b.disabledContent),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminStateLayer &&
      other.hover == hover &&
      other.focus == focus &&
      other.pressed == pressed &&
      other.selected == selected &&
      other.dragged == dragged &&
      other.tintHover == tintHover &&
      other.tintPressed == tintPressed &&
      other.disabledContent == disabledContent;

  @override
  int get hashCode => Object.hash(
    hover,
    focus,
    pressed,
    selected,
    dragged,
    tintHover,
    tintPressed,
    disabledContent,
  );

  @override
  String toString() =>
      'AdminStateLayer(hover $hover, focus $focus, pressed $pressed, '
      'selected $selected, dragged $dragged, tint $tintHover/$tintPressed, '
      'disabled content $disabledContent)';
}
