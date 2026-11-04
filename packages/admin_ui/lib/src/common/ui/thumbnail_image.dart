import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// An image shown small — a table thumb, a grid tile, a picker preview —
/// decoded at the size it is drawn instead of the source's full resolution,
/// with a [fallback] where it fails to load.
///
/// The [image] is decoded just large enough to cover the box at the device
/// pixel ratio, keeping its aspect ratio and never enlarged: a 48px thumb of
/// a 6000px photo decodes to 96px on a 2x screen. Give the box a [size], or
/// a [width] and [height]; without a width it is taken from the parent's
/// constraints. A load error draws [fallback] — by default a muted
/// broken-image glyph on `surfaceMuted` — and never Flutter's error box.
class ThumbnailImage extends StatelessWidget {
  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;

  /// Drawn in the box when [image] fails to load.
  final Widget? fallback;

  /// What the image shows, for screen readers; null leaves it out of the
  /// semantics tree as decoration.
  final String? semanticLabel;

  const ThumbnailImage({
    super.key,
    required this.image,
    double? size,
    double? width,
    double? height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.semanticLabel,
  }) : width = width ?? size,
       height = height ?? size;

  @override
  Widget build(BuildContext context) {
    if (width != null) return _sized(context, width, height);
    return LayoutBuilder(
      builder: (context, constraints) => _sized(
        context,
        constraints.hasBoundedWidth ? constraints.maxWidth : null,
        height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : null),
      ),
    );
  }

  Widget _sized(BuildContext context, double? boxWidth, double? boxHeight) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    int? pixels(double? logical) =>
        logical == null || !logical.isFinite || logical <= 0
        ? null
        : (logical * dpr).round();
    final extent = [boxWidth, boxHeight].nonNulls.where((d) => d.isFinite);
    Widget child = Image(
      image: _CoverResizeImage.resizeIfNeeded(
        image,
        pixels(boxWidth),
        pixels(boxHeight),
      ),
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      gaplessPlayback: true,
      errorBuilder: (context, _, _) {
        final shown = SizedBox(
          width: width,
          height: height,
          child:
              fallback ??
              _BrokenImage(
                extent: extent.isEmpty ? null : extent.reduce(math.min),
              ),
        );
        return semanticLabel == null
            ? shown
            : Semantics(image: true, label: semanticLabel, child: shown);
      },
    );
    if (borderRadius case final radius?) {
      child = ClipRRect(borderRadius: radius, child: child);
    }
    return child;
  }
}

/// The default [ThumbnailImage.fallback]: a broken-image glyph at half the
/// box's shorter side (12–32), in [AdminPalette.foregroundMuted] lifted to 3:1
/// on the `surfaceMuted` fill it sits on.
class _BrokenImage extends StatelessWidget {
  final double? extent;

  const _BrokenImage({this.extent});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: extent == null ? 16 : (extent! / 2).clamp(12, 32),
          color: colors.readableOn(
            colors.foregroundMuted,
            surfaces: [colors.surfaceMuted],
            minContrast: 3,
          ),
        ),
      ),
    );
  }
}

/// [provider] decoded just large enough to cover a [width] × [height] box
/// (in physical pixels) — the least [BoxFit.cover] draws without upscaling,
/// and enough for every other fit — keeping its aspect ratio and never
/// enlarged. With no [height], the width alone sets the size.
///
/// [ResizeImage] cannot do this: given one side it fits that side, which
/// leaves a landscape source too short to cover a square; given both it
/// fits inside the box or stretches to it.
@immutable
class _CoverResizeImage extends ImageProvider<_CoverResizeKey> {
  final ImageProvider<Object> provider;
  final int width;
  final int? height;

  const _CoverResizeImage(this.provider, this.width, this.height);

  /// [provider] resized to cover [width] × [height], or unchanged when no
  /// width is known or it already resizes itself.
  static ImageProvider<Object> resizeIfNeeded(
    ImageProvider<Object> provider,
    int? width,
    int? height,
  ) {
    if (width == null || provider is ResizeImage) return provider;
    return _CoverResizeImage(provider, width, height);
  }

  @override
  Future<_CoverResizeKey> obtainKey(ImageConfiguration configuration) {
    // Answers synchronously when the provider does, as ResizeImage does, so
    // a cached thumbnail paints in its first frame.
    Completer<_CoverResizeKey>? completer;
    Future<_CoverResizeKey>? result;
    provider
        .obtainKey(configuration)
        .then(
          (key) {
            final resized = _CoverResizeKey(key, width, height);
            if (completer == null) {
              result = SynchronousFuture(resized);
            } else {
              completer.complete(resized);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (completer == null) {
              result = Future.error(error, stack);
            } else {
              completer.completeError(error, stack);
            }
          },
        );
    return result ?? (completer = Completer()).future;
  }

  @override
  ImageStreamCompleter loadImage(
    _CoverResizeKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeToCover(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) => decode(buffer, getTargetSize: getTargetSize ?? _cover);
    final completer = provider.loadImage(key.providerKey, decodeToCover);
    // The cache holds a load under this key until it yields an image, and a
    // failed one never does: evict it, as ResizeImage does, so the next
    // resolve tries again rather than replaying the error. A microtask, as
    // the failure can arrive before the cache has added the key.
    completer.addEphemeralErrorListener((_, _) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    });
    return completer;
  }

  ui.TargetImageSize _cover(int intrinsicWidth, int intrinsicHeight) {
    final byWidth = width / intrinsicWidth;
    final byHeight = (height ?? 0) / intrinsicHeight;
    if (math.max(byWidth, byHeight) >= 1) return const ui.TargetImageSize();
    return byWidth >= byHeight
        ? ui.TargetImageSize(width: width)
        : ui.TargetImageSize(height: height);
  }

  @override
  bool operator ==(Object other) =>
      other is _CoverResizeImage &&
      other.provider == provider &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(provider, width, height);
}

@immutable
class _CoverResizeKey {
  final Object providerKey;
  final int width;
  final int? height;

  const _CoverResizeKey(this.providerKey, this.width, this.height);

  @override
  bool operator ==(Object other) =>
      other is _CoverResizeKey &&
      other.providerKey == providerKey &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(providerKey, width, height);
}
