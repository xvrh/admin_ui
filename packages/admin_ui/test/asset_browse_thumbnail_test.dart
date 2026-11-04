import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/media_tile.dart';
import 'package:admin_ui/src/assets/ui/provider_browser.dart';
import 'package:admin_ui/src/common/ui/thumbnail_image.dart';
import 'package:admin_ui/src/fields/ui/media_body.dart';
import 'package:admin_ui/src/fields/ui/reference_body.dart';
import 'package:admin_ui/src/forms/asset_detail.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A provider whose load fails, as a dead URL would.
class _Broken extends ImageProvider<_Broken> {
  const _Broken();

  @override
  Future<_Broken> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Broken key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('404 Not Found')),
      );
}

const _broken = _Broken();

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 820, height: 700, child: child),
    ),
  ),
);

/// Pumps until the failed loads have reached their error builders.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a grid tile whose image fails shows the fallback glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AssetLibrary(
          assets: [Asset(id: 'a', name: 'gone.jpg', thumbnail: _broken)],
        ),
      ),
    );
    await _settle(tester);
    expect(find.byType(ThumbnailImage), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('so does a list row, a provider tile and the detail preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AssetLibrary(
          view: AssetView.list,
          assets: [Asset(id: 'a', name: 'gone.jpg', thumbnail: _broken)],
        ),
      ),
    );
    await _settle(tester);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const ProviderBrowser(
          providerLabel: 'Stock',
          items: [ProviderItem(id: 'p', title: 'gone', preview: _broken)],
        ),
      ),
    );
    await _settle(tester);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const AssetDetailView(
          asset: Asset(id: 'a', name: 'gone.jpg', thumbnail: _broken),
        ),
      ),
    );
    await _settle(tester);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field thumbnails decode small and fall back too', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: ReferenceTileCard(title: 'Gone', thumbnail: _broken),
            ),
          ],
        ),
      ),
    );
    await _settle(tester);
    final thumb = tester.widget<ThumbnailImage>(find.byType(ThumbnailImage));
    expect(thumb.width, 36);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 600,
          child: MediaBody(
            items: const [
              MediaItem(id: 'm', name: 'gone.jpg', thumbnail: _broken),
            ],
            onAddRequested: () {},
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.byType(ThumbnailImage), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a swatch glyph takes the colour that reads on it', (
    tester,
  ) async {
    const light = Color(0xFFFDE68A);
    const deep = Color(0xFF1E3A8A);
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            SizedBox.square(dimension: 96, child: MediaThumb(swatch: light)),
            SizedBox.square(dimension: 96, child: MediaThumb(swatch: deep)),
          ],
        ),
      ),
    );
    final glyphs = tester
        .widgetList<Icon>(find.byIcon(Icons.image_outlined))
        .toList();
    final palette = defaultTokens.palette;
    expect(contrastRatio(glyphs[0].color!, light), greaterThanOrEqualTo(3));
    expect(contrastRatio(glyphs[1].color!, deep), greaterThanOrEqualTo(3));
    expect(glyphs[0].color!.a, 1, reason: 'no see-through glyph');
    expect(glyphs[1].color, palette.foregroundOn(deep));
  });
}
