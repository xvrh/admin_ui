import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// An overlay that plays its arrival back as it leaves follows the theme's
// exit curve as time runs. Flutter evaluates a `reverseCurve` at the
// animation's value, which runs from 1 to 0, so each overlay hands over the
// curve flipped; given as it is, an accelerating curve leaves fast and slows
// to a stop.

/// How much of the overlay is left, 1 at rest and 0 once gone, a [share] of
/// the way through leaving on [exit].
double _left(Curve exit, double share) => 1 - exit.transform(share);

/// The shares of the exit each overlay is measured at.
const _shares = [0.25, 0.5, 0.75];

Widget _app(AdminTokens tokens, Widget home) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: _kitLanguages.locales,
  localizationsDelegates: _kitLanguages.delegates,
  home: home,
);

Widget _trigger(void Function(BuildContext context) onTap) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => onTap(context),
        child: const Text('Open'),
      ),
    ),
  ),
);

/// The opacity of the nearest fade around [inside].
double _opacity(WidgetTester tester, Finder inside) => tester
    .widget<FadeTransition>(
      find.ancestor(of: inside, matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;

/// How far out the side sheet has slid: 0 in place, 1 once off the screen.
double _slid(WidgetTester tester) => tester
    .widget<SlideTransition>(
      find
          .ancestor(
            of: find.byType(SideSheet),
            matching: find.byType(SlideTransition),
          )
          .first,
    )
    .position
    .value
    .dx
    .abs();

Duration _share(Duration whole, double share) =>
    Duration(microseconds: (whole.inMicroseconds * share).round());

void main() {
  test('every shipped exit curve accelerates', () {
    // What "leaves on the exit curve" is measured against below: a quarter
    // of the way through, less than a quarter of the move is done.
    for (final theme in adminThemes) {
      final exit = theme.tokens.motion.exit;
      expect(exit.transform(0.25), lessThan(0.25), reason: theme.name);
      expect(exit.transform(0.75), lessThan(0.75), reason: theme.name);
    }
  });

  for (final theme in adminThemes) {
    final tokens = theme.tokens;
    final motion = tokens.motion;

    group(theme.name, () {
      for (final share in _shares) {
        final percent = (share * 100).round();

        testWidgets('a modal is on its exit curve $percent% through leaving', (
          tester,
        ) async {
          final look = tokens.overlay.modalMotion;
          final duration = motion.durationOf(look.speed);
          await tester.pumpWidget(
            _app(
              tokens,
              _trigger(
                (context) => showModal<void>(
                  context,
                  builder: (context) => Modal(
                    title: 'Delete page?',
                    onDismiss: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          final rest = tester.getRect(find.byType(Modal));

          await tester.tap(find.byType(IconAction));
          await tester.pump();
          await tester.pump(_share(duration, share));
          final left = _left(look.reverseCurve ?? motion.exit, share);
          expect(_opacity(tester, find.byType(Modal)), closeTo(left, 0.001));
          // The card is as far along as the fade.
          final card = tester.getRect(find.byType(Modal));
          final scale = look.scale + (1 - look.scale) * left;
          expect(card.width, closeTo(rest.width * scale, 0.01));
          expect(
            card.center.dy,
            closeTo(rest.center.dy - look.slide * (1 - left), 0.01),
          );

          await tester.pumpAndSettle();
          expect(find.byType(Modal), findsNothing);
        });

        testWidgets(
          'a side sheet is on its exit curve $percent% through leaving',
          (tester) async {
            await tester.pumpWidget(
              _app(
                tokens,
                _trigger(
                  (context) => showSideSheet<void>(
                    context,
                    builder: (_) =>
                        const SideSheet(title: 'Sheet', child: Text('Body')),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            expect(_slid(tester), 0);

            await tester.tap(find.byIcon(Icons.close_rounded));
            await tester.pump();
            await tester.pump(_share(motion.slow, share));
            expect(
              _slid(tester),
              closeTo(1 - _left(motion.exit, share), 0.001),
            );

            await tester.pumpAndSettle();
            expect(find.byType(SideSheet), findsNothing);
          },
        );

        testWidgets('a toast is on its exit curve $percent% through leaving', (
          tester,
        ) async {
          await tester.pumpWidget(
            _app(
              tokens,
              ToastScope(
                child: _trigger(
                  (context) =>
                      ToastScope.of(context).show(const Toast('Saved')),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pump();
          await tester.pump(_share(motion.slow, share));
          expect(
            _opacity(tester, find.text('Saved')),
            closeTo(_left(motion.exit, share), 0.001),
          );

          await tester.pumpAndSettle();
          expect(find.text('Saved'), findsNothing);
        });

        testWidgets(
          'a modal on an anchor is on its exit curve $percent% through '
          'leaving',
          (tester) async {
            final controller = ModalAnchorController();
            await tester.pumpWidget(
              _app(
                tokens,
                Scaffold(
                  body: ModalAnchor(
                    controller: controller,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
            controller.show<void>(builder: (_) => const Text('Anchored'));
            await tester.pumpAndSettle();
            expect(_opacity(tester, find.text('Anchored')), 1);

            controller.close();
            await tester.pump();
            await tester.pump(_share(motion.slow, share));
            expect(
              _opacity(tester, find.text('Anchored')),
              closeTo(_left(motion.exit, share), 0.001),
            );

            await tester.pumpAndSettle();
            expect(find.text('Anchored'), findsNothing);
          },
        );
      }
    });
  }

  testWidgets('a leaving overlay starts slowly and ends fast', (tester) async {
    // The property the curve is there for, measured without naming it: a
    // side sheet covers less ground in the first third of its exit than in
    // the last.
    final tokens = adminThemes.first.tokens;
    await tester.pumpWidget(
      _app(
        tokens,
        _trigger(
          (context) => showSideSheet<void>(
            context,
            builder: (_) =>
                const SideSheet(title: 'Sheet', child: Text('Body')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final third = _share(tokens.motion.slow, 1 / 3);
    double left() => tester.getRect(find.byType(SideSheet)).left;

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    final start = left();
    await tester.pump(third);
    final afterFirst = left();
    await tester.pump(third);
    final afterSecond = left();
    await tester.pump(third - const Duration(microseconds: 10));
    final nearEnd = left();

    expect(afterFirst - start, lessThan(afterSecond - afterFirst));
    expect(afterSecond - afterFirst, lessThan(nearEnd - afterSecond));
    await tester.pumpAndSettle();
  });
}
