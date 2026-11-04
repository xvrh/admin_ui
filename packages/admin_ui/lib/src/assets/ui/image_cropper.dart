import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/slider.dart';
import '../../common/ui/spinner.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// What the pointer grabbed: a resize handle, the interior (move), or the focal
/// marker. Corners resize two edges, edges resize one.
enum CropHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  move,
  focal,
}

extension CropHandleX on CropHandle {
  bool get isCorner =>
      this == CropHandle.topLeft ||
      this == CropHandle.topRight ||
      this == CropHandle.bottomLeft ||
      this == CropHandle.bottomRight;

  bool get isEdge =>
      this == CropHandle.top ||
      this == CropHandle.right ||
      this == CropHandle.bottom ||
      this == CropHandle.left;
}

/// A crop selection plus an optional focal point, both expressed in normalized
/// image coordinates (0..1, independent of pixel size). [rect] is the kept
/// region; [focal] marks the subject so downstream auto-crops to arbitrary
/// aspect ratios keep it in frame — the Sanity/Contentful model. [focal] is
/// always inside [rect].
@immutable
class CropValue {
  final Rect rect;
  final Offset? focal;

  /// Clockwise 90° turns (0..3) applied to the source before [rect]. [rect] and
  /// [focal] are expressed in the post-transform (on-screen) frame.
  final int quarterTurns;
  final bool flipH;
  final bool flipV;

  /// Fine straighten angle in degrees (clockwise), applied on top of
  /// [quarterTurns]. The image auto-scales to keep the crop filled.
  final double angle;

  const CropValue({
    this.rect = const Rect.fromLTRB(0, 0, 1, 1),
    this.focal,
    this.quarterTurns = 0,
    this.flipH = false,
    this.flipV = false,
    this.angle = 0,
  });

  /// The whole image, no crop or transform.
  static const full = CropValue();

  /// Centre of the current crop — the default focal when none is set.
  Offset get center => rect.center;

  /// Any non-identity transform is applied.
  bool get isTransformed => quarterTurns != 0 || flipH || flipV || angle != 0;

  CropValue copyWith({
    Rect? rect,
    Offset? focal,
    int? quarterTurns,
    bool? flipH,
    bool? flipV,
    double? angle,
  }) => CropValue(
    rect: rect ?? this.rect,
    focal: focal ?? this.focal,
    quarterTurns: quarterTurns ?? this.quarterTurns,
    flipH: flipH ?? this.flipH,
    flipV: flipV ?? this.flipV,
    angle: angle ?? this.angle,
  );

  /// [focal] re-clamped into [rect] (the crop may have shrunk past it).
  CropValue withClampedFocal() =>
      focal == null ? this : copyWith(focal: cropClampFocal(focal!, rect));

  /// Storage form. [rect] is `[left, top, right, bottom]` and [focal] `[x, y]`,
  /// all fractional (0..1) so it is resolution-independent and pixel coordinates
  /// can be derived for any rendition. A null focal is omitted.
  Map<String, dynamic> toJson() => {
    'rect': [rect.left, rect.top, rect.right, rect.bottom],
    if (focal != null) 'focal': [focal!.dx, focal!.dy],
    if (quarterTurns != 0) 'rot': quarterTurns,
    if (flipH) 'flipH': true,
    if (flipV) 'flipV': true,
    if (angle != 0) 'angle': angle,
  };

  /// Parses [toJson]. Tolerant of int or double numbers (JSON loses the type)
  /// and of an absent transform (older records predate it).
  factory CropValue.fromJson(Map<String, dynamic> json) {
    final r = (json['rect'] as List).cast<num>();
    final f = (json['focal'] as List?)?.cast<num>();
    return CropValue(
      rect: Rect.fromLTRB(
        r[0].toDouble(),
        r[1].toDouble(),
        r[2].toDouble(),
        r[3].toDouble(),
      ),
      focal: f == null ? null : Offset(f[0].toDouble(), f[1].toDouble()),
      quarterTurns: (json['rot'] as num?)?.toInt() ?? 0,
      flipH: json['flipH'] as bool? ?? false,
      flipV: json['flipV'] as bool? ?? false,
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CropValue &&
      other.rect == rect &&
      other.focal == focal &&
      other.quarterTurns == quarterTurns &&
      other.flipH == flipH &&
      other.flipV == flipV &&
      other.angle == angle;

  @override
  int get hashCode =>
      Object.hash(rect, focal, quarterTurns, flipH, flipV, angle);
}

/// A selectable aspect ratio for the preset bar. [ratio] is width / height in
/// pixels; `null` means freeform.
@immutable
class AspectPreset {
  /// The chip's text, such as '16:9'; null for [free]'s, which is "Free" in
  /// the app's language ([labelOf]).
  final String? label;
  final double? ratio;

  const AspectPreset(this.label, this.ratio);

  static const free = AspectPreset(null, null);

  /// [label], or "Free" in [context]'s language.
  String labelOf(BuildContext context) =>
      label ?? context.adminL10n.assets.aspectFree;

  /// A sensible default bar covering the common editorial ratios.
  static const defaults = [
    free,
    AspectPreset('1:1', 1),
    AspectPreset('16:9', 16 / 9),
    AspectPreset('4:3', 4 / 3),
    AspectPreset('3:2', 3 / 2),
    AspectPreset('2:3', 2 / 3),
  ];

  @override
  bool operator ==(Object other) =>
      other is AspectPreset && other.label == label && other.ratio == ratio;

  @override
  int get hashCode => Object.hash(label, ratio);
}

// ── pure geometry ──────────────────────────────────────────────────────────
// All normalized (0..1) and side-effect free so the resize/move/hit-test rules
// are unit-testable without an image or a render box.

/// Resizes [rect] by dragging [handle] through [deltaNorm] (normalized). When
/// [lockRatio] is set (normalized width / height to preserve) only corner drags
/// apply and the opposite corner stays anchored; otherwise edges move freely.
/// The result stays within the unit square and within the size limits — at
/// least [minNorm] per side, or the per-axis [minNormW]/[minNormH] and at most
/// [maxNormW]/[maxNormH] when given (derived from a pixel min/max by the host).
Rect cropResize({
  required Rect rect,
  required CropHandle handle,
  required Offset deltaNorm,
  double? lockRatio,
  double minNorm = 0.06,
  double? minNormW,
  double? minNormH,
  double? maxNormW,
  double? maxNormH,
}) {
  final minW = minNormW ?? minNorm;
  final minH = minNormH ?? minNorm;
  final maxW = maxNormW ?? 1.0;
  final maxH = maxNormH ?? 1.0;

  if (lockRatio != null) {
    if (!handle.isCorner) return rect;
    return _resizeLocked(
      rect,
      handle,
      deltaNorm,
      lockRatio,
      minW,
      minH,
      maxW,
      maxH,
    );
  }

  if (handle == CropHandle.move || handle == CropHandle.focal) return rect;

  final movesLeft =
      handle == CropHandle.left ||
      handle == CropHandle.topLeft ||
      handle == CropHandle.bottomLeft;
  final movesRight =
      handle == CropHandle.right ||
      handle == CropHandle.topRight ||
      handle == CropHandle.bottomRight;
  final movesTop =
      handle == CropHandle.top ||
      handle == CropHandle.topLeft ||
      handle == CropHandle.topRight;
  final movesBottom =
      handle == CropHandle.bottom ||
      handle == CropHandle.bottomLeft ||
      handle == CropHandle.bottomRight;

  var l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
  if (movesLeft) l += deltaNorm.dx;
  if (movesRight) r += deltaNorm.dx;
  if (movesTop) t += deltaNorm.dy;
  if (movesBottom) b += deltaNorm.dy;

  // Clamp each dragged edge against its fixed opposite: between the min and max
  // span and inside the image.
  if (movesLeft) l = _clampEdge(l, math.max(0.0, r - maxW), r - minW);
  if (movesRight) r = _clampEdge(r, l + minW, math.min(1.0, l + maxW));
  if (movesTop) t = _clampEdge(t, math.max(0.0, b - maxH), b - minH);
  if (movesBottom) b = _clampEdge(b, t + minH, math.min(1.0, t + maxH));
  return Rect.fromLTRB(l, t, r, b);
}

/// Clamp guarded against an inverted range (lo > hi when the rect already
/// violates a limit).
double _clampEdge(double v, double lo, double hi) =>
    v.clamp(math.min(lo, hi), math.max(lo, hi));

Rect _resizeLocked(
  Rect rect,
  CropHandle handle,
  Offset delta,
  double ratio,
  double minW,
  double minH,
  double maxW,
  double maxH,
) {
  // Anchor the opposite corner; grow from it toward the dragged corner.
  late double anchorX, anchorY, cornerX;
  late double dirX, dirY;
  switch (handle) {
    case CropHandle.bottomRight:
      anchorX = rect.left;
      anchorY = rect.top;
      cornerX = rect.right;
      dirX = 1;
      dirY = 1;
    case CropHandle.topLeft:
      anchorX = rect.right;
      anchorY = rect.bottom;
      cornerX = rect.left;
      dirX = -1;
      dirY = -1;
    case CropHandle.topRight:
      anchorX = rect.left;
      anchorY = rect.bottom;
      cornerX = rect.right;
      dirX = 1;
      dirY = -1;
    case CropHandle.bottomLeft:
      anchorX = rect.right;
      anchorY = rect.top;
      cornerX = rect.left;
      dirX = -1;
      dirY = 1;
    default:
      return rect;
  }

  var width = (cornerX + delta.dx - anchorX).abs();
  final maxByX = dirX > 0 ? 1 - anchorX : anchorX;
  final maxByY = dirY > 0 ? 1 - anchorY : anchorY;
  final minWidth = math.max(minW, minH * ratio);
  final maxWidth = math.min(
    math.min(maxByX, maxByY * ratio),
    math.min(maxW, maxH * ratio),
  );
  if (maxWidth < minWidth) return rect;
  width = width.clamp(minWidth, maxWidth);
  final height = width / ratio;

  final left = dirX > 0 ? anchorX : anchorX - width;
  final right = dirX > 0 ? anchorX + width : anchorX;
  final top = dirY > 0 ? anchorY : anchorY - height;
  final bottom = dirY > 0 ? anchorY + height : anchorY;
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Slides [rect] by [deltaNorm], clamped so it stays fully inside the image.
Rect cropMove(Rect rect, Offset deltaNorm) {
  final dx = deltaNorm.dx.clamp(-rect.left, 1 - rect.right);
  final dy = deltaNorm.dy.clamp(-rect.top, 1 - rect.bottom);
  return rect.shift(Offset(dx, dy));
}

/// Rotates the whole [value] a quarter turn — [dir] >= 0 is clockwise. The crop
/// and focal are rotated with the content so the same region stays framed, and
/// [CropValue.quarterTurns] tracks the turn for the pixel render.
CropValue cropRotate(CropValue value, int dir) {
  final q = ((value.quarterTurns + (dir >= 0 ? 1 : -1)) % 4 + 4) % 4;
  final r = value.rect;
  final f = value.focal;
  if (dir >= 0) {
    return value.copyWith(
      quarterTurns: q,
      rect: Rect.fromLTRB(1 - r.bottom, r.left, 1 - r.top, r.right),
      focal: f == null ? null : Offset(1 - f.dy, f.dx),
    );
  }
  return value.copyWith(
    quarterTurns: q,
    rect: Rect.fromLTRB(r.top, 1 - r.right, r.bottom, 1 - r.left),
    focal: f == null ? null : Offset(f.dy, 1 - f.dx),
  );
}

/// Mirrors the whole [value] along [axis]. The crop and focal mirror with the
/// content; the matching flip flag toggles for the pixel render.
CropValue cropFlip(CropValue value, Axis axis) {
  final r = value.rect;
  final f = value.focal;
  if (axis == Axis.horizontal) {
    return value.copyWith(
      flipH: !value.flipH,
      rect: Rect.fromLTRB(1 - r.right, r.top, 1 - r.left, r.bottom),
      focal: f == null ? null : Offset(1 - f.dx, f.dy),
    );
  }
  return value.copyWith(
    flipV: !value.flipV,
    rect: Rect.fromLTRB(r.left, 1 - r.bottom, r.right, 1 - r.top),
    focal: f == null ? null : Offset(f.dx, 1 - f.dy),
  );
}

/// [focal] clamped inside [rect].
Offset cropClampFocal(Offset focal, Rect rect) => Offset(
  focal.dx.clamp(rect.left, rect.right),
  focal.dy.clamp(rect.top, rect.bottom),
);

/// Keyboard nudge: shifts the crop (or, when [focal] is set, the focal point) by
/// [deltaNorm], clamped to the image. Used by the arrow-key handler.
CropValue cropNudge(CropValue value, Offset deltaNorm, {bool focal = false}) {
  if (focal) {
    final f = (value.focal ?? value.center) + deltaNorm;
    return value.copyWith(focal: cropClampFocal(f, value.rect));
  }
  return value
      .copyWith(rect: cropMove(value.rect, deltaNorm))
      .withClampedFocal();
}

/// The crop [rect] expressed as a pixel rect inside [display].
Rect cropToPixels(Rect rect, Rect display) => Rect.fromLTRB(
  display.left + rect.left * display.width,
  display.top + rect.top * display.height,
  display.left + rect.right * display.width,
  display.top + rect.bottom * display.height,
);

/// Inverse of [cropToPixels]: a pixel point back to normalized image coords.
Offset cropToNorm(Offset point, Rect display) => Offset(
  ((point.dx - display.left) / display.width).clamp(0.0, 1.0),
  ((point.dy - display.top) / display.height).clamp(0.0, 1.0),
);

/// The largest normalized rect of visual [targetAspect] (pixels w/h) centred on
/// [focal] and clamped inside the image, given the image's own [imageAspect].
/// This is the downstream payoff of a focal point: render the same asset to any
/// shape and the subject stays framed.
Rect focalCrop({
  required Offset focal,
  required double imageAspect,
  required double targetAspect,
}) {
  final normRatio = targetAspect / imageAspect;
  final double w, h;
  if (normRatio >= 1) {
    w = 1;
    h = 1 / normRatio;
  } else {
    h = 1;
    w = normRatio;
  }
  final left = (focal.dx - w / 2).clamp(0.0, 1 - w);
  final top = (focal.dy - h / 2).clamp(0.0, 1 - h);
  return Rect.fromLTWH(left, top, w, h);
}

/// How the crop is manipulated. [region] drags a crop rectangle over a static
/// image (the default). [frame] holds the crop window fixed and pans / zooms the
/// image beneath it (avatar-style) — both emit the same [CropValue].
enum CropMode { region, frame }

/// Largest crop rect of normalized aspect [lockRatio] (width / height) centred
/// in the image — the fully zoomed-out window for [CropMode.frame].
Rect maxFramedRect(double lockRatio) {
  final double w, h;
  if (lockRatio >= 1) {
    w = 1;
    h = 1 / lockRatio;
  } else {
    h = 1;
    w = lockRatio;
  }
  return Rect.fromLTWH((1 - w) / 2, (1 - h) / 2, w, h);
}

/// Frame mode: zoom the crop window by [scaleFactor] (> 1 zooms in) around
/// [focus] (normalized, default the window centre), holding aspect [lockRatio]
/// and staying inside the image. Bounded to [maxZoom]× the fully-out window.
CropValue cropZoom(
  CropValue value,
  double scaleFactor, {
  required double lockRatio,
  double maxZoom = 6,
  Offset? focus,
}) {
  final maxRect = maxFramedRect(lockRatio);
  final r = value.rect;
  final newW = (r.width / scaleFactor).clamp(
    maxRect.width / maxZoom,
    maxRect.width,
  );
  final newH = newW / lockRatio;
  final ratio = newW / r.width;
  final f = focus ?? r.center;
  final left = (f.dx - (f.dx - r.left) * ratio).clamp(0.0, 1 - newW);
  final top = (f.dy - (f.dy - r.top) * ratio).clamp(0.0, 1 - newH);
  return value.copyWith(rect: Rect.fromLTWH(left, top, newW, newH));
}

/// Frame mode placement: where to draw the whole image (box coords) so its
/// normalized [rect] fills the fixed [frame].
Rect framedImageRect(Rect rect, Rect frame) {
  final w = frame.width / rect.width;
  final h = frame.height / rect.height;
  return Rect.fromLTWH(
    frame.left - rect.left * w,
    frame.top - rect.top * h,
    w,
    h,
  );
}

/// Scale needed so an image filling a box of [displayAspect] (width / height),
/// rotated by [angleDeg], still covers the whole box — no empty corners. Used
/// by the straighten control. Returns 1 at angle 0.
double straightenCoverScale(double angleDeg, double displayAspect) {
  final a = angleDeg * math.pi / 180;
  final c = math.cos(a).abs();
  final s = math.sin(a).abs();
  final w = displayAspect, h = 1.0;
  final sx = (w * c + h * s) / w;
  final sy = (w * s + h * c) / h;
  return math.max(sx, sy);
}

/// Which part of the crop [cropPx] (pixels) sits under [point]. Focal wins over
/// everything when [focalPx] is given; then corners, then edges (unless
/// [locked]), then the interior. Returns null on a miss.
CropHandle? cropHitTest({
  required Rect cropPx,
  required Offset point,
  double edge = 22,
  Offset? focalPx,
  double focalRadius = 18,
  bool locked = false,
}) {
  if (focalPx != null && (point - focalPx).distance <= focalRadius) {
    return CropHandle.focal;
  }
  bool near(Offset c) => (point - c).distance <= edge;
  if (near(cropPx.topLeft)) return CropHandle.topLeft;
  if (near(cropPx.topRight)) return CropHandle.topRight;
  if (near(cropPx.bottomLeft)) return CropHandle.bottomLeft;
  if (near(cropPx.bottomRight)) return CropHandle.bottomRight;

  if (!locked) {
    final inX = point.dx > cropPx.left + edge && point.dx < cropPx.right - edge;
    final inY = point.dy > cropPx.top + edge && point.dy < cropPx.bottom - edge;
    if (inX && (point.dy - cropPx.top).abs() <= edge) return CropHandle.top;
    if (inX && (point.dy - cropPx.bottom).abs() <= edge) {
      return CropHandle.bottom;
    }
    if (inY && (point.dx - cropPx.left).abs() <= edge) return CropHandle.left;
    if (inY && (point.dx - cropPx.right).abs() <= edge) return CropHandle.right;
  }
  if (cropPx.contains(point)) return CropHandle.move;
  return null;
}

// ── widget ───────────────────────────────────────────────────────────────

/// An image crop + focal-point editor. View-pure: it owns no asset bytes beyond
/// the [image] provider and emits a new [CropValue] through [onChanged] on every
/// drag — a null [onChanged] is read-only.
///
/// [imageAspect] (pixel width / height) is required so the canvas letterboxes
/// correctly and aspect-locking is exact without decoding the bitmap. Pass
/// [lockedAspect] to constrain the crop to a pixel ratio (corner handles only);
/// pass [aspectPresets] + [onAspectChanged] to show the ratio bar (it is
/// disabled while the cropper is read-only). Turn on
/// [showFocalPoint] for the draggable subject marker.
///
/// The editing affordances are opt-in feature flags so a host enables only what
/// it wants: [allowRotate] (90° turns), [allowFlip] (mirror), [allowReset]
/// (back to the whole image). Each adds a button to the toolbar.
///
/// [mode] picks the interaction: [CropMode.region] (default) drags a crop
/// rectangle over a static image; [CropMode.frame] holds a fixed window and
/// pans / zooms the image beneath it — which needs [lockedAspect].
class ImageCropper extends StatefulWidget {
  final ImageProvider image;
  final double imageAspect;
  final CropValue value;
  final ValueChanged<CropValue>? onChanged;
  final CropMode mode;

  /// Pixel width / height the crop is constrained to; null is freeform. Required
  /// in [CropMode.frame] (it is the frame's shape).
  final double? lockedAspect;

  /// Frame mode: largest zoom-in multiple over the fully-out window.
  final double maxZoom;

  final bool showFocalPoint;

  /// Rule-of-thirds guide lines inside the crop.
  final bool showThirds;

  /// The ratios offered in a bar above the canvas; shown only with
  /// [onAspectChanged], which gets the one picked. The host keeps it and
  /// passes its ratio back as [lockedAspect]; picking one with a ratio also
  /// reshapes the crop to it, as large as fits around the crop's centre.
  final List<AspectPreset>? aspectPresets;
  final ValueChanged<AspectPreset>? onAspectChanged;

  /// Opt-in toolbar affordances.
  final bool allowRotate;
  final bool allowFlip;
  final bool allowReset;

  /// Opt-in straighten slider, spanning ±[maxStraighten] degrees.
  final bool allowStraighten;
  final double maxStraighten;

  /// Pixel dimensions of the source. Required to enforce [minSize]/[maxSize];
  /// otherwise optional (the aspect alone drives layout).
  final Size? imageSize;

  /// Smallest / largest crop allowed, in source pixels. Need [imageSize].
  final Size? minSize;
  final Size? maxSize;

  const ImageCropper({
    super.key,
    required this.image,
    required this.imageAspect,
    this.value = CropValue.full,
    this.onChanged,
    this.mode = CropMode.region,
    this.lockedAspect,
    this.maxZoom = 6,
    this.showFocalPoint = false,
    this.showThirds = true,
    this.aspectPresets,
    this.onAspectChanged,
    this.allowRotate = false,
    this.allowFlip = false,
    this.allowReset = false,
    this.allowStraighten = false,
    this.maxStraighten = 15,
    this.imageSize,
    this.minSize,
    this.maxSize,
  }) : assert(
         (minSize == null && maxSize == null) || imageSize != null,
         'minSize/maxSize need imageSize to convert pixels to fractions',
       ),
       assert(
         mode == CropMode.region || lockedAspect != null,
         'frame mode needs lockedAspect — the frame shape',
       );

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  CropHandle? _active;
  CropHandle? _hover;
  bool _focused = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'ImageCropper');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _readOnly => widget.onChanged == null;

  KeyEventResult _onKey(KeyEvent event, Rect display) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final step = keyboard.isShiftPressed ? 0.05 : 0.01;
    final Offset delta;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        delta = Offset(-step, 0);
      case LogicalKeyboardKey.arrowRight:
        delta = Offset(step, 0);
      case LogicalKeyboardKey.arrowUp:
        delta = Offset(0, -step);
      case LogicalKeyboardKey.arrowDown:
        delta = Offset(0, step);
      default:
        return KeyEventResult.ignored;
    }
    final focal = widget.showFocalPoint && keyboard.isAltPressed;
    widget.onChanged!(cropNudge(widget.value, delta, focal: focal));
    return KeyEventResult.handled;
  }

  /// The on-screen aspect after rotation — odd quarter turns swap width/height.
  double get _effectiveAspect => widget.value.quarterTurns.isOdd
      ? 1 / widget.imageAspect
      : widget.imageAspect;

  /// The crop's locked ratio in normalized space (visual aspect ÷ image aspect).
  double? get _lockRatio => widget.lockedAspect == null
      ? null
      : widget.lockedAspect! / _effectiveAspect;

  Rect _displayRect(Size box) {
    var w = box.width;
    var h = w / _effectiveAspect;
    if (h > box.height) {
      h = box.height;
      w = h * _effectiveAspect;
    }
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  /// Source pixel size in the displayed orientation (axes swap on odd turns).
  Size? get _effectiveImageSize {
    final s = widget.imageSize;
    if (s == null) return null;
    return widget.value.quarterTurns.isOdd ? Size(s.height, s.width) : s;
  }

  double? get _minNormW => widget.minSize == null
      ? null
      : widget.minSize!.width / _effectiveImageSize!.width;
  double? get _minNormH => widget.minSize == null
      ? null
      : widget.minSize!.height / _effectiveImageSize!.height;
  double? get _maxNormW => widget.maxSize == null
      ? null
      : widget.maxSize!.width / _effectiveImageSize!.width;
  double? get _maxNormH => widget.maxSize == null
      ? null
      : widget.maxSize!.height / _effectiveImageSize!.height;

  Offset? _focalPx(Rect display) {
    if (!widget.showFocalPoint) return null;
    final f = widget.value.focal ?? widget.value.center;
    return Offset(
      display.left + f.dx * display.width,
      display.top + f.dy * display.height,
    );
  }

  void _onPanStart(DragStartDetails d, Rect display) {
    if (_readOnly) return;
    final cropPx = cropToPixels(widget.value.rect, display);
    final hit = cropHitTest(
      cropPx: cropPx,
      point: d.localPosition,
      focalPx: _focalPx(display),
      locked: _lockRatio != null,
    );
    setState(() => _active = hit);
  }

  void _onPanUpdate(DragUpdateDetails d, Rect display) {
    final handle = _active;
    if (handle == null) return;
    final deltaNorm = Offset(
      d.delta.dx / display.width,
      d.delta.dy / display.height,
    );
    final v = widget.value;
    CropValue next;
    switch (handle) {
      case CropHandle.focal:
        next = v.copyWith(
          focal: cropClampFocal(cropToNorm(d.localPosition, display), v.rect),
        );
      case CropHandle.move:
        next = v.copyWith(rect: cropMove(v.rect, deltaNorm)).withClampedFocal();
      default:
        next = v
            .copyWith(
              rect: cropResize(
                rect: v.rect,
                handle: handle,
                deltaNorm: deltaNorm,
                lockRatio: _lockRatio,
                minNormW: _minNormW,
                minNormH: _minNormH,
                maxNormW: _maxNormW,
                maxNormH: _maxNormH,
              ),
            )
            .withClampedFocal();
    }
    widget.onChanged!(next);
  }

  void _updateHover(Offset? local, Rect display) {
    if (_readOnly) {
      return;
    }
    final hit = local == null
        ? null
        : cropHitTest(
            cropPx: cropToPixels(widget.value.rect, display),
            point: local,
            focalPx: _focalPx(display),
            locked: _lockRatio != null,
          );
    if (hit != _hover) setState(() => _hover = hit);
  }

  MouseCursor _cursorFor(CropHandle? h) {
    switch (h) {
      case CropHandle.topLeft:
      case CropHandle.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case CropHandle.topRight:
      case CropHandle.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case CropHandle.left:
      case CropHandle.right:
        return SystemMouseCursors.resizeLeftRight;
      case CropHandle.top:
      case CropHandle.bottom:
        return SystemMouseCursors.resizeUpDown;
      case CropHandle.focal:
        return SystemMouseCursors.grab;
      case CropHandle.move:
        return SystemMouseCursors.move;
      case null:
        return MouseCursor.defer;
    }
  }

  bool get _hasTransforms =>
      !_readOnly &&
      widget.mode == CropMode.region &&
      (widget.allowRotate || widget.allowFlip || widget.allowReset);

  void _emit(CropValue v) => widget.onChanged!(v);

  void _pickAspect(AspectPreset preset) {
    widget.onAspectChanged!(preset);
    final ratio = preset.ratio;
    if (ratio == null || _readOnly) return;
    final rect = focalCrop(
      focal: widget.value.rect.center,
      imageAspect: _effectiveAspect,
      targetAspect: ratio,
    );
    if (rect != widget.value.rect) _emit(widget.value.copyWith(rect: rect));
  }

  Widget _buildImage() => Image(
    image: widget.image,
    fit: BoxFit.fill,
    loadingBuilder: (context, child, progress) =>
        progress == null ? child : const _ImageStatus(),
    errorBuilder: (context, error, stack) => _ImageStatus(
      icon: Icons.broken_image_outlined,
      label: context.adminL10n.assets.imageUnavailable,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final region = widget.mode == CropMode.region;
    final hasAspectBar =
        region &&
        widget.aspectPresets != null &&
        widget.onAspectChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasAspectBar || _hasTransforms) ...[
          Row(
            children: [
              if (hasAspectBar)
                Expanded(
                  child: _AspectBar(
                    presets: widget.aspectPresets!,
                    selected: widget.lockedAspect,
                    onChanged: _readOnly ? null : _pickAspect,
                  ),
                )
              else
                const Spacer(),
              if (_hasTransforms)
                _TransformBar(
                  allowRotate: widget.allowRotate,
                  allowFlip: widget.allowFlip,
                  allowReset: widget.allowReset,
                  canReset: widget.value != CropValue.full,
                  onRotate: (dir) => _emit(cropRotate(widget.value, dir)),
                  onFlip: (axis) => _emit(cropFlip(widget.value, axis)),
                  onReset: () => _emit(CropValue.full),
                ),
            ],
          ),
          const Gap(AdminSpacing.md),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final box = constraints.biggest;
              return region
                  ? _regionStage(context, _displayRect(box))
                  : _frameStage(context, box);
            },
          ),
        ),
        if (widget.allowStraighten && !_readOnly && region) ...[
          const Gap(AdminSpacing.md),
          _StraightenSlider(
            angle: widget.value.angle,
            max: widget.maxStraighten,
            onChanged: (a) => _emit(widget.value.copyWith(angle: a)),
          ),
        ],
        if (!region && !_readOnly) ...[
          const Gap(AdminSpacing.md),
          _ZoomSlider(
            zoom: _frameZoom,
            maxZoom: widget.maxZoom,
            onChanged: _setZoom,
          ),
        ],
      ],
    );
  }

  Widget _regionStage(BuildContext context, Rect display) {
    return Semantics(
      label: context.adminL10n.assets.cropArea,
      hint: _readOnly ? null : context.adminL10n.assets.cropAreaHint,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: !_readOnly,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: _readOnly ? null : (_, event) => _onKey(event, display),
        child: MouseRegion(
          cursor: _cursorFor(_active ?? _hover),
          onHover: (e) => _updateHover(e.localPosition, display),
          onExit: (_) => _updateHover(null, display),
          child: GestureDetector(
            onPanStart: (d) {
              _focusNode.requestFocus();
              _onPanStart(d, display);
            },
            onPanUpdate: (d) => _onPanUpdate(d, display),
            onPanEnd: (_) => setState(() => _active = null),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Physical: the crop is geometry of the image's pixels, which
                // do not mirror, so neither do the stage, its handles and keys.
                Positioned.fromRect(
                  rect: display,
                  child: ClipRect(
                    child: Transform.flip(
                      flipX: widget.value.flipH,
                      flipY: widget.value.flipV,
                      child: Transform.rotate(
                        angle: widget.value.angle * math.pi / 180,
                        child: Transform.scale(
                          scale: straightenCoverScale(
                            widget.value.angle,
                            display.width / display.height,
                          ),
                          child: RotatedBox(
                            quarterTurns: widget.value.quarterTurns,
                            child: _buildImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CropPainter(
                      display: display,
                      value: widget.value,
                      accent: context.colors.primary,
                      onImage: context.colors.onImage,
                      scrim: context.colors.imageScrim,
                      // Half a check box's corner on a handle two thirds its
                      // size: square in a square theme, never a dot.
                      handleRadius: context.radii.radiusCheck / 2,
                      locked: _lockRatio != null,
                      showThirds: widget.showThirds && !_readOnly,
                      showHandles: !_readOnly,
                      showFocal: widget.showFocalPoint,
                      focalPx: _focalPx(display),
                      focused: _focused,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── frame mode ──

  /// Largest rect of the frame's pixel aspect ([ImageCropper.lockedAspect])
  /// centred in [box].
  Rect _frameRect(Size box) {
    final aspect = widget.lockedAspect!;
    var w = box.width;
    var h = w / aspect;
    if (h > box.height) {
      h = box.height;
      w = h * aspect;
    }
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  double get _frameZoom =>
      maxFramedRect(_lockRatio!).width / widget.value.rect.width;

  void _setZoom(double zoom) {
    final lockRatio = _lockRatio!;
    final targetW = maxFramedRect(lockRatio).width / zoom;
    widget.onChanged!(
      cropZoom(
        widget.value,
        widget.value.rect.width / targetW,
        lockRatio: lockRatio,
        maxZoom: widget.maxZoom,
      ),
    );
  }

  void _onFramePan(DragUpdateDetails d, Rect frame) {
    final r = widget.value.rect;
    final delta = Offset(
      -d.delta.dx * r.width / frame.width,
      -d.delta.dy * r.height / frame.height,
    );
    widget.onChanged!(widget.value.copyWith(rect: cropMove(r, delta)));
  }

  void _onFrameScroll(PointerSignalEvent e, Rect imageRect) {
    if (e is! PointerScrollEvent) return;
    final factor = e.scrollDelta.dy < 0 ? 1.1 : 1 / 1.1;
    final focus = Offset(
      ((e.localPosition.dx - imageRect.left) / imageRect.width).clamp(0.0, 1.0),
      ((e.localPosition.dy - imageRect.top) / imageRect.height).clamp(0.0, 1.0),
    );
    widget.onChanged!(
      cropZoom(
        widget.value,
        factor,
        lockRatio: _lockRatio!,
        maxZoom: widget.maxZoom,
        focus: focus,
      ),
    );
  }

  Widget _frameStage(BuildContext context, Size box) {
    final frame = _frameRect(box);
    final imageRect = framedImageRect(widget.value.rect, frame);
    return Semantics(
      label: context.adminL10n.assets.positionArea,
      hint: _readOnly ? null : context.adminL10n.assets.positionAreaHint,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: !_readOnly,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: _readOnly ? null : (_, event) => _onKey(event, frame),
        child: MouseRegion(
          cursor: _readOnly ? MouseCursor.defer : SystemMouseCursors.move,
          child: Listener(
            onPointerSignal: _readOnly
                ? null
                : (e) => _onFrameScroll(e, imageRect),
            child: GestureDetector(
              onPanStart: _readOnly ? null : (_) => _focusNode.requestFocus(),
              onPanUpdate: _readOnly ? null : (d) => _onFramePan(d, frame),
              child: ColoredBox(
                color: context.colors.surfaceMuted,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Physical: the frame shows the image's own pixels.
                    Positioned.fromRect(
                      rect: frame,
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fromRect(
                              rect: imageRect.shift(-frame.topLeft),
                              child: _buildImage(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FrameOverlayPainter(
                          frame: frame,
                          accent: context.colors.primary,
                          onImage: context.colors.onImage,
                          showThirds: widget.showThirds && !_readOnly,
                          focused: _focused,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  final double zoom;
  final double maxZoom;
  final ValueChanged<double> onChanged;

  const _ZoomSlider({
    required this.zoom,
    required this.maxZoom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.adminL10n.assets.zoom,
          style: context.type.bodySmall.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
        const Gap(AdminSpacing.md),
        Expanded(
          child: ValueSlider(
            value: zoom.clamp(1, maxZoom),
            min: 1,
            max: maxZoom,
            showValue: false,
            onChanged: onChanged,
          ),
        ),
        const Gap(AdminSpacing.md),
        SizedBox(
          width: 36,
          child: Text(
            context.adminL10n.assets.zoomLevel(
              context.adminFormats.decimal(zoom, fractionDigits: 1),
            ),
            textAlign: TextAlign.end,
            style: context.type.bodySmall.copyWith(
              color: context.colors.foregroundSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _FrameOverlayPainter extends CustomPainter {
  final Rect frame;
  final Color accent;

  /// Guides drawn over the photo.
  final Color onImage;
  final bool showThirds;
  final bool focused;

  _FrameOverlayPainter({
    required this.frame,
    required this.accent,
    required this.onImage,
    required this.showThirds,
    required this.focused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (focused) {
      canvas.drawRect(
        frame.inflate(2),
        Paint()
          // token-literal: the focused frame, drawn over the picture
          ..color = accent.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
    if (showThirds) {
      final grid = Paint()
        // token-literal: the rule-of-thirds lines, drawn over the picture
        ..color = onImage.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      for (var i = 1; i < 3; i++) {
        final dx = frame.left + frame.width * i / 3;
        final dy = frame.top + frame.height * i / 3;
        canvas.drawLine(Offset(dx, frame.top), Offset(dx, frame.bottom), grid);
        canvas.drawLine(Offset(frame.left, dy), Offset(frame.right, dy), grid);
      }
    }
    canvas.drawRect(
      frame,
      Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_FrameOverlayPainter old) =>
      old.frame != frame ||
      old.accent != accent ||
      old.onImage != onImage ||
      old.showThirds != showThirds ||
      old.focused != focused;
}

class _StraightenSlider extends StatelessWidget {
  final double angle;
  final double max;
  final ValueChanged<double> onChanged;

  const _StraightenSlider({
    required this.angle,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.adminL10n.assets.straighten,
          style: context.type.bodySmall.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
        const Gap(AdminSpacing.md),
        Expanded(
          child: Directionality(
            // Physical: the image never mirrors; right turns it clockwise.
            textDirection: TextDirection.ltr,
            child: ValueSlider(
              value: angle,
              min: -max,
              max: max,
              showValue: false,
              onChanged: onChanged,
            ),
          ),
        ),
        const Gap(AdminSpacing.md),
        SizedBox(
          width: 36,
          child: Text(
            context.adminL10n.assets.degrees(
              context.adminFormats.integer(angle.round()),
            ),
            textAlign: TextAlign.end,
            style: context.type.bodySmall.copyWith(
              color: context.colors.foregroundSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _AspectBar extends StatelessWidget {
  final List<AspectPreset> presets;
  final double? selected;
  final ValueChanged<AspectPreset>? onChanged;

  const _AspectBar({
    required this.presets,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.xs,
      runSpacing: AdminSpacing.xs,
      children: [
        for (final p in presets)
          _AspectChip(
            label: p.labelOf(context),
            active: p.ratio == selected,
            onTap: onChanged == null ? null : () => onChanged!(p),
          ),
      ],
    );
  }
}

/// One ratio of the bar: a toggle, filled in the primary while chosen, and
/// greyed out with the rest of the bar while the cropper is read-only.
class _AspectChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _AspectChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(context.radii.radiusSmall);
    final Color fill;
    final Color border;
    final Color text;
    if (!enabled) {
      fill = active ? colors.surfaceMuted : colors.background;
      border = colors.border;
      text = colors.placeholder;
    } else if (active) {
      fill = colors.primary;
      border = colors.primary;
      text = colors.onPrimary;
    } else {
      fill = colors.background;
      border = colors.border;
      text = colors.foregroundSecondary;
    }
    return Semantics(
      button: true,
      selected: active,
      enabled: enabled,
      child: Material(
        color: fill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.md,
              vertical: AdminSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: border),
            ),
            child: Text(
              label,
              style: context.type
                  .weighted(
                    context.type.bodySmall,
                    active ? FontWeight.w600 : FontWeight.w500,
                  )
                  .copyWith(color: text),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageStatus extends StatelessWidget {
  final IconData? icon;
  final String? label;

  const _ImageStatus({this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Center(
        child: icon == null
            ? const Spinner()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: colors.foregroundMuted),
                  if (label != null) ...[
                    const Gap(AdminSpacing.sm),
                    Text(
                      label!,
                      style: context.type.bodySmall.copyWith(
                        color: colors.foregroundMuted,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TransformBar extends StatelessWidget {
  final bool allowRotate;
  final bool allowFlip;
  final bool allowReset;
  final bool canReset;
  final ValueChanged<int> onRotate;
  final ValueChanged<Axis> onFlip;
  final VoidCallback onReset;

  const _TransformBar({
    required this.allowRotate,
    required this.allowFlip,
    required this.allowReset,
    required this.canReset,
    required this.onRotate,
    required this.onFlip,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    return Wrap(
      spacing: AdminSpacing.xs,
      children: [
        if (allowRotate) ...[
          _ToolButton(
            icon: Icons.rotate_90_degrees_ccw_outlined,
            tooltip: strings.rotateLeft,
            onTap: () => onRotate(-1),
          ),
          _ToolButton(
            icon: Icons.rotate_90_degrees_cw_outlined,
            tooltip: strings.rotateRight,
            onTap: () => onRotate(1),
          ),
        ],
        if (allowFlip) ...[
          _ToolButton(
            icon: Icons.flip,
            tooltip: strings.flipHorizontal,
            onTap: () => onFlip(Axis.horizontal),
          ),
          _ToolButton(
            icon: Icons.flip,
            iconQuarterTurns: 1,
            tooltip: strings.flipVertical,
            onTap: () => onFlip(Axis.vertical),
          ),
        ],
        if (allowReset)
          _ToolButton(
            icon: Icons.restart_alt,
            tooltip: context.adminL10n.reset,
            onTap: canReset ? onReset : null,
          ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int iconQuarterTurns;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconQuarterTurns = 0,
  });

  @override
  Widget build(BuildContext context) {
    final button = Button.icon(
      icon,
      semanticLabel: tooltip,
      size: ControlSize.small,
      onPressed: onTap,
    );
    // A glyph turned a quarter (the vertical flip is the horizontal one on
    // its side) turns its square button with it, which looks the same.
    if (iconQuarterTurns == 0) return button;
    return RotatedBox(quarterTurns: iconQuarterTurns, child: button);
  }
}

class _CropPainter extends CustomPainter {
  final Rect display;
  final CropValue value;
  final Color accent;

  /// Handles, guides and the focal marker's halo, drawn over the photo.
  final Color onImage;

  /// The wash dimming the photo outside the crop.
  final Color scrim;

  /// The corner of the square drag handles.
  final double handleRadius;
  final bool locked;
  final bool showThirds;
  final bool showHandles;
  final bool showFocal;
  final Offset? focalPx;
  final bool focused;

  _CropPainter({
    required this.display,
    required this.value,
    required this.accent,
    required this.onImage,
    required this.scrim,
    required this.handleRadius,
    required this.locked,
    required this.showThirds,
    required this.showHandles,
    required this.showFocal,
    required this.focalPx,
    required this.focused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final crop = cropToPixels(value.rect, display);

    if (focused) {
      canvas.drawRect(
        display.inflate(2),
        Paint()
          // token-literal: the focused frame, drawn over the picture
          ..color = accent.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Dim everything outside the crop.
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addRect(crop)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = scrim);

    if (showThirds) {
      final grid = Paint()
        // token-literal: the rule-of-thirds lines, drawn over the picture
        ..color = onImage.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      for (var i = 1; i < 3; i++) {
        final dx = crop.left + crop.width * i / 3;
        final dy = crop.top + crop.height * i / 3;
        canvas.drawLine(Offset(dx, crop.top), Offset(dx, crop.bottom), grid);
        canvas.drawLine(Offset(crop.left, dy), Offset(crop.right, dy), grid);
      }
    }

    // Crop frame.
    canvas.drawRect(
      crop,
      Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    if (showHandles) {
      final fill = Paint()..color = onImage;
      final ring = Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      void handle(Offset c) {
        final r = Rect.fromCenter(center: c, width: 12, height: 12);
        final rr = RRect.fromRectAndRadius(r, Radius.circular(handleRadius));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, ring);
      }

      handle(crop.topLeft);
      handle(crop.topRight);
      handle(crop.bottomLeft);
      handle(crop.bottomRight);
      if (!locked) {
        handle(crop.topCenter);
        handle(crop.bottomCenter);
        handle(crop.centerLeft);
        handle(crop.centerRight);
      }
    }

    if (showFocal && focalPx != null) {
      final c = focalPx!;
      final outline = Paint()
        ..color = onImage
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final stroke = Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(c, 11, outline);
      canvas.drawCircle(c, 11, stroke);
      for (final d in const [
        Offset(-7, 0),
        Offset(7, 0),
        Offset(0, -7),
        Offset(0, 7),
      ]) {
        canvas.drawLine(c, c + d, stroke);
      }
      canvas.drawCircle(c, 2.5, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.display != display ||
      old.value != value ||
      old.accent != accent ||
      old.onImage != onImage ||
      old.scrim != scrim ||
      old.handleRadius != handleRadius ||
      old.locked != locked ||
      old.showThirds != showThirds ||
      old.showHandles != showHandles ||
      old.showFocal != showFocal ||
      old.focalPx != focalPx ||
      old.focused != focused;
}
