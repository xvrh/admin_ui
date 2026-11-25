import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// How a popover arrives and leaves: the theme's
// AdminOverlayStyle.popoverMotion, which Popover plays on its content, and so
// on every menu, select, picker and hover card.

/// Each shipped theme's popover motion, from its reference. Null is a
/// popover that is there, and gone, at once.
const _expected = <String, AdminOverlayMotion?>{
  // the kit's own
  'Iris': null,
  // Flutter's M3 menu unfolds its height and fades its items in turn, which
  // this motion does not draw
  'Material': null,
  // PopoverContent, DropdownMenuContent, SelectContent, HoverCardContent:
  // fade-in-0 zoom-in-95 slide-in-from-*-2 over tw-animate's 150ms on ease
  'shadcn': AdminOverlayMotion(
    scale: 0.95,
    slide: 8,
    speed: MotionSpeed.fast,
    curve: Curves.ease,
    reverseCurve: Curves.ease,
  ),
  // antSlideUpIn from scaleY(0.8) over motionDurationMid, on
  // motionEaseOutQuint and out on motionEaseInQuint
  'Ant': AdminOverlayMotion(
    stretch: 0.8,
    curve: Cubic(0.23, 1, 0.32, 1),
    reverseCurve: Cubic(0.755, 0.05, 0.855, 0.06),
  ),
  // PopoverSurfaceMotion, MenuSurfaceMotion: a fade and a 10px slide over
  // durationSlower on curveDecelerateMid, and no exit
  'Fluent': AdminOverlayMotion(
    slide: 10,
    duration: Duration(milliseconds: 400),
    leaves: false,
  ),
  // menus, popovers and list boxes are shown and hidden with no transition
  'Carbon': null,
};

/// How long each theme's popover takes to arrive, in milliseconds.
const _milliseconds = <String, int?>{
  'Iris': null,
  'Material': null,
  'shadcn': 150,
  'Ant': 200,
  'Fluent': 400,
  'Carbon': null,
};

const _panel = Key('panel');
const _size = Size(200, 120);

/// A motion that does everything, for the geometry: half scale, half
/// height, 20 off its place, over a round 200ms on linear curves.
const _all = AdminOverlayMotion(
  scale: 0.5,
  stretch: 0.5,
  slide: 20,
  duration: Duration(milliseconds: 200),
  curve: Curves.linear,
  reverseCurve: Curves.linear,
);

AdminTokens _with(AdminOverlayMotion? motion) => AdminTokens.from(
  palette: irisPalette,
  overlay: AdminOverlayStyle(popoverMotion: motion),
);

Widget _app(
  AdminTokens tokens,
  Widget body, {
  bool reduced = false,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: _kitLanguages.locales,
  localizationsDelegates: _kitLanguages.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: Scaffold(body: body),
);

/// A popover on a button, its content a plain box of [_size].
Widget _popover({
  AlignmentGeometry alignment = Alignment.center,
  PopoverSide side = PopoverSide.bottom,
  PopoverAlign align = PopoverAlign.start,
  bool showArrow = false,
  ValueChanged<bool>? onOpenChanged,
  void Function(PopoverController)? onController,
  Widget? content,
}) => Align(
  alignment: alignment,
  child: Popover(
    side: side,
    align: align,
    showArrow: showArrow,
    onOpenChanged: onOpenChanged,
    anchor: (context, c) {
      onController?.call(c);
      return TextButton(onPressed: c.toggle, child: const Text('Open'));
    },
    content: (context, c) => Material(
      key: _panel,
      child: SizedBox.fromSize(size: _size, child: content),
    ),
  ),
);

Future<void> _toggle(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pump();
}

Rect _rect(WidgetTester tester) => tester.getRect(find.byKey(_panel));

/// The opacity the popover fades its content at.
double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_panel),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

Duration _durationOf(AdminTokens tokens) =>
    tokens.overlay.popoverMotion?.durationIn(tokens.motion) ?? Duration.zero;

/// Where a popover below its anchor, lined up at the start in left-to-right
/// text, is drawn [t] of the way into place: out of its top left corner.
Rect _below(Rect rest, AdminOverlayMotion motion, double t) {
  final scale = motion.scale + (1 - motion.scale) * t;
  final stretch = motion.stretch + (1 - motion.stretch) * t;
  return Rect.fromLTWH(
    rest.left,
    rest.top - motion.slide * (1 - t),
    rest.width * scale,
    rest.height * scale * stretch,
  );
}

Matcher _near(Rect rect) => within<Rect>(
  distance: 0.01,
  from: rect,
  distanceFunction: (a, b) => [
    (a.left - b.left).abs(),
    (a.top - b.top).abs(),
    (a.right - b.right).abs(),
    (a.bottom - b.bottom).abs(),
  ].reduce((x, y) => x > y ? x : y),
);

void main() {
  group('AdminOverlayMotion', () {
    test('by default does not stretch, takes a named duration and leaves', () {
      const motion = AdminOverlayMotion();
      expect(motion.stretch, 1);
      expect(motion.duration, isNull);
      expect(motion.leaves, isTrue);
      expect(const AdminOverlayMotion(stretch: 0.8).moves, isTrue);
      expect(const AdminOverlayMotion(leaves: false).moves, isFalse);
      expect(
        const AdminOverlayMotion(duration: Duration(seconds: 1)).moves,
        isFalse,
      );
    });

    test('a stretch outside (0, 1] is refused', () {
      expect(() => AdminOverlayMotion(stretch: 0), throwsAssertionError);
      expect(() => AdminOverlayMotion(stretch: 1.2), throwsAssertionError);
    });

    test('takes its own duration, or the one its speed names', () {
      const motion = AdminMotion();
      expect(const AdminOverlayMotion().durationIn(motion), motion.medium);
      expect(
        const AdminOverlayMotion(speed: MotionSpeed.fast).durationIn(motion),
        motion.fast,
      );
      const own = AdminOverlayMotion(
        speed: MotionSpeed.fast,
        duration: Duration(milliseconds: 400),
      );
      expect(own.durationIn(motion), const Duration(milliseconds: 400));
      // The three are zeroed under reduced motion; an authored one is the
      // caller's to zero.
      expect(
        const AdminOverlayMotion().durationIn(motion.reduced),
        Duration.zero,
      );
      expect(own.durationIn(motion.reduced), const Duration(milliseconds: 400));
    });

    test('copyWith, lerp, == and toString carry the new members', () {
      const plain = AdminOverlayMotion();
      final ant = _expected['Ant']!;
      final fluent = _expected['Fluent']!;
      expect(
        plain.copyWith(
          stretch: 0.8,
          curve: const Cubic(0.23, 1, 0.32, 1),
          reverseCurve: const Cubic(0.755, 0.05, 0.855, 0.06),
        ),
        ant,
      );
      expect(
        plain.copyWith(
          slide: 10,
          duration: const Duration(milliseconds: 400),
          leaves: false,
        ),
        fluent,
      );
      expect(fluent.copyWith(slide: 12).duration, fluent.duration);
      expect(fluent.copyWith(slide: 12).leaves, isFalse);
      for (final one in [
        plain.copyWith(stretch: 0.9),
        plain.copyWith(duration: const Duration(milliseconds: 180)),
        plain.copyWith(leaves: false),
      ]) {
        expect(one, isNot(plain));
        expect(one.hashCode, isNot(plain.hashCode));
      }

      final mid = AdminOverlayMotion.lerp(ant, fluent, 0.5);
      expect(mid.stretch, closeTo(0.9, 1e-9));
      expect(mid.slide, 5);
      // The duration and whether it leaves are the nearer side's.
      expect(mid.duration, fluent.duration);
      expect(mid.leaves, isFalse);
      final near = AdminOverlayMotion.lerp(ant, fluent, 0.4);
      expect(near.duration, isNull);
      expect(near.leaves, isTrue);

      expect('$ant', contains('unfolding from 0.8'));
      expect('$fluent', allOf(contains('400ms'), contains('gone at once')));
    });
  });

  group('AdminOverlayStyle', () {
    test('carries the popover motion, and none by default', () {
      const style = AdminOverlayStyle();
      final ant = _expected['Ant']!;
      final fluent = _expected['Fluent']!;
      expect(style.popoverMotion, isNull);
      final moved = style.copyWith(popoverMotion: ant);
      expect(moved.popoverMotion, ant);
      expect(moved, isNot(style));
      expect(moved.hashCode, isNot(style.hashCode));
      expect(moved.copyWith(tooltipRadius: 4).popoverMotion, ant);
      expect('$style', contains('popovers at once'));
      expect('$moved', contains('popovers AdminOverlayMotion('));

      // Interpolated where both sides move; the nearer side's otherwise.
      final other = style.copyWith(popoverMotion: fluent);
      expect(AdminOverlayStyle.lerp(moved, other, 0.5).popoverMotion!.slide, 5);
      expect(AdminOverlayStyle.lerp(style, moved, 0.4).popoverMotion, isNull);
      expect(AdminOverlayStyle.lerp(style, moved, 0.6).popoverMotion, ant);

      final tokens = AdminTokens.from(palette: irisPalette, overlay: moved);
      expect(tokens.overlay.popoverMotion, ant);
      expect(
        tokens.branded(const Color(0xFF0D9488)).overlay.popoverMotion,
        ant,
      );
    });
  });

  group('each shipped theme', () {
    test('has an expectation', () {
      expect(_expected.keys.toSet(), {for (final t in adminThemes) t.name});
      expect(_milliseconds.keys.toSet(), _expected.keys.toSet());
    });

    for (final theme in adminThemes) {
      test('${theme.name} takes its reference popover motion', () {
        for (final tokens in [theme.tokens, theme.dark!]) {
          final motion = tokens.overlay.popoverMotion;
          expect(motion, _expected[theme.name]);
          expect(
            motion?.durationIn(tokens.motion).inMilliseconds,
            _milliseconds[theme.name],
          );
        }
      });
    }
  });

  group('a Popover', () {
    for (final theme in adminThemes) {
      final tokens = theme.tokens;
      final motion = tokens.overlay.popoverMotion;
      final duration = _durationOf(tokens);
      final enter = motion?.curve ?? tokens.motion.enter;
      final exit = motion?.reverseCurve ?? tokens.motion.exit;

      testWidgets('${theme.name}: it arrives as the theme says', (
        tester,
      ) async {
        await tester.pumpWidget(_app(tokens, _popover()));
        await _toggle(tester);
        final first = _rect(tester);
        final firstOpacity = _opacity(tester);
        await tester.pump(duration ~/ 2);
        final mid = _rect(tester);
        final midOpacity = _opacity(tester);
        await tester.pumpAndSettle();
        final rest = _rect(tester);
        expect(rest.size, _size);
        expect(_opacity(tester), 1);

        if (motion == null) {
          // There at once: in place and opaque in its first frame.
          expect(first, rest);
          expect(firstOpacity, 1);
          expect(mid, rest);
          return;
        }
        expect(firstOpacity, 0);
        expect(first, _near(_below(rest, motion, 0)));
        final t = enter.transform(0.5);
        expect(midOpacity, closeTo(t, 0.001));
        expect(mid, _near(_below(rest, motion, t)));
      });

      testWidgets('${theme.name}: it leaves as the theme says', (tester) async {
        final log = <bool>[];
        late PopoverController controller;
        await tester.pumpWidget(
          _app(
            tokens,
            _popover(
              onOpenChanged: log.add,
              onController: (c) => controller = c,
            ),
          ),
        );
        await _toggle(tester);
        await tester.pumpAndSettle();
        final rest = _rect(tester);

        await _toggle(tester);
        // Closed at once, whatever is still on screen.
        expect(controller.isOpen, isFalse);
        expect(log, [true, false]);
        if (motion == null || !motion.leaves) {
          expect(find.byKey(_panel), findsNothing);
          return;
        }
        expect(_rect(tester), rest);
        await tester.pump(duration ~/ 2);
        // On the exit curve as time runs: see exit_curve_test.dart.
        final t = 1 - exit.transform(0.5);
        expect(_opacity(tester), closeTo(t, 0.001));
        expect(_rect(tester), _near(_below(rest, motion, t)));

        await tester.pump(duration);
        await tester.pump();
        expect(find.byKey(_panel), findsNothing);
        expect(log, [true, false]);
      });

      testWidgets('${theme.name}: under reduced motion it is there, and gone, '
          'at once', (tester) async {
        await tester.pumpWidget(_app(tokens, _popover(), reduced: true));
        await _toggle(tester);
        expect(_rect(tester).size, _size);
        expect(_opacity(tester), 1);
        final rest = _rect(tester);
        await tester.pump(const Duration(seconds: 1));
        expect(_rect(tester), rest);

        await _toggle(tester);
        expect(find.byKey(_panel), findsNothing);
      });
    }

    group('moves from its anchor', () {
      Future<(Rect first, Rect rest)> open(
        WidgetTester tester,
        Widget popover, {
        TextDirection direction = TextDirection.ltr,
      }) async {
        await tester.pumpWidget(
          _app(_with(_all), popover, direction: direction),
        );
        await _toggle(tester);
        final first = _rect(tester);
        await tester.pumpAndSettle();
        return (first, _rect(tester));
      }

      testWidgets('below: out of its top, from above', (tester) async {
        final (first, rest) = await open(tester, _popover());
        expect(first, _near(_below(rest, _all, 0)));
        expect(first.top, rest.top - 20);
        expect(first.left, rest.left);
        expect(first.width, rest.width / 2);
        // Half the scale, and half the height again.
        expect(first.height, rest.height / 4);
      });

      testWidgets('flipped above: out of its bottom, from below', (
        tester,
      ) async {
        final (first, rest) = await open(
          tester,
          _popover(alignment: Alignment.bottomCenter),
        );
        final anchor = tester.getRect(find.text('Open'));
        expect(rest.bottom, lessThan(anchor.top), reason: 'it flipped');
        expect(first.bottom, rest.bottom + 20);
        expect(first.left, rest.left);
        expect(first.height, rest.height / 4);
      });

      testWidgets('lined up at the end: out of that corner', (tester) async {
        final (first, rest) = await open(
          tester,
          _popover(align: PopoverAlign.end),
        );
        expect(first.right, rest.right);
        expect(first.top, rest.top - 20);
      });

      testWidgets('centred: out of the middle of its edge', (tester) async {
        final (first, rest) = await open(
          tester,
          _popover(align: PopoverAlign.center),
        );
        expect(first.center.dx, closeTo(rest.center.dx, 0.01));
        expect(first.top, rest.top - 20);
      });

      testWidgets('right-to-left: the start is its right', (tester) async {
        final (first, rest) = await open(
          tester,
          _popover(),
          direction: TextDirection.rtl,
        );
        expect(first.right, rest.right);
        expect(first.width, rest.width / 2);
      });

      testWidgets('beside, at the end: out of its near edge, from the anchor', (
        tester,
      ) async {
        final (first, rest) = await open(
          tester,
          _popover(side: PopoverSide.end),
        );
        expect(first.left, rest.left - 20);
        // Lined up by its top, and unfolding from it.
        expect(first.top, rest.top);
        expect(first.width, rest.width / 2);
      });

      testWidgets('beside, right-to-left: mirrored', (tester) async {
        final (first, rest) = await open(
          tester,
          _popover(side: PopoverSide.end),
          direction: TextDirection.rtl,
        );
        final anchor = tester.getRect(find.text('Open'));
        expect(rest.right, lessThan(anchor.left), reason: 'the end is left');
        expect(first.right, rest.right + 20);
        expect(first.top, rest.top);
      });

      testWidgets('with an arrow: out of the point the arrow stands at', (
        tester,
      ) async {
        ValueListenable<PopoverPlacement>? placement;
        final (first, rest) = await open(
          tester,
          _popover(
            align: PopoverAlign.center,
            showArrow: true,
            content: Builder(
              builder: (context) {
                placement = Popover.placementOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        );
        final arrow = placement!.value.arrowOffset!;
        final at = rest.left + arrow;
        // That point does not move as the box grows around it.
        expect(first.left, closeTo(at - arrow / 2, 0.01));
        expect(first.right, closeTo(at + (rest.width - arrow) / 2, 0.01));
      });
    });

    group('that is leaving', () {
      testWidgets('takes no pointer, and lets it through', (tester) async {
        var inside = 0;
        var under = 0;
        await tester.pumpWidget(
          _app(
            _with(_all),
            Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => under++,
                  ),
                ),
                _popover(
                  content: TextButton(
                    onPressed: () => inside++,
                    child: const Text('Inside'),
                  ),
                ),
              ],
            ),
          ),
        );
        await _toggle(tester);
        await tester.pumpAndSettle();
        final at = _rect(tester).center;
        await tester.tapAt(at);
        await tester.pump();
        expect(inside, 1);
        expect(under, 0);

        await _toggle(tester);
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.text('Inside'), findsOneWidget);
        await tester.tapAt(at);
        await tester.pump();
        expect(inside, 1, reason: 'the button on its way out is not pressed');
        expect(under, 1, reason: 'the page under it is');
        await tester.pumpAndSettle();
      });

      testWidgets('holds no focus and is left out of semantics', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final field = FocusNode();
        addTearDown(field.dispose);
        await tester.pumpWidget(
          _app(
            _with(_all),
            _popover(
              content: Semantics(
                label: 'Reply box',
                child: TextField(focusNode: field),
              ),
            ),
          ),
        );
        await _toggle(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pump();
        expect(field.hasFocus, isTrue);
        expect(find.semantics.byLabel('Reply box'), findsOne);

        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.byType(TextField), findsOneWidget);
        expect(field.hasFocus, isFalse);
        expect(find.semantics.byLabel('Reply box'), findsNothing);
        await tester.pumpAndSettle();
        handle.dispose();
      });

      testWidgets('is not brought back or cut short by Escape', (tester) async {
        late PopoverController controller;
        await tester.pumpWidget(
          _app(_with(_all), _popover(onController: (c) => controller = c)),
        );
        await _toggle(tester);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(controller.isOpen, isFalse);
        await tester.pump(const Duration(milliseconds: 100));
        expect(_opacity(tester), closeTo(0.5, 0.001));

        // Focus is back on the trigger, whose menu anchor still counts the
        // popover open and takes the key.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(controller.isOpen, isFalse);
        expect(_opacity(tester), closeTo(0.5, 0.001));
        await tester.pump(const Duration(milliseconds: 101));
        await tester.pump();
        expect(find.byKey(_panel), findsNothing);
      });

      testWidgets('opened again, it comes back from where it had got to, with '
          'its state', (tester) async {
        final log = <bool>[];
        late PopoverController controller;
        await tester.pumpWidget(
          _app(
            _with(_all),
            _popover(
              onOpenChanged: log.add,
              onController: (c) => controller = c,
              content: const TextField(),
            ),
          ),
        );
        await _toggle(tester);
        await tester.pumpAndSettle();
        final rest = _rect(tester);
        await tester.enterText(find.byType(TextField), 'draft');

        controller.close();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(_opacity(tester), closeTo(0.5, 0.001));

        controller.open();
        await tester.pump();
        expect(controller.isOpen, isTrue);
        expect(log, [true, false, true]);
        // No jump back to the start: it goes on from half way.
        expect(_opacity(tester), closeTo(0.5, 0.001));
        await tester.pump(const Duration(milliseconds: 50));
        expect(_opacity(tester), closeTo(0.75, 0.001));
        await tester.pumpAndSettle();
        expect(_rect(tester), rest);
        expect(find.text('draft'), findsOneWidget);
        // And it takes the pointer again.
        await tester.enterText(find.byType(TextField), 'sent');
        expect(find.text('sent'), findsOneWidget);
      });

      testWidgets('asked to close twice, it leaves once', (tester) async {
        final log = <bool>[];
        late PopoverController controller;
        await tester.pumpWidget(
          _app(
            _with(_all),
            _popover(
              onOpenChanged: log.add,
              onController: (c) => controller = c,
            ),
          ),
        );
        await _toggle(tester);
        await tester.pumpAndSettle();
        controller.close();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        controller.close();
        await tester.pump();
        // Still half way, not started over or cut short.
        expect(_opacity(tester), closeTo(0.5, 0.001));
        await tester.pump(const Duration(milliseconds: 99));
        expect(find.byKey(_panel), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 2));
        await tester.pump();
        expect(find.byKey(_panel), findsNothing);
        expect(log, [true, false]);
      });

      testWidgets('closed in the frame it opened, it is gone', (tester) async {
        late PopoverController controller;
        await tester.pumpWidget(
          _app(_with(_all), _popover(onController: (c) => controller = c)),
        );
        controller.open();
        await tester.pump();
        controller.close();
        await tester.pump();
        await tester.pump();
        expect(find.byKey(_panel), findsNothing);
        expect(controller.isOpen, isFalse);
      });

      testWidgets('torn down, it throws nothing', (tester) async {
        await tester.pumpWidget(_app(_with(_all), _popover()));
        await _toggle(tester);
        await tester.pumpAndSettle();
        await _toggle(tester);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('with motion reduced under it, it is gone', (tester) async {
        await tester.pumpWidget(_app(_with(_all), _popover()));
        await _toggle(tester);
        await tester.pumpAndSettle();
        await _toggle(tester);
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(_panel), findsOneWidget);

        await tester.pumpWidget(_app(_with(_all), _popover(), reduced: true));
        await tester.pump();
        expect(find.byKey(_panel), findsNothing);
      });
    });

    testWidgets('a motion that does not leave is gone at once', (tester) async {
      final motion = _all.copyWith(leaves: false);
      await tester.pumpWidget(_app(_with(motion), _popover()));
      await _toggle(tester);
      expect(_opacity(tester), 0);
      await tester.pumpAndSettle();
      await _toggle(tester);
      expect(find.byKey(_panel), findsNothing);
    });

    testWidgets('a theme change under an open popover keeps its state', (
      tester,
    ) async {
      Widget host(AdminTokens tokens) =>
          _app(tokens, _popover(content: const TextField()));
      await tester.pumpWidget(host(_with(null)));
      await _toggle(tester);
      await tester.enterText(find.byType(TextField), 'draft');
      final rest = _rect(tester);

      await tester.pumpWidget(host(_with(_all)));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsOneWidget);
      // Already in place: a motion it gets while open does not replay.
      expect(_rect(tester), rest);
      expect(_opacity(tester), 1);

      // It leaves by the motion it has now.
      await _toggle(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacity(tester), closeTo(0.5, 0.001));
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);
    });

    testWidgets('takes taps where it is drawn while it arrives', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(
        _app(
          _with(const AdminOverlayMotion(slide: 40, curve: Curves.linear)),
          _popover(
            content: Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: () => pressed++,
                child: const Text('Inside'),
              ),
            ),
          ),
        ),
      );
      await _toggle(tester);
      // 40 above its place, in its first frame.
      final first = tester.getRect(find.text('Inside'));
      await tester.tapAt(first.center);
      expect(pressed, 1);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Inside')).top, first.top + 40);
    });
  });
}
