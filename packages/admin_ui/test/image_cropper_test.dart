import 'dart:async';
import 'dart:math' as math;

import 'package:admin_ui/src/assets/ui/image_cropper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Never resolves — the cropper shows its loading placeholder, so widget tests
/// don't depend on decoding a real bitmap.
class _PendingImage extends ImageProvider<_PendingImage> {
  const _PendingImage();

  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);

  @override
  bool operator ==(Object other) => other is _PendingImage;

  @override
  int get hashCode => 0;
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, height: 320, child: child)),
  ),
);

void main() {
  group('cropResize — freeform', () {
    const rect = Rect.fromLTRB(0.2, 0.2, 0.8, 0.8);

    test('an edge moves only its own side', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.right,
        deltaNorm: const Offset(-0.1, 0.3),
      );
      expect(r.left, 0.2);
      expect(r.top, 0.2);
      expect(r.bottom, 0.8);
      expect(r.right, closeTo(0.7, 1e-9));
    });

    test('a corner moves both its edges', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.topLeft,
        deltaNorm: const Offset(-0.1, -0.05),
      );
      expect(r.left, closeTo(0.1, 1e-9));
      expect(r.top, closeTo(0.15, 1e-9));
      expect(r.right, 0.8);
      expect(r.bottom, 0.8);
    });

    test('clamps inside the unit square', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.topLeft,
        deltaNorm: const Offset(-1, -1),
      );
      expect(r.left, 0);
      expect(r.top, 0);
    });

    test('cannot shrink past the minimum size', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.left,
        deltaNorm: const Offset(1, 0),
        minNorm: 0.1,
      );
      expect(r.right - r.left, closeTo(0.1, 1e-9));
    });
  });

  group('cropResize — size limits', () {
    test('maxNormW caps how far an edge can grow', () {
      final r = cropResize(
        rect: const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5),
        handle: CropHandle.right,
        deltaNorm: const Offset(1, 0),
        maxNormW: 0.2,
      );
      expect(r.right, closeTo(0.4, 1e-9));
    });

    test('minNormW stops an edge from shrinking past it', () {
      final r = cropResize(
        rect: const Rect.fromLTRB(0.2, 0.2, 0.8, 0.8),
        handle: CropHandle.left,
        deltaNorm: const Offset(1, 0),
        minNormW: 0.3,
      );
      expect(r.width, closeTo(0.3, 1e-9));
    });

    test('maxNormH caps vertical growth independently', () {
      final r = cropResize(
        rect: const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5),
        handle: CropHandle.bottom,
        deltaNorm: const Offset(0, 1),
        maxNormH: 0.1,
      );
      expect(r.height, closeTo(0.1, 1e-9));
    });

    test('a per-axis minimum is honoured under aspect lock', () {
      final r = cropResize(
        rect: const Rect.fromLTRB(0.2, 0.2, 0.4, 0.4),
        handle: CropHandle.bottomRight,
        deltaNorm: Offset.zero,
        lockRatio: 1,
        minNormW: 0.3,
        minNormH: 0.3,
      );
      expect(r.width, closeTo(0.3, 1e-9));
      expect(r.height, closeTo(0.3, 1e-9));
    });
  });

  group('cropResize — aspect locked', () {
    const rect = Rect.fromLTRB(0.2, 0.2, 0.6, 0.6);

    test('edge handles are inert when locked', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.right,
        deltaNorm: const Offset(0.2, 0),
        lockRatio: 1,
      );
      expect(r, rect);
    });

    test('a corner keeps the ratio and anchors the opposite corner', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.bottomRight,
        deltaNorm: const Offset(0.2, 0),
        lockRatio: 1,
      );
      expect(r.left, closeTo(0.2, 1e-9));
      expect(r.top, closeTo(0.2, 1e-9));
      expect(r.width, closeTo(r.height, 1e-9));
      expect(r.width, greaterThan(rect.width));
    });

    test('growth is capped by the nearer bound, ratio intact', () {
      final r = cropResize(
        rect: rect,
        handle: CropHandle.bottomRight,
        deltaNorm: const Offset(5, 5),
        lockRatio: 1,
      );
      expect(r.right, lessThanOrEqualTo(1.0));
      expect(r.bottom, lessThanOrEqualTo(1.0));
      expect(r.width, closeTo(r.height, 1e-9));
    });
  });

  group('cropMove', () {
    test('slides within bounds', () {
      final r = cropMove(
        const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5),
        const Offset(0.1, -0.1),
      );
      expect(r.left, closeTo(0.3, 1e-9));
      expect(r.top, closeTo(0.1, 1e-9));
      expect(r.right, closeTo(0.6, 1e-9));
      expect(r.bottom, closeTo(0.4, 1e-9));
    });

    test('clamps so the rect stays fully inside', () {
      final r = cropMove(
        const Rect.fromLTRB(0.7, 0.7, 0.9, 0.9),
        const Offset(0.5, 0.5),
      );
      expect(r.right, closeTo(1.0, 1e-9));
      expect(r.bottom, closeTo(1.0, 1e-9));
      expect(r.width, closeTo(0.2, 1e-9));
    });
  });

  group('cropClampFocal', () {
    const rect = Rect.fromLTRB(0.3, 0.3, 0.7, 0.7);
    test('inside is unchanged', () {
      expect(
        cropClampFocal(const Offset(0.5, 0.5), rect),
        const Offset(0.5, 0.5),
      );
    });
    test('outside is pulled to the edge', () {
      expect(
        cropClampFocal(const Offset(0.1, 0.9), rect),
        const Offset(0.3, 0.7),
      );
    });
  });

  group('focalCrop', () {
    test('a square crop of a wide image fills the height', () {
      final r = focalCrop(
        focal: const Offset(0.5, 0.5),
        imageAspect: 16 / 9,
        targetAspect: 1,
      );
      expect(r.height, closeTo(1.0, 1e-9));
      expect(r.width, lessThan(1.0));
      expect(r.center.dx, closeTo(0.5, 1e-9));
    });

    test('keeps the focal centred until it hits a wall, then clamps', () {
      final r = focalCrop(
        focal: const Offset(0.95, 0.5),
        imageAspect: 16 / 9,
        targetAspect: 1,
      );
      expect(r.right, closeTo(1.0, 1e-9));
      expect(r.left, closeTo(1 - r.width, 1e-9));
    });

    test('output rect has the requested visual aspect', () {
      final r = focalCrop(
        focal: const Offset(0.5, 0.5),
        imageAspect: 16 / 9,
        targetAspect: 4 / 3,
      );
      final visual = (r.width * 16 / 9) / r.height;
      expect(visual, closeTo(4 / 3, 1e-9));
    });
  });

  group('cropRotate', () {
    const v = CropValue(
      rect: Rect.fromLTRB(0.1, 0.2, 0.5, 0.9),
      focal: Offset(0.3, 0.4),
    );

    test('clockwise maps the rect and focal into the turned frame', () {
      final r = cropRotate(v, 1);
      expect(r.quarterTurns, 1);
      expect(r.rect.left, closeTo(0.1, 1e-9));
      expect(r.rect.top, closeTo(0.1, 1e-9));
      expect(r.rect.right, closeTo(0.8, 1e-9));
      expect(r.rect.bottom, closeTo(0.5, 1e-9));
      expect(r.focal!.dx, closeTo(0.6, 1e-9));
      expect(r.focal!.dy, closeTo(0.3, 1e-9));
    });

    test('counter-clockwise wraps quarterTurns to 3', () {
      final r = cropRotate(v, -1);
      expect(r.quarterTurns, 3);
      expect(r.rect, const Rect.fromLTRB(0.2, 0.5, 0.9, 0.9));
    });

    test('four clockwise turns are the identity', () {
      var r = v;
      for (var i = 0; i < 4; i++) {
        r = cropRotate(r, 1);
      }
      expect(r.quarterTurns, 0);
      expect(r.rect.left, closeTo(v.rect.left, 1e-9));
      expect(r.rect.top, closeTo(v.rect.top, 1e-9));
      expect(r.rect.right, closeTo(v.rect.right, 1e-9));
      expect(r.rect.bottom, closeTo(v.rect.bottom, 1e-9));
      expect(r.focal!.dx, closeTo(v.focal!.dx, 1e-9));
    });
  });

  group('cropFlip', () {
    const v = CropValue(
      rect: Rect.fromLTRB(0.1, 0.2, 0.5, 0.9),
      focal: Offset(0.3, 0.4),
    );

    test('horizontal mirrors x and toggles the flag', () {
      final r = cropFlip(v, Axis.horizontal);
      expect(r.flipH, isTrue);
      expect(r.rect, const Rect.fromLTRB(0.5, 0.2, 0.9, 0.9));
      expect(r.focal!.dx, closeTo(0.7, 1e-9));
      expect(r.focal!.dy, closeTo(0.4, 1e-9));
    });

    test('vertical mirrors y and toggles the flag', () {
      final r = cropFlip(v, Axis.vertical);
      expect(r.flipV, isTrue);
      expect(r.rect.left, closeTo(0.1, 1e-9));
      expect(r.rect.top, closeTo(0.1, 1e-9));
      expect(r.rect.right, closeTo(0.5, 1e-9));
      expect(r.rect.bottom, closeTo(0.8, 1e-9));
      expect(r.focal!.dy, closeTo(0.6, 1e-9));
    });

    test('flipping twice restores the original', () {
      final r = cropFlip(cropFlip(v, Axis.horizontal), Axis.horizontal);
      expect(r.flipH, isFalse);
      expect(r.rect.left, closeTo(v.rect.left, 1e-9));
      expect(r.rect.right, closeTo(v.rect.right, 1e-9));
    });
  });

  group('cropNudge', () {
    const v = CropValue(
      rect: Rect.fromLTRB(0.2, 0.2, 0.6, 0.6),
      focal: Offset(0.4, 0.4),
    );

    test('moves the crop and drags the focal along', () {
      final r = cropNudge(v, const Offset(0.1, 0));
      expect(r.rect.left, closeTo(0.3, 1e-9));
      expect(r.rect.right, closeTo(0.7, 1e-9));
      expect(r.focal!.dx, closeTo(0.4, 1e-9));
    });

    test('focal mode moves only the focal, clamped to the crop', () {
      final r = cropNudge(v, const Offset(0.5, 0), focal: true);
      expect(r.rect, v.rect);
      expect(r.focal!.dx, closeTo(0.6, 1e-9));
    });

    test('crop nudge is bounded by the image edge', () {
      final r = cropNudge(v, const Offset(1, 0));
      expect(r.rect.right, closeTo(1.0, 1e-9));
      expect(r.rect.width, closeTo(0.4, 1e-9));
    });
  });

  group('frame mode geometry', () {
    test('maxFramedRect is the largest centred rect of the aspect', () {
      final r = maxFramedRect(0.5625); // square frame over a 16:9 image
      expect(r.height, closeTo(1.0, 1e-9));
      expect(r.width, closeTo(0.5625, 1e-9));
      expect(r.center.dx, closeTo(0.5, 1e-9));
    });

    test('cropZoom shrinks the window toward the centre', () {
      final v = CropValue(rect: maxFramedRect(1));
      final z = cropZoom(v, 2, lockRatio: 1);
      expect(z.rect.width, closeTo(0.5, 1e-9));
      expect(z.rect.center.dx, closeTo(0.5, 1e-9));
      expect(z.rect.center.dy, closeTo(0.5, 1e-9));
    });

    test('cropZoom cannot zoom out past the full window', () {
      final v = const CropValue(rect: Rect.fromLTRB(0.3, 0.3, 0.7, 0.7));
      final z = cropZoom(v, 0.1, lockRatio: 1);
      expect(z.rect, maxFramedRect(1));
    });

    test('cropZoom is bounded by maxZoom', () {
      final v = CropValue(rect: maxFramedRect(1));
      final z = cropZoom(v, 1000, lockRatio: 1, maxZoom: 4);
      expect(z.rect.width, closeTo(0.25, 1e-9));
    });

    test('cropZoom keeps a corner focus in place', () {
      final v = CropValue(rect: maxFramedRect(1));
      final z = cropZoom(v, 2, lockRatio: 1, focus: const Offset(1, 1));
      expect(z.rect.right, closeTo(1.0, 1e-9));
      expect(z.rect.bottom, closeTo(1.0, 1e-9));
    });

    test('framedImageRect scales the image so the rect fills the frame', () {
      final img = framedImageRect(
        const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(img.width, closeTo(200, 1e-9));
      expect(img.left, closeTo(-50, 1e-9));
    });
  });

  group('straightenCoverScale', () {
    test('is 1 at zero angle', () {
      expect(straightenCoverScale(0, 16 / 9), closeTo(1, 1e-9));
    });

    test('a square needs root-2 at 45 degrees', () {
      expect(straightenCoverScale(45, 1), closeTo(math.sqrt2, 1e-9));
    });

    test('grows with the angle and is symmetric in sign', () {
      expect(
        straightenCoverScale(10, 16 / 9),
        closeTo(straightenCoverScale(-10, 16 / 9), 1e-9),
      );
      expect(
        straightenCoverScale(10, 16 / 9),
        greaterThan(straightenCoverScale(5, 16 / 9)),
      );
    });
  });

  group('CropValue serialization', () {
    test('round-trips a crop with a focal point', () {
      const v = CropValue(
        rect: Rect.fromLTRB(0.1, 0.2, 0.8, 0.9),
        focal: Offset(0.4, 0.6),
      );
      expect(CropValue.fromJson(v.toJson()), v);
    });

    test('omits a null focal and round-trips', () {
      const v = CropValue(rect: Rect.fromLTRB(0, 0, 0.5, 0.5));
      expect(v.toJson().containsKey('focal'), isFalse);
      expect(CropValue.fromJson(v.toJson()), v);
    });

    test('accepts integer numbers from JSON', () {
      final v = CropValue.fromJson(const {
        'rect': [0, 0, 1, 1],
        'focal': [1, 0],
      });
      expect(v.rect, const Rect.fromLTRB(0, 0, 1, 1));
      expect(v.focal, const Offset(1, 0));
    });

    test('round-trips rotation, flip and straighten angle', () {
      const v = CropValue(
        rect: Rect.fromLTRB(0.1, 0.1, 0.6, 0.6),
        quarterTurns: 3,
        flipH: true,
        angle: -7.5,
      );
      final json = v.toJson();
      expect(json['rot'], 3);
      expect(json['flipH'], true);
      expect(json.containsKey('flipV'), isFalse);
      expect(json['angle'], -7.5);
      expect(CropValue.fromJson(json), v);
    });

    test('omits an identity transform and defaults it back on read', () {
      const v = CropValue(rect: Rect.fromLTRB(0, 0, 1, 1));
      final json = v.toJson();
      expect(json.containsKey('rot'), isFalse);
      final back = CropValue.fromJson(json);
      expect(back.quarterTurns, 0);
      expect(back.flipH, isFalse);
      expect(back.flipV, isFalse);
    });
  });

  group('cropHitTest', () {
    const crop = Rect.fromLTRB(100, 100, 300, 300);

    test('corners take priority', () {
      expect(
        cropHitTest(cropPx: crop, point: const Offset(102, 98)),
        CropHandle.topLeft,
      );
    });

    test('edges register between corners when unlocked', () {
      expect(
        cropHitTest(cropPx: crop, point: const Offset(200, 101)),
        CropHandle.top,
      );
    });

    test('edges are suppressed when locked', () {
      expect(
        cropHitTest(cropPx: crop, point: const Offset(200, 101), locked: true),
        CropHandle.move,
      );
    });

    test('interior is a move', () {
      expect(
        cropHitTest(cropPx: crop, point: const Offset(200, 200)),
        CropHandle.move,
      );
    });

    test('focal beats everything when present', () {
      expect(
        cropHitTest(
          cropPx: crop,
          point: const Offset(200, 200),
          focalPx: const Offset(200, 200),
        ),
        CropHandle.focal,
      );
    });

    test('a miss returns null', () {
      expect(cropHitTest(cropPx: crop, point: const Offset(10, 10)), isNull);
    });
  });

  group('widget', () {
    testWidgets('region mode emits a new value on drag', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          ImageCropper(
            image: const _PendingImage(),
            imageAspect: 16 / 9,
            value: const CropValue(rect: Rect.fromLTRB(0.2, 0.2, 0.8, 0.8)),
            onChanged: (_) => calls++,
          ),
        ),
      );
      await tester.pump();
      await tester.drag(find.byType(ImageCropper), const Offset(15, 0));
      await tester.pump();
      expect(calls, greaterThan(0));
    });

    testWidgets('frame mode builds and pans without resizing', (tester) async {
      final initial = CropValue(rect: maxFramedRect(1 / (16 / 9)));
      CropValue? out;
      await tester.pumpWidget(
        _host(
          ImageCropper(
            image: const _PendingImage(),
            imageAspect: 16 / 9,
            mode: CropMode.frame,
            lockedAspect: 1,
            value: initial,
            onChanged: (v) => out = v,
          ),
        ),
      );
      await tester.pump();
      await tester.drag(find.byType(ImageCropper), const Offset(20, 0));
      await tester.pump();
      expect(out, isNotNull);
      expect(out!.rect.width, closeTo(initial.rect.width, 1e-9));
    });
  });
}
