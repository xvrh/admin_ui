import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Whether [kind] points without hovering — a finger or a pen — so a view
/// shows for good what a mouse would reveal on hover.
bool isCoarsePointer(PointerDeviceKind kind) => switch (kind) {
  PointerDeviceKind.touch ||
  PointerDeviceKind.stylus ||
  PointerDeviceKind.invertedStylus => true,
  _ => false,
};

/// Whether the platform is touch-first: the pointer to assume before one
/// lands.
bool get coarsePointerByDefault => switch (defaultTargetPlatform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => true,
  _ => false,
};
