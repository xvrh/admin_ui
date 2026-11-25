import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// How a modal arrives and leaves: the theme's AdminOverlayStyle.modalMotion,
// which showModal plays on the scrim and the card.

/// Each shipped theme's dialog motion, from its reference.
const _expected = {
  // the kit's own: a fade over the medium duration
  'Iris': AdminOverlayMotion(),
  // Flutter's M3 dialog fades
  'Material': AdminOverlayMotion(),
  // DialogContent: fade-in-0 zoom-in-95 over duration-200, on tw-animate's
  // default easing, CSS ease
  'shadcn': AdminOverlayMotion(
    scale: 0.95,
    curve: Curves.ease,
    reverseCurve: Curves.ease,
  ),
  // antZoomIn from scale(0.2) over motionDurationMid, on motionEaseOutCirc
  // and out on motionEaseInOutCirc
  'Ant': AdminOverlayMotion(
    scale: 0.2,
    curve: Cubic(0.08, 0.82, 0.17, 1),
    reverseCurve: Cubic(0.78, 0.14, 0.15, 0.86),
  ),
  // DialogSurfaceMotion: Scale from 0.85 over durationGentle, on
  // curveDecelerateMid and out on curveAccelerateMin
  'Fluent': AdminOverlayMotion(
    scale: 0.85,
    speed: MotionSpeed.slow,
    reverseCurve: Cubic(0.8, 0, 0.78, 1),
  ),
  // the container's translate3d(0, -24px, 0) over $duration-moderate-02, on
  // the expressive entrance and exit curves
  'Carbon': AdminOverlayMotion(
    slide: 24,
    speed: MotionSpeed.slow,
    curve: Cubic(0, 0, 0.3, 1),
    reverseCurve: Cubic(0.4, 0.14, 1, 1),
  ),
};

/// How long each theme's modal takes, in milliseconds: the duration its
/// reference gives, which the theme's motion already names.
const _milliseconds = {
  'Iris': 180,
  'Material': 200,
  'shadcn': 200,
  'Ant': 200,
  'Fluent': 250,
  'Carbon': 240,
};

Widget _host(AdminTokens tokens, {bool reduced = false}) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: _kitLanguages.locales,
  localizationsDelegates: _kitLanguages.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showModal<void>(
            context,
            builder: (context) => Modal(
              title: 'Delete page?',
              message: 'It cannot be restored.',
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

/// Taps the trigger and builds the route's first frame, where the modal has
/// not moved yet.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pump();
}

Rect _card(WidgetTester tester) => tester.getRect(find.byType(Modal));

/// The opacity the modal's route fades its page at.
double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(Modal),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  group('AdminOverlayMotion', () {
    test('by default only fades, over the medium duration', () {
      const motion = AdminOverlayMotion();
      expect(motion.scale, 1);
      expect(motion.slide, 0);
      expect(motion.speed, MotionSpeed.medium);
      expect(motion.curve, isNull);
      expect(motion.reverseCurve, isNull);
      expect(motion.moves, isFalse);
      expect(const AdminOverlayMotion(scale: 0.95).moves, isTrue);
      expect(const AdminOverlayMotion(slide: 24).moves, isTrue);
      expect(const AdminOverlayMotion(speed: MotionSpeed.slow).moves, isFalse);
    });

    test('a scale outside (0, 1] or a negative slide is refused', () {
      expect(() => AdminOverlayMotion(scale: 0), throwsAssertionError);
      expect(() => AdminOverlayMotion(scale: 1.1), throwsAssertionError);
      expect(() => AdminOverlayMotion(slide: -1), throwsAssertionError);
    });

    test('copyWith, lerp, == and toString', () {
      const plain = AdminOverlayMotion();
      final carbon = _expected['Carbon']!;
      final shadcn = _expected['shadcn']!;
      expect(plain.copyWith(), plain);
      expect(plain.copyWith().hashCode, plain.hashCode);
      expect(
        plain.copyWith(
          scale: 0.95,
          curve: Curves.ease,
          reverseCurve: Curves.ease,
        ),
        shadcn,
      );
      expect(
        plain.copyWith(
          slide: 24,
          speed: MotionSpeed.slow,
          curve: const Cubic(0, 0, 0.3, 1),
          reverseCurve: const Cubic(0.4, 0.14, 1, 1),
        ),
        carbon,
      );
      expect(carbon.copyWith(slide: 12).curve, carbon.curve);
      for (final one in [
        plain.copyWith(scale: 0.9),
        plain.copyWith(slide: 8),
        plain.copyWith(speed: MotionSpeed.fast),
        plain.copyWith(curve: Curves.easeOut),
        plain.copyWith(reverseCurve: Curves.easeIn),
      ]) {
        expect(one, isNot(plain));
        expect(one.hashCode, isNot(plain.hashCode));
      }

      expect(AdminOverlayMotion.lerp(plain, carbon, 0), plain);
      expect(AdminOverlayMotion.lerp(plain, carbon, 1), carbon);
      final mid = AdminOverlayMotion.lerp(shadcn, carbon, 0.5);
      expect(mid.scale, closeTo(0.975, 1e-9));
      expect(mid.slide, 12);
      // The speed and the curves are the nearer side's.
      expect(mid.speed, MotionSpeed.slow);
      expect(mid.curve, carbon.curve);
      final near = AdminOverlayMotion.lerp(shadcn, carbon, 0.4);
      expect(near.speed, MotionSpeed.medium);
      expect(near.curve, shadcn.curve);

      expect('$plain', 'AdminOverlayMotion(a fade, medium)');
      expect('$shadcn', contains('from scale 0.95'));
      expect(
        '$carbon',
        allOf(contains('sliding 24.0'), contains('slow'), contains('curves')),
      );
    });
  });

  group('AdminMotion', () {
    test('gives a speed its duration, and none under reduced motion', () {
      const motion = AdminMotion();
      expect(motion.durationOf(MotionSpeed.fast), motion.fast);
      expect(motion.durationOf(MotionSpeed.medium), motion.medium);
      expect(motion.durationOf(MotionSpeed.slow), motion.slow);
      for (final speed in MotionSpeed.values) {
        expect(motion.reduced.durationOf(speed), Duration.zero);
      }
    });
  });

  group('AdminOverlayStyle', () {
    test('carries the modal motion', () {
      const style = AdminOverlayStyle();
      final carbon = _expected['Carbon']!;
      expect(style.modalMotion, const AdminOverlayMotion());
      final moved = style.copyWith(modalMotion: carbon);
      expect(moved.modalMotion, carbon);
      expect(moved, isNot(style));
      expect(moved.hashCode, isNot(style.hashCode));
      expect(moved.copyWith(tooltipRadius: 4).modalMotion, carbon);
      expect(AdminOverlayStyle.lerp(style, moved, 0.5).modalMotion.slide, 12);
      expect('$moved', contains('modals AdminOverlayMotion('));

      final tokens = AdminTokens.from(palette: irisPalette, overlay: moved);
      expect(tokens.overlay.modalMotion, carbon);
      expect(
        tokens.branded(const Color(0xFF0D9488)).overlay.modalMotion,
        carbon,
      );
    });
  });

  group('each shipped theme', () {
    test('has an expectation', () {
      expect(_expected.keys.toSet(), {for (final t in adminThemes) t.name});
      expect(_milliseconds.keys.toSet(), _expected.keys.toSet());
    });

    for (final theme in adminThemes) {
      test('${theme.name} takes its reference dialog motion', () {
        for (final tokens in [theme.tokens, theme.dark!]) {
          final motion = tokens.overlay.modalMotion;
          expect(motion, _expected[theme.name]);
          expect(
            tokens.motion.durationOf(motion.speed).inMilliseconds,
            _milliseconds[theme.name],
          );
        }
      });
    }
  });

  group('showModal', () {
    for (final theme in adminThemes) {
      testWidgets('${theme.name}: the card arrives as the theme says', (
        tester,
      ) async {
        final tokens = theme.tokens;
        final motion = tokens.overlay.modalMotion;
        final duration = tokens.motion.durationOf(motion.speed);
        await tester.pumpWidget(_host(tokens));
        await _open(tester);

        // The first frame: transparent, at its starting scale and place.
        final start = _card(tester);
        expect(_opacity(tester), 0);

        await tester.pump(duration);
        await tester.pump();
        final rest = _card(tester);
        expect(_opacity(tester), 1);
        expect(tester.takeException(), isNull);

        // Grown from the scale about its centre, and slid down from above.
        expect(start.width, closeTo(rest.width * motion.scale, 0.01));
        expect(start.height, closeTo(rest.height * motion.scale, 0.01));
        expect(start.center.dx, closeTo(rest.center.dx, 0.01));
        expect(start.center.dy, closeTo(rest.center.dy - motion.slide, 0.01));
        if (!motion.moves) expect(start, rest);

        // Part of the way there, it is between the two.
        await tester.pumpWidget(_host(tokens));
        await tester.tap(find.byType(IconAction));
        await tester.pumpAndSettle();
        await _open(tester);
        await tester.pump(duration ~/ 2);
        final mid = _card(tester);
        expect(_opacity(tester), inExclusiveRange(0, 1));
        if (motion.scale < 1) {
          expect(mid.width, inExclusiveRange(start.width, rest.width));
        }
        if (motion.slide > 0) {
          expect(mid.top, inExclusiveRange(start.top, rest.top));
        }
        await tester.pumpAndSettle();
        expect(_card(tester), rest);
      });

      testWidgets('${theme.name}: it leaves the way it came', (tester) async {
        final tokens = theme.tokens;
        final motion = tokens.overlay.modalMotion;
        final duration = tokens.motion.durationOf(motion.speed);
        await tester.pumpWidget(_host(tokens));
        await _open(tester);
        await tester.pumpAndSettle();
        final rest = _card(tester);

        await tester.tap(find.byType(IconAction));
        await tester.pump();
        await tester.pump(duration ~/ 2);
        // Still there, fading, and on its way back to where it started.
        expect(find.byType(Modal), findsOneWidget);
        expect(_opacity(tester), inExclusiveRange(0, 1));
        final leaving = _card(tester);
        if (motion.scale < 1) expect(leaving.width, lessThan(rest.width));
        if (motion.slide > 0) expect(leaving.top, lessThan(rest.top));
        if (!motion.moves) expect(leaving, rest);

        await tester.pump(duration);
        await tester.pump();
        expect(find.byType(Modal), findsNothing);
      });

      testWidgets('${theme.name}: under reduced motion it is there at once', (
        tester,
      ) async {
        await tester.pumpWidget(_host(theme.tokens, reduced: true));
        await _open(tester);
        await tester.pump();
        final first = _card(tester);
        expect(_opacity(tester), 1);
        await tester.pumpAndSettle();
        expect(_card(tester), first);

        await tester.tap(find.byType(IconAction));
        await tester.pump();
        await tester.pump();
        expect(find.byType(Modal), findsNothing);
      });
    }

    testWidgets('the card takes taps where it is drawn while it arrives', (
      tester,
    ) async {
      // Carbon's card starts 24 above its place.
      final tokens = carbonTheme.tokens;
      await tester.pumpWidget(_host(tokens));
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 60));
      // The close button is hit where it shows, part of the way down.
      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.byType(Modal), findsNothing);
    });

    testWidgets('a theme change while it is open keeps it in place', (
      tester,
    ) async {
      await tester.pumpWidget(_host(shadcnTheme.tokens));
      await _open(tester);
      await tester.pumpAndSettle();
      final rest = _card(tester);
      await tester.pumpWidget(_host(carbonTheme.tokens));
      await tester.pumpAndSettle();
      expect(find.byType(Modal), findsOneWidget);
      expect(_card(tester).center, rest.center);
      expect(tester.takeException(), isNull);
    });
  });

  group('a motion\'s stretch, duration and leaves, on a modal', () {
    Future<void> open(WidgetTester tester, AdminOverlayMotion motion) async {
      await tester.pumpWidget(
        _host(
          AdminTokens.from(
            palette: irisPalette,
            overlay: AdminOverlayStyle(modalMotion: motion),
          ),
        ),
      );
      await _open(tester);
    }

    testWidgets('unfolds from its top by the motion\'s stretch', (
      tester,
    ) async {
      await open(
        tester,
        const AdminOverlayMotion(stretch: 0.5, curve: Curves.linear),
      );
      final first = _card(tester);
      await tester.pumpAndSettle();
      final rest = _card(tester);
      expect(first.top, rest.top);
      expect(first.width, rest.width);
      expect(first.height, closeTo(rest.height / 2, 0.01));
    });

    testWidgets('takes the motion\'s own duration', (tester) async {
      await open(
        tester,
        const AdminOverlayMotion(
          scale: 0.5,
          duration: Duration(milliseconds: 400),
          curve: Curves.linear,
        ),
      );
      final first = _card(tester);
      await tester.pump(const Duration(milliseconds: 200));
      final mid = _card(tester);
      await tester.pumpAndSettle();
      final rest = _card(tester);
      expect(first.width, closeTo(rest.width / 2, 0.01));
      expect(mid.width, closeTo(rest.width * 0.75, 0.01));
    });

    testWidgets('plays its arrival back whatever the motion\'s leaves says', (
      tester,
    ) async {
      await open(
        tester,
        const AdminOverlayMotion(
          scale: 0.5,
          duration: Duration(milliseconds: 200),
          curve: Curves.linear,
          reverseCurve: Curves.linear,
          leaves: false,
        ),
      );
      await tester.pumpAndSettle();
      final rest = _card(tester);
      await tester.tap(find.byType(IconAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_card(tester).width, closeTo(rest.width * 0.75, 0.01));
      await tester.pumpAndSettle();
      expect(find.byType(Modal), findsNothing);
    });
  });
}
