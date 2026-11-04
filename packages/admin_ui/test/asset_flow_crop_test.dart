import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Never resolves, so no bitmap has to decode.
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

/// The pixel width / height of [crop] over an image of [imageAspect].
double _pixelAspect(CropValue crop, double imageAspect) =>
    crop.rect.width / crop.rect.height * imageAspect;

const _imageAspect = 4 / 3;

/// Opens the crop dialog at [initial]; the getter reads what it resolved.
Future<CropValue? Function()> _open(
  WidgetTester tester, {
  CropValue initial = CropValue.full,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  CropValue? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCropDialog(
              context,
              image: const _PendingImage(),
              imageAspect: _imageAspect,
              initial: initial,
            ),
            child: const Text('crop'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('crop'));
  await tester.pumpAndSettle();
  return () => result;
}

ImageCropper _cropper(WidgetTester tester) =>
    tester.widget<ImageCropper>(find.byType(ImageCropper));

void main() {
  testWidgets('a preset locks the crop to its ratio and reshapes it', (
    tester,
  ) async {
    final result = await _open(tester);
    expect(_cropper(tester).lockedAspect, isNull, reason: 'Free by default');

    await tester.tap(find.text('1:1'));
    await tester.pumpAndSettle();
    expect(_cropper(tester).lockedAspect, 1);
    expect(
      _pixelAspect(_cropper(tester).value, _imageAspect),
      closeTo(1, 1e-9),
    );

    await tester.tap(find.text('16:9'));
    await tester.pumpAndSettle();
    expect(_cropper(tester).lockedAspect, 16 / 9);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(_pixelAspect(result()!, _imageAspect), closeTo(16 / 9, 1e-9));
  });

  testWidgets('a locked crop takes corner drags only', (tester) async {
    await _open(tester);
    await tester.tap(find.text('1:1'));
    await tester.pumpAndSettle();
    final before = _cropper(tester).value.rect;

    // The right edge's midpoint: freeform it would resize, locked it is inert.
    final canvas = tester.getRect(find.byType(ImageCropper));
    await tester.dragFrom(
      Offset(canvas.center.dx + canvas.height * 0.25, canvas.center.dy),
      const Offset(-10, 0),
    );
    await tester.pumpAndSettle();
    expect(_cropper(tester).value.rect.size, before.size);
  });

  testWidgets('a crop saved at a preset opens with that preset chosen', (
    tester,
  ) async {
    await _open(
      tester,
      initial: const CropValue(rect: Rect.fromLTWH(0, 0.125, 1, 0.75)),
    );
    expect(_cropper(tester).lockedAspect, 16 / 9);
    expect(
      tester.getSemantics(find.text('16:9')),
      isSemantics(
        isButton: true,
        isSelected: true,
        isEnabled: true,
        hasTapAction: true,
        label: '16:9',
      ),
    );
  });

  testWidgets('cancel resolves null; the header close does too', (
    tester,
  ) async {
    var result = await _open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result(), isNull);
    expect(find.byType(ImageCropper), findsNothing);

    result = await _open(tester);
    expect(find.text('Crop & focal point'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageCropper), findsNothing);
    expect(result(), isNull);
  });

  group('ImageCropper aspect bar', () {
    Widget host(Widget child) => MaterialApp(
      theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
      home: Scaffold(
        body: Center(child: SizedBox(width: 480, height: 360, child: child)),
      ),
    );

    testWidgets('is hidden without onAspectChanged', (tester) async {
      await tester.pumpWidget(
        host(
          ImageCropper(
            image: const _PendingImage(),
            imageAspect: _imageAspect,
            onChanged: (_) {},
            aspectPresets: AspectPreset.defaults,
          ),
        ),
      );
      expect(find.text('1:1'), findsNothing);
    });

    testWidgets('is disabled while the cropper is read-only', (tester) async {
      AspectPreset? picked;
      await tester.pumpWidget(
        host(
          ImageCropper(
            image: const _PendingImage(),
            imageAspect: _imageAspect,
            aspectPresets: AspectPreset.defaults,
            onAspectChanged: (p) => picked = p,
          ),
        ),
      );
      expect(find.text('1:1'), findsOneWidget);
      await tester.tap(find.text('1:1'));
      expect(picked, isNull);
      expect(
        tester.getSemantics(find.text('1:1')),
        matchesSemantics(
          isButton: true,
          hasSelectedState: true,
          hasEnabledState: true,
          label: '1:1',
        ),
      );
    });
  });
}
