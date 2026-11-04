import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// Geometry of the keyboard-focus ring: a [width] stroke drawn [offset] outside
/// the control's edge, so it separates from filled controls. The colour is the
/// palette's `focusRing`. Provided via [AdminTokens]; read through
/// `context.focus`.
@immutable
class AdminFocusSpec {
  /// Stroke width of the ring.
  final double width;

  /// Gap between the control's edge and the ring.
  final double offset;

  /// A band this wide in the palette's `surface` just inside a flush ring
  /// ([offset] 0), so the ring reads on a fill of its own colour: Fluent's
  /// 1px colorStrokeFocus1 inside its 2px colorStrokeFocus2. Zero, the
  /// default, draws none; a ring with an offset has its gap for that.
  final double innerWidth;

  const AdminFocusSpec({this.width = 2, this.offset = 2, this.innerWidth = 0});

  AdminFocusSpec copyWith({double? width, double? offset, double? innerWidth}) {
    return AdminFocusSpec(
      width: width ?? this.width,
      offset: offset ?? this.offset,
      innerWidth: innerWidth ?? this.innerWidth,
    );
  }

  static AdminFocusSpec lerp(AdminFocusSpec a, AdminFocusSpec b, double t) {
    return AdminFocusSpec(
      width: lerpDouble(a.width, b.width, t)!,
      offset: lerpDouble(a.offset, b.offset, t)!,
      innerWidth: lerpDouble(a.innerWidth, b.innerWidth, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminFocusSpec &&
      other.width == width &&
      other.offset == offset &&
      other.innerWidth == innerWidth;

  @override
  int get hashCode => Object.hash(width, offset, innerWidth);

  @override
  String toString() =>
      'AdminFocusSpec(width $width, offset $offset'
      '${innerWidth == 0 ? '' : ', inner $innerWidth'})';
}
