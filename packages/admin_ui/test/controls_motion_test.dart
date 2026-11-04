import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] under the kit's theme, with the platform asking for less motion
/// when [reduced].
Widget _host(Widget child, {required bool reduced}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: ToastScope(
    child: Scaffold(body: Center(child: child)),
  ),
);

/// A tap target that runs [onPressed] with a context under the host, and
/// draws no ink of its own that would keep frames coming.
Widget _trigger(void Function(BuildContext context) onPressed) => Builder(
  builder: (context) =>
      GestureDetector(onTap: () => onPressed(context), child: const Text('go')),
);

void main() {
  final motion = defaultTokens.motion;

  for (final reduced in [true, false]) {
    final how = reduced ? 'reduced motion' : 'full motion';
    final ends = reduced
        ? 'lands on its end state in one frame'
        : 'animates there';

    /// Checks, one frame after the change, that the widget is where it ends
    /// and no ticker is left running ([reduced]), or that it is still on its
    /// way.
    Future<void> expectOneFrame(
      WidgetTester tester, {
      required bool Function() atEnd,
      required Duration settle,
    }) async {
      await tester.pump();
      if (reduced) {
        expect(atEnd(), isTrue, reason: 'at its end state after one frame');
        expect(tester.binding.transientCallbackCount, 0);
      } else {
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pump(settle ~/ 2);
        expect(atEnd(), isFalse, reason: 'still moving halfway through');
        await tester.pumpAndSettle();
        expect(atEnd(), isTrue);
      }
    }

    testWidgets('$how: a side sheet $ends', (tester) async {
      await tester.pumpWidget(
        _host(
          _trigger(
            (context) => showSideSheet<void>(
              context,
              builder: (_) => const SideSheet(child: Text('Sheet')),
            ),
          ),
          reduced: reduced,
        ),
      );
      final screen = tester.getSize(find.byType(Scaffold)).width;
      await tester.tap(find.text('go'));
      await expectOneFrame(
        tester,
        atEnd: () => tester.getTopRight(find.byType(SideSheet)).dx == screen,
        settle: motion.slow,
      );
    });

    testWidgets('$how: a toast $ends', (tester) async {
      await tester.pumpWidget(
        _host(
          _trigger(
            (context) =>
                ToastScope.of(context)
                    .show(const Toast('Saved.', duration: null)),
          ),
          reduced: reduced,
        ),
      );
      await tester.tap(find.text('go'));
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text('Saved.'),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;
      await expectOneFrame(
        tester,
        atEnd: () => opacity() == 1,
        settle: motion.slow,
      );
    });

    testWidgets('$how: a toggle $ends', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Toggle(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          reduced: reduced,
        ),
      );
      final knob = find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(Container),
      );
      final track = find.byType(AnimatedContainer);
      await tester.tap(find.byType(Toggle));
      await expectOneFrame(
        tester,
        // The knob rests against the track's end, inside its inset.
        atEnd: () =>
            tester.getTopRight(track).dx - tester.getTopRight(knob).dx ==
            (tester.getSize(track).height - tester.getSize(knob).height) / 2,
        settle: motion.fast,
      );
    });

    testWidgets('$how: an accordion $ends', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 320,
            child: Accordion(
              sections: [
                AccordionSection(title: 'Details', child: Text('Body')),
              ],
            ),
          ),
          reduced: reduced,
        ),
      );
      await tester.tap(find.text('Details'));
      double turns() =>
          tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;
      Matrix4 chevron() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(AnimatedRotation),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform;
      await expectOneFrame(
        tester,
        atEnd: () =>
            turns() == 0.5 &&
            find.text('Body').evaluate().isNotEmpty &&
            chevron().storage[0] < -0.999,
        settle: motion.medium,
      );
    });

    testWidgets('$how: a ModalAnchor modal $ends', (tester) async {
      final controller = ModalAnchorController();
      await tester.pumpWidget(
        _host(
          ModalAnchor(
            controller: controller,
            child: _trigger(
              (_) => controller.show<void>(
                builder: (_) => const Material(child: Text('Modal')),
              ),
            ),
          ),
          reduced: reduced,
        ),
      );
      await tester.tap(find.text('go'));
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text('Modal'),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;
      await expectOneFrame(
        tester,
        atEnd: () => opacity() == 1,
        settle: motion.slow,
      );
      controller.close();
      await tester.pumpAndSettle();
    });
  }
}
