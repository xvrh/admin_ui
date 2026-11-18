import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A ValueSlider drawn from the theme's AdminSliderStyle: the track's height,
// each kind of thumb, the rail's colour and the ink.

Widget _host(
  Widget child, {
  AdminSliderStyle style = const AdminSliderStyle(),
  AdminPalette? palette,
  AdminControlSizes? sizes,
}) => MaterialApp(
  theme: buildAppTheme(
    AdminTokens.from(
      palette: palette ?? irisPalette,
      slider: style,
      sizes: sizes,
    ),
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        // a column, so the slider takes its own height
        child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
      ),
    ),
  ),
);

SliderThemeData _theme(WidgetTester tester) =>
    SliderTheme.of(tester.element(find.byType(Slider)));

const _material = AdminSliderStyle(
  trackHeight: 16,
  thumb: SliderThumb.bar,
  thumbSize: 44,
  rail: SliderRail.soft,
);

const _shadcn = AdminSliderStyle(
  trackHeight: 6,
  thumb: SliderThumb.ringed,
  thumbSize: 16,
  thumbRing: 1,
);

const _fluent = AdminSliderStyle(
  thumb: SliderThumb.inset,
  thumbSize: 20,
  thumbRing: 4,
  rail: SliderRail.control,
);

const _carbon = AdminSliderStyle(
  trackHeight: 2,
  thumbSize: 14,
  ink: SelectionInk.foreground,
);

void main() {
  Widget slider({bool enabled = true, int? divisions}) => ValueSlider(
    value: 0.5,
    divisions: divisions,
    showValue: false,
    onChanged: enabled ? (_) {} : null,
  );

  testWidgets('the default: a 4px track under an 18px disc in the accent', (
    tester,
  ) async {
    final p = irisPalette;
    await tester.pumpWidget(_host(slider()));
    final theme = _theme(tester);
    expect(theme.trackHeight, 4);
    expect(theme.activeTrackColor, p.controlAccent);
    expect(theme.thumbColor, p.controlAccent);
    expect(theme.inactiveTrackColor, p.border);
    expect(theme.thumbShape, isA<RoundSliderThumbShape>());
    expect(
      theme.thumbShape!.getPreferredSize(true, false),
      const Size.square(18),
    );
    expect(theme.trackShape, isA<RoundedRectSliderTrackShape>());
    expect(theme.trackGap, isNull);
    expect(tester.getSize(find.byType(Slider)).height, 36);
    expect(find.byType(Slider), paints..circle(color: p.controlAccent));
  });

  testWidgets('a disc in the foreground on a 2px track: Carbon’s', (
    tester,
  ) async {
    final p = carbonPalette;
    await tester.pumpWidget(_host(slider(), style: _carbon, palette: p));
    await tester.pumpAndSettle();
    final theme = _theme(tester);
    expect(theme.trackHeight, 2);
    expect(theme.activeTrackColor, p.foreground);
    expect(theme.thumbColor, p.foreground);
    expect(theme.activeTrackColor, isNot(p.controlAccent));
    expect(theme.activeTickMarkColor, const Color(0xFFFFFFFF));
    expect(
      theme.thumbShape!.getPreferredSize(true, false),
      const Size.square(14),
    );
    expect(find.byType(Slider), paints..circle(color: p.foreground, radius: 7));
  });

  testWidgets('ringed: the surface colour inside a ring of the ink, on the '
      'theme’s small shadow', (tester) async {
    final p = irisPalette;
    await tester.pumpWidget(_host(slider(), style: _shadcn));
    await tester.pumpAndSettle();
    final theme = _theme(tester);
    expect(theme.trackHeight, 6);
    expect(
      theme.thumbShape!.getPreferredSize(true, false),
      const Size.square(16),
    );
    final shadows = defaultElevation.sm;
    expect(shadows, hasLength(1));
    expect(
      find.byType(Slider),
      paints
        // the shadow, under the thumb
        ..circle(radius: 8 + shadows.single.spreadRadius)
        ..circle(color: p.surface, radius: 8, style: PaintingStyle.fill)
        // the ring lies inside the thumb's edge
        ..circle(
          color: p.controlAccent,
          radius: 7.5,
          style: PaintingStyle.stroke,
          strokeWidth: 1,
        ),
    );
  });

  testWidgets('inset: the ink inside a band of the surface colour, edged in '
      'a hairline', (tester) async {
    final p = irisPalette;
    await tester.pumpWidget(_host(slider(), style: _fluent));
    await tester.pumpAndSettle();
    final theme = _theme(tester);
    expect(theme.inactiveTrackColor, p.controlBorder);
    expect(
      theme.thumbShape!.getPreferredSize(true, false),
      const Size.square(20),
    );
    expect(
      find.byType(Slider),
      paints
        ..circle(color: p.surface, radius: 10, style: PaintingStyle.fill)
        ..circle(color: p.controlAccent, radius: 6, style: PaintingStyle.fill)
        ..circle(
          color: p.border,
          radius: 9.5,
          style: PaintingStyle.stroke,
          strokeWidth: 1,
        ),
    );
  });

  testWidgets('bar: M3’s handle parts a 16dp track, soft past it', (
    tester,
  ) async {
    final p = materialPalette;
    await tester.pumpWidget(_host(slider(), style: _material, palette: p));
    await tester.pumpAndSettle();
    final theme = _theme(tester);
    expect(theme.trackHeight, 16);
    expect(theme.inactiveTrackColor, p.softFill);
    expect(theme.thumbShape, isA<HandleThumbShape>());
    expect(theme.thumbSize!.resolve({}), const Size(4, 44));
    expect(theme.trackGap, 6);
    expect(theme.trackShape, isA<GappedSliderTrackShape>());
    // the handle, 4 wide and 44 tall, in the accent, at the value
    final box = tester.getSize(find.byType(Slider));
    expect(
      find.byType(Slider),
      paints..something((method, arguments) {
        if (method != #drawRRect) return false;
        final rrect = arguments[0] as RRect;
        return rrect.width == 4 &&
            rrect.height == 44 &&
            rrect.center == box.center(Offset.zero) &&
            // a paint holds its colour at a lower precision
            (arguments[1] as Paint).color.toARGB32() ==
                p.controlAccent.toARGB32();
      }),
    );
  });

  testWidgets('the row is a medium control tall, or the thumb where that is '
      'taller', (tester) async {
    for (final (style, medium, height) in [
      (const AdminSliderStyle(), 36.0, 36.0),
      (_shadcn, 36.0, 36.0),
      (_fluent, 32.0, 32.0),
      (_material, 40.0, 44.0),
      (const AdminSliderStyle(thumbSize: 40), 32.0, 40.0),
    ]) {
      await tester.pumpWidget(
        _host(
          slider(),
          style: style,
          sizes: AdminControlSizes(small: 24, medium: medium, large: 48),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(Slider)).height,
        height,
        reason: '$style in a $medium row',
      );
      expect(_theme(tester).padding!.vertical, greaterThanOrEqualTo(0));
      // the track still runs from edge to edge
      expect(_theme(tester).padding!.horizontal, 0);
      expect(tester.getSize(find.byType(Slider)).width, 320);
    }
  });

  testWidgets('disabled, every thumb greys', (tester) async {
    final p = irisPalette;
    for (final style in [
      const AdminSliderStyle(),
      _shadcn,
      _fluent,
      _material,
      _carbon,
    ]) {
      await tester.pumpWidget(_host(slider(enabled: false), style: style));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final theme = _theme(tester);
      expect(theme.disabledThumbColor, p.foregroundSubtle);
      expect(theme.disabledActiveTrackColor, p.foregroundFaint);
      switch (style.thumb) {
        case SliderThumb.disc:
          expect(
            find.byType(Slider),
            paints..circle(color: p.foregroundSubtle),
          );
        case SliderThumb.ringed:
          expect(
            find.byType(Slider),
            paints
              ..circle()
              ..circle(color: p.surface)
              ..circle(color: p.foregroundSubtle, style: PaintingStyle.stroke),
          );
        case SliderThumb.inset:
          expect(
            find.byType(Slider),
            paints
              ..circle(color: p.surface)
              ..circle(color: p.foregroundSubtle),
          );
        case SliderThumb.bar:
          expect(theme.thumbShape, isA<HandleThumbShape>());
      }
    }
  });

  testWidgets('every thumb drags, snaps and shows its value', (tester) async {
    for (final style in [
      const AdminSliderStyle(),
      _shadcn,
      _fluent,
      _material,
      _carbon,
    ]) {
      var value = 0.0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => ValueSlider(
              value: value,
              divisions: 4,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          style: style,
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(Slider));
      await tester.tapAt(Offset(box.left + box.width * 0.7, box.center.dy));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(value, 0.75, reason: '$style');
      expect(find.text('0.75'), findsWidgets);
    }
  });

  group('every shipped theme', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        testWidgets('${theme.name} $mode draws its slider', (tester) async {
          final style = tokens.slider;
          final p = tokens.palette;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(tokens),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueSlider(value: 0.4, onChanged: (_) {}),
                        ValueSlider(
                          value: 0.5,
                          divisions: 4,
                          onChanged: (_) {},
                        ),
                        const ValueSlider(value: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final data = SliderTheme.of(
            tester.element(find.byType(Slider).first),
          );
          expect(data.trackHeight, style.trackHeight);
          expect(data.activeTrackColor, style.inkOf(p));
          expect(data.inactiveTrackColor, style.railOf(p));
          expect(
            tester.getSize(find.byType(Slider).first).height,
            style.thumbSize > tokens.sizes.medium
                ? style.thumbSize
                : tokens.sizes.medium,
          );
        });
      }
    }
  });
}
