import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/shortcut_label.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'focus_ring.dart';
import 'icon_action.dart';
import 'tappable.dart';

/// Zooms a [ZoomView] from outside it, and says what it shows. Give one to
/// the view's [ZoomView.controller], and listen to it: it notifies on every
/// change of [scale] or of the part of the content in view.
///
/// One controller drives one view at a time. Until that view has laid out,
/// [scale] is 1, [isFitted] is true, [canZoomIn] is false and the methods do
/// nothing.
class ZoomController extends ChangeNotifier {
  _ZoomViewState? _view;

  /// Logical pixels per content pixel. At 1 each content pixel takes one
  /// logical pixel, as a browser draws an image at its own size: the
  /// controls read it as 100%.
  double get scale => _view?._scale ?? 1;

  /// Whether the whole content is in view, as large as it fits: where the
  /// view opens, and as far as it zooms out.
  bool get isFitted => _view?._fitted ?? true;

  /// Whether the view is short of its [ZoomView.maxScale], so [zoomIn]
  /// moves it.
  bool get canZoomIn => _view?._canZoomIn ?? false;

  /// Shows the whole content, centred.
  void fit() => _view?._fit();

  /// Shows the content at actual pixels, a [scale] of 1, about the middle
  /// of the view. A content that actual pixels would show smaller than
  /// fitted fits instead.
  void actualSize() => _view?._actualSize();

  /// Zooms in one step about the middle of the view, to the next of 100%,
  /// 150%, 200%, 300%, 400%, 600%, 800%…, or below 100% of 67%, 50%, 33%,
  /// 25%…, at least a fifth larger, and no further than
  /// [ZoomView.maxScale].
  void zoomIn() => _view?._zoomIn();

  /// Zooms out one step about the middle of the view, down the levels
  /// [zoomIn] climbs, and no further than fitted.
  void zoomOut() => _view?._zoomOut();

  /// Zooms and pans to [region], a rectangle of the content in its own
  /// pixels, such as one the app painted over a picture: as large as the
  /// view holds it, centred on it. No larger than [ZoomView.maxScale], so a
  /// small region shows at that scale about its centre, and no smaller than
  /// fitted, so a region larger than the view fits it instead. Near an edge
  /// the view stops at the content's edge, as a pan does. Inflate [region]
  /// to leave room around it.
  void show(Rect region) => _view?._showRegion(region);

  void _changed() => notifyListeners();
}

/// A large picture, a photo, a scan or a plan, fitted to the space it is
/// given, that the reader zooms and pans to look at closely.
///
/// [child] is laid out at exactly [contentSize], the content's own size,
/// such as an image's pixels, so whatever it paints over the picture, a
/// [CustomPaint] in a [Stack] with an [Image], is in the content's
/// coordinates. Zooming and panning only transform it: [child] is never
/// built or laid out again by them, and it paints behind a
/// [RepaintBoundary], so a heavy painter is cheap to zoom. An [Image] chooses
/// its own `filterQuality`: [FilterQuality.none] shows a photo's pixels as
/// squares close up.
///
/// It fills the space its parent gives it. Given an unbounded height, in a
/// [Column] or a list, it is as tall as the content fitted to its width;
/// given an unbounded width, as wide as fitted to its height.
///
/// It opens fitted: the whole content in view, centred, with empty bands
/// along the sides it does not fill. It paints nothing of its own there, so
/// the surface behind it shows. While fitted, it stays fitted as the space
/// it is given changes. Once zoomed in, it keeps the content point at its
/// middle in place through a resize, and its scale, unless fitted is now
/// larger. A new [contentSize] opens fitted again; a new [child] of the same
/// size keeps the reader's place, to compare pictures of one size at one
/// spot.
///
/// It never shows the content smaller than fitted, nor larger than
/// [maxScale]. Panning stops where an edge of the content meets the edge of
/// the view; along an axis where the content is smaller than the view, it
/// stays centred.
///
/// - **Mouse:** the wheel zooms about the pointer, and a drag pans, with
///   the open hand under the pointer while there is somewhere to pan, and
///   the closed one while dragged. A double click zooms from fitted to
///   actual pixels about the pointer, and from anywhere else back to
///   fitted. Where actual pixels are no larger than fitted, it zooms in one
///   step instead.
/// - **Trackpad:** a pinch zooms about the pointer, and a two-finger
///   scroll pans. A page that scrolls around the view does not scroll with
///   either. (On the web in Firefox, which does not tell a trackpad from a
///   wheel, a two-finger scroll zooms.)
/// - **Touch:** a pinch zooms about the fingers, a drag pans, and a double
///   tap works as a double click.
/// - **Keyboard:** the view takes focus on a click, and is in the Tab order.
///   `+` or `=` zooms in, `-` out, `0` fits and `1` shows actual pixels, with
///   or without ⌘ (Ctrl elsewhere), and the arrow keys pan while there is
///   somewhere to.
///
/// Steps, from the keyboard, the controls, a double click or the
/// [controller], take the theme's `context.motion.medium`, and land at once
/// under reduced motion. The wheel, a pinch and a drag follow the hand.
///
/// With [showControls], a bar floats in the bottom end corner, over the
/// content: zoom out, the scale as a percentage of actual pixels, zoom in,
/// and zoom to fit. A [controller] drives the view from controls of the
/// app's own.
///
/// It is announced as one place, [semanticLabel] or "Zoomable view", with
/// its scale as the value and how to zoom and pan from the keyboard as the
/// hint; the content's own semantics sit inside it. The bar's buttons are
/// named, and the percentage is announced as it changes.
///
/// Right to left, the bar moves to the bottom left and runs from the right.
/// The content is a picture, and the view does not mirror it: the arrow keys
/// pan the way they point. [child] still reads the ambient direction, so a
/// [Row] that sets a label beside a point of the picture gives its own.
class ZoomView extends StatefulWidget {
  /// The content's own size, in its own pixels: [child] is laid out at
  /// exactly this size, and the scale is in logical pixels per one of them.
  final Size contentSize;

  /// The content, at [contentSize].
  final Widget child;

  final ZoomController? controller;

  /// The largest scale, in logical pixels per content pixel: 8 by default,
  /// 800%. Never below fitted: a content that fits only larger cannot zoom
  /// in.
  final double maxScale;

  /// Shows the floating bar of controls.
  final bool showControls;

  /// The accessible name of what the view shows, such as "Floor plan,
  /// level 2": "Zoomable view" unless set.
  final String? semanticLabel;

  const ZoomView({
    super.key,
    required this.contentSize,
    required this.child,
    this.controller,
    this.maxScale = 8,
    this.showControls = true,
    this.semanticLabel,
  }) : assert(maxScale > 0);

  @override
  State<ZoomView> createState() => _ZoomViewState();
}

/// A scale and the place of the content's top-left corner in the view.
typedef _Frame = ({double scale, Offset origin});

/// A step zooms by at least this factor, so a step off a scale between
/// levels, fitted at 23%, never moves by a few percent only.
const _step = 1.2;

/// How close, relative, a scale must be to fitted to be fitted, so a
/// rounding never leaves a hair to pan.
const _snap = 1e-3;

/// The scroll distance that zooms by a factor of e, as Flutter's
/// `InteractiveViewer` and the web engine's pinch take it.
const _wheelPixels = 200.0;

/// How much of the view an arrow key pans by.
const _arrowShare = 0.1;

/// A zoom level of [ZoomController.zoomIn]'s steps: 100% at 0, then
/// alternately ×1.5 and ×4/3 upward (150%, 200%, 300%, 400%…), and the
/// reciprocals below (67%, 50%, 33%, 25%…).
double _level(int index) {
  final n = index.abs();
  final level = math.pow(2, n ~/ 2) * (n.isOdd ? 1.5 : 1);
  return index < 0 ? 1 / level : level.toDouble();
}

/// The lowest level at or above [scale], which is positive.
double _levelAtLeast(double scale) {
  var index = (2 * math.log(scale) / math.ln2).floor() - 2;
  while (_level(index) < scale) {
    index++;
  }
  return _level(index);
}

/// The highest level at or below [scale], which is positive.
double _levelAtMost(double scale) {
  var index = (2 * math.log(scale) / math.ln2).ceil() + 2;
  while (_level(index) > scale) {
    index--;
  }
  return _level(index);
}

/// [scale] as the bar and the semantics value show it: '25%', or with a
/// decimal below 10%, '2.5%'.
String _percent(AdminFormats formats, double scale) =>
    formats.percent(scale, decimals: scale < 0.1 ? 1 : 0);

/// The devices a drag pans and a pinch zooms with. A trackpad's gestures go
/// to [_TrackpadRecognizer] instead.
const _dragDevices = {
  PointerDeviceKind.mouse,
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

class _ZoomViewState extends State<ZoomView>
    with SingleTickerProviderStateMixin {
  ZoomController? _ownController;

  ZoomController get _controller =>
      widget.controller ?? (_ownController ??= ZoomController());

  final _focus = FocusNode(debugLabel: 'ZoomView');
  late final _motion = AnimationController(vsync: this)..addListener(_onMotion);

  /// Whether a drag is under way, for the closed hand.
  final _grabbing = ValueNotifier(false);

  /// The size of the view as of its last layout.
  Size _viewport = Size.zero;

  /// Whether the content has a place in [_viewport]: false until the first
  /// layout and after a new content size, which both open fitted.
  bool _placed = false;

  /// Whether the next layout must check the place against the view, though
  /// it kept its size: after a new maximum scale.
  bool _stale = false;

  double _scale = 1;
  Offset _origin = Offset.zero;
  bool _fitted = true;
  bool _focused = false;
  bool _notifyQueued = false;

  // The step under way: from where, to where, and the point of the view
  // whose content point moves in a straight line meanwhile.
  _Frame? _from;
  _Frame? _to;
  Offset _anchor = Offset.zero;

  // The theme's motion, as of the last build.
  Duration _duration = Duration.zero;
  Curve? _curve;

  // The gesture under way.
  Offset? _lastFocal;
  double _lastGestureScale = 1;
  double _lastPanZoomScale = 1;
  Offset? _doubleTapAt;

  @override
  void initState() {
    super.initState();
    assert(_debugCheckContentSize(widget.contentSize));
    _attach(_controller);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(ZoomView old) {
    super.didUpdateWidget(old);
    assert(_debugCheckContentSize(widget.contentSize));
    if (widget.controller != old.controller) {
      final previous = old.controller ?? _ownController;
      if (previous?._view == this) previous!._view = null;
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _attach(_controller);
      _notifyLater();
    }
    if (widget.contentSize != old.contentSize) {
      _motion.stop();
      _placed = false;
    }
    if (widget.maxScale != old.maxScale) _stale = true;
  }

  @override
  void dispose() {
    if (_controller._view == this) _controller._view = null;
    _ownController?.dispose();
    _focus.dispose();
    _motion.dispose();
    _grabbing.dispose();
    super.dispose();
  }

  void _attach(ZoomController controller) {
    assert(
      controller._view == null || controller._view == this,
      'A ZoomController drives one ZoomView at a time.',
    );
    controller._view = this;
  }

  bool _debugCheckContentSize(Size size) {
    if (size.isFinite && size.width > 0 && size.height > 0) return true;
    throw FlutterError(
      'ZoomView.contentSize must be finite and larger than zero, not $size.',
    );
  }

  void _onFocus() {
    final focused = _focus.hasPrimaryFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  // ── geometry ──

  Size get _content => widget.contentSize;

  Offset get _middle => _viewport.center(Offset.zero);

  double get _fitScale => math.min(
    _viewport.width / _content.width,
    _viewport.height / _content.height,
  );

  double get _maxScale => math.max(widget.maxScale, _fitScale);

  bool _isFit(double scale) => scale <= _fitScale * (1 + _snap);

  bool get _canZoomIn =>
      !_viewport.isEmpty && _target.scale < _maxScale * (1 - _snap);

  /// Whether zooming out or fitting moves the view: it is not fitted, nor
  /// on its way there.
  bool get _canZoomOut => !_viewport.isEmpty && !_isFit(_target.scale);

  /// Whether the content overflows the view along an axis, by more than
  /// half a pixel.
  bool get _canPan =>
      _content.width * _scale > _viewport.width + 0.5 ||
      _content.height * _scale > _viewport.height + 0.5;

  /// Where the view is going: the end of the step under way, or where it is.
  _Frame get _target =>
      _motion.isAnimating ? _to! : (scale: _scale, origin: _origin);

  _Frame get _fitFrame {
    final scale = _fitScale;
    return (scale: scale, origin: _clampOrigin(scale, Offset.zero));
  }

  double _clampScale(double scale) {
    final fit = _fitScale;
    final clamped = scale.clamp(fit, _maxScale);
    return _isFit(clamped) ? fit : clamped;
  }

  /// [origin] moved as little as keeps the content over the view, or
  /// centred along an axis where it is smaller.
  Offset _clampOrigin(double scale, Offset origin) {
    double along(double view, double content, double at) {
      final extent = content * scale;
      if (extent <= view) return (view - extent) / 2;
      return at.clamp(view - extent, 0.0);
    }

    return Offset(
      along(_viewport.width, _content.width, origin.dx),
      along(_viewport.height, _content.height, origin.dy),
    );
  }

  /// [from] zoomed to [scale], clamped, with the content point under
  /// [focal] kept there as far as the clamp allows.
  _Frame _zoomed(_Frame from, double scale, Offset focal) {
    final point = (focal - from.origin) / from.scale;
    final clamped = _clampScale(scale);
    return (
      scale: clamped,
      origin: _clampOrigin(clamped, focal - point * clamped),
    );
  }

  Matrix4 get _matrix =>
      Matrix4.diagonal3Values(_scale, _scale, 1)
        ..setTranslationRaw(_origin.dx, _origin.dy, 0);

  MouseCursor get _cursor {
    if (!_canPan) return SystemMouseCursors.basic;
    return _grabbing.value
        ? SystemMouseCursors.grabbing
        : SystemMouseCursors.grab;
  }

  // ── changes ──

  void _show(_Frame frame) {
    if (frame.scale == _scale && frame.origin == _origin) return;
    _scale = frame.scale;
    _origin = frame.origin;
    _fitted = _isFit(_scale);
    _controller._changed();
  }

  /// Moves to [target] over the theme's medium duration, or at once under
  /// reduced motion.
  void _moveTo(_Frame target, {required Offset anchor}) {
    _motion.stop();
    final curve = _curve;
    if (_duration == Duration.zero || curve == null) {
      _show(target);
      return;
    }
    if (target.scale == _scale && target.origin == _origin) return;
    _from = (scale: _scale, origin: _origin);
    _to = target;
    _anchor = anchor;
    _motion
      ..duration = _duration
      ..forward(from: 0);
  }

  /// A frame of the step under way: the scale eases geometrically, and the
  /// content point under the anchor moves in a straight line, so a zoom
  /// about a point keeps that point still.
  void _onMotion() {
    final from = _from!;
    final to = _to!;
    final t = _curve!.transform(_motion.value);
    if (t >= 1) {
      _show(to);
      return;
    }
    final scale = math.exp(
      lerpDouble(math.log(from.scale), math.log(to.scale), t)!,
    );
    final start = (_anchor - from.origin) / from.scale;
    final end = (_anchor - to.origin) / to.scale;
    final point = Offset.lerp(start, end, t)!;
    _show((scale: scale, origin: _clampOrigin(scale, _anchor - point * scale)));
  }

  /// Pans by [pan], then zooms by [ratio] about [focal], at once.
  void _follow({
    Offset pan = Offset.zero,
    double ratio = 1,
    required Offset focal,
  }) {
    if (_viewport.isEmpty) return;
    _show(
      _zoomed((scale: _scale, origin: _origin + pan), _scale * ratio, focal),
    );
  }

  void _fit() {
    if (_viewport.isEmpty) return;
    _moveTo(_fitFrame, anchor: _middle);
  }

  void _actualSize() {
    if (_viewport.isEmpty) return;
    _moveTo(_zoomed(_target, 1, _middle), anchor: _middle);
  }

  void _zoomIn() {
    if (!_canZoomIn) return;
    final from = _target;
    final scale = math.min(_maxScale, _levelAtLeast(from.scale * _step));
    _moveTo(_zoomed(from, scale, _middle), anchor: _middle);
  }

  void _showRegion(Rect region) {
    assert(
      region.isFinite && region.width >= 0 && region.height >= 0,
      'ZoomController.show takes a finite region of the content, not $region.',
    );
    if (_viewport.isEmpty) return;
    final scale = _clampScale(
      math.min(
        _viewport.width / math.max(region.width, 1e-9),
        _viewport.height / math.max(region.height, 1e-9),
      ),
    );
    final origin = _clampOrigin(scale, _middle - region.center * scale);
    _moveTo((scale: scale, origin: origin), anchor: _middle);
  }

  void _zoomOut() {
    if (!_canZoomOut) return;
    final from = _target;
    var scale = _levelAtMost(from.scale / _step);
    if (scale < _fitScale * _step) scale = _fitScale;
    _moveTo(_zoomed(from, scale, _middle), anchor: _middle);
  }

  /// Notifies the controller's listeners after this frame, for a change made
  /// while laying out, when a listener may not build.
  void _notifyLater() {
    if (_notifyQueued) return;
    _notifyQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyQueued = false;
      if (mounted) _controller._changed();
    });
  }

  /// Places the content in a view of [viewport]: fitted when it was, or
  /// opens; otherwise at the same scale, as the bounds allow, with the
  /// content point at the middle kept there.
  void _layOut(Size viewport) {
    if (viewport == _viewport && _placed && !_stale) return;
    _stale = false;
    if (_motion.isAnimating) {
      // A resize ends a step on its target, so a fit lands fitted.
      _motion.stop();
      _scale = _to!.scale;
      _origin = _to!.origin;
      _fitted = _isFit(_scale);
    }
    final before = (scale: _scale, origin: _origin);
    if (!_placed || _fitted || _viewport.isEmpty) {
      _viewport = viewport;
      final fit = _fitFrame;
      _scale = fit.scale;
      _origin = fit.origin;
    } else {
      final middle = (_middle - _origin) / _scale;
      _viewport = viewport;
      _scale = _clampScale(_scale);
      _origin = _clampOrigin(_scale, _middle - middle * _scale);
    }
    _placed = true;
    _fitted = _isFit(_scale);
    if (before.scale != _scale || before.origin != _origin) _notifyLater();
  }

  /// The view's size under [constraints]: all of it, or along an unbounded
  /// axis the content's extent fitted to the bounded one.
  Size _viewportOf(BoxConstraints constraints) {
    final aspect = _content.width / _content.height;
    if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
      return constraints.biggest;
    }
    if (constraints.hasBoundedWidth) {
      final width = constraints.maxWidth;
      return constraints.constrain(Size(width, width / aspect));
    }
    if (constraints.hasBoundedHeight) {
      final height = constraints.maxHeight;
      return constraints.constrain(Size(height * aspect, height));
    }
    assert(() {
      throw FlutterError(
        'A ZoomView was given an unbounded width and height. It fills the '
        'space its parent gives it, and fits its content to a bounded width '
        'or height: give it one, with a SizedBox or an Expanded.',
      );
    }());
    return constraints.constrain(_content);
  }

  // ── input ──

  void _onPointerDown(PointerDownEvent event) {
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (_viewport.isEmpty) return;
    if (event is! PointerScrollEvent && event is! PointerScaleEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      _motion.stop();
      switch (event) {
        case PointerScaleEvent(:final scale, :final localPosition):
          _follow(ratio: scale, focal: localPosition);
        case PointerScrollEvent(
          :final scrollDelta,
          :final localPosition,
          :final kind,
        ):
          // A trackpad on the web scrolls with wheel events: it pans.
          if (kind == PointerDeviceKind.trackpad || scrollDelta.dy == 0) {
            _follow(pan: -scrollDelta, focal: localPosition);
          } else {
            _follow(
              ratio: math.exp(-scrollDelta.dy / _wheelPixels),
              focal: localPosition,
            );
          }
          event.respond(allowPlatformDefault: false);
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _motion.stop();
    _lastFocal = details.localFocalPoint;
    _lastGestureScale = 1;
    _grabbing.value = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final focal = details.localFocalPoint;
    final pan = focal - (_lastFocal ?? focal);
    final ratio = details.scale / _lastGestureScale;
    _lastFocal = focal;
    _lastGestureScale = details.scale;
    _follow(pan: pan, ratio: ratio, focal: focal);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocal = null;
    _grabbing.value = false;
  }

  void _onPanZoomStart(PointerPanZoomStartEvent event) {
    _motion.stop();
    _lastPanZoomScale = 1;
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final ratio = event.scale / _lastPanZoomScale;
    _lastPanZoomScale = event.scale;
    _follow(pan: event.localPanDelta, ratio: ratio, focal: event.localPosition);
  }

  void _onDoubleTapDown(TapDownDetails details) =>
      _doubleTapAt = details.localPosition;

  void _onDoubleTap() {
    if (_viewport.isEmpty) return;
    final at = _doubleTapAt ?? _middle;
    final from = _target;
    if (!_isFit(from.scale)) {
      _moveTo(_fitFrame, anchor: at);
      return;
    }
    final fit = _fitScale;
    final scale = _isFit(1) ? _levelAtLeast(fit * _step) : 1.0;
    _moveTo(_zoomed(from, scale, at), anchor: at);
  }

  /// Whether [event] is one of [keys].
  bool _isKey(KeyEvent event, List<ShortcutActivator> keys) =>
      keys.any((key) => key.accepts(event, HardwareKeyboard.instance));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _viewport.isEmpty) {
      return KeyEventResult.ignored;
    }
    VoidCallback? action;
    if (_isKey(event, [
      const CharacterActivator('+'),
      const CharacterActivator('='),
      primaryModifierActivator(LogicalKeyboardKey.equal),
      primaryModifierActivator(LogicalKeyboardKey.equal, shift: true),
      primaryModifierActivator(LogicalKeyboardKey.numpadAdd),
    ])) {
      action = _zoomIn;
    } else if (_isKey(event, [
      const CharacterActivator('-'),
      primaryModifierActivator(LogicalKeyboardKey.minus),
      primaryModifierActivator(LogicalKeyboardKey.numpadSubtract),
    ])) {
      action = _zoomOut;
    } else if (_isKey(event, [
      const CharacterActivator('0'),
      primaryModifierActivator(LogicalKeyboardKey.digit0),
      primaryModifierActivator(LogicalKeyboardKey.numpad0),
    ])) {
      action = _fit;
    } else if (_isKey(event, [
      const CharacterActivator('1'),
      primaryModifierActivator(LogicalKeyboardKey.digit1),
      primaryModifierActivator(LogicalKeyboardKey.numpad1),
    ])) {
      action = _actualSize;
    }
    if (action != null) {
      // Handled at a limit too, so a command form never reaches the
      // browser, which would zoom the page.
      action();
      return KeyEventResult.handled;
    }

    final x = _viewport.width * _arrowShare;
    final y = _viewport.height * _arrowShare;
    // Physical: the content is a picture, which right to left does not
    // mirror, so an arrow shows more of the side it points to.
    final pan = <LogicalKeyboardKey, Offset>{
      LogicalKeyboardKey.arrowLeft: Offset(x, 0),
      LogicalKeyboardKey.arrowRight: Offset(-x, 0),
      LogicalKeyboardKey.arrowUp: Offset(0, y),
      LogicalKeyboardKey.arrowDown: Offset(0, -y),
    };
    for (final MapEntry(:key, :value) in pan.entries) {
      if (!SingleActivator(key).accepts(event, HardwareKeyboard.instance)) {
        continue;
      }
      if (!_canPan) return KeyEventResult.ignored;
      final from = _target;
      final scale = from.scale;
      _moveTo((
        scale: scale,
        origin: _clampOrigin(scale, from.origin + value),
      ), anchor: _middle);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    _duration = motion.medium;
    _curve = motion.standard;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = _viewportOf(constraints);
        _layOut(viewport);
        return SizedBox.fromSize(size: viewport, child: _view(context));
      },
    );
  }

  Widget _view(BuildContext context) {
    final strings = context.adminL10n.display;
    final formats = context.adminFormats;
    final content = RepaintBoundary(child: widget.child);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) => Semantics(
        container: true,
        label: widget.semanticLabel ?? strings.zoomArea,
        value: _percent(formats, _scale),
        hint: strings.zoomAreaHint,
        child: child,
      ),
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: FocusRing(
          focused: _focused,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerSignal: _onPointerSignal,
            child: RawGestureDetector(
              gestures: {
                _TrackpadRecognizer:
                    GestureRecognizerFactoryWithHandlers<_TrackpadRecognizer>(
                      () => _TrackpadRecognizer(debugOwner: this),
                      (recognizer) => recognizer
                        ..onStart = _onPanZoomStart
                        ..onUpdate = _onPanZoomUpdate,
                    ),
              },
              excludeFromSemantics: true,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _surface(content),
                    if (widget.showControls)
                      PositionedDirectional(
                        end: AdminSpacing.md,
                        bottom: AdminSpacing.md,
                        child: SelectionContainer.disabled(
                          child: _ZoomControls(view: this),
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

  /// The content, transformed, under the drag, pinch and double-click
  /// gestures. The bar is outside it, so a click on a button is never held
  /// back to see whether it is a double click.
  Widget _surface(Widget content) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    gestures: {
      ScaleGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(
              debugOwner: this,
              supportedDevices: _dragDevices,
            ),
            (recognizer) => recognizer
              ..onStart = _onScaleStart
              ..onUpdate = _onScaleUpdate
              ..onEnd = _onScaleEnd,
          ),
      DoubleTapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
            () => DoubleTapGestureRecognizer(debugOwner: this),
            (recognizer) => recognizer
              ..onDoubleTapDown = _onDoubleTapDown
              ..onDoubleTap = _onDoubleTap,
          ),
    },
    child: ListenableBuilder(
      listenable: Listenable.merge([_controller, _grabbing]),
      child: content,
      // The content is a tap target's: none of its text is selected.
      builder: (context, content) => CursorRegion(
        cursor: _cursor,
        child: OverflowBox(
          // Physical: the content's own pixels, from its top-left corner.
          alignment: Alignment.topLeft,
          minWidth: _content.width,
          maxWidth: _content.width,
          minHeight: _content.height,
          maxHeight: _content.height,
          child: Transform(transform: _matrix, child: content),
        ),
      ),
    ),
  );
}

/// The floating bar: zoom out, the percentage, zoom in, zoom to fit.
class _ZoomControls extends StatelessWidget {
  final _ZoomViewState view;

  const _ZoomControls({required this.view});

  static const _figures = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.adminL10n.display;
    final formats = context.adminFormats;
    // Concentric with the buttons' corners, the padding outside them.
    final radius = context.radii.button(ControlSize.small) + AdminSpacing.xxs;
    final style = context.type.bodySmall
        .copyWith(color: colors.foregroundSecondary)
        .merge(_figures);
    return ListenableBuilder(
      listenable: view._controller,
      builder: (context, _) {
        final canZoomOut = view._canZoomOut;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: colors.border,
              width: context.stroke.hairline,
            ),
            boxShadow: context.elevation.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconAction(
                  context.icons.zoomOut,
                  label: strings.zoomOut,
                  size: IconActionSize.small,
                  onPressed: canZoomOut ? view._zoomOut : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.xs,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // As wide as the widest percentage, so the bar keeps
                      // its width as the scale changes.
                      Visibility(
                        visible: false,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Text(
                          _percent(formats, view._maxScale),
                          style: style,
                        ),
                      ),
                      Semantics(
                        container: true,
                        liveRegion: true,
                        child: Text(
                          _percent(formats, view._scale),
                          style: style,
                        ),
                      ),
                    ],
                  ),
                ),
                IconAction(
                  context.icons.zoomIn,
                  label: strings.zoomIn,
                  size: IconActionSize.small,
                  onPressed: view._canZoomIn ? view._zoomIn : null,
                ),
                IconAction(
                  context.icons.zoomFit,
                  label: strings.zoomToFit,
                  size: IconActionSize.small,
                  onPressed: canZoomOut ? view._fit : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Takes a trackpad's two-finger gesture as it starts, so a page that
/// scrolls around the view does not scroll with it: it pans and zooms the
/// view alone. A mouse, a finger or a pen it leaves to the others.
class _TrackpadRecognizer extends OneSequenceGestureRecognizer {
  _TrackpadRecognizer({super.debugOwner})
    : super(supportedDevices: const {PointerDeviceKind.trackpad});

  ValueChanged<PointerPanZoomStartEvent>? onStart;
  ValueChanged<PointerPanZoomUpdateEvent>? onUpdate;

  @override
  bool isPointerAllowed(PointerDownEvent event) => false;

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onStart?.call(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerPanZoomUpdateEvent) {
      onUpdate?.call(event);
    } else if (event is PointerPanZoomEndEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) => stopTrackingPointer(pointer);

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'trackpad pan and zoom';
}
