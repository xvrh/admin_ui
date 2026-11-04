import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Widths no theme ships, so a control that reads a literal instead of the
/// tokens shows.
const _stroke = AdminStroke(
  control: 1.25,
  controlStrong: 1.75,
  fieldFocus: 3,
  fieldError: 2.5,
  indicator: 3,
);

final _tokens = AdminTokens.from(palette: irisPalette, stroke: _stroke);

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

/// The border a [BoxDecoration] under [of] draws, first found.
Border _border(WidgetTester tester, Finder of) {
  final box = tester
      .widgetList<Container>(
        find.descendant(of: of, matching: find.byType(Container)),
      )
      .firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).border is Border,
      );
  return (box.decoration as BoxDecoration).border! as Border;
}

void main() {
  group('field outlines take the stroke tokens', () {
    for (final (name, chrome, width) in [
      ('at rest', const FieldChrome(child: Text('x')), _stroke.control),
      (
        'active',
        const FieldChrome(active: true, child: Text('x')),
        _stroke.fieldFocus,
      ),
      (
        'invalid',
        const FieldChrome(invalid: true, child: Text('x')),
        _stroke.fieldError,
      ),
      (
        'invalid and active',
        const FieldChrome(invalid: true, active: true, child: Text('x')),
        _stroke.fieldFocus,
      ),
    ]) {
      testWidgets('FieldChrome $name', (tester) async {
        await tester.pumpWidget(_host(chrome));
        expect(_border(tester, find.byType(FieldChrome)).top.width, width);
      });
    }

    testWidgets('FieldChrome keeps its content still as the border widens', (
      tester,
    ) async {
      Future<Offset> textAt({required bool active}) async {
        await tester.pumpWidget(
          _host(FieldChrome(active: active, child: const Text('x'))),
        );
        return tester.getTopLeft(find.text('x'));
      }

      expect(await textAt(active: true), await textAt(active: false));
    });

    testWidgets('an InputField', (tester) async {
      FieldBorder border() =>
          tester
                  .widget<InputDecorator>(find.byType(InputDecorator))
                  .decoration
                  .border!
              as FieldBorder;

      await tester.pumpWidget(_host(const InputField(value: 'x')));
      expect(border().chromeOf(const {}).outline.width, _stroke.control);
      expect(
        border().chromeOf({WidgetState.focused}).outline.width,
        _stroke.fieldFocus,
      );

      await tester.pumpWidget(
        _host(const InputField(value: 'x', errorText: 'Wrong')),
      );
      expect(border().chromeOf(const {}).outline.width, _stroke.fieldError);
    });

    testWidgets('a Segmented control', (tester) async {
      await tester.pumpWidget(
        _host(
          Segmented<String>(
            value: 'a',
            onChanged: (_) {},
            segments: const [
              SegmentOption('a', 'List'),
              SegmentOption('b', 'Grid'),
            ],
          ),
        ),
      );
      final group = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(Segmented<String>),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.foregroundDecoration is BoxDecoration);
      final border =
          (group.foregroundDecoration! as BoxDecoration).border! as Border;
      expect(border.top.width, _stroke.control);
    });
  });

  testWidgets('an unchecked Check draws the strong control outline', (
    tester,
  ) async {
    await tester.pumpWidget(_host(Check(value: false, onChanged: (_) {})));
    expect(
      _border(tester, find.byType(Check)).top.width,
      _stroke.controlStrong,
    );
  });

  testWidgets('the underlined tab marks the selection at indicator width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Tabs(
          tabs: const [TabItem('Day'), TabItem('Week')],
          selected: 0,
          onChanged: (_) {},
        ),
      ),
    );
    final bars = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(Tabs),
            matching: find.byType(Container),
          ),
        )
        .where((c) => c.color == _tokens.palette.controlAccent);
    expect(bars, isNotEmpty);
    for (final bar in bars) {
      expect(bar.constraints?.maxHeight, _stroke.indicator);
    }
  });
}
