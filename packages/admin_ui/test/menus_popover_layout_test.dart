import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A 420×360 window with one trigger at [at].
Future<void> _pump(
  WidgetTester tester, {
  required Offset at,
  required Widget child,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(420, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              width: 96,
              height: 36,
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}

Menu _menu(int count, {PopoverAlign align = PopoverAlign.start}) => Menu(
  align: align,
  entries: [
    for (var i = 0; i < count; i++) MenuItem('Item $i', onSelect: () {}),
  ],
  builder: (context, c) =>
      TextButton(onPressed: c.toggle, child: const Text('Open')),
);

Rect _surface(WidgetTester tester) =>
    tester.getRect(find.byType(PopoverMenuSurface));

Rect _trigger(WidgetTester tester) => tester.getRect(find.byType(TextButton));

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a menu at the bottom edge flips above its trigger', (
    tester,
  ) async {
    await _pump(tester, at: const Offset(24, 300), child: _menu(4));
    await _open(tester);
    final surface = _surface(tester);
    final trigger = _trigger(tester);
    expect(surface.bottom, lessThanOrEqualTo(trigger.top));
    expect(surface.overlaps(trigger), isFalse, reason: 'never covers it');
    expect(surface.top, greaterThanOrEqualTo(8));
  });

  testWidgets('a menu that fits below stays below', (tester) async {
    await _pump(tester, at: const Offset(24, 40), child: _menu(4));
    await _open(tester);
    expect(_surface(tester).top, _trigger(tester).bottom + 6);
  });

  testWidgets('a long menu is capped to the room beside its trigger and '
      'scrolls', (tester) async {
    // 186 below the trigger's bottom, 150 above its top: 160 and 136 of room
    // after the 6px gap and 8px margin.
    await _pump(tester, at: const Offset(24, 150), child: _menu(30));
    await _open(tester);
    final surface = _surface(tester);
    final trigger = _trigger(tester);
    expect(surface.height, 160);
    expect(surface.top, trigger.bottom + 6);
    expect(surface.bottom, lessThanOrEqualTo(352));
    expect(find.text('Item 29').hitTestable(), findsNothing);
  });

  testWidgets('content that cannot shrink keeps its size and is clamped', (
    tester,
  ) async {
    await _pump(
      tester,
      at: const Offset(24, 150),
      child: Popover(
        anchor: (context, c) =>
            TextButton(onPressed: c.toggle, child: const Text('Open')),
        content: (context, c) =>
            const SizedBox(key: Key('rigid'), width: 200, height: 300),
      ),
    );
    await _open(tester);
    final rect = tester.getRect(find.byKey(const Key('rigid')));
    expect(rect.height, 300);
    expect(rect.top, greaterThanOrEqualTo(8));
    expect(rect.bottom, lessThanOrEqualTo(352));
  });

  testWidgets('scrolled out of view, the anchor takes the popover with it', (
    tester,
  ) async {
    Widget popover() => Popover(
      anchor: (context, c) =>
          TextButton(onPressed: c.toggle, child: const Text('Open')),
      content: (context, c) =>
          const SizedBox(key: Key('rigid'), width: 200, height: 100),
    );
    await _pump(tester, at: const Offset(24, 150), child: popover());
    await _open(tester);
    // The trigger moves wholly below the 360px window, the popover open.
    await _pump(tester, at: const Offset(24, 420), child: popover());
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const Key('rigid')));
    final anchor = _trigger(tester);
    expect(anchor.top, greaterThan(360));
    // Above its anchor and touching it, not held inside the window.
    expect(rect.bottom, lessThanOrEqualTo(anchor.top));
    expect(rect.bottom, greaterThan(352));
  });

  testWidgets('a menu near the right edge is clamped into the window', (
    tester,
  ) async {
    await _pump(tester, at: const Offset(316, 40), child: _menu(3));
    await _open(tester);
    final surface = _surface(tester);
    expect(surface.right, 412, reason: 'pushed left to the 8px margin');
    expect(surface.left, lessThan(_trigger(tester).left));
  });

  testWidgets('start and end follow the text direction', (tester) async {
    await _pump(
      tester,
      at: const Offset(200, 40),
      direction: TextDirection.rtl,
      child: _menu(3),
    );
    await _open(tester);
    expect(_surface(tester).right, _trigger(tester).right);

    await tester.tapAt(const Offset(10, 340));
    await tester.pumpAndSettle();
    await _pump(
      tester,
      at: const Offset(200, 40),
      direction: TextDirection.rtl,
      child: _menu(3, align: PopoverAlign.end),
    );
    await _open(tester);
    expect(_surface(tester).left, _trigger(tester).left);
  });

  testWidgets('availableHeightOf reports the larger side', (tester) async {
    double? available;
    await _pump(
      tester,
      at: const Offset(24, 150),
      child: Popover(
        anchor: (context, c) =>
            TextButton(onPressed: c.toggle, child: const Text('Open')),
        content: (context, c) {
          available = Popover.availableHeightOf(context);
          return const SizedBox(width: 10, height: 10);
        },
      ),
    );
    expect(available, isNull);
    await _open(tester);
    expect(available, 160);
  });
}
