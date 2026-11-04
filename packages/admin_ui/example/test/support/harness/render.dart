import 'dart:async';
import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui_example/src/ui/demo_kit.dart';
import 'package:admin_ui_example/src/utils/test_app.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'entries.dart';
import 'fonts.dart';
import 'matrix.dart';

/// The body of a package's `test/flutter_test_config.dart`, so a demo lays
/// out on every run as it does on a device: real fonts (see
/// [loadTestFonts]), no network, and a caret that does not blink.
Future<void> runWithCatalogHarness(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  EditableText.debugDeterministicCursor = true;
  await loadTestFonts();
  await testMain();
}

/// The surface a demo is first laid out on: a laptop window.
const defaultSurface = Size(1280, 900);

/// The shortest surface a page is cropped to.
const _minHeight = 320.0;

/// Room kept around a menu or popover: its shadow, and the margin it keeps
/// from the window's edge.
const _floatingMargin = 16.0;

const _step = Duration(milliseconds: 100);

const _rootKey = ValueKey('pumpEntry root');

/// Pumps [entry] themed as [config] says, the way the catalog's preview shell
/// themes it, and returns the finder of its root.
///
/// Deterministic: a pixel ratio of 1, fixed steps (never `pumpAndSettle`:
/// demos run timers), and the images on screen decoded. The text
/// scale and reduced motion are set on the platform, so overlays inherit
/// them too; both are reset when the test ends. Arabic is drawn in the test
/// Arabic font whatever the locale (see [withTestFontFallback]), and text in
/// a family no test font serves fails the test (see [textWithoutFont]).
///
/// The surface is [size] when given. Otherwise the demo is laid out on
/// [defaultSurface], and one that is a [DemoPage] is cropped to the page:
/// its `maxWidth` wide (at most 1280) and as tall as its content, between 320
/// and [maxHeight], grown to keep an open menu or popover whole. The demo is
/// then mounted afresh on that surface, since a menu closes when its window
/// resizes. A page under a dialog or sheet keeps the full surface: those lay
/// out against the window.
///
/// Exceptions the demo throws, on any of those mounts, are left for the
/// caller: take them with `tester.takeException()`, or the test fails with
/// them.
Future<Finder> pumpEntry(
  WidgetTester tester,
  DemoEntry entry,
  RenderConfig config, {
  Size? size,
  double maxHeight = 2400,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final platform = tester.platformDispatcher;
  platform.textScaleFactorTestValue = config.textScale;
  addTearDown(platform.clearTextScaleFactorTestValue);
  platform.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
    disableAnimations: config.disableAnimations,
    reduceMotion: config.disableAnimations,
  );
  addTearDown(platform.clearAccessibilityFeaturesTestValue);

  var surface = size ?? defaultSurface;
  // A list lays out only what is near its viewport and estimates the rest,
  // and a popover may flip on another surface, so the crop settles over a
  // few mounts.
  for (var mount = 0; ; mount++) {
    tester.view.physicalSize = surface;
    await _mount(tester, entry, config);
    if (size != null || mount == 3) break;
    final fit = _pageFit(tester, maxHeight);
    if (fit == null || fit == surface) break;
    surface = fit;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  }
  final boxed = textWithoutFont();
  if (boxed.isNotEmpty) {
    throw TestFailure(
      '${entry.id} draws text in no font the tests load, which shows as '
      'boxes: ${boxed.join(', ')}. Load it in loadTestFonts (test/support/harness/fonts.dart).',
    );
  }
  return find.byKey(_rootKey);
}

/// Unmounts the demo, then lets the timers it left (a fake fetch, a toast)
/// run out, so none is pending when the test ends.
Future<void> unmountAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 1));
  expect(tester.takeException(), isNull);
}

Future<void> _mount(
  WidgetTester tester,
  DemoEntry entry,
  RenderConfig config,
) async {
  ThemeData theme(ThemeMode mode) => buildAppTheme(
    withTestFontFallback(
      config.copyWith(mode: mode).tokens,
      fallback: catalogFontFallback,
    ),
  );

  await _offline(entry, () async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: _rootKey,
        child: TestApp(
          theme: theme(ThemeMode.light),
          darkTheme: theme(ThemeMode.dark),
          themeMode: config.mode,
          locale: config.locale,
          textDirection: config.direction,
          child: entry.build(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(_step);
    }
    await _loadAsync(tester, entry);
    await tester.pump(_step);
  });
}

/// Runs [body] quiet: what the demo prints, a debug build's log of the errors it
/// shows, say, is dropped, as are the lines of the timers it starts, which
/// run in this zone. Flutter's error reports still print.
Future<void> _offline(DemoEntry entry, Future<void> Function() body) {
  final zone = Zone.current;
  final done = Completer<void>();
  runZonedGuarded(
    () => body().then(done.complete, onError: done.completeError),
    zone.handleUncaughtError,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (line.startsWith(_errorReport)) parent.print(zone, line);
      },
    ),
  );
  return done.future;
}

/// How `FlutterError.dumpErrorToConsole` starts a report.
const _errorReport = '══╡';

/// Decodes every image on screen, in real time: under fake async it would
/// not finish.
Future<void> _loadAsync(WidgetTester tester, DemoEntry entry) async {
  final images = <(ImageProvider, BuildContext)>[];
  for (final element in tester.allElements) {
    switch (element.widget) {
      case Image(:final image):
      case DecoratedBox(
        decoration: BoxDecoration(image: DecorationImage(:final image)),
      ):
        images.add((image, element));
    }
  }
  await tester.runAsync(() async {
    await Future.wait([
      for (final (image, context) in images)
        precacheImage(image, context, onError: (_, _) {}),
    ]).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TestFailure('${entry.id}: an image never loaded'),
    );
  });
}

/// The surface that fits the [DemoPage] filling the current one, or null
/// when the demo is not such a page or a route shows over it.
Size? _pageFit(WidgetTester tester, double maxHeight) {
  final pages = find.byType(DemoPage);
  // Every route has a barrier, the page's own included.
  if (pages.evaluate().isEmpty ||
      find.byType(ModalBarrier).evaluate().length > 1) {
    return null;
  }
  final page = pages.first;
  final surface = tester.view.physicalSize / tester.view.devicePixelRatio;
  if (tester.getSize(page) != surface) return null;

  var width = tester.widget<DemoPage>(page).maxWidth;
  var height = 0.0;
  tester
      .renderObject(
        find.descendant(of: page, matching: find.byType(Viewport)).first,
      )
      .visitChildren(
        (sliver) => height += (sliver as RenderSliver).geometry!.scrollExtent,
      );
  final floating = _floating(
    tester.renderObject(find.byKey(_rootKey)),
    tester.renderObject(page),
    surface,
  );
  if (floating != null) {
    final bounds = floating.inflate(_floatingMargin);
    final center = surface.width / 2;
    width = math.max(
      width,
      2 * math.max(center - bounds.left, bounds.right - center),
    );
    height = math.max(height, bounds.bottom);
  }
  return Size(
    math.min(width, defaultSurface.width).ceilToDouble(),
    height.clamp(_minHeight, maxHeight).ceilToDouble(),
  );
}

/// The bounds of what shows outside [page] (a menu, a popover, a tip), in
/// global coordinates: the first boxes down from [root] that do not fill
/// the surface, as the overlay's layers all do.
Rect? _floating(RenderObject root, RenderObject page, Size surface) {
  Rect? bounds;
  void visit(RenderObject node) {
    if (identical(node, page) || node is! RenderBox || !node.hasSize) return;
    if (node.size == surface) {
      node.visitChildren(visit);
      return;
    }
    if (node.size.isEmpty) return;
    final rect = MatrixUtils.transformRect(
      node.getTransformTo(null),
      Offset.zero & node.size,
    );
    bounds = bounds?.expandToInclude(rect) ?? rect;
  }

  visit(root);
  return bounds;
}
