import 'dart:ui' as ui;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A [width] × [height] PNG, encoded for real so the decode can be measured.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// A provider whose load throws, as a dead URL or a corrupt file would.
class _ThrowingImage extends ImageProvider<_ThrowingImage> {
  final bool async;

  const _ThrowingImage({this.async = false});

  @override
  Future<_ThrowingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ThrowingImage key,
    ImageDecoderCallback decode,
  ) {
    if (!async) throw StateError('no such image');
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('no such image')),
    );
  }
}

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// Pumps [child] and lets its image decode; returns the decoded size.
Future<Size> _decoded(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_host(child));
  final image = tester.widget<Image>(find.byType(Image)).image;
  await tester.runAsync(
    () => precacheImage(image, tester.element(find.byType(Image))),
  );
  await tester.pump();
  final raw = tester.widget<RawImage>(find.byType(RawImage)).image!;
  return Size(raw.width.toDouble(), raw.height.toDouble());
}

void main() {
  setUp(() => PaintingBinding.instance.imageCache.clear());

  group('decodes at the size it is drawn', () {
    late Uint8List square, landscape, portrait, tiny;
    setUpAll(() async {
      square = await _png(400, 400);
      landscape = await _png(400, 200);
      portrait = await _png(200, 400);
      tiny = await _png(40, 40);
    });

    testWidgets('size × device pixel ratio', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = await _decoded(
        tester,
        ThumbnailImage(image: MemoryImage(square), size: 48),
      );
      expect(size, const Size(96, 96));
      expect(tester.getSize(find.byType(ThumbnailImage)), const Size(48, 48));
    });

    testWidgets('a landscape source still covers a square', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = await _decoded(
        tester,
        ThumbnailImage(image: MemoryImage(landscape), size: 48),
      );
      expect(size, const Size(192, 96));
    });

    testWidgets('a portrait source covers a square', (tester) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = await _decoded(
        tester,
        ThumbnailImage(image: MemoryImage(portrait), width: 40, height: 40),
      );
      expect(size, const Size(120, 240));
    });

    testWidgets('a width alone sets the size', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = await _decoded(
        tester,
        ThumbnailImage(image: MemoryImage(landscape), width: 64),
      );
      expect(size, const Size(128, 64));
    });

    testWidgets('without a size, the parent sets it', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = await _decoded(
        tester,
        SizedBox.square(
          dimension: 60,
          child: ThumbnailImage(image: MemoryImage(square)),
        ),
      );
      expect(size, const Size(120, 120));
    });

    testWidgets('a small source is never enlarged', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = await _decoded(
        tester,
        ThumbnailImage(image: MemoryImage(tiny), size: 48),
      );
      expect(size, const Size(40, 40));
    });
  });

  group('a failed load', () {
    for (final async in [false, true]) {
      testWidgets(
        'draws the fallback, not the error box (${async ? 'async' : 'sync'})',
        (tester) async {
          await tester.pumpWidget(
            _host(
              ThumbnailImage(
                image: _ThrowingImage(async: async),
                size: 48,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byType(ErrorWidget), findsNothing);
          final glyph = find.byIcon(Icons.broken_image_outlined);
          expect(glyph, findsOneWidget);
          expect(
            tester.getSize(find.byType(ThumbnailImage)),
            const Size(48, 48),
          );
          final colors = defaultTokens.palette;
          expect(
            contrastRatio(
              tester.widget<Icon>(glyph).color!,
              colors.surfaceMuted,
            ),
            greaterThanOrEqualTo(3),
            reason: 'the glyph reads on its surfaceMuted fill',
          );
        },
      );
    }

    testWidgets('leaves the image cache, so the next resolve tries again', (
      tester,
    ) async {
      final cache = PaintingBinding.instance.imageCache;
      await tester.pumpWidget(
        _host(
          const ThumbnailImage(image: _ThrowingImage(async: true), size: 48),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(cache.pendingImageCount, 0);
      expect(cache.currentSize, 0);
    });

    testWidgets('draws a given fallback and keeps the label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const ThumbnailImage(
            image: _ThrowingImage(),
            size: 32,
            fallback: Text('none'),
            semanticLabel: 'Cover photo',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('none'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Cover photo')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('dark themes read the glyph too', (tester) async {
      final dark = AdminTokens.from(palette: irisDarkPalette);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(dark),
          home: const Scaffold(
            body: ThumbnailImage(image: _ThrowingImage(), size: 48),
          ),
        ),
      );
      await tester.pump();
      final glyph = tester.widget<Icon>(
        find.byIcon(Icons.broken_image_outlined),
      );
      expect(
        contrastRatio(glyph.color!, irisDarkPalette.surfaceMuted),
        greaterThanOrEqualTo(3),
      );
    });
  });
}
