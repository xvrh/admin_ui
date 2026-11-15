import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _content = Key('content');

/// A [ZoomView] of [contentSize] in a [size] box at the top left of the
/// screen.
Widget _host({
  Size contentSize = const Size(800, 400),
  Size size = const Size(400, 300),
  ZoomController? controller,
  double maxScale = 8,
  bool showControls = true,
  String? semanticLabel,
  TextDirection direction = TextDirection.ltr,
  bool reducedMotion = false,
  Widget? child,
}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Directionality(
    textDirection: direction,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox.fromSize(
              size: size,
              child: ZoomView(
                contentSize: contentSize,
                controller: controller,
                maxScale: maxScale,
                showControls: showControls,
                semanticLabel: semanticLabel,
                child:
                    child ??
                    const ColoredBox(key: _content, color: Color(0xFF3366CC)),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The bar's button labelled [label].
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is IconAction && w.label == label);

/// Where the content is drawn, in the view's coordinates.
Rect _drawn(WidgetTester tester) => tester
    .getRect(find.byKey(_content))
    .shift(-tester.getTopLeft(find.byType(ZoomView)));

/// The content point drawn at [at], a point of the view.
Offset _pointAt(WidgetTester tester, Offset at, double scale) =>
    (at - _drawn(tester).topLeft) / scale;

Matcher _rectCloseTo(Rect rect) => isA<Rect>()
    .having((r) => r.left, 'left', closeTo(rect.left, 1e-6))
    .having((r) => r.top, 'top', closeTo(rect.top, 1e-6))
    .having((r) => r.right, 'right', closeTo(rect.right, 1e-6))
    .having((r) => r.bottom, 'bottom', closeTo(rect.bottom, 1e-6));

Matcher _offsetCloseTo(Offset offset) => isA<Offset>()
    .having((o) => o.dx, 'dx', closeTo(offset.dx, 1e-6))
    .having((o) => o.dy, 'dy', closeTo(offset.dy, 1e-6));

Future<TestPointer> _wheel(WidgetTester tester, Offset at, double dy) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.hover(at));
  await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  await tester.pump();
  return pointer;
}

Future<void> _doubleClick(WidgetTester tester, Offset at) async {
  await tester.tapAt(at, kind: PointerDeviceKind.mouse);
  await tester.pump(kDoubleTapMinTime);
  await tester.tapAt(at, kind: PointerDeviceKind.mouse);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('it opens fitted: a wide content fills the width, centred '
      'between empty bands', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller));

    expect(controller.scale, 0.5);
    expect(controller.isFitted, isTrue);
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('a tall content fills the height, centred', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(
      _host(contentSize: const Size(300, 900), controller: controller),
    );

    expect(controller.scale, closeTo(1 / 3, 1e-9));
    expect(_drawn(tester), _rectCloseTo(const Rect.fromLTWH(150, 0, 100, 300)));
    expect(find.text('33%'), findsOneWidget);
  });

  testWidgets('the wheel zooms about the pointer, the point under it kept '
      'there', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller));
    // Left of the middle, on the middle row: the bounds never move it.
    const at = Offset(100, 150);
    final before = _pointAt(tester, at, controller.scale);

    await _wheel(tester, at, -100);
    expect(controller.scale, greaterThan(0.5));
    expect(controller.isFitted, isFalse);
    expect(_pointAt(tester, at, controller.scale), _offsetCloseTo(before));

    await _wheel(tester, at, 40);
    expect(_pointAt(tester, at, controller.scale), _offsetCloseTo(before));
  });

  testWidgets('it never zooms out past fitted nor in past maxScale', (
    tester,
  ) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller, maxScale: 2));
    const at = Offset(200, 150);

    await _wheel(tester, at, 5000);
    expect(controller.scale, 0.5);
    expect(controller.isFitted, isTrue);
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));

    await _wheel(tester, at, -5000);
    expect(controller.scale, 2);
    expect(controller.canZoomIn, isFalse);
    controller.zoomIn();
    await tester.pumpAndSettle();
    expect(controller.scale, 2);

    // A maxScale below fitted cannot zoom in at all.
    await tester.pumpWidget(_host(controller: controller, maxScale: 0.25));
    await tester.pumpAndSettle();
    expect(controller.scale, 0.5);
    expect(controller.canZoomIn, isFalse);
    await _wheel(tester, at, -500);
    expect(controller.scale, 0.5);
  });

  testWidgets('a drag pans no further than the content reaches, and along '
      'an axis where the content is smaller it stays centred', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(
      _host(contentSize: const Size(800, 200), controller: controller),
    );
    controller.actualSize();
    await tester.pumpAndSettle();
    expect(controller.scale, 1);
    expect(_drawn(tester), const Rect.fromLTWH(-200, 50, 800, 200));

    await tester.dragFrom(
      const Offset(200, 150),
      const Offset(1000, 1000),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 800, 200));

    await tester.dragFrom(
      const Offset(200, 150),
      const Offset(-5000, -40),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(_drawn(tester), const Rect.fromLTWH(-400, 50, 800, 200));

    // Fitted, there is nowhere to pan.
    controller.fit();
    await tester.pumpAndSettle();
    await tester.dragFrom(
      const Offset(200, 150),
      const Offset(100, 100),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(kDoubleTapTimeout);
    expect(_drawn(tester), const Rect.fromLTWH(0, 100, 400, 100));
  });

  testWidgets('a double click shows actual pixels about the pointer, and '
      'another fits again', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller));
    const at = Offset(150, 120);
    final point = _pointAt(tester, at, controller.scale);

    await _doubleClick(tester, at);
    expect(controller.scale, 1);
    expect(_pointAt(tester, at, 1), _offsetCloseTo(point));

    await _doubleClick(tester, at);
    expect(controller.isFitted, isTrue);
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));

    // Where actual pixels are no larger than fitted, it steps in instead.
    await tester.pumpWidget(
      _host(contentSize: const Size(200, 100), controller: controller),
    );
    await tester.pumpAndSettle();
    expect(controller.scale, 2);
    await _doubleClick(tester, at);
    expect(controller.scale, 3);
  });

  testWidgets('the controller steps through the levels, fits and shows '
      'actual pixels, and notifies its listeners', (tester) async {
    final controller = ZoomController();
    var notified = 0;
    controller.addListener(() => notified++);
    await tester.pumpWidget(_host(controller: controller));
    await tester.pump();

    final steps = <double>[];
    Future<void> run(VoidCallback step) async {
      step();
      await tester.pumpAndSettle();
      steps.add(controller.scale);
    }

    await run(controller.zoomIn);
    await run(controller.zoomIn);
    await run(controller.zoomIn);
    await run(controller.zoomOut);
    await run(controller.zoomOut);
    await run(controller.zoomOut);
    expect(steps, [closeTo(2 / 3, 1e-9), 1, 1.5, 1, closeTo(2 / 3, 1e-9), 0.5]);
    expect(controller.isFitted, isTrue);

    await run(controller.actualSize);
    expect(controller.scale, 1);
    expect(find.text('100%'), findsOneWidget);
    // About the middle of the view.
    expect(_drawn(tester), const Rect.fromLTWH(-200, -50, 800, 400));

    await run(controller.fit);
    expect(controller.isFitted, isTrue);
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));
    expect(notified, greaterThan(8));
  });

  group('show', () {
    // A 400 × 300 view of an 800 × 400 content, fitted at 0.5.

    testWidgets('fills the view with a region, centred on it', (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(_host(controller: controller));

      controller.show(const Rect.fromLTWH(300, 150, 100, 50));
      await tester.pumpAndSettle();
      // The width binds: 400 / 100.
      expect(controller.scale, 4);
      expect(
        _pointAt(tester, const Offset(200, 150), 4),
        const Offset(350, 175),
      );
      expect(find.text('400%'), findsOneWidget);
    });

    testWidgets('near an edge, stops at the content\'s edge', (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(_host(controller: controller));

      controller.show(const Rect.fromLTWH(0, 0, 100, 100));
      await tester.pumpAndSettle();
      // The height binds: 300 / 100.
      expect(controller.scale, 3);
      expect(_drawn(tester).topLeft, Offset.zero);
    });

    testWidgets('a small region shows at the maximum scale, a large one '
        'fits', (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(_host(controller: controller, maxScale: 4));

      controller.show(const Rect.fromLTWH(400, 200, 2, 2));
      await tester.pumpAndSettle();
      expect(controller.scale, 4);
      expect(
        _pointAt(tester, const Offset(200, 150), 4),
        const Offset(401, 201),
      );

      controller.show(const Rect.fromLTWH(-100, -100, 1000, 600));
      await tester.pumpAndSettle();
      expect(controller.isFitted, isTrue);
      expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));
    });

    testWidgets('lands in one frame under reduced motion', (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(
        _host(controller: controller, reducedMotion: true),
      );

      controller.show(const Rect.fromLTWH(300, 150, 100, 50));
      expect(controller.scale, 4);
    });
  });

  testWidgets('steps land in one frame under reduced motion', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller, reducedMotion: true));

    controller.zoomIn();
    expect(controller.scale, closeTo(2 / 3, 1e-9));
    controller.actualSize();
    expect(controller.scale, 1);
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('fitted, it stays fitted as the view resizes; zoomed in, it '
      'keeps its scale and the content point at the middle', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller));

    await tester.pumpWidget(
      _host(controller: controller, size: const Size(600, 300)),
    );
    expect(controller.isFitted, isTrue);
    expect(controller.scale, 0.75);
    expect(_drawn(tester), const Rect.fromLTWH(0, 0, 600, 300));

    await tester.pumpWidget(_host(controller: controller));
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));

    controller.actualSize();
    await tester.pumpAndSettle();
    await tester.dragFrom(
      const Offset(200, 150),
      const Offset(-60, 30),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    final middle = _pointAt(tester, const Offset(200, 150), 1);

    await tester.pumpWidget(
      _host(controller: controller, size: const Size(500, 260)),
    );
    expect(controller.scale, 1);
    expect(controller.isFitted, isFalse);
    expect(_pointAt(tester, const Offset(250, 130), 1), _offsetCloseTo(middle));

    // Grown until fitted is actual pixels, it is fitted.
    await tester.pumpWidget(
      _host(controller: controller, size: const Size(800, 600)),
    );
    expect(controller.isFitted, isTrue);
    expect(controller.scale, 1);
    await tester.pump(kDoubleTapTimeout);
  });

  testWidgets('the child is never built again by zooming or panning', (
    tester,
  ) async {
    var builds = 0;
    final controller = ZoomController();
    await tester.pumpWidget(
      _host(
        controller: controller,
        child: Builder(
          builder: (context) {
            builds++;
            return const SizedBox.expand(key: _content);
          },
        ),
      ),
    );
    expect(builds, 1);

    await _wheel(tester, const Offset(100, 100), -200);
    await tester.dragFrom(
      const Offset(200, 150),
      const Offset(-80, 40),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    controller.zoomIn();
    await tester.pumpAndSettle();
    controller.fit();
    await tester.pumpAndSettle();
    await tester.pump(kDoubleTapTimeout);
    expect(builds, 1);
  });

  testWidgets('keys zoom and pan while it has focus', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller));
    await tester.tapAt(const Offset(200, 150));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pumpAndSettle();
    expect(controller.scale, closeTo(2 / 3, 1e-9));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(controller.scale, 1);

    final before = _drawn(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_drawn(tester).left, closeTo(before.left - 40, 1e-6));

    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pumpAndSettle();
    expect(controller.scale, closeTo(2 / 3, 1e-9));

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect(controller.scale, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.pumpAndSettle();
    expect(controller.isFitted, isTrue);
  });

  testWidgets('a trackpad pinch zooms about the pointer and a two-finger '
      'scroll pans, and a page around the view does not scroll', (
    tester,
  ) async {
    final controller = ZoomController();
    final page = ScrollController();
    addTearDown(page.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Scaffold(
          body: ListView(
            controller: page,
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: ZoomView(
                    contentSize: const Size(800, 400),
                    controller: controller,
                    child: const ColoredBox(
                      key: _content,
                      color: Color(0xFF3366CC),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    final view = tester.getTopLeft(find.byType(ZoomView));
    const at = Offset(100, 120);
    final point = _pointAt(tester, at, controller.scale);

    final trackpad = TestPointer(2, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(trackpad.panZoomStart(view + at));
    await tester.sendEventToBinding(
      trackpad.panZoomUpdate(view + at, scale: 2),
    );
    await tester.sendEventToBinding(trackpad.panZoomEnd());
    await tester.pump();
    expect(controller.scale, 1);
    expect(_pointAt(tester, at, 1), _offsetCloseTo(point));

    final before = _drawn(tester);
    await tester.sendEventToBinding(trackpad.panZoomStart(view + at));
    await tester.sendEventToBinding(
      trackpad.panZoomUpdate(view + at, pan: const Offset(-30, -40)),
    );
    await tester.sendEventToBinding(trackpad.panZoomEnd());
    await tester.pump();
    expect(_drawn(tester).topLeft, before.topLeft + const Offset(-30, -40));
    expect(page.offset, 0);

    // On the web a trackpad scrolls with wheel events, which pan too.
    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.trackpad,
        position: view + at,
        scrollDelta: const Offset(0, 10),
      ),
    );
    await tester.pump();
    expect(controller.scale, 1);
    expect(_drawn(tester).top, before.top - 50);
    expect(page.offset, 0);
  });

  testWidgets('the pointer shows the open hand where there is somewhere to '
      'pan, and the closed one while dragging', (tester) async {
    final controller = ZoomController();
    await tester.pumpWidget(_host(controller: controller));
    MouseCursor? cursor() =>
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(200, 150));
    await tester.pump();
    expect(cursor(), SystemMouseCursors.basic);

    controller.zoomIn();
    await tester.pumpAndSettle();
    expect(cursor(), SystemMouseCursors.grab);

    await mouse.down(const Offset(200, 150));
    await mouse.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(cursor(), SystemMouseCursors.grabbing);
    await mouse.up();
    await tester.pump(kDoubleTapTimeout);
    expect(cursor(), SystemMouseCursors.grab);
  });

  testWidgets('the bar floats in the bottom end corner, and is gone with '
      'showControls: false', (tester) async {
    await tester.pumpWidget(_host());
    final view = tester.getRect(find.byType(ZoomView));
    final zoomOut = tester.getRect(_button('Zoom out'));
    final fit = tester.getRect(_button('Zoom to fit'));
    expect(_button('Zoom in'), findsOneWidget);
    expect(zoomOut.left, lessThan(fit.left));
    expect(fit.right, lessThan(view.right));
    expect(view.right - fit.right, lessThan(16));
    expect(view.bottom - fit.bottom, lessThan(16));

    await tester.pumpWidget(_host(showControls: false));
    expect(find.byType(IconAction), findsNothing);
    expect(find.text('50%'), findsNothing);
  });

  testWidgets('right to left, the bar sits in the bottom left and runs from '
      'the right', (tester) async {
    await tester.pumpWidget(_host(direction: TextDirection.rtl));
    final view = tester.getRect(find.byType(ZoomView));
    final zoomOut = tester.getRect(_button('Zoom out'));
    final fit = tester.getRect(_button('Zoom to fit'));
    expect(fit.left - view.left, lessThan(16));
    expect(view.bottom - fit.bottom, lessThan(16));
    expect(zoomOut.left, greaterThan(fit.left));
    // The content does not mirror.
    expect(_drawn(tester), const Rect.fromLTWH(0, 50, 400, 200));
  });

  testWidgets('it is announced by name with its scale, and its buttons by '
      'theirs', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(semanticLabel: 'Floor plan'));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Floor plan')),
      matchesSemantics(
        label: 'Floor plan',
        value: '50%',
        hint:
            'Scroll to zoom, drag to pan; + and − zoom, 0 fits, arrow keys '
            'pan.',
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Zoom in'), findsOneWidget);
    expect(find.bySemanticsLabel('Zoom out'), findsOneWidget);
    expect(find.bySemanticsLabel('Zoom to fit'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('50%')),
      matchesSemantics(label: '50%', isLiveRegion: true),
    );

    await tester.pumpWidget(_host());
    expect(find.bySemanticsLabel('Zoomable view'), findsOneWidget);
    semantics.dispose();
  });
}
