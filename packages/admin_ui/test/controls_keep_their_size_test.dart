import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A switch or a checkbox with no label keeps its own size in a box that
// stretches it: it stands at the start, centred in the height, and only the
// control takes the tap.

const _control = Key('control');

final _taps = <bool>[];

Widget _toggle({bool label = false}) => Toggle(
  key: _control,
  value: false,
  label: label ? 'Reduce motion' : null,
  semanticLabel: label ? null : 'Reduce motion',
  onChanged: _taps.add,
);

Widget _check({bool label = false}) => Check(
  key: _control,
  value: false,
  label: label ? 'Reduce motion' : null,
  semanticLabel: label ? null : 'Reduce motion',
  onChanged: _taps.add,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AdminTheme? theme,
  TextDirection direction = TextDirection.ltr,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme((theme ?? irisTheme).tokens),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  ),
);

/// What the control draws: its track, or its box.
Rect _drawn(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byKey(_control),
        matching: find.byWidgetPredicate(
          (w) => w is Container || w is AnimatedContainer,
        ),
      )
      .first,
);

Size _sizeOf(AdminTheme theme, {required bool toggle}) {
  final style = theme.tokens.selection;
  return toggle
      ? Size(style.toggleWidth, style.toggleHeight)
      : Size.square(style.checkSize);
}

void main() {
  setUp(_taps.clear);

  for (final (name, build, toggle) in [
    ('a switch', _toggle, true),
    ('a checkbox', _check, false),
  ]) {
    group('$name with no label', () {
      final natural = _sizeOf(irisTheme, toggle: toggle);

      testWidgets('in a column that fills its width is its own size, at the '
          'start', (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [build()],
            ),
          ),
        );
        final drawn = _drawn(tester);
        expect(drawn.size, natural);
        expect(drawn.left, 0);
        // The widget fills the row it was given; what it draws does not.
        expect(tester.getSize(find.byKey(_control)).width, 400);
      });

      testWidgets('right to left it stands at the right', (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [build()],
            ),
          ),
          direction: TextDirection.rtl,
        );
        final drawn = _drawn(tester);
        expect(drawn.size, natural);
        expect(drawn.right, 400);
      });

      testWidgets('in a box of a fixed size is centred in its height', (
        tester,
      ) async {
        await _pump(tester, SizedBox(width: 400, height: 60, child: build()));
        final drawn = _drawn(tester);
        expect(drawn.size, natural);
        expect(drawn.left, 0);
        expect(drawn.center.dy, 30);
      });

      testWidgets('as the control of a labelled field is its own size, at the '
          'field\'s start', (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 400,
            child: LabeledField(label: 'Motion', child: build()),
          ),
        );
        final drawn = _drawn(tester);
        expect(drawn.size, natural);
        final field = tester.getRect(find.byType(LabeledField));
        expect(drawn.left, field.left);
        expect(drawn.bottom, lessThanOrEqualTo(field.bottom));
      });

      testWidgets('with room of its own is exactly its size', (tester) async {
        await _pump(tester, build());
        expect(tester.getSize(find.byKey(_control)), natural);
        expect(_drawn(tester).size, natural);
      });

      testWidgets('takes a tap on itself, and none on the row beside it', (
        tester,
      ) async {
        await _pump(
          tester,
          SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [build()],
            ),
          ),
        );
        final drawn = _drawn(tester);
        await tester.tapAt(Offset(300, drawn.center.dy));
        await tester.pump();
        expect(_taps, isEmpty);

        await tester.tapAt(drawn.center);
        await tester.pump();
        expect(_taps, [true]);
      });

      testWidgets('is its theme\'s size in every theme', (tester) async {
        for (final theme in adminThemes) {
          await _pump(
            tester,
            SizedBox(width: 400, height: 60, child: build()),
            theme: theme,
          );
          await tester.pumpAndSettle();
          expect(
            _drawn(tester).size,
            _sizeOf(theme, toggle: toggle),
            reason: theme.name,
          );
        }
      });
    });

    testWidgets('$name with a label hugs it, as before, in a box that '
        'stretches it', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [build(label: true)],
          ),
        ),
      );
      final natural = _sizeOf(irisTheme, toggle: toggle);
      final drawn = _drawn(tester);
      expect(drawn.size, natural);
      expect(drawn.left, 0);
      final label = tester.getRect(find.text('Reduce motion'));
      expect(label.left, drawn.right + AdminSpacing.md);

      // The label is part of the target; the rest of the row is not.
      await tester.tapAt(label.center);
      await tester.pump();
      expect(_taps, [true]);
      await tester.tapAt(Offset(390, label.center.dy));
      await tester.pump();
      expect(_taps, [true]);
    });
  }
}
