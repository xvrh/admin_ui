import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/popover.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _viewport = Size(800, 600);

/// A 100×40 anchor in the middle of [_viewport].
final _anchor = const Rect.fromLTWH(300, 250, 100, 40);

const _child = Size(160, 80);

Offset _place(
  PopoverSide side,
  PopoverAlign align, {
  TextDirection direction = TextDirection.ltr,
  Rect? anchor,
  Size child = _child,
  Size viewport = _viewport,
  double alignOffset = 0,
}) => placePopover(
  anchor: anchor ?? _anchor,
  child: child,
  viewport: viewport,
  side: side,
  align: align,
  gap: 6,
  alignOffset: alignOffset,
  textDirection: direction,
).offset;

PopoverSide _sideOf(
  PopoverSide side, {
  TextDirection direction = TextDirection.ltr,
  required Rect anchor,
  Size child = _child,
}) => placePopover(
  anchor: anchor,
  child: child,
  viewport: _viewport,
  side: side,
  align: PopoverAlign.start,
  gap: 6,
  textDirection: direction,
).placement.side;

/// The placement before the sides beside the anchor, centring and arrows,
/// as it was written then: [placePopover] must give the same offset for
/// every top or bottom, start or end placement.
Offset _before(
  Rect anchor,
  Size child,
  Size viewport,
  PopoverSide side,
  PopoverAlign align,
  TextDirection direction,
) {
  const gap = 6.0, margin = 8.0;
  PopoverSide opposite(PopoverSide side) =>
      side == PopoverSide.bottom ? PopoverSide.top : PopoverSide.bottom;
  double room(PopoverSide side) => math.max(
    0,
    side == PopoverSide.bottom
        ? viewport.height - anchor.bottom - gap - margin
        : anchor.top - gap - margin,
  );
  double clamp(double value, double extent, double childExtent) {
    final max = extent - childExtent - margin;
    if (max < margin) return margin;
    return value.clamp(margin, max);
  }

  final leading =
      (align == PopoverAlign.start) == (direction == TextDirection.ltr);
  var dx = leading ? anchor.left : anchor.right - child.width;
  var placed = side;
  final preferred = room(side);
  if (child.height > preferred && room(opposite(side)) > preferred) {
    placed = opposite(side);
  }
  var dy = placed == PopoverSide.bottom
      ? anchor.bottom + gap
      : anchor.top - gap - child.height;
  dx = clamp(dx, viewport.width, child.width);
  dy = clamp(dy, viewport.height, child.height);
  dx = dx.clamp(anchor.left - child.width, anchor.right);
  dy = dy.clamp(anchor.top - gap - child.height, anchor.bottom + gap);
  return Offset(dx, dy);
}

/// An app of [size] with [child] at [at], [anchorSize] big.
Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  Offset at = const Offset(300, 250),
  Size anchorSize = const Size(100, 40),
  Size size = _viewport,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              width: anchorSize.width,
              height: anchorSize.height,
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _anchorButton(BuildContext context, PopoverController c) =>
    TextButton(onPressed: c.toggle, child: const Text('Open'));

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

const _content = Key('content');

void main() {
  group('placePopover', () {
    test('every side and alignment, left to right', () {
      final expected = {
        (PopoverSide.bottom, PopoverAlign.start): const Offset(300, 296),
        (PopoverSide.bottom, PopoverAlign.center): const Offset(270, 296),
        (PopoverSide.bottom, PopoverAlign.end): const Offset(240, 296),
        (PopoverSide.top, PopoverAlign.start): const Offset(300, 164),
        (PopoverSide.top, PopoverAlign.center): const Offset(270, 164),
        (PopoverSide.top, PopoverAlign.end): const Offset(240, 164),
        (PopoverSide.start, PopoverAlign.start): const Offset(134, 250),
        (PopoverSide.start, PopoverAlign.center): const Offset(134, 230),
        (PopoverSide.start, PopoverAlign.end): const Offset(134, 210),
        (PopoverSide.end, PopoverAlign.start): const Offset(406, 250),
        (PopoverSide.end, PopoverAlign.center): const Offset(406, 230),
        (PopoverSide.end, PopoverAlign.end): const Offset(406, 210),
      };
      for (final MapEntry(key: (side, align), value: at) in expected.entries) {
        expect(_place(side, align), at, reason: '$side $align');
      }
    });

    test('right to left, start and end mirror; top and bottom do not', () {
      const rtl = TextDirection.rtl;
      final expected = {
        (PopoverSide.bottom, PopoverAlign.start): const Offset(240, 296),
        (PopoverSide.bottom, PopoverAlign.center): const Offset(270, 296),
        (PopoverSide.bottom, PopoverAlign.end): const Offset(300, 296),
        (PopoverSide.top, PopoverAlign.start): const Offset(240, 164),
        (PopoverSide.top, PopoverAlign.end): const Offset(300, 164),
        (PopoverSide.start, PopoverAlign.start): const Offset(406, 250),
        (PopoverSide.start, PopoverAlign.center): const Offset(406, 230),
        (PopoverSide.start, PopoverAlign.end): const Offset(406, 210),
        (PopoverSide.end, PopoverAlign.start): const Offset(134, 250),
        (PopoverSide.end, PopoverAlign.end): const Offset(134, 210),
      };
      for (final MapEntry(key: (side, align), value: at) in expected.entries) {
        expect(_place(side, align, direction: rtl), at, reason: '$side $align');
      }
    });

    test('alignOffset moves away from the edge lined up, mirrored in '
        'right to left', () {
      Offset shifted(
        PopoverSide side,
        PopoverAlign align, [
        TextDirection direction = TextDirection.ltr,
      ]) =>
          _place(side, align, direction: direction, alignOffset: 10) -
          _place(side, align, direction: direction);

      expect(
        shifted(PopoverSide.bottom, PopoverAlign.start),
        const Offset(10, 0),
      );
      expect(
        shifted(PopoverSide.bottom, PopoverAlign.center),
        const Offset(10, 0),
      );
      expect(
        shifted(PopoverSide.bottom, PopoverAlign.end),
        const Offset(-10, 0),
      );
      expect(
        shifted(PopoverSide.top, PopoverAlign.start, TextDirection.rtl),
        const Offset(-10, 0),
      );
      expect(
        shifted(PopoverSide.top, PopoverAlign.end, TextDirection.rtl),
        const Offset(10, 0),
      );
      expect(
        shifted(PopoverSide.start, PopoverAlign.start),
        const Offset(0, 10),
      );
      expect(shifted(PopoverSide.end, PopoverAlign.end), const Offset(0, -10));
      expect(
        shifted(PopoverSide.end, PopoverAlign.start, TextDirection.rtl),
        const Offset(0, 10),
        reason: 'beside the anchor, start is the top in either direction',
      );
    });

    test('flips on either axis, and only toward more room', () {
      // 80 below the anchor's bottom: 66 of room after the gap and margin.
      final low = const Rect.fromLTWH(300, 480, 100, 40);
      expect(_sideOf(PopoverSide.bottom, anchor: low), PopoverSide.top);
      expect(_sideOf(PopoverSide.top, anchor: low), PopoverSide.top);
      final high = const Rect.fromLTWH(300, 20, 100, 40);
      expect(_sideOf(PopoverSide.top, anchor: high), PopoverSide.bottom);

      final left = const Rect.fromLTWH(20, 250, 100, 40);
      expect(_sideOf(PopoverSide.start, anchor: left), PopoverSide.end);
      expect(_sideOf(PopoverSide.end, anchor: left), PopoverSide.end);
      final right = const Rect.fromLTWH(680, 250, 100, 40);
      expect(_sideOf(PopoverSide.end, anchor: right), PopoverSide.start);
      expect(
        _sideOf(PopoverSide.start, anchor: right, direction: TextDirection.rtl),
        PopoverSide.end,
        reason: 'in right to left the start is the right',
      );

      // Short on both sides, the preferred side has more room: it stays.
      final tall = const Rect.fromLTWH(300, 300, 100, 40);
      const big = Size(160, 400);
      expect(
        _sideOf(PopoverSide.bottom, anchor: tall, child: big),
        PopoverSide.top,
        reason: '286 above against 246 below',
      );
      expect(
        _sideOf(PopoverSide.top, anchor: tall, child: big),
        PopoverSide.top,
      );
      final wide = const Rect.fromLTWH(390, 250, 20, 40);
      const broad = Size(500, 80);
      expect(
        _sideOf(PopoverSide.start, anchor: wide, child: broad),
        PopoverSide.start,
        reason: '376 on the start against 376 on the end: no more room',
      );
    });

    test('clamps into the viewport, but never parts from the anchor', () {
      // Near the right edge: pushed left to the 8px margin.
      expect(
        _place(
          PopoverSide.bottom,
          PopoverAlign.start,
          anchor: const Rect.fromLTWH(700, 100, 60, 40),
        ),
        const Offset(632, 146),
      );
      // Wholly past the right edge: flush with the anchor's start instead.
      expect(
        _place(
          PopoverSide.bottom,
          PopoverAlign.start,
          anchor: const Rect.fromLTWH(900, 100, 60, 40),
        ),
        const Offset(740, 146),
      );
      // Beside the anchor, the vertical clamp does the same.
      expect(
        _place(
          PopoverSide.end,
          PopoverAlign.start,
          anchor: const Rect.fromLTWH(300, 560, 100, 40),
        ),
        const Offset(406, 512),
      );
      expect(
        _place(
          PopoverSide.end,
          PopoverAlign.start,
          anchor: const Rect.fromLTWH(300, 700, 100, 40),
        ),
        const Offset(406, 620),
      );
      // Taller than the viewport: held at the top margin.
      expect(
        _place(
          PopoverSide.start,
          PopoverAlign.center,
          child: const Size(160, 700),
        ),
        const Offset(134, 8),
      );
    });

    test('top and bottom, start and end: the same offsets as before', () {
      // The audit's menu at the bottom edge of a 420×360 window: flipped
      // above its trigger rather than covering it.
      const small = Size(420, 360);
      final trigger = const Rect.fromLTWH(24, 300, 96.7, 36);
      expect(
        _place(
          PopoverSide.bottom,
          PopoverAlign.start,
          anchor: trigger,
          child: const Size(180, 192),
          viewport: small,
        ),
        const Offset(24, 102),
      );
      expect(
        _place(
          PopoverSide.bottom,
          PopoverAlign.end,
          anchor: const Rect.fromLTWH(316, 40, 96, 36),
          child: const Size(180, 120),
          viewport: small,
        ),
        const Offset(232, 82),
      );

      final anchors = [
        for (final x in const [-200.0, 0.0, 24.0, 300.0, 700.0, 760.0, 900.0])
          for (final y in const [-100.0, 0.0, 20.0, 250.0, 460.0, 560.0, 700.0])
            Rect.fromLTWH(x, y, 96.5, 36),
      ];
      const children = [Size(160, 80), Size(300, 400), Size(900, 700)];
      var checked = 0;
      for (final anchor in anchors) {
        for (final child in children) {
          for (final side in [PopoverSide.bottom, PopoverSide.top]) {
            for (final align in [PopoverAlign.start, PopoverAlign.end]) {
              for (final direction in TextDirection.values) {
                expect(
                  _place(
                    side,
                    align,
                    anchor: anchor,
                    child: child,
                    direction: direction,
                  ),
                  _before(anchor, child, _viewport, side, align, direction),
                  reason: '$anchor $child $side $align $direction',
                );
                checked++;
              }
            }
          }
        }
      }
      expect(checked, 1176);
    });

    test('the arrow points at the anchor, clear of the corners', () {
      PopoverPlacement placed(
        Rect anchor, {
        PopoverSide side = PopoverSide.bottom,
        PopoverAlign align = PopoverAlign.start,
      }) => placePopover(
        anchor: anchor,
        child: _child,
        viewport: _viewport,
        side: side,
        align: align,
        gap: 6,
        arrowHeight: 6,
        arrowPadding: 15,
        textDirection: TextDirection.ltr,
      ).placement;

      final result = placePopover(
        anchor: _anchor,
        child: _child,
        viewport: _viewport,
        side: PopoverSide.bottom,
        align: PopoverAlign.center,
        gap: 6,
        arrowHeight: 6,
        arrowPadding: 15,
        textDirection: TextDirection.ltr,
      );
      expect(result.offset, const Offset(270, 302), reason: 'gap + arrow');
      expect(result.placement.arrowOffset, 80, reason: 'centred');
      expect(placed(_anchor).arrowOffset, 50);
      expect(
        placed(const Rect.fromLTWH(300, 250, 20, 40)).arrowOffset,
        15,
        reason: 'the corner radius plus half the arrow',
      );
      expect(
        placed(
          const Rect.fromLTWH(300, 250, 20, 40),
          align: PopoverAlign.end,
        ).arrowOffset,
        145,
      );
      expect(
        placed(
          _anchor,
          side: PopoverSide.end,
          align: PopoverAlign.end,
        ).arrowOffset,
        60,
        reason: 'down the edge beside the anchor',
      );
      expect(placed(_anchor).arrowOffset, isNotNull);
      expect(
        _place(PopoverSide.bottom, PopoverAlign.start),
        const Offset(300, 296),
      );
      expect(
        placePopover(
          anchor: _anchor,
          child: _child,
          viewport: _viewport,
          side: PopoverSide.bottom,
          align: PopoverAlign.start,
          gap: 6,
          textDirection: TextDirection.ltr,
        ).placement.arrowOffset,
        isNull,
        reason: 'no arrow',
      );
    });
  });

  group('Popover', () {
    testWidgets('availableSizeOf: along the side, the larger room; across, '
        'the viewport less its margins', (tester) async {
      final sizes = <PopoverSide, Size?>{};
      for (final side in PopoverSide.values) {
        await _pump(
          tester,
          child: Popover(
            key: ValueKey(side),
            side: side,
            anchor: _anchorButton,
            content: (context, c) {
              sizes[side] = Popover.availableSizeOf(context);
              return const SizedBox(width: 10, height: 10);
            },
          ),
        );
        await _open(tester);
      }
      expect(
        Popover.availableSizeOf(tester.element(find.byType(Scaffold))),
        isNull,
        reason: 'outside a popover',
      );
      // 296 below the anchor, 236 above; 286 before it, 386 after.
      expect(sizes[PopoverSide.bottom], const Size(784, 296));
      expect(sizes[PopoverSide.top], const Size(784, 296));
      expect(sizes[PopoverSide.start], const Size(386, 584));
      expect(sizes[PopoverSide.end], const Size(386, 584));
    });

    testWidgets('beside its anchor, a fitted surface narrows to the room, '
        'down to its minWidth', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 600),
        at: const Offset(150, 250),
        child: Popover(
          side: PopoverSide.end,
          anchor: _anchorButton,
          content: (context, c) => const PopoverMenuSurface(
            minWidth: 120,
            maxWidth: 320,
            fitAvailableHeight: true,
            child: SizedBox(width: 300, height: 40),
          ),
        ),
      );
      await _open(tester);
      final surface = tester.getRect(find.byType(PopoverMenuSurface));
      // 150 - 6 - 8 on either side.
      expect(surface.width, 136);
      expect(surface.left, 256);
    });

    testWidgets('with less room than its minWidth on either side, it keeps '
        'its width and slides over the anchor', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 600),
        at: const Offset(150, 250),
        child: Popover(
          side: PopoverSide.end,
          anchor: _anchorButton,
          content: (context, c) => const PopoverMenuSurface(
            minWidth: 180,
            maxWidth: 320,
            fitAvailableHeight: true,
            child: SizedBox(width: 300, height: 40),
          ),
        ),
      );
      await _open(tester);
      final surface = tester.getRect(find.byType(PopoverMenuSurface));
      expect(surface.width, 300);
      // Kept on its side, then 8 inside the viewport's end edge.
      expect(surface.right, 400 - 8);
    });

    testWidgets('start and end sides follow the text direction', (
      tester,
    ) async {
      for (final (direction, left) in [
        (TextDirection.ltr, 134.0),
        (TextDirection.rtl, 406.0),
      ]) {
        await _pump(
          tester,
          direction: direction,
          child: Popover(
            side: PopoverSide.start,
            align: PopoverAlign.center,
            anchor: _anchorButton,
            content: (context, c) =>
                const SizedBox(key: _content, width: 160, height: 80),
          ),
        );
        await _open(tester);
        expect(
          tester.getRect(find.byKey(_content)),
          const Rect.fromLTWH(0, 230, 160, 80).translate(left, 0),
          reason: '$direction',
        );
        await tester.tapAt(const Offset(790, 590));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('placementOf reports the side it flipped to, without '
        'rebuilding in the middle of a frame', (tester) async {
      final seen = <PopoverSide>[];
      await _pump(
        tester,
        at: const Offset(20, 250),
        child: Popover(
          side: PopoverSide.start,
          anchor: _anchorButton,
          content: (context, c) => ValueListenableBuilder(
            valueListenable: Popover.placementOf(context)!,
            builder: (context, placement, _) {
              seen.add(placement.side);
              return const SizedBox(key: _content, width: 160, height: 80);
            },
          ),
        ),
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(seen.last, PopoverSide.end);
      expect(tester.getRect(find.byKey(_content)).left, 126);
    });

    testWidgets('with showArrow, the surface stands off by the arrow and '
        'draws it where placementOf says', (tester) async {
      ValueListenable<PopoverPlacement>? placement;
      await _pump(
        tester,
        child: Popover(
          showArrow: true,
          align: PopoverAlign.center,
          anchor: _anchorButton,
          content: (context, c) {
            placement = Popover.placementOf(context);
            return const PopoverMenuSurface(
              width: 200,
              child: SizedBox(height: 60),
            );
          },
        ),
      );
      await _open(tester);
      final surface = tester.getRect(find.byType(PopoverMenuSurface));
      // Iris: a 12×6 arrow, 6 off the anchor's bottom at 290.
      expect(surface.top, 302);
      expect(surface.left, 250);
      expect(
        placement!.value,
        const PopoverPlacement(
          side: PopoverSide.bottom,
          align: PopoverAlign.center,
          arrowOffset: 100,
        ),
      );
      final arrows = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.foregroundPainter is PopoverArrowPainter,
      );
      expect(arrows, findsOneWidget);

      await tester.tapAt(const Offset(790, 590));
      await tester.pumpAndSettle();
      await _pump(
        tester,
        at: const Offset(300, 250),
        anchorSize: const Size(20, 40),
        child: Popover(
          showArrow: true,
          anchor: _anchorButton,
          content: (context, c) {
            placement = Popover.placementOf(context);
            return const PopoverMenuSurface(
              width: 200,
              child: SizedBox(height: 60),
            );
          },
        ),
      );
      await _open(tester);
      expect(
        placement!.value.arrowOffset,
        15,
        reason: 'radiusMenu 9 plus half the 12px arrow, not the 10 across',
      );
    });

    testWidgets('no arrow is drawn without showArrow', (tester) async {
      await _pump(
        tester,
        child: Popover(
          anchor: _anchorButton,
          content: (context, c) =>
              const PopoverMenuSurface(width: 200, child: SizedBox(height: 60)),
        ),
      );
      await _open(tester);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.foregroundPainter is PopoverArrowPainter,
        ),
        findsNothing,
      );
      expect(tester.getRect(find.byType(PopoverMenuSurface)).top, 296);
    });

    testWidgets('openPopoverAt opens at the point, flips near the bottom-end '
        'corner, and open() goes back to the anchor', (tester) async {
      late PopoverController controller;
      await _pump(
        tester,
        at: Offset.zero,
        anchorSize: _viewport,
        child: Popover(
          anchor: (context, c) {
            controller = c;
            return const SizedBox.expand();
          },
          content: (context, c) =>
              const SizedBox(key: _content, width: 160, height: 100),
        ),
      );
      openPopoverAt(controller, const Offset(100, 120));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTWH(100, 126, 160, 100),
      );

      openPopoverAt(controller, const Offset(780, 580));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      // Above the point, and shifted in to the 8px margin.
      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTWH(632, 474, 160, 100),
      );

      controller.close();
      await tester.pumpAndSettle();
      controller.open();
      await tester.pumpAndSettle();
      // Below the whole-window anchor there is no room, nor above it: the
      // popover is clamped in at the margins.
      expect(
        tester.getRect(find.byKey(_content)).topLeft,
        const Offset(8, 492),
      );
    });

    // The framework's semantics cannot take a non-finite transform either.
    testWidgets(
      'an anchor with no finite rect lays its content out hidden',
      semanticsEnabled: false,
      (tester) async {
        late PopoverController controller;
        Size? available;
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              // Measures the anchor as NaN, as a box laid out where nothing
              // paints it can.
              child: Transform(
                transform: Matrix4.diagonal3Values(double.nan, double.nan, 1),
                child: Popover(
                  showArrow: true,
                  anchor: (context, c) {
                    controller = c;
                    return const Text('Anchor');
                  },
                  content: (context, c) {
                    available = Popover.availableSizeOf(context);
                    return const PopoverMenuSurface(
                      width: 200,
                      fitAvailableHeight: true,
                      child: Text('Content'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        controller.open();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(controller.isOpen, isTrue);
        expect(available!.isFinite, isTrue);
        expect(find.text('Content', skipOffstage: false), findsOneWidget);
        expect(find.text('Content'), findsNothing, reason: 'not shown');
      },
    );
  });

  group('nested popovers', () {
    late PopoverController outer;
    late List<bool> innerChanges;

    Widget nested() => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(onPressed: () {}, child: const Text('elsewhere')),
            Popover(
              closeOnFocusOut: true,
              anchor: (context, c) {
                outer = c;
                return ElevatedButton(
                  onPressed: c.toggle,
                  child: const Text('outer'),
                );
              },
              content: (context, c) => Material(
                child: Popover(
                  autofocus: false,
                  side: PopoverSide.end,
                  onOpenChanged: innerChanges.add,
                  anchor: (context, c) =>
                      TextButton(onPressed: c.toggle, child: const Text('row')),
                  content: (context, c) => const Material(
                    child: SizedBox(width: 200, child: TextField()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Future<void> openBoth(WidgetTester tester) async {
      await tester.tap(find.text('outer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('row'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    }

    setUp(() => innerChanges = []);

    testWidgets('focus moving into the child keeps the parent open; Escape '
        'closes the child first and focuses its row', (tester) async {
      await tester.pumpWidget(nested());
      await openBoth(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('row'), findsOneWidget, reason: 'still open');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('row'), findsOneWidget);
      expect(
        Focus.of(tester.element(find.text('row'))).hasPrimaryFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('row'), findsNothing);
    });

    testWidgets('the child closes with its parent', (tester) async {
      await tester.pumpWidget(nested());
      await openBoth(tester);
      outer.close();
      await tester.pumpAndSettle();
      expect(find.text('row'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(innerChanges, [true, false]);

      await tester.tap(find.text('outer'));
      await tester.pumpAndSettle();
      expect(find.text('row'), findsOneWidget);
      expect(find.byType(TextField), findsNothing, reason: 'reopens closed');
    });

    testWidgets('a tap in the child is inside the parent; a tap outside '
        'both closes both', (tester) async {
      await tester.pumpWidget(nested());
      await openBoth(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('row'), findsOneWidget);

      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();
      expect(find.text('row'), findsNothing);
      expect(innerChanges, [true, false]);
    });

    testWidgets('focus leaving both closes both', (tester) async {
      await tester.pumpWidget(nested());
      await openBoth(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('elsewhere'))).requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('row'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
