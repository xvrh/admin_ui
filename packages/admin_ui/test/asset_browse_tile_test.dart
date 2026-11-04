import 'dart:ui' as ui;

import 'package:admin_ui/src/assets/ui/media_tile.dart';
import 'package:admin_ui/src/common/ui/focus_ring.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

const _red = Color(0xFFFF0000);

/// A solid, fully opaque [width] × [height] PNG: a photo the ring could hide
/// behind if it were painted first.
Future<Uint8List> _opaquePng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = _red,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

final _palette = defaultTokens.palette;

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  ),
);

Widget _tile({
  bool selected = false,
  WidgetStatesController? states,
  Widget thumbnail = const ColoredBox(color: _red),
  Key? key,
}) => SizedBox(
  width: 120,
  child: RepaintBoundary(
    key: key,
    child: MediaTile(
      thumbnail: thumbnail,
      title: 'harbour.jpg',
      subtitle: '2400 × 1600',
      selected: selected,
      check: MediaTileCheck.always,
      statesController: states,
      onTap: () {},
    ),
  ),
);

/// The square's edge as drawn: the foreground decoration nearest the tile.
BoxDecoration _edge(WidgetTester tester) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(MediaTile),
          matching: find.byType(DecoratedBox),
        ),
      )
      .firstWhere((d) => d.position == DecorationPosition.foreground);
  return box.decoration as BoxDecoration;
}

Color _pixel(ByteData bytes, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

void main() {
  testWidgets('the selection ring is painted after an opaque image', (
    tester,
  ) async {
    final png = (await tester.runAsync(() => _opaquePng(64, 64)))!;
    final image = MemoryImage(png);
    const boundary = Key('boundary');
    await tester.pumpWidget(
      _host(
        _tile(
          selected: true,
          key: boundary,
          thumbnail: MediaThumb(image: image),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(image, tester.element(find.byType(MediaTile))),
    );
    await tester.pump();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);

    final render = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundary),
    );
    final bytes = (await tester.runAsync(() async {
      final shot = await render.toImage();
      final data = await shot.toByteData();
      shot.dispose();
      return data;
    }))!;
    final width = render.size.width.round();

    // Mid-edge, clear of the rounded corners: the 2px ring, then the 2px
    // mat, then the picture.
    const middle = 60;
    expect(_pixel(bytes, width, 0, middle), _palette.controlAccent);
    expect(_pixel(bytes, width, 1, middle), _palette.controlAccent);
    expect(_pixel(bytes, width, 2, middle), _palette.surface);
    expect(_pixel(bytes, width, 3, middle), _palette.surface);
    expect(_pixel(bytes, width, 5, middle), _red);
    expect(_pixel(bytes, width, 60, middle), _red);
  });

  testWidgets(
    'the ring is a foreground decoration, 2px of the control accent',
    (tester) async {
      await tester.pumpWidget(_host(_tile(selected: true)));
      final edge = _edge(tester);
      expect(edge.border!.top.color, _palette.controlAccent);
      expect(edge.border!.top.width, 2);
    },
  );

  group('the selection ring stands out in every palette', () {
    const brands = <String, Color?>{
      'Default': null,
      'Crimson': Color(0xFFE11D48),
      'Violet': Color(0xFF7C3AED),
      'Teal': Color(0xFF0D9488),
      'Amber': Color(0xFFD97706),
    };
    for (final MapEntry(key: name, value: shipped) in shippedPalettes.entries) {
      for (final MapEntry(key: brand, value: seed) in brands.entries) {
        final palette = seed == null ? shipped : shipped.branded(seed);
        testWidgets('$name, brand $brand', (tester) async {
          final states = WidgetStatesController();
          addTearDown(states.dispose);
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(AdminTokens.from(palette: palette)),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 120,
                    child: MediaTile(
                      thumbnail: const ColoredBox(color: _red),
                      title: 'harbour.jpg',
                      selected: true,
                      statesController: states,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          final foreground = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(MediaTile),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .where((d) => d.position == DecorationPosition.foreground)
              .map((d) => (d.decoration as BoxDecoration).border!.top)
              .toList();
          final ring = foreground[0].color;
          final mat = foreground[1].color;
          for (final (surface, colour) in [
            ('its mat', mat),
            ('the surface', palette.surface),
            ('the background', palette.background),
          ]) {
            expect(
              contrastRatio(ring, colour),
              greaterThanOrEqualTo(3),
              reason: 'the ring on $surface',
            );
          }
          final pressed = palette.controlAccent.withValues(alpha: 0.6);
          expect(
            contrastRatio(ring, Color.alphaBlend(pressed, palette.surface)),
            greaterThanOrEqualTo(1.5),
            reason: 'a pick never reads as a press',
          );

          states.update(WidgetState.hovered, true);
          await tester.pump();
          final hovered = _edge(tester).border!.top.color;
          expect(contrastRatio(hovered, mat), greaterThanOrEqualTo(3));
          expect(
            contrastRatio(hovered, palette.surface),
            greaterThanOrEqualTo(3),
          );
        });
      }
    }
  });

  testWidgets('selecting never moves or resizes the square', (tester) async {
    Rect square() => tester.getRect(
      find.descendant(
        of: find.byType(MediaTile),
        matching: find.byType(ClipRRect),
      ),
    );
    await tester.pumpWidget(_host(_tile()));
    final rest = square();
    expect(rest.width, rest.height, reason: 'the square fills the width');
    expect(rest.width, 120);

    await tester.pumpWidget(_host(_tile(selected: true)));
    expect(square(), rest);
  });

  testWidgets('at rest the edge is a hairline; hover rings it at 40%', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_tile()));
    final rest = _edge(tester).border!.top;
    expect(rest.width, 1);
    expect(rest.color, _palette.foreground.withValues(alpha: 0.12));

    final hovered = WidgetStatesController({WidgetState.hovered});
    addTearDown(hovered.dispose);
    await tester.pumpWidget(_host(_tile(states: hovered)));
    final hover = _edge(tester).border!.top;
    expect(hover.width, 2);
    expect(hover.color, _palette.controlAccent.withValues(alpha: 0.4));

    hovered.update(WidgetState.hovered, false);
    hovered.update(WidgetState.pressed, true);
    await tester.pump();
    expect(
      _edge(tester).border!.top.color,
      _palette.controlAccent.withValues(alpha: 0.6),
    );
  });

  testWidgets('a real hover rings the tile', (tester) async {
    await tester.pumpWidget(_host(_tile()));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(MediaTile)));
    await tester.pump();
    expect(_edge(tester).border!.top.width, 2);
  });

  testWidgets('keyboard focus rings the square, not the caption', (
    tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(_host(_tile()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final ring = tester.widget<FocusRing>(
      find.descendant(
        of: find.byType(MediaTile),
        matching: find.byType(FocusRing),
      ),
    );
    expect(ring.focused, isTrue);
    final ringRect = tester.getRect(
      find.descendant(
        of: find.byType(MediaTile),
        matching: find.byType(FocusRing),
      ),
    );
    expect(ringRect.height, ringRect.width, reason: 'around the square only');
  });

  testWidgets('the check disc shows per the check mode', (tester) async {
    Widget tile(MediaTileCheck check, bool selected) => _host(
      SizedBox(
        width: 120,
        child: MediaTile(
          thumbnail: const SizedBox(),
          title: 't',
          selected: selected,
          check: check,
        ),
      ),
    );
    await tester.pumpWidget(tile(MediaTileCheck.selected, false));
    expect(find.byIcon(Icons.check), findsNothing);
    await tester.pumpWidget(tile(MediaTileCheck.selected, true));
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.pumpWidget(tile(MediaTileCheck.none, true));
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('Enter confirms, Space only taps', (tester) async {
    var taps = 0;
    var confirms = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 120,
          child: MediaTile(
            thumbnail: const SizedBox(),
            title: 't',
            onTap: () => taps++,
            onConfirm: () => confirms++,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect((taps, confirms), (1, 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect((taps, confirms), (1, 1));
  });

  testWidgets('a list row lays hover over its selected fill', (tester) async {
    final hovered = WidgetStatesController({WidgetState.hovered});
    addTearDown(hovered.dispose);
    Color fill() => tester
        .widget<Container>(
          find
              .descendant(
                of: find.byType(MediaListTile),
                matching: find.byType(Container),
              )
              .first,
        )
        .color!;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          child: MediaListTile(
            thumbnail: const SizedBox(),
            title: 'hero.jpg',
            selected: true,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(fill(), _palette.primarySubtle);
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          child: MediaListTile(
            thumbnail: const SizedBox(),
            title: 'hero.jpg',
            selected: true,
            statesController: hovered,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(
      fill(),
      Color.alphaBlend(_palette.hoverOverlay, _palette.primarySubtle),
    );
  });
}
