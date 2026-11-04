import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The default test surface.
const _view = Size(800, 600);

/// A 40px target in the middle of the view.
final _middle = Rect.fromCenter(
  center: const Offset(400, 300),
  width: 40,
  height: 40,
);

const _arrow = AdminOverlayStyle(
  tooltipArrow: true,
  arrowWidth: 10,
  arrowHeight: 5,
);

/// [tip], or any tooltip, around a target at [target].
Widget _host(
  Widget Function(Widget target) tip, {
  required Rect target,
  TextDirection direction = TextDirection.ltr,
  AdminTokens? tokens,
}) => MaterialApp(
  theme: buildAppTheme(tokens ?? defaultTokens),
  home: Directionality(
    textDirection: direction,
    child: Stack(
      children: [
        Positioned.fromRect(
          rect: target,
          child: tip(const SizedBox.expand(key: Key('target'))),
        ),
      ],
    ),
  ),
);

Future<void> _show(WidgetTester tester) async {
  tester.state<TooltipState>(find.byType(Tooltip)).ensureTooltipVisible();
  await tester.pumpAndSettle();
}

/// The chip carrying [message].
Finder _chip(String message) => find
    .ancestor(
      of: find.textContaining(message, findRichText: true),
      matching: find.byType(DecoratedBox),
    )
    .first;

/// Where the chip for [tip] opens around [target].
Future<Rect> _open(
  WidgetTester tester,
  Widget Function(Widget target) tip, {
  required Rect target,
  TextDirection direction = TextDirection.ltr,
  AdminTokens? tokens,
  String message = 'Hint',
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    _host(tip, target: target, direction: direction, tokens: tokens),
  );
  await _show(tester);
  return tester.getRect(_chip(message));
}

void main() {
  group('the default position is a bare Tooltip’s', () {
    // A Tip without a side used to be a bare Tooltip: below, centred, its
    // near edge 24 from the target's middle, 10 from the view's edges.
    final targets = {
      'a 24px icon': const Rect.fromLTWH(100, 100, 24, 24),
      'an Ant or Fluent icon action': const Rect.fromLTWH(100, 100, 32, 32),
      'an Iris or shadcn icon action': const Rect.fromLTWH(100, 100, 36, 36),
      'a Material or Carbon icon action': const Rect.fromLTWH(100, 100, 40, 40),
      'a tall row': const Rect.fromLTWH(100, 100, 300, 72),
      'at the view’s start edge': const Rect.fromLTWH(0, 100, 24, 24),
      'at the view’s end edge': const Rect.fromLTWH(776, 100, 24, 24),
      'at the view’s bottom, flipping above': const Rect.fromLTWH(
        300,
        570,
        36,
        30,
      ),
    };
    for (final MapEntry(key: name, value: target) in targets.entries) {
      testWidgets(name, (tester) async {
        const message = 'Hint for the target';
        final tip = await _open(
          tester,
          (child) => Tip(message: message, child: child),
          target: target,
          message: message,
        );
        final bare = await _open(
          tester,
          (child) => Tooltip(message: message, child: child),
          target: target,
          message: message,
        );
        expect(tip, bare);
      });
    }

    testWidgets('in numbers: 6 below a 36px target, centred', (tester) async {
      final target = const Rect.fromLTWH(100, 100, 36, 36);
      final chip = await _open(
        tester,
        (child) => Tip(message: 'Hint', child: child),
        target: target,
      );
      expect(chip.top, target.bottom + 6);
      expect(chip.center.dx, target.center.dx);
    });
  });

  group('side and align', () {
    const gap = 8.0;
    for (final direction in TextDirection.values) {
      final ltr = direction == TextDirection.ltr;
      for (final side in PopoverSide.values) {
        for (final align in PopoverAlign.values) {
          testWidgets('${direction.name} ${side.name} ${align.name}', (
            tester,
          ) async {
            final chip = await _open(
              tester,
              (child) => Tip(
                message: 'Hint',
                side: side,
                align: align,
                gap: gap,
                showArrow: false,
                child: child,
              ),
              target: _middle,
              direction: direction,
            );
            final t = _middle;
            // The physical side: start and end follow the direction.
            final left =
                side == PopoverSide.start && ltr ||
                side == PopoverSide.end && !ltr;
            switch (side) {
              case PopoverSide.bottom || PopoverSide.top:
                if (side == PopoverSide.bottom) {
                  expect(chip.top, t.bottom + gap);
                } else {
                  expect(chip.bottom, t.top - gap);
                }
                final leading = ltr ? chip.left : chip.right;
                final trailing = ltr ? chip.right : chip.left;
                switch (align) {
                  case PopoverAlign.start:
                    expect(leading, ltr ? t.left : t.right);
                  case PopoverAlign.center:
                    expect(chip.center.dx, t.center.dx);
                  case PopoverAlign.end:
                    expect(trailing, ltr ? t.right : t.left);
                }
              case PopoverSide.start || PopoverSide.end:
                if (left) {
                  expect(chip.right, t.left - gap);
                } else {
                  expect(chip.left, t.right + gap);
                }
                switch (align) {
                  case PopoverAlign.start:
                    expect(chip.top, t.top);
                  case PopoverAlign.center:
                    expect(chip.center.dy, t.center.dy);
                  case PopoverAlign.end:
                    expect(chip.bottom, t.bottom);
                }
            }
          });
        }
      }
    }

    testWidgets('beside the target, the gap is 4 by default', (tester) async {
      final chip = await _open(
        tester,
        (child) => Tip(
          message: 'Hint',
          side: PopoverSide.end,
          showArrow: false,
          child: child,
        ),
        target: _middle,
      );
      expect(chip.left, _middle.right + 4);
    });
  });

  group('flips where the side has no room', () {
    Future<Rect> flip(
      WidgetTester tester,
      PopoverSide side,
      Rect target, [
      TextDirection direction = TextDirection.ltr,
    ]) => _open(
      tester,
      (child) => Tip(
        message: 'Hint',
        side: side,
        gap: 8,
        showArrow: false,
        child: child,
      ),
      target: target,
      direction: direction,
    );

    testWidgets('bottom at the bottom edge opens above', (tester) async {
      final target = const Rect.fromLTWH(380, 570, 40, 30);
      expect((await flip(tester, PopoverSide.bottom, target)).bottom, 562);
    });

    testWidgets('top at the top edge opens below', (tester) async {
      final target = const Rect.fromLTWH(380, 0, 40, 30);
      expect((await flip(tester, PopoverSide.top, target)).top, 38);
    });

    testWidgets('start at the start edge opens at the end', (tester) async {
      final target = const Rect.fromLTWH(0, 280, 40, 40);
      expect((await flip(tester, PopoverSide.start, target)).left, 48);
    });

    testWidgets('right to left, start at the right edge opens at the left', (
      tester,
    ) async {
      final target = const Rect.fromLTWH(760, 280, 40, 40);
      final chip = await flip(
        tester,
        PopoverSide.start,
        target,
        TextDirection.rtl,
      );
      expect(chip.right, 752);
    });
  });

  group('the arrow', () {
    final tokens = AdminTokens.from(palette: irisPalette, overlay: _arrow);

    /// Whether the chip's painting has an arrow standing on [edge] at
    /// [along] (from the edge's top or left end), and none on the
    /// opposite edge.
    PaintPattern arrowAt(AxisDirection edge, double along, Size chip) {
      final out = _arrow.arrowHeight / 2;
      Offset point(AxisDirection on) => switch (on) {
        AxisDirection.up => Offset(along, -out),
        AxisDirection.down => Offset(along, chip.height + out),
        AxisDirection.left => Offset(-out, along),
        AxisDirection.right => Offset(chip.width + out, along),
      };
      return paints
        ..rrect()
        ..path(
          includes: [point(edge)],
          excludes: [point(flipAxisDirection(edge))],
        );
    }

    testWidgets('the theme’s tooltipArrow turns it on', (tester) async {
      Future<Decoration?> decorationOf(Tip tip, AdminTokens tokens) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _host((child) => tip, target: _middle, tokens: tokens),
        );
        return tester.widget<Tooltip>(find.byType(Tooltip)).decoration;
      }

      const tip = Tip(message: 'Hint', child: SizedBox.expand());
      expect(await decorationOf(tip, defaultTokens), isNull);
      expect(await decorationOf(tip, tokens), isNotNull);
      const plain = Tip(
        message: 'Hint',
        showArrow: false,
        child: SizedBox.expand(),
      );
      expect(await decorationOf(plain, tokens), isNull);
      const pointed = Tip(
        message: 'Hint',
        showArrow: true,
        child: SizedBox.expand(),
      );
      expect(await decorationOf(pointed, defaultTokens), isNotNull);
    });

    testWidgets('its tip keeps the gap, 4 by default', (tester) async {
      final chip = await _open(
        tester,
        (child) => Tip(message: 'Hint', child: child),
        target: _middle,
        tokens: tokens,
      );
      expect(chip.top, _middle.bottom + 4 + _arrow.arrowHeight);
      expect(
        tester.renderObject(_chip('Hint')),
        arrowAt(AxisDirection.up, chip.width / 2, chip.size),
      );
    });

    testWidgets('it follows a flip to the other edge', (tester) async {
      final target = const Rect.fromLTWH(380, 570, 40, 30);
      final chip = await _open(
        tester,
        (child) => Tip(message: 'Hint', child: child),
        target: target,
        tokens: tokens,
      );
      expect(chip.bottom, target.top - 4 - _arrow.arrowHeight);
      expect(
        tester.renderObject(_chip('Hint')),
        arrowAt(AxisDirection.down, chip.width / 2, chip.size),
      );
    });

    testWidgets('a later flip repaints it in that frame', (tester) async {
      Widget tip(Widget child) => Tip(message: 'Hint', child: child);
      await _open(tester, tip, target: _middle, tokens: tokens);
      final chip = tester.renderObject<RenderBox>(_chip('Hint'));
      expect(chip.debugNeedsPaint, isFalse);

      final target = const Rect.fromLTWH(380, 570, 40, 30);
      await tester.pumpWidget(
        _host(tip, target: target, tokens: tokens),
        phase: EnginePhase.layout,
      );
      expect(
        chip.debugNeedsPaint,
        isTrue,
        reason: 'same size, moved above: only the arrow changed',
      );
      await tester.pump();
      expect(chip, arrowAt(AxisDirection.down, chip.size.width / 2, chip.size));
    });

    testWidgets('it points at the target when the chip is shifted', (
      tester,
    ) async {
      const message = 'A hint long enough to be shifted';
      final target = const Rect.fromLTWH(740, 280, 24, 24);
      final chip = await _open(
        tester,
        (child) => Tip(message: message, child: child),
        target: target,
        tokens: tokens,
        message: message,
      );
      expect(chip.right, _view.width - 10, reason: 'kept 10 from the edge');
      final along = target.center.dx - chip.left;
      expect(along, greaterThan(chip.width / 2 + _arrow.arrowWidth));
      expect(
        tester.renderObject(_chip(message)),
        arrowAt(AxisDirection.up, along, chip.size),
      );
    });

    testWidgets('beside the target, right to left, it is on the chip’s '
        'right edge for the end side', (tester) async {
      final chip = await _open(
        tester,
        (child) => Tip(message: 'Hint', side: PopoverSide.end, child: child),
        target: _middle,
        direction: TextDirection.rtl,
        tokens: tokens,
      );
      expect(chip.right, _middle.left - 4 - _arrow.arrowHeight);
      expect(
        tester.renderObject(_chip('Hint')),
        arrowAt(AxisDirection.right, chip.height / 2, chip.size),
      );
    });
  });

  group('waitDuration', () {
    Future<void> hover(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(_middle.center);
    }

    testWidgets('its own delay', (tester) async {
      await tester.pumpWidget(
        _host(
          (child) => Tip(
            message: 'Hint',
            waitDuration: const Duration(milliseconds: 100),
            child: child,
          ),
          target: _middle,
        ),
      );
      await hover(tester);
      await tester.pump(const Duration(milliseconds: 90));
      expect(find.text('Hint'), findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Hint'), findsOneWidget);
    });

    testWidgets('the theme’s 400ms when null', (tester) async {
      await tester.pumpWidget(
        _host(
          (child) => Tip(message: 'Hint', child: child),
          target: _middle,
        ),
      );
      await hover(tester);
      await tester.pump(const Duration(milliseconds: 390));
      expect(find.text('Hint'), findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Hint'), findsOneWidget);
    });
  });

  group('shortcut', () {
    testWidgets('shown after the message, muted, read left to right', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await _open(
          tester,
          (child) => Tip(message: 'Save', shortcut: '⌘S', child: child),
          target: _middle,
          direction: direction,
          message: 'Save',
        );
        final keys = tester.widget<Text>(find.text('⌘S'));
        expect(keys.textDirection, TextDirection.ltr);
        final message = tester.getRect(
          find.textContaining('Save', findRichText: true).first,
        );
        final hint = tester.getRect(find.text('⌘S'));
        if (direction == TextDirection.ltr) {
          expect(hint.right, message.right, reason: 'at the end');
        } else {
          expect(hint.left, message.left, reason: 'at the end, on the left');
        }

        final text = defaultTokens.palette.surface;
        final fill = defaultTokens.palette.foreground;
        final muted = keys.style!.color!;
        expect(muted, isNot(text));
        expect(
          defaultTokens.palette.readableOn(muted, surfaces: [fill]),
          muted,
          reason: 'readable on the chip',
        );
      }
    });

    testWidgets('announced once, after the message', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          (child) => Tip(message: 'Save', shortcut: '⌘S', child: child),
          target: _middle,
        ),
      );
      final carrying = find.semantics.byPredicate(
        (node) => [
          node.label,
          node.tooltip,
          node.value,
          node.hint,
        ].any((text) => text.contains('⌘S')),
      );
      expect(carrying, findsOne);
      expect(
        find.semantics.byPredicate((node) => node.tooltip == 'Save ⌘S'),
        findsOne,
      );
      semantics.dispose();
    });

    testWidgets('left out with the message by excludeFromSemantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          (child) => Tip(
            message: 'Save',
            shortcut: '⌘S',
            excludeFromSemantics: true,
            child: child,
          ),
          target: _middle,
        ),
      );
      expect(
        find.semantics.byPredicate((node) => node.tooltip.contains('Save')),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('keyboard focus opens it', (tester) async {
      await tester.pumpWidget(
        _host(
          (child) => Tip(
            message: 'Save',
            shortcut: '⌘S',
            child: Focus(child: child),
          ),
          target: _middle,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('⌘S'), findsOneWidget);
    });
  });
}
